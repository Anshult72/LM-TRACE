import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, UploadFile, File, Form, Body, HTTPException, status, Request
from typing import Dict, Any, Optional, List

from app.services.listing.listing_service import online_listing_service
from app.services.ocr import get_ocr_service
from app.services.llm import get_llm_service
from app.services.declaration.correctness_service import declaration_correctness_service
from app.engines.compliance_engine.compliance_engine import compliance_engine
from app.storage.file_storage import storage_manager
from app.core.security import get_current_user_payload
from app.repositories import get_repository
from app.schemas.domain import (
    OcrResult, OcrBlock, BoundingBox,
    EcommerceListingFetchRequest, EcommerceListingFetchResponse,
    EcommerceListingAnalyzeRequest
)
from app.services.audit.audit_service import audit_service
from app.services.product.product_intelligence_service import product_intelligence_service

router = APIRouter(prefix="/api/listings", tags=["Online Listings"])

def get_utc_now_iso():
    return datetime.now(timezone.utc).isoformat()


def _ocr_from_listing_text(text: str) -> OcrResult:
    """Builds an OCR result from extracted listing text."""
    clipped = (text or "").strip()[:4000]
    return OcrResult(
        raw_text=clipped,
        blocks=[
            OcrBlock(
                block_id="blk-listing-url-1",
                text=clipped[:1500] if clipped else "(empty listing text)",
                confidence=0.85,
                bbox=BoundingBox(x=0, y=0, width=100, height=100),
                image_id="img-listing-url",
                surface_type="FRONT",
            )
        ],
        confidence=0.85,
        image_id="img-listing-url",
    )


@router.post("/fetch", response_model=EcommerceListingFetchResponse)
async def fetch_online_listing(
    req: EcommerceListingFetchRequest,
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Safely fetches and performs layered extraction on a public product listing URL.
    Enforces SSRF protection, extracts JSON-LD, meta tags, and specification tables,
    generates a hashed snapshot, and logs the retrieval in the audit trail.
    """
    url = (req.url or "").strip()
    if not url:
        raise HTTPException(status_code=400, detail="Product listing URL is required.")

    actor_id = user_payload.get("sub", "system")
    role = user_payload.get("role", "INSPECTOR")
    repo = get_repository()

    # 1. Audit Log: Fetch Started
    await audit_service.record_event(
        action="LISTING_FETCH_STARTED",
        actor_id=actor_id,
        role=role,
        resource_type="ONLINE_LISTING",
        resource_id=url,
        inspection_id=req.inspection_id,
        description=f"Initiated safe fetch of e-commerce listing: {url}",
        metadata={"url": url}
    )

    # 2. Run Fetch & Layered Extraction
    fetch_result = await online_listing_service.fetch_and_extract_listing(url, req.inspection_id)
    fetch_status = fetch_result.get("fetch_status", "FAILED")

    # 3. If inspection_id is supplied, persist snapshot and metadata
    if req.inspection_id:
        try:
            ins = await repo.get_by_id(req.inspection_id)
            if ins:
                updates = {
                    "listing_url": url,
                    "canonical_url": fetch_result.get("final_url") or url,
                    "marketplace": fetch_result.get("marketplace"),
                    "listing_metadata": {
                        "fetch_status": fetch_status,
                        "retrieved_at": fetch_result.get("retrieved_at"),
                        "product_title": fetch_result.get("product_title"),
                        "brand": fetch_result.get("brand"),
                        "seller": fetch_result.get("seller"),
                        "category": fetch_result.get("category"),
                        "mrp": fetch_result.get("mrp"),
                        "selling_price": fetch_result.get("selling_price"),
                        "unit_sale_price": fetch_result.get("unit_sale_price"),
                        "net_quantity": fetch_result.get("net_quantity"),
                        "country_of_origin": fetch_result.get("country_of_origin"),
                        "snapshot_id": fetch_result.get("snapshot_id"),
                        "content_hash": fetch_result.get("content_hash"),
                        "warnings": fetch_result.get("warnings", []),
                    }
                }
                if fetch_result.get("product_title"):
                    updates["business_name"] = fetch_result.get("seller") or fetch_result.get("brand") or ins.get("business_name")
                await repo.update(req.inspection_id, updates)

                # Save Evidence Item for the Snapshot
                if fetch_result.get("snapshot_id"):
                    evidence_item = {
                        "id": f"ev-{uuid.uuid4().hex[:10]}",
                        "inspection_id": req.inspection_id,
                        "evidence_type": "LISTING_SNAPSHOT",
                        "original_path": f"listing_snapshots/{fetch_result.get('snapshot_id')}.html",
                        "description": f"Retrieved listing snapshot from {url} at {fetch_result.get('retrieved_at')}",
                        "sha256": fetch_result.get("content_hash"),
                        "status": "STORED",
                        "created_by": actor_id,
                        "created_at": get_utc_now_iso(),
                    }
                    await repo.save_evidence_items(req.inspection_id, [evidence_item])

        except Exception as e:
            logger.warning(f"Error associating listing fetch with inspection {req.inspection_id}: {e}")

    # 4. Audit Log: Result
    if fetch_status in ("RETRIEVED", "PARTIAL"):
        await audit_service.record_event(
            action="LISTING_FETCH_COMPLETED",
            actor_id=actor_id,
            role=role,
            resource_type="ONLINE_LISTING",
            resource_id=url,
            inspection_id=req.inspection_id,
            result="SUCCESS",
            description=f"Successfully fetched listing ({fetch_status}). Marketplace: {fetch_result.get('marketplace')}.",
            metadata={
                "fetch_status": fetch_status,
                "final_url": fetch_result.get("final_url"),
                "content_hash": fetch_result.get("content_hash"),
                "detected_declarations_count": sum(1 for d in fetch_result.get("declarations_matrix", []) if d.get("status") == "DETECTED"),
            }
        )
    else:
        await audit_service.record_event(
            action="LISTING_FETCH_FAILED",
            actor_id=actor_id,
            role=role,
            resource_type="ONLINE_LISTING",
            resource_id=url,
            inspection_id=req.inspection_id,
            result="FAILURE",
            description=f"Listing fetch failed ({fetch_status}): {fetch_result.get('error_message')}",
            metadata={"fetch_status": fetch_status, "error": fetch_result.get("error_message")}
        )

    return EcommerceListingFetchResponse(**fetch_result)


@router.post("/analyze")
async def analyze_online_listing(
    request: Request,
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Evaluates statutory compliance for an online listing under PCR 2011 Rule 6(10).
    Can receive JSON payload (url, inspection_id, extracted_data) or multipart form (file, url, inspection_id).
    """
    actor_id = user_payload.get("sub", "system")
    role = user_payload.get("role", "INSPECTOR")
    repo = get_repository()

    content_type = request.headers.get("content-type", "")
    req_url = None
    req_ins_id = None
    file = None
    manual_extracted = None

    if "application/json" in content_type:
        try:
            body = await request.json()
            req_url = body.get("url")
            req_ins_id = body.get("inspection_id")
            manual_extracted = body.get("extracted_data")
        except Exception:
            pass
    elif "multipart/form-data" in content_type:
        form = await request.form()
        req_url = form.get("url")
        req_ins_id = form.get("inspection_id")
        file = form.get("file")
    else:
        # Try JSON parse as fallback
        try:
            body = await request.json()
            req_url = body.get("url")
            req_ins_id = body.get("inspection_id")
            manual_extracted = body.get("extracted_data")
        except Exception:
            pass

    screenshot_path = None
    ocr_res: Optional[OcrResult] = None
    source_type = "URL"
    extracted_declarations_map: Dict[str, Any] = {}
    declarations_matrix: List[Dict[str, Any]] = []

    if file:
        file_bytes = await file.read()
        listing_id = uuid.uuid4().hex[:8]
        screenshot_path, _, _, _, _ = await storage_manager.save_inspection_image(
            f"listing-{listing_id}", file_bytes, getattr(file, "filename", "listing.png") or "listing.png"
        )
        ocr_service = get_ocr_service()
        ocr_res = await ocr_service.extract_text(screenshot_path, "img-listing-01", surface_type="FRONT")
        source_type = "SCREENSHOT"
        llm_service = get_llm_service()
        extracted_payload = await llm_service.extract_declarations([ocr_res], product_category="Packaged Food")
        extracted_declarations_map = extracted_payload.model_dump()
        correctness = declaration_correctness_service.evaluate_correctness(extracted_payload, ocr_res.blocks, is_imported=False)
        declarations_matrix = correctness.get("matrix", [])

    elif manual_extracted:
        extracted_declarations_map = manual_extracted
        ocr_res = _ocr_from_listing_text("Direct listing declaration data")
        source_type = "STRUCTURED_PAYLOAD"

    elif req_url:
        fetch_res = await online_listing_service.fetch_and_extract_listing(req_url, req_ins_id)
        if fetch_res.get("fetch_status") in ("FAILED", "BLOCKED", "LOGIN_REQUIRED", "TIMEOUT"):
            raise HTTPException(
                status_code=400,
                detail=f"Unable to analyze listing ({fetch_res.get('fetch_status')}): {fetch_res.get('error_message')}"
            )
        
        declarations_matrix = fetch_res.get("declarations_matrix", [])
        raw_text = fetch_res.get("raw_text_preview") or ""
        ocr_res = _ocr_from_listing_text(raw_text)

        # Normalize extracted declarations into standard structure
        raw_decls = fetch_res.get("declarations", {})
        for k, v in raw_decls.items():
            val = v.get("value") if isinstance(v, dict) else v
            if val:
                extracted_declarations_map[k] = {"value": str(val), "confidence": 0.95}

        # Also fallback to LLM for any missing structured fields from preview text
        if raw_text:
            try:
                llm_service = get_llm_service()
                llm_decls = await llm_service.extract_declarations([ocr_res], product_category="Packaged Food")
                for k, v in llm_decls.model_dump().items():
                    if v and isinstance(v, dict) and v.get("value"):
                        if k not in extracted_declarations_map or not extracted_declarations_map[k].get("value"):
                            extracted_declarations_map[k] = v
            except Exception as llm_err:
                logger.warning(f"LLM normalization fallback skipped: {llm_err}")

        source_type = "URL"

    else:
        raise HTTPException(
            status_code=400,
            detail="Provide either a valid product listing URL, an inspection ID, or an uploaded screenshot."
        )

    # Build ExtractedDeclarationsPayload for correctness evaluation
    from app.schemas.domain import ExtractedDeclarationsPayload, SemanticDeclarationField
    extracted_payload = ExtractedDeclarationsPayload()
    for k, v in extracted_declarations_map.items():
        val = v.get("value") if isinstance(v, dict) else v
        conf = float(v.get("confidence", 0.95)) if isinstance(v, dict) else 0.95
        if hasattr(extracted_payload, k) and val:
            setattr(extracted_payload, k, SemanticDeclarationField(field_name=k, value=str(val), confidence=conf))

    correctness = declaration_correctness_service.evaluate_correctness(
        extracted_payload, ocr_res.blocks if ocr_res else [], is_imported=False
    )

    # Context specifically declares E-Commerce channel under Rule 6(10)
    context = {
        "inspectionDate": get_utc_now_iso(),
        "productCategory": "Packaged Food",
        "isEcommerce": True,
        "isImported": False,
        "inspectionChannel": "ECOMMERCE",
        "calibrationStatus": "NOT_CALIBRATED"
    }

    # Run Statutory Rule & Compliance Evaluation
    assessment = await compliance_engine.evaluate_compliance(
        extracted_declarations=extracted_declarations_map,
        correctness_data=correctness,
        context=context
    )

    # Persist findings and checks to inspection if provided
    if req_ins_id:
        try:
            ins = await repo.get_by_id(req_ins_id)
            if ins:
                checks_to_save = [c.model_dump() for c in assessment.checks]
                violations_to_save = assessment.potential_violations or []
                await repo.save_compliance_results(req_ins_id, checks_to_save, violations_to_save)

                # Persist declarations
                decl_list = []
                for fname, dval in extracted_declarations_map.items():
                    val = dval.get("value") if isinstance(dval, dict) else dval
                    if val:
                        decl_list.append({
                            "id": f"dec-{uuid.uuid4().hex[:8]}",
                            "inspection_id": req_ins_id,
                            "field_name": fname,
                            "ai_value": str(val),
                            "verified_value": str(val),
                            "confidence": 0.95,
                            "provenance": "ONLINE_LISTING_EXTRACTION",
                            "presence_status": "DETECTED",
                            "correctness_status": "VALID",
                            "verification_status": "VERIFIED",
                        })
                if decl_list:
                    await repo.save_declarations(req_ins_id, decl_list)

                # Update inspection status
                new_status = "NEEDS_REVIEW" if assessment.overall_status in ("POTENTIAL_VIOLATION", "REVIEW") else "READY"
                await repo.update(req_ins_id, {
                    "status": new_status,
                    "score": assessment.score
                })

                # Product Intelligence Integration: Link or Register Product
                try:
                    await product_intelligence_service.identify_and_link_product(
                        inspection=ins,
                        declarations=decl_list
                    )
                except Exception as pi_err:
                    logger.warning(f"Product Intelligence linkage warning for {req_ins_id}: {pi_err}")

        except Exception as persist_err:
            logger.warning(f"Error persisting compliance results for {req_ins_id}: {persist_err}")

    # Audit Logging
    await audit_service.record_event(
        action="RULE_EVALUATION_COMPLETED",
        actor_id=actor_id,
        role=role,
        resource_type="RULE_ENGINE",
        resource_id=req_ins_id or "adhoc-listing",
        inspection_id=req_ins_id,
        result="SUCCESS",
        description=f"Evaluated Rule 6(10) E-Commerce compliance: overall status {assessment.overall_status} (Score: {assessment.score}%)",
        metadata={
            "overall_status": assessment.overall_status,
            "score": assessment.score,
            "violations_count": len(assessment.potential_violations),
            "source_type": source_type,
            "url": req_url
        }
    )

    return {
        "success": True,
        "source_type": source_type,
        "url": req_url,
        "screenshot_path": screenshot_path,
        "extracted_declarations": extracted_declarations_map,
        "assessment": assessment.model_dump(),
        "matrix": declarations_matrix or correctness.get("matrix", [])
    }
