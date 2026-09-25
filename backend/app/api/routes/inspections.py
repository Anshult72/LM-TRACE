import base64
import os
import uuid
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from fastapi.responses import FileResponse, Response
from app.schemas.domain import (
    InspectionCreate, InspectionUpdate, FinalizeInspectionRequest,
    InspectionResponse, ImageResponse, ComplianceAssessmentResponse
)

from app.repositories import get_repository
from app.core.security import get_current_user_payload
from app.storage.file_storage import storage_manager
from app.services.vision.cv_service import cv_service
from app.services.vision.pdp_measurement_service import pdp_measurement_service
from app.services.ocr import get_ocr_service
from app.services.llm import get_llm_service
from app.services.declaration.correctness_service import declaration_correctness_service
from app.services.declaration.applicability_service import declaration_applicability_service
from app.services.declaration.placement_service import declaration_placement_service
from app.engines.compliance_engine.compliance_engine import compliance_engine
from app.engines.rule_engine.rule_engine import rule_engine
from app.services.evidence.evidence_service import evidence_service
from app.core.config import settings
from app.core.logging import logger
from app.services.inspection.surface_validator import validate_inspection_surfaces, REQUIRED_SURFACE_CODES, ALLOWED_SURFACE_CODES
from app.services.product.product_intelligence_service import product_intelligence_service
from app.services.audit.audit_service import audit_service
import shutil
from app.services.storage.cloudinary_service import cloudinary_storage_service

router = APIRouter(prefix="/api/inspections", tags=["Inspections"])


def get_utc_now_iso():
    return datetime.now(timezone.utc).isoformat()

@router.post("", response_model=Dict[str, Any])
async def create_inspection(
    req: InspectionCreate,
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    code_suffix = uuid.uuid4().hex[:5].upper()
    inspection_code = f"INS-2026-{code_suffix}"
    
    loc = req.location
    if req.inspection_type == "ONLINE_LISTING" and ("Field Scan" in loc or not loc):
        loc = f"Online Listing ({req.marketplace or 'E-Commerce Marketplace'})"

    ins_data = {
        "id": f"ins-{uuid.uuid4().hex[:12]}",
        "inspection_code": inspection_code,
        "inspector_id": user_payload["sub"],
        "product_id": None,
        "inspection_type": req.inspection_type,
        "inspection_date": get_utc_now_iso(),
        "location": loc,
        "seller_name": req.seller_name,
        "business_name": req.business_name,
        "status": "DRAFT",
        "score": None,
        "package_type": req.package_type,
        "package_construction_type": req.package_construction_type,
        "calibration_status": "NOT_CALIBRATED",
        "listing_url": req.listing_url,
        "canonical_url": req.canonical_url,
        "marketplace": req.marketplace,
        "listing_metadata": req.listing_metadata,
        "rule_snapshot": {
            "product_category": req.product_category,
            "applicability_context": req.applicability_context.model_dump(),
        },
        "notes": req.notes
    }

    created = await repo.create(ins_data)

    act_name = "ECOMMERCE_LISTING_CREATED" if req.inspection_type == "ONLINE_LISTING" else "INSPECTION_CREATED"
    await audit_service.record_event(
        action=act_name,
        actor_id=user_payload["sub"],
        actor_name=user_payload.get("full_name") or user_payload.get("sub"),
        role=user_payload.get("role", "INSPECTOR"),
        resource_type="INSPECTION",
        resource_id=created["id"],
        inspection_id=created["id"],
        result="SUCCESS",
        description=f"Inspection case {inspection_code} created for {req.product_category} at {req.location}.",
        new_value={"code": inspection_code, "location": req.location, "product_category": req.product_category}
    )

    return created

@router.get("", response_model=List[Dict[str, Any]])
async def list_inspections(
    status: Optional[str] = None,
    query: Optional[str] = None,
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    # If inspector, filter own unless supervisor/admin
    inspector_id = user_payload["sub"] if user_payload["role"] == "INSPECTOR" else None
    return await repo.list_inspections(inspector_id=inspector_id, status=status, query=query)

@router.get("/{inspection_id}", response_model=Dict[str, Any])
async def get_inspection(
    inspection_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")
    return ins

@router.patch("/{inspection_id}", response_model=Dict[str, Any])
async def update_inspection(
    inspection_id: str,
    req: Dict[str, Any],
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")
    if ins.get("status") == "FINALIZED":
        if settings.is_demo_mode:
            logger.info("Reopening finalized inspection %s for demo modification", inspection_id)
            await repo.update(inspection_id, {"status": "DRAFT", "finalized_at": None})
        else:
            raise HTTPException(status_code=400, detail="Cannot modify a finalized inspection. Please select an in-progress case or create a new case.")

    updates = dict(req)
    if "calibration_data" in updates:
        calibration = updates.get("calibration_data")
        if not isinstance(calibration, dict):
            raise HTTPException(status_code=400, detail="Calibration data must be an object.")
        point1 = calibration.get("point1")
        point2 = calibration.get("point2")
        known_distance = calibration.get("knownDistance") or calibration.get("known_distance_mm")
        if calibration.get("planeVerified") is not True:
            raise HTTPException(status_code=400, detail="Calibration reference must be confirmed on the same plane as the declaration.")
        try:
            known_distance = float(known_distance)
        except (TypeError, ValueError):
            raise HTTPException(status_code=400, detail="Known calibration distance must be a positive number.")
        pixels_per_mm, calibration_status, calibration_confidence = pdp_measurement_service.derive_scale_from_known_distance(
            point1, point2, known_distance
        )
        if calibration_status != "CALIBRATED":
            raise HTTPException(status_code=400, detail="Calibration points are too close or invalid for a reliable scale.")
        calibration["knownDistance"] = known_distance
        calibration["pixelsPerMm"] = pixels_per_mm
        calibration["confidence"] = calibration_confidence
        calibration["planeVerified"] = True
        updates["calibration_data"] = calibration
        updates["calibration_status"] = calibration_status

    if "pdp_data" in updates:
        pdp_data = updates.get("pdp_data")
        if not isinstance(pdp_data, dict):
            raise HTTPException(status_code=400, detail="PDP measurement data must be an object.")
        raw_area = pdp_data.get("areaCm2") or pdp_data.get("area_cm2")
        try:
            area_cm2 = float(raw_area)
        except (TypeError, ValueError):
            raise HTTPException(status_code=400, detail="PDP area must be a positive number in square centimetres.")
        if not 0 < area_cm2 <= 1_000_000:
            raise HTTPException(status_code=400, detail="PDP area is outside the supported physical range.")
        pdp_data["areaCm2"] = round(area_cm2, 4)
        pdp_data.setdefault("method", "OFFICER_MEASURED")
        pdp_data.setdefault("confidence", 0.95)
        updates["pdp_data"] = pdp_data
    if "applicability_context" in updates or "product_category" in updates:
        snapshot = dict(ins.get("rule_snapshot") or {})
        if "applicability_context" in updates:
            context_value = updates.pop("applicability_context")
            snapshot["applicability_context"] = (
                context_value.model_dump() if hasattr(context_value, "model_dump") else context_value
            )
        if "product_category" in updates:
            snapshot["product_category"] = updates.pop("product_category")
        updates["rule_snapshot"] = snapshot
    updated = await repo.update(inspection_id, updates)
    return updated

@router.post("/{inspection_id}/images", response_model=Dict[str, Any])
async def upload_image(
    inspection_id: str,
    surface_type: str = Form("FRONT"),
    file: UploadFile = File(...),
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")
    if ins.get("status") == "FINALIZED":
        if settings.is_demo_mode:
            logger.info("Reopening finalized inspection %s for demo image upload", inspection_id)
            await repo.update(inspection_id, {"status": "DRAFT", "finalized_at": None})
        else:
            raise HTTPException(
                status_code=400,
                detail="Cannot add images to a finalized inspection. Please select an in-progress case or create a new case."
            )

    normalized_surface = (surface_type or "").strip().upper()
    if normalized_surface not in ALLOWED_SURFACE_CODES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid package surface. Use one of: {', '.join(ALLOWED_SURFACE_CODES)}.",
        )

    file_bytes = await file.read()
    try:
        orig_path, thumb_path, width, height, sha256 = await storage_manager.save_inspection_image(
            inspection_id, file_bytes, file.filename or "surface.jpg"
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    # Perform CV Image Quality Assessment
    quality_info = cv_service.assess_image_quality(orig_path)

    # Persist image bytes as base64 in the quality_details JSON so images
    # survive Railway's ephemeral filesystem restarts without needing a
    # schema migration or external object storage.
    quality_info["_image_b64"] = base64.b64encode(file_bytes).decode("ascii")

    image_record = {
        "id": f"img-{uuid.uuid4().hex[:8]}",
        "inspection_id": inspection_id,
        "surface_type": normalized_surface,
        "original_path": orig_path,
        "thumbnail_path": thumb_path,
        "width": width,
        "height": height,
        "mime_type": file.content_type or "image/jpeg",
        "file_size": len(file_bytes),
        "quality_score": quality_info["quality_score"],
        "quality_assessment": quality_info["assessment"],
        "quality_details": quality_info
    }

    # Supersede older image(s) for the same surface to ensure fresh replacement state
    existing_images = ins.get("images") or []
    norm_surface = normalized_surface
    for prev_img in existing_images:
        if (prev_img.get("surface_type") or "").upper() == norm_surface:
            prev_id = prev_img.get("id")
            if prev_id:
                try:
                    await repo.delete_image(inspection_id, prev_id)
                except Exception as del_err:
                    logger.warning("Could not delete superseded image %s: %s", prev_id, del_err)

    saved_img = await repo.add_image(inspection_id, image_record)

    await audit_service.record_event(
        action="EVIDENCE_UPLOADED",
        actor_id=user_payload["sub"],
        actor_name=user_payload.get("full_name") or user_payload.get("sub"),
        role=user_payload.get("role", "INSPECTOR"),
        resource_type="INSPECTION_IMAGE",
        resource_id=saved_img["id"],
        inspection_id=inspection_id,
        result="SUCCESS",
        description=f"Uploaded {normalized_surface} surface package image for inspection {ins.get('code', inspection_id)}.",
        metadata={"surface": normalized_surface, "sha256": sha256, "image_id": saved_img["id"]}
    )

    return saved_img

@router.get("/{inspection_id}/images/{image_id}")
async def get_inspection_image(
    inspection_id: str,
    image_id: str,
):
    """Retrieve raw image file for an inspection.
    Attempts local disk read, and gracefully falls back to recovering image bytes
    from quality_details base64 storage if running on an ephemeral Railway container."""
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")

    images = ins.get("images", [])
    target = next((img for img in images if img.get("id") == image_id), None)
    if not target:
        raise HTTPException(status_code=404, detail="Image not found")

    orig_path = target.get("original_path")
    mime = target.get("mime_type") or "image/jpeg"

    if orig_path and os.path.isfile(orig_path):
        return FileResponse(orig_path, media_type=mime)

    # Ephemeral Railway fallback: restore from quality_details base64
    quality_details = target.get("quality_details") or {}
    b64_data = quality_details.get("_image_b64")
    if b64_data:
        try:
            raw_bytes = base64.b64decode(b64_data)
            return Response(content=raw_bytes, media_type=mime)
        except Exception:
            logger.warning("Failed to decode base64 image data for %s", image_id)

    raise HTTPException(status_code=404, detail="Image content unavailable")

@router.delete("/{inspection_id}/images/{image_id}")
async def delete_image(
    inspection_id: str,
    image_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")
    if ins.get("status") == "FINALIZED":
        if settings.is_demo_mode:
            await repo.update(inspection_id, {"status": "DRAFT", "finalized_at": None})
        else:
            raise HTTPException(status_code=400, detail="Cannot delete images from a finalized inspection")
    deleted = await repo.delete_image(inspection_id, image_id)
    return {"success": deleted}

@router.delete("/{inspection_id}")
async def delete_inspection(
    inspection_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Strict Admin-Only Deletion of an Inspection case.
    Rejects any non-ADMIN role with 403 Forbidden before initiating deletion.
    Cascades safely through dependent tables and cleans associated Cloudinary evidence.
    """
    user_role = (user_payload.get("role") or "").upper()
    if user_role != "ADMIN":
        logger.warning(
            "Unauthorized deletion attempt on inspection %s by user %s with role %s",
            inspection_id, user_payload.get("sub"), user_role
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "code": "FORBIDDEN",
                "message": f"Access denied: Only administrators can delete inspections. Role '{user_role}' is not authorized.",
                "details": None
            }
        )

    repo = get_repository()

    # Verify existence
    existing = await repo.get_by_id(inspection_id)
    if not existing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "code": "INSPECTION_NOT_FOUND",
                "message": f"Inspection '{inspection_id}' not found.",
                "details": None
            }
        )

    del_result = await repo.delete_inspection(inspection_id)
    if not del_result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={
                "code": "INSPECTION_NOT_FOUND",
                "message": f"Inspection '{inspection_id}' not found.",
                "details": None
            }
        )

    actual_id = del_result.get("inspection_id", inspection_id)
    code = del_result.get("inspection_code", inspection_id)
    cloudinary_pids = del_result.get("cloudinary_public_ids", [])

    # Clean Cloudinary evidence assets belonging specifically to this inspection
    if cloudinary_pids:
        for c_pid in cloudinary_pids:
            try:
                await cloudinary_storage_service.delete_evidence_image(c_pid)
                logger.info("Cleaned Cloudinary evidence asset: %s", c_pid)
            except Exception as c_err:
                logger.warning("Could not delete Cloudinary asset %s: %s", c_pid, c_err)

    # Clean local storage folder if it exists
    try:
        local_folder = os.path.join(storage_manager.inspections_dir, actual_id)
        if os.path.exists(local_folder):
            shutil.rmtree(local_folder, ignore_errors=True)
            logger.info("Cleaned local inspection directory: %s", local_folder)
    except Exception as fs_err:
        logger.warning("Could not clean local storage folder: %s", fs_err)

    # Record audit trail event
    await audit_service.record_event(
        action="INSPECTION_DELETED",
        actor_id=user_payload["sub"],
        actor_name=user_payload.get("full_name") or user_payload.get("sub"),
        role=user_role,
        resource_type="INSPECTION",
        resource_id=actual_id,
        inspection_id=actual_id,
        result="SUCCESS",
        description=f"Inspection case {code} was permanently deleted by administrator {user_payload.get('full_name') or user_payload.get('sub')}.",
        old_value={"code": code, "status": del_result.get("status")}
    )

    return {
        "success": True,
        "message": f"Inspection {code} successfully deleted.",
        "deleted_id": actual_id
    }

@router.get("/{inspection_id}/required-surfaces", response_model=Dict[str, Any])
async def get_required_surfaces(
    inspection_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    """Authoritative real-time validation of required package surfaces for an inspection."""
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")
    return validate_inspection_surfaces(ins)

@router.post("/{inspection_id}/analyze", response_model=Dict[str, Any])
async def analyze_product(
    inspection_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Full AI-Assisted Pipeline:
    1. OCR extraction on captured images
    2. LLM semantic normalization referencing OCR block IDs
    3. Declaration Correctness & Cross-Field Consistency evaluation
    4. Versioned Rule Engine & Rule 7 Table-I PDP threshold resolution
    5. Computer Vision readability & placement analysis
    6. Deterministic Compliance Engine assessment
    """
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")

    # Validate ALL required product surfaces BEFORE executing any AI, OCR, CV, or Rule engines
    validation = validate_inspection_surfaces(ins)
    if not validation["valid"]:
        missing_str = ", ".join(validation["missing_surfaces"])
        raise HTTPException(
            status_code=400,
            detail={
                "code": "REQUIRED_IMAGES_MISSING",
                "message": f"All required product images must be uploaded before analysis. Missing: {missing_str}",
                "required_count": validation["required_count"],
                "completed_count": validation["completed_count"],
                "missing_surfaces": validation["missing_surfaces"],
                "completed_surfaces": validation["completed_surfaces"],
            }
        )

    images = ins.get("images", [])

    # ── Restore missing image files from database-persisted base64 ──
    # Railway (like Render) uses an ephemeral filesystem; uploaded images
    # vanish on redeploy.  Re-materialise them from the base64 payload
    # stored in quality_details at upload time.
    for img_record in images:
        orig = img_record.get("original_path")
        if orig and not os.path.isfile(orig):
            qd = img_record.get("quality_details") or {}
            b64_data = qd.get("_image_b64")
            if b64_data:
                try:
                    os.makedirs(os.path.dirname(orig), exist_ok=True)
                    with open(orig, "wb") as f:
                        f.write(base64.b64decode(b64_data))
                    logger.info("Restored missing image from DB: %s", orig)
                except Exception as restore_err:
                    logger.warning("Could not restore image %s: %s", orig, restore_err)

    # Update status — any failure below must reset to DRAFT so the case is not stuck.
    await repo.update(inspection_id, {"status": "ANALYSING"})

    try:
        # Step 1: OCR extraction
        ocr_service = get_ocr_service()
        try:
            ocr_results = await ocr_service.extract_text_from_images(images)
        except FileNotFoundError as exc:
            logger.warning("Image file missing for %s: %s", inspection_id, exc)
            raise HTTPException(
                status_code=400,
                detail=(
                    "Captured package images are no longer available in server storage. "
                    "Please re-capture or re-upload the package photos."
                ),
            ) from exc
        except RuntimeError as exc:
            err_msg = str(exc).lower()
            if "no longer available" in err_msg or "storage" in err_msg:
                logger.warning("Image storage error for %s: %s", inspection_id, exc)
                raise HTTPException(
                    status_code=400,
                    detail=(
                        "Captured package images are no longer available in server storage. "
                        "Please re-capture or re-upload the package photos."
                    ),
                ) from exc
            logger.warning("OCR service error for %s: %s", inspection_id, exc)
            raise HTTPException(status_code=503, detail=str(exc)) from exc

        # Step 2: LLM Normalization
        llm_service = get_llm_service()
        configured_category = (ins.get("rule_snapshot") or {}).get("product_category") or "General Packaged Commodity"
        extracted_payload = await llm_service.extract_declarations(ocr_results, product_category=configured_category)

        # Step 3: Declaration Correctness & Consistency
        all_ocr_blocks = []
        for r in ocr_results:
            all_ocr_blocks.extend(r.blocks)

        if not all_ocr_blocks:
            raise HTTPException(
                status_code=400,
                detail="No readable text detected on the package images. Please capture a clear, well-lit photo of the label declarations."
            )

        ocr_summary = [
            {
                "image_id": result.image_id,
                "surface_type": next(
                    (img.get("surface_type") for img in images if img.get("id") == result.image_id),
                    "UNKNOWN",
                ),
                "block_count": len(result.blocks),
                "confidence": result.confidence,
                "raw_text": result.raw_text,
                "blocks": [block.model_dump() for block in result.blocks],
            }
            for result in ocr_results
        ]

        await audit_service.record_event(
            action="OCR_COMPLETED",
            actor_id=user_payload["sub"],
            actor_name=user_payload.get("full_name") or user_payload.get("sub"),
            role=user_payload.get("role", "INSPECTOR"),
            resource_type="INSPECTION",
            resource_id=inspection_id,
            inspection_id=inspection_id,
            result="SUCCESS",
            description=f"Multi-surface OCR text extraction completed ({len(all_ocr_blocks)} text blocks identified across {len(ocr_results)} surfaces).",
            metadata={"blocks_count": len(all_ocr_blocks), "surfaces_analyzed": len(ocr_results)}
        )

        rule_context, applicability_inferences = declaration_applicability_service.build_context(ins, extracted_payload)
        correctness_data = declaration_correctness_service.evaluate_correctness(
            extracted_payload, all_ocr_blocks, is_imported=rule_context["isImported"]
        )

        # Step 4: Map declarations to database records
        declarations_records = []
        blocks_by_id = {block.block_id: block for block in all_ocr_blocks}
        matrix = correctness_data.get("matrix", [])
        for idx, item in enumerate(matrix):
            field_name = item["field_name"]
            val = item.get("value")
            source_block = blocks_by_id.get(item.get("source_block_id"))
            declarations_records.append({
                "id": f"dec-{inspection_id}-{idx + 1}",
                "inspection_id": inspection_id,
                "field_name": field_name,
                "ai_value": val,
                "verified_value": val,
                "unit": item.get("canonical_unit"),
                "confidence": item.get("confidence", 0.95),
                "source_image_id": item.get("source_image_id") or (source_block.image_id if source_block else None),
                "source_block_id": item.get("source_block_id"),
                "source_text": item.get("source_text") or (source_block.text if source_block else None),
                "bbox": item.get("bbox") or (source_block.bbox.model_dump() if source_block else None),
                "presence_status": "DETECTED" if item.get("presence") else "MISSING",
                "correctness_status": item.get("correctness", "VALID"),
                "verification_status": "PENDING",
                "provenance": "AI_EXTRACTED"
            })

        # Persist the complete extraction schema, not only the smaller
        # correctness matrix. This makes every prescribed/conditional field
        # visible as DETECTED or MISSING and retains its OCR provenance.
        extracted_fields = extracted_payload.model_dump()
        matrix_by_field = {item.get("field_name"): item for item in matrix if item.get("field_name")}
        correctness_aliases = {
            "manufacturer_name": "manufacturer",
            "manufacturer_address": "manufacturer",
            "importer_name": "importer",
            "importer_address": "importer",
            "manufacturing_date": "manufacturing_packing_date",
            "packing_date": "manufacturing_packing_date",
            "import_date": "manufacturing_packing_date",
        }
        represented_fields = {record["field_name"] for record in declarations_records}
        for field_name, semantic in extracted_fields.items():
            if field_name in represented_fields:
                continue
            semantic = semantic or {}
            value = semantic.get("value") if isinstance(semantic, dict) else None
            source_block_id = semantic.get("source_block_id") if isinstance(semantic, dict) else None
            source_block = blocks_by_id.get(source_block_id)
            corr_item = matrix_by_field.get(field_name) or matrix_by_field.get(correctness_aliases.get(field_name)) or {}
            declarations_records.append({
                "id": f"dec-{inspection_id}-{len(declarations_records) + 1}",
                "inspection_id": inspection_id,
                "field_name": field_name,
                "ai_value": value,
                "verified_value": value,
                "unit": semantic.get("canonical_unit") or semantic.get("unit") if isinstance(semantic, dict) else None,
                "confidence": semantic.get("confidence", 0.0) if isinstance(semantic, dict) else 0.0,
                "source_image_id": semantic.get("source_image_id") or (source_block.image_id if source_block else None) if isinstance(semantic, dict) else None,
                "source_block_id": source_block_id,
                "source_text": semantic.get("source_text") or (source_block.text if source_block else None) if isinstance(semantic, dict) else None,
                "bbox": semantic.get("bbox") or (source_block.bbox.model_dump() if source_block else None) if isinstance(semantic, dict) else None,
                "presence_status": "DETECTED" if value else "MISSING",
                "correctness_status": corr_item.get("correctness", "UNVERIFIED"),
                "verification_status": "PENDING",
                "provenance": semantic.get("provenance", "AI_EXTRACTED") if isinstance(semantic, dict) else "AI_EXTRACTED",
            })

        await repo.save_declarations(inspection_id, declarations_records)

        # Step 5: Rule & Compliance Engine
        pdp_info = ins.get("pdp_data")
        calibration_info = ins.get("calibration_data") or {}
        rule_context["inspectionDate"] = ins.get("inspection_date") or get_utc_now_iso()
        rule_context["pdpAreaCm2"] = (
            pdp_info.get("areaCm2") or pdp_info.get("area_cm2")
            if isinstance(pdp_info, dict) else None
        )
        rule_context["pdpBbox"] = (
            pdp_info.get("bbox") or pdp_info.get("selected_pdp_bbox")
            if isinstance(pdp_info, dict) else None
        )
        rule_context["pdpImageId"] = (
            pdp_info.get("imageId") or pdp_info.get("image_id")
            if isinstance(pdp_info, dict) else None
        )
        rule_context["pixelsPerMm"] = (
            calibration_info.get("pixelsPerMm") or calibration_info.get("pixels_per_mm")
            if isinstance(calibration_info, dict) else None
        )
        rule_context["calibrationImageId"] = (
            calibration_info.get("image_id") or calibration_info.get("imageId")
            if isinstance(calibration_info, dict) else None
        )

        # This is measured from the captured photo; no default quality values are
        # used when the image cannot be analysed.
        applicable_rules = await rule_engine.get_applicable_rules(rule_context)
        required_declarations = rule_engine.determine_required_declarations(applicable_rules, rule_context)
        placement_results = declaration_placement_service.evaluate(
            required_declarations, declarations_records, rule_context, images
        )
        image_by_id = {item.get("id"): item for item in images if isinstance(item, dict)}
        declarations_by_field = {item.get("field_name"): item for item in declarations_records}
        readability_results = []
        typography_results = []
        typography_fields = {"net_quantity", "mrp", "best_before", "consumer_care"}
        for field, requirement in required_declarations.items():
            if not requirement.get("required"):
                continue
            candidates = [field] + list(requirement.get("alternatives") or [])
            declaration = next(
                (declarations_by_field.get(candidate) for candidate in candidates if declarations_by_field.get(candidate, {}).get("ai_value")),
                None,
            )
            if not declaration:
                continue
            source_image = image_by_id.get(declaration.get("source_image_id")) or {}
            source_path = source_image.get("original_path")
            readability = cv_service.evaluate_readability(source_path, declaration.get("bbox"))
            readability_results.append({"field_name": field, "matched_field": declaration.get("field_name"), **readability})
            if field in typography_fields:
                geometry = cv_service.measure_character_geometry(
                    source_path,
                    declaration.get("bbox"),
                    declaration.get("source_text") or declaration.get("ai_value"),
                )
                typography_results.append({
                    "field_name": field,
                    "matched_field": declaration.get("field_name"),
                    "source_image_id": declaration.get("source_image_id"),
                    **geometry,
                })
        visual_analysis = {
            "readability_results": readability_results,
            "typography_results": typography_results,
        }

        await audit_service.record_event(
            action="CV_ANALYSIS_COMPLETED",
            actor_id=user_payload["sub"],
            actor_name=user_payload.get("full_name") or user_payload.get("sub"),
            role=user_payload.get("role", "INSPECTOR"),
            resource_type="INSPECTION",
            resource_id=inspection_id,
            inspection_id=inspection_id,
            result="SUCCESS",
            description=f"Computer Vision PDP and typography analysis completed ({len(readability_results)} readability checks, {len(typography_results)} character height measurements).",
            metadata={"readability_count": len(readability_results), "typography_count": len(typography_results)}
        )

        compliance_assessment = await compliance_engine.evaluate_compliance(
            extracted_declarations=extracted_payload.model_dump(),
            correctness_data=correctness_data,
            context=rule_context,
            readability_data=visual_analysis,
            placement_data=placement_results,
        )

        await audit_service.record_event(
            action="RULE_EVALUATION_COMPLETED",
            actor_id=user_payload["sub"],
            actor_name=user_payload.get("full_name") or user_payload.get("sub"),
            role=user_payload.get("role", "INSPECTOR"),
            resource_type="INSPECTION",
            resource_id=inspection_id,
            inspection_id=inspection_id,
            result="SUCCESS",
            description=f"Statutory rule applicability evaluated ({len(applicable_rules)} active rules applied under Legal Metrology Act).",
            metadata={"applicable_rules_count": len(applicable_rules), "rule_version": "2024.1"}
        )

        await audit_service.record_event(
            action="COMPLIANCE_EVALUATION_COMPLETED",
            actor_id=user_payload["sub"],
            actor_name=user_payload.get("full_name") or user_payload.get("sub"),
            role=user_payload.get("role", "INSPECTOR"),
            resource_type="INSPECTION",
            resource_id=inspection_id,
            inspection_id=inspection_id,
            result="SUCCESS",
            description=f"Compliance assessment evaluated: score {compliance_assessment.score}%, {len(compliance_assessment.checks)} checks, {len(compliance_assessment.potential_violations)} violations.",
            metadata={"score": compliance_assessment.score, "checks": len(compliance_assessment.checks), "violations": len(compliance_assessment.potential_violations)}
        )

        # Convert checks and violations to records
        check_records = []
        for idx, c in enumerate(compliance_assessment.checks):
            check_records.append({
                "id": f"chk-{inspection_id}-{idx + 1}",
                "inspection_id": inspection_id,
                "check_type": c.check_type,
                "field_name": c.field_name,
                "rule_code": c.rule_code,
                "rule_version": c.rule_version,
                "input_value": c.input_value,
                "expected_condition": c.expected_condition,
                "result": c.result,
                "confidence": c.confidence,
                "explanation": c.explanation,
                "source_reference": c.source_reference,
                "evidence_id": c.evidence_id,
            })

        violation_records = []
        for idx, v in enumerate(compliance_assessment.potential_violations):
            if isinstance(v, dict):
                v_type = v.get("type", "UNKNOWN")
                v_sev = v.get("severity", "HIGH")
                v_conf = v.get("confidence", 0.95)
                v_exp = v.get("explanation") or v.get("ai_explanation")
            else:
                v_type = str(v)
                v_sev = "HIGH"
                v_conf = 0.95
                v_exp = str(v)
            violation_records.append({
                "id": f"viol-{inspection_id}-{idx + 1}",
                "inspection_id": inspection_id,
                "type": v_type,
                "severity": v_sev,
                "confidence": v_conf,
                "status": "AI_DETECTED",
                "provenance": "AI_DETECTED",
                "ai_explanation": v_exp,
                "inspector_comment": None,
                "field": v.get("field") if isinstance(v, dict) else None,
                "bbox": v.get("bbox") if isinstance(v, dict) else None,
                "source_image_id": v.get("source_image_id") if isinstance(v, dict) else None,
                "source_reference": v.get("source_reference") if isinstance(v, dict) else None,
            })

        await repo.save_compliance_results(inspection_id, check_records, violation_records)

        # Step 6: Generate preprocessed evidence crops & annotated overlays, upload to Cloudinary & persist in Neon
        evidence_records = []
        try:
            evidence_records = await evidence_service.process_inspection_evidence(
                inspection_id=inspection_id,
                images=images,
                declarations=declarations_records,
                violations=violation_records,
                checks=check_records,
            )
            if evidence_records:
                saved_ev = await repo.save_evidence_items(inspection_id, evidence_records)
                evidence_records = saved_ev or evidence_records
                logger.info("Archived %d evidence items for inspection %s", len(evidence_records), inspection_id)
        except Exception as ev_err:
            logger.warning("Evidence processing warning for %s: %s", inspection_id, ev_err)

        # Update inspection status & score
        final_status = "NEEDS_REVIEW" if (compliance_assessment.review_count > 0 or compliance_assessment.violation_count > 0) else "READY"
        analysis_snapshot = dict(ins.get("rule_snapshot") or {})
        analysis_snapshot.update({
            "resolved_applicability_context": rule_context,
            "applicability_inferences": applicability_inferences,
            "required_declarations": required_declarations,
            "placement_results": placement_results,
            "visual_analysis": visual_analysis,
            "resolved_at": get_utc_now_iso(),
        })
        await repo.update(inspection_id, {
            "status": final_status,
            "score": compliance_assessment.score,
            "applied_rule_version": "2024.1",
            "rule_snapshot": analysis_snapshot,
        })

        # Step 7: Automatic Product Identification, Fingerprinting & Version Linking
        product_detail = None
        try:
            product_detail = await product_intelligence_service.identify_and_link_product(
                inspection=ins,
                declarations=declarations_records,
                images=images
            )
        except Exception as prod_err:
            logger.warning("Product identification warning for inspection %s: %s", inspection_id, prod_err)

        return {
            "success": True,
            "status": final_status,
            "score": compliance_assessment.score,
            "assessment": compliance_assessment.model_dump(),
            "declarations": declarations_records,
            "correctness_matrix": matrix,
            "ocr_summary": ocr_summary,
            "applicability": {
                "context": rule_context,
                "inferences": applicability_inferences,
            },
            "required_declarations": required_declarations,
            "placement_results": placement_results,
            "visual_analysis": visual_analysis,
            "evidence": evidence_records,
            "product": product_detail.get("product") if product_detail else None,
        }
    except HTTPException:
        await repo.update(inspection_id, {"status": "DRAFT"})
        raise
    except Exception as exc:
        logger.exception("Analysis failed for inspection %s", inspection_id)
        await repo.update(inspection_id, {"status": "DRAFT"})
        raise HTTPException(status_code=500, detail=f"Analysis failed: {exc}") from exc

@router.get("/{inspection_id}/evidence", response_model=List[Dict[str, Any]])
async def get_inspection_evidence(
    inspection_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Returns all preprocessed Cloudinary evidence images, crops, overlays, and SHA-256 integrity digests.
    """
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")
    return await repo.list_evidence(inspection_id)

@router.post("/{inspection_id}/evidence/{evidence_id}/retry", response_model=Dict[str, Any])
async def retry_evidence_upload(
    inspection_id: str,
    evidence_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Retries Cloudinary upload for an evidence record without creating duplicate items.
    """
    repo = get_repository()
    ev = await repo.get_evidence_by_id(evidence_id)
    if not ev:
        raise HTTPException(status_code=404, detail="Evidence record not found")
    if ev.get("inspection_id") != inspection_id:
        raise HTTPException(status_code=400, detail="Evidence does not belong to this inspection")

    try:
        updated = await evidence_service.retry_evidence_upload(ev, repo)
        return {"success": True, "evidence": updated}
    except Exception as e:
        logger.error("Retry failed for evidence %s: %s", evidence_id, e)
        raise HTTPException(status_code=500, detail=f"Evidence upload retry failed: {e}")

@router.post("/{inspection_id}/finalize", response_model=Dict[str, Any])
async def finalize_inspection(
    inspection_id: str,
    req: Optional[FinalizeInspectionRequest] = None,
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")
    if ins.get("status") == "FINALIZED":
        return {"message": "Inspection already finalized", "inspection": ins}

    # RBAC ownership check: inspectors can only finalize their own inspection
    if user_payload.get("role") == "INSPECTOR" and ins.get("inspector_id") and ins.get("inspector_id") != user_payload.get("sub"):
        raise HTTPException(status_code=403, detail="You do not have permission to finalize this inspection.")

    # Merge finalization details if submitted
    additional_updates: Dict[str, Any] = {}
    if req:
        req_dict = req.model_dump(exclude_unset=True) if hasattr(req, "model_dump") else req
        for field in [
            "business_name", "location", "seller_name", "product_category",
            "inspection_type", "package_type", "package_construction_type", "notes"
        ]:
            if field in req_dict and req_dict[field] is not None:
                additional_updates[field] = req_dict[field]

        if req_dict.get("product_category") is not None or req_dict.get("applicability_context") is not None:
            snapshot = dict(ins.get("rule_snapshot") or {})
            if req_dict.get("product_category") is not None:
                snapshot["product_category"] = req_dict["product_category"]
            if req_dict.get("applicability_context") is not None:
                snapshot["applicability_context"] = req_dict["applicability_context"]
            additional_updates["rule_snapshot"] = snapshot

    # Validate statutory requirements
    effective_business_name = (additional_updates.get("business_name") or ins.get("business_name") or "").strip()
    effective_location = (additional_updates.get("location") or ins.get("location") or "").strip()

    if not effective_business_name:
        raise HTTPException(
            status_code=400,
            detail="Establishment / Trader Name is required to finalize inspection."
        )

    if not effective_location or effective_location == "Field Scan (Pending Finalisation)":
        raise HTTPException(
            status_code=400,
            detail="A valid inspection location address is required to finalize inspection."
        )

    # Verification: Ensure inspection has captured packaging or analysis records
    has_images = bool(ins.get("images"))
    has_analysis = bool(ins.get("declarations") or ins.get("checks") or ins.get("score") is not None)
    if not (has_images or has_analysis):
        raise HTTPException(
            status_code=400,
            detail="Cannot finalize an inspection before package scanning and statutory analysis."
        )

    # Seal immutable snapshot
    snapshot_data = dict(ins.get("rule_snapshot") or {})
    snapshot_data.update({
        "inspection_code": ins.get("inspection_code"),
        "finalized_at": get_utc_now_iso(),
        "finalized_by": user_payload["sub"],
        "officer_name": user_payload.get("full_name", "Officer"),
        "applied_rule_versions": ["RULE-006:v2024.1", "RULE-007:v2024.1", "RULE-009:v2024.1"],
        "score": ins.get("score"),
        "status": ins.get("status")
    })
    if "rule_snapshot" in additional_updates:
        snapshot_data.update(additional_updates.pop("rule_snapshot"))

    finalized = await repo.finalize_inspection(inspection_id, snapshot_data, additional_updates=additional_updates)

    # Ensure finalized inspection is linked to Product Intelligence
    try:
        if ins.get("declarations"):
            await product_intelligence_service.identify_and_link_product(
                inspection=finalized,
                declarations=ins.get("declarations", []),
                images=ins.get("images", [])
            )
    except Exception as fin_prod_err:
        logger.warning("Post-finalization product sync warning for %s: %s", inspection_id, fin_prod_err)

    await audit_service.record_event(
        action="INSPECTION_FINALIZED",
        actor_id=user_payload["sub"],
        actor_name=user_payload.get("full_name") or user_payload.get("sub"),
        role=user_payload.get("role", "INSPECTOR"),
        resource_type="INSPECTION",
        resource_id=inspection_id,
        inspection_id=inspection_id,
        result="SUCCESS",
        description=f"Inspection case {ins.get('code', inspection_id)} formally finalized and sealed.",
        old_value={"status": ins.get("status")},
        new_value={
            "status": "FINALIZED",
            "business_name": effective_business_name,
            "location": effective_location
        }
    )

    return {"success": True, "inspection": finalized}
