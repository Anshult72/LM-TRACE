import uuid
from typing import Dict, Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from app.repositories import get_repository
from app.core.security import get_current_user_payload
from app.core.logging import logger
from app.schemas.domain import (
    CalibrationCreateRequest,
    CalibrationResponse,
    CalibrationMeasurementPreview,
)
from app.services.vision.calibration_service import calibration_service
from app.services.audit.audit_service import audit_service

router = APIRouter(prefix="/api/inspections/{inspection_id}/calibrations", tags=["Calibrations"])
standalone_router = APIRouter(prefix="/api/calibrations", tags=["Calibrations"])

@router.get("", response_model=List[CalibrationResponse])
async def list_calibrations(
    inspection_id: str,
    image_id: Optional[str] = None,
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")
    calibs = await repo.get_calibrations(inspection_id, image_id=image_id)
    return [
        CalibrationResponse(
            id=c["id"],
            inspection_id=c["inspection_id"],
            image_id=c.get("image_id"),
            user_id=c["user_id"],
            reference_type=c.get("reference_type") or "RULER",
            reference_description=c.get("reference_description"),
            point_a={"x": c.get("point_a_x", 0), "y": c.get("point_a_y", 0)},
            point_b={"x": c.get("point_b_x", 0), "y": c.get("point_b_y", 0)},
            pixel_distance=c.get("pixel_distance", 0),
            known_distance=c.get("known_distance", 0),
            unit=c.get("unit") or "mm",
            pixels_per_unit=c.get("pixels_per_unit", 0),
            image_width=c.get("image_width"),
            image_height=c.get("image_height"),
            image_hash=c.get("image_hash"),
            calibration_status=c.get("calibration_status") or "VALID",
            perspective_warning=bool(c.get("perspective_warning", False)),
            created_at=c.get("created_at") or "",
            updated_at=c.get("updated_at")
        ) for c in calibs
    ]

@router.get("/active", response_model=Optional[CalibrationResponse])
async def get_active_calibration(
    inspection_id: str,
    image_id: Optional[str] = None,
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")
    calibs = await repo.get_calibrations(inspection_id, image_id=image_id)
    active = next((c for c in calibs if c.get("calibration_status") == "VALID"), None)
    if not active and calibs:
        active = calibs[0]
    if not active:
        return None

    return CalibrationResponse(
        id=active["id"],
        inspection_id=active["inspection_id"],
        image_id=active.get("image_id"),
        user_id=active["user_id"],
        reference_type=active.get("reference_type") or "RULER",
        reference_description=active.get("reference_description"),
        point_a={"x": active.get("point_a_x", 0), "y": active.get("point_a_y", 0)},
        point_b={"x": active.get("point_b_x", 0), "y": active.get("point_b_y", 0)},
        pixel_distance=active.get("pixel_distance", 0),
        known_distance=active.get("known_distance", 0),
        unit=active.get("unit") or "mm",
        pixels_per_unit=active.get("pixels_per_unit", 0),
        image_width=active.get("image_width"),
        image_height=active.get("image_height"),
        image_hash=active.get("image_hash"),
        calibration_status=active.get("calibration_status") or "VALID",
        perspective_warning=bool(active.get("perspective_warning", False)),
        created_at=active.get("created_at") or "",
        updated_at=active.get("updated_at")
    )

@router.post("", response_model=CalibrationResponse, status_code=status.HTTP_201_CREATED)
async def create_calibration(
    inspection_id: str,
    req: CalibrationCreateRequest,
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")

    target_image = None
    image_width = None
    image_height = None
    image_hash = None

    if req.image_id:
        images = ins.get("images") or []
        target_image = next((img for img in images if img.get("id") == req.image_id), None)
        if not target_image:
            raise HTTPException(
                status_code=404,
                detail=f"Image {req.image_id} does not belong to inspection {inspection_id}."
            )
        image_width = target_image.get("width")
        image_height = target_image.get("height")
        image_hash = (target_image.get("quality_details") or {}).get("sha256")

    # Mathematical & coordinate validation
    try:
        calc_result = calibration_service.validate_and_calculate(
            point_a=req.point_a.model_dump(),
            point_b=req.point_b.model_dump(),
            known_distance_mm=req.known_distance_mm,
            image_width=image_width,
            image_height=image_height,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    # Perspective warning check (if reference type is OTHER or no plane alignment)
    is_perspective_warning = req.reference_type == "OTHER"

    # Persist calibration
    cal_data = {
        "id": f"cal-{uuid.uuid4().hex[:8]}",
        "inspection_id": ins["id"],
        "image_id": req.image_id,
        "user_id": user_payload.get("sub", "system"),
        "reference_type": req.reference_type,
        "reference_description": req.reference_description,
        "point_a_x": req.point_a.x,
        "point_a_y": req.point_a.y,
        "point_b_x": req.point_b.x,
        "point_b_y": req.point_b.y,
        "pixel_distance": calc_result["pixel_distance"],
        "known_distance": calc_result["known_distance_mm"],
        "unit": "mm",
        "pixels_per_unit": calc_result["pixels_per_mm"],
        "image_width": image_width,
        "image_height": image_height,
        "image_hash": image_hash,
        "calibration_status": "VALID",
        "perspective_warning": is_perspective_warning,
    }

    saved = await repo.save_calibration(ins["id"], cal_data)

    # If PDP area override provided, persist on inspection pdp_data
    if req.custom_pdp_area_cm2 is not None and req.custom_pdp_area_cm2 > 0:
        area_cm2 = round(req.custom_pdp_area_cm2, 2)
        await repo.update(ins["id"], {
            "pdp_data": {"areaCm2": area_cm2, "method": "CALIBRATED_MANUAL", "confidence": 0.95},
            "package_construction_type": req.package_construction_type or "NORMAL"
        })

    # Append authoritative audit log
    await audit_service.record_event(
        action="CALIBRATION_CREATED",
        actor_id=user_payload.get("sub", "system"),
        actor_name=user_payload.get("full_name") or user_payload.get("sub", "system"),
        role=user_payload.get("role", "INSPECTOR"),
        resource_type="CALIBRATION",
        resource_id=saved["id"],
        inspection_id=ins["id"],
        result="SUCCESS",
        description=f"Physical scale calibration computed ({saved['pixels_per_unit']:.2f} px/mm on {saved['reference_type']}) for inspection {ins.get('code', ins['id'])}.",
        new_value={
            "pixels_per_mm": saved["pixels_per_unit"],
            "known_distance_mm": saved["known_distance"],
            "pixel_distance": saved["pixel_distance"],
            "image_id": saved.get("image_id"),
            "reference_type": saved["reference_type"]
        }
    )

    return CalibrationResponse(
        id=saved["id"],
        inspection_id=saved["inspection_id"],
        image_id=saved.get("image_id"),
        user_id=saved["user_id"],
        reference_type=saved["reference_type"],
        reference_description=saved.get("reference_description"),
        point_a={"x": saved["point_a_x"], "y": saved["point_a_y"]},
        point_b={"x": saved["point_b_x"], "y": saved["point_b_y"]},
        pixel_distance=saved["pixel_distance"],
        known_distance=saved["known_distance"],
        unit=saved["unit"],
        pixels_per_unit=saved["pixels_per_unit"],
        image_width=saved.get("image_width"),
        image_height=saved.get("image_height"),
        image_hash=saved.get("image_hash"),
        calibration_status=saved["calibration_status"],
        perspective_warning=bool(saved.get("perspective_warning", False)),
        created_at=saved["created_at"],
        updated_at=saved.get("updated_at")
    )

@router.post("/preview", response_model=CalibrationMeasurementPreview)
async def preview_calibration(
    inspection_id: str,
    req: CalibrationCreateRequest,
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    ins = await repo.get_by_id(inspection_id)
    if not ins:
        raise HTTPException(status_code=404, detail="Inspection not found")

    image_width = None
    image_height = None
    if req.image_id:
        images = ins.get("images") or []
        target_image = next((img for img in images if img.get("id") == req.image_id), None)
        if target_image:
            image_width = target_image.get("width")
            image_height = target_image.get("height")

    try:
        calc_result = calibration_service.validate_and_calculate(
            point_a=req.point_a.model_dump(),
            point_b=req.point_b.model_dump(),
            known_distance_mm=req.known_distance_mm,
            image_width=image_width,
            image_height=image_height,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    px_per_mm = calc_result["pixels_per_mm"]
    pdp_area, min_h, label = calibration_service.resolve_pdp_context(
        ins,
        custom_pdp_area_cm2=req.custom_pdp_area_cm2,
        package_construction_type=req.package_construction_type
    )

    declarations = [dict(item) for item in (ins.get("declarations") or []) if isinstance(item, dict)]
    visual_analysis = ((ins.get("rule_snapshot") or {}).get("visual_analysis") or {})
    typography_by_field = {
        item.get("matched_field") or item.get("field_name"): item
        for item in visual_analysis.get("typography_results", [])
        if isinstance(item, dict)
    }
    for declaration in declarations:
        geometry = typography_by_field.get(declaration.get("field_name")) or {}
        if geometry.get("status") == "MEASURED":
            declaration.update({
                "char_height_px": geometry.get("char_height_px"),
                "char_width_px": geometry.get("char_width_px"),
                "measurement_confidence": geometry.get("measurement_confidence"),
            })
    measurements = calibration_service.derive_declaration_character_measurements(
        declarations,
        pixels_per_mm=px_per_mm,
        min_height_mm=min_h
    )

    return CalibrationMeasurementPreview(
        pixel_distance=calc_result["pixel_distance"],
        known_distance_mm=calc_result["known_distance_mm"],
        pixels_per_mm=px_per_mm,
        status="VALID",
        pdp_area_cm2=pdp_area,
        pdp_threshold_label=label,
        required_min_height_mm=min_h,
        declaration_measurements=measurements
    )

@standalone_router.get("/{calibration_id}", response_model=CalibrationResponse)
async def get_calibration_by_id_endpoint(
    calibration_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    repo = get_repository()
    c = await repo.get_calibration_by_id(calibration_id)
    if not c:
        raise HTTPException(status_code=404, detail="Calibration not found")
    return CalibrationResponse(
        id=c["id"],
        inspection_id=c["inspection_id"],
        image_id=c.get("image_id"),
        user_id=c["user_id"],
        reference_type=c.get("reference_type") or "RULER",
        reference_description=c.get("reference_description"),
        point_a={"x": c.get("point_a_x", 0), "y": c.get("point_a_y", 0)},
        point_b={"x": c.get("point_b_x", 0), "y": c.get("point_b_y", 0)},
        pixel_distance=c.get("pixel_distance", 0),
        known_distance=c.get("known_distance", 0),
        unit=c.get("unit") or "mm",
        pixels_per_unit=c.get("pixels_per_unit", 0),
        image_width=c.get("image_width"),
        image_height=c.get("image_height"),
        image_hash=c.get("image_hash"),
        calibration_status=c.get("calibration_status") or "VALID",
        perspective_warning=bool(c.get("perspective_warning", False)),
        created_at=c.get("created_at") or "",
        updated_at=c.get("updated_at")
    )
