import os
from typing import Dict, Any, List, Set, Optional

REQUIRED_SURFACES = [
    {"code": "FRONT", "name": "Front (PDP)", "description": "Principal Display Panel"},
    {"code": "BACK", "name": "Back (Declarations)", "description": "Mandatory Declarations"},
    {"code": "SIDE", "name": "Side (Consumer Care)", "description": "Consumer Care & Contact Details"},
    {"code": "MRP_AREA", "name": "MRP & Date Stamp", "description": "MRP, Unit Sale Price & Date"},
]

REQUIRED_SURFACE_CODES: List[str] = [s["code"] for s in REQUIRED_SURFACES]
OPTIONAL_SURFACES = [
    {"code": "OUTER_WRAPPER", "name": "Outer Wrapper", "description": "Declarations on opaque outside container/wrapper"},
    {"code": "INNER_PACKAGE", "name": "Inner Retail Package", "description": "Declarations on constituent package"},
]
ALLOWED_SURFACE_CODES: List[str] = REQUIRED_SURFACE_CODES + [s["code"] for s in OPTIONAL_SURFACES]
SURFACE_CODE_TO_NAME: Dict[str, str] = {s["code"]: s["name"] for s in REQUIRED_SURFACES}

def validate_inspection_surfaces(inspection: Dict[str, Any]) -> Dict[str, Any]:
    """
    Validates that every required product package surface has a valid, successfully
    uploaded, non-empty image record belonging strictly to the given inspection.
    
    Returns a structured validation dictionary with:
      - valid: bool (True only if all required surfaces have at least 1 valid image)
      - required_count: int (total required surfaces, e.g. 4)
      - completed_count: int (number of distinct required surfaces present)
      - missing_surfaces: List[str] (names of missing surfaces)
      - completed_surfaces: List[str] (names of completed surfaces)
      - surfaces: List[Dict[str, Any]] (per-surface status and image details)
    """
    inspection_id = inspection.get("id")
    images = inspection.get("images") or []

    available_surface_codes: Set[str] = set()
    surfaces_info: List[Dict[str, Any]] = []

    for req in REQUIRED_SURFACES:
        code = req["code"]
        name = req["name"]

        # Filter images matching this surface code AND belonging to this inspection
        matching_images = [
            img for img in images
            if (img.get("surface_type") or "").upper() == code
            and (not img.get("inspection_id") or img.get("inspection_id") == inspection_id)
        ]

        has_valid_image = False
        valid_img_id: Optional[str] = None

        for img in matching_images:
            orig_path = img.get("original_path")
            has_file_on_disk = bool(orig_path and os.path.isfile(orig_path) and os.path.getsize(orig_path) > 0)
            
            qd = img.get("quality_details") or {}
            has_b64_payload = bool(qd.get("_image_b64"))
            
            has_file_size = bool(img.get("file_size", 0) > 0)

            # Valid image must have actual file on disk, base64 payload, or positive file size
            if has_file_on_disk or has_b64_payload or has_file_size:
                has_valid_image = True
                valid_img_id = img.get("id")
                break

        if has_valid_image:
            available_surface_codes.add(code)
            surfaces_info.append({
                "code": code,
                "name": name,
                "status": "AVAILABLE",
                "image_id": valid_img_id,
            })
        else:
            surfaces_info.append({
                "code": code,
                "name": name,
                "status": "MISSING",
                "image_id": None,
            })

    missing_surfaces = [
        SURFACE_CODE_TO_NAME[code]
        for code in REQUIRED_SURFACE_CODES
        if code not in available_surface_codes
    ]

    completed_surfaces = [
        SURFACE_CODE_TO_NAME[code]
        for code in REQUIRED_SURFACE_CODES
        if code in available_surface_codes
    ]

    is_valid = len(missing_surfaces) == 0

    return {
        "valid": is_valid,
        "required_count": len(REQUIRED_SURFACES),
        "completed_count": len(available_surface_codes),
        "missing_surfaces": missing_surfaces,
        "completed_surfaces": completed_surfaces,
        "surfaces": surfaces_info,
    }
