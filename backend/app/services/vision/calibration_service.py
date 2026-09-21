import math
from typing import Dict, Any, List, Optional, Tuple
from app.services.vision.pdp_measurement_service import pdp_measurement_service, CalibrationStatus
from app.core.logging import logger

class CalibrationService:
    """
    Production Calibration Service.
    Handles coordinate-space validation, mathematical scale calculation,
    PDP context resolution, and CV declaration character height derivation.
    """

    @staticmethod
    def validate_and_calculate(
        point_a: Dict[str, float],
        point_b: Dict[str, float],
        known_distance_mm: float,
        image_width: Optional[int] = None,
        image_height: Optional[int] = None,
    ) -> Dict[str, Any]:
        """
        Validates calibration points against physical and image constraints.
        Returns calculated pixel distance and derived pixels_per_mm.
        """
        if known_distance_mm <= 0:
            raise ValueError("Known physical distance must be greater than 0 mm.")

        x1 = float(point_a.get("x", 0))
        y1 = float(point_a.get("y", 0))
        x2 = float(point_b.get("x", 0))
        y2 = float(point_b.get("y", 0))

        # Check bounds if native image dimensions are provided
        if image_width is not None and image_width > 0:
            if not (0 <= x1 <= image_width) or not (0 <= x2 <= image_width):
                raise ValueError(
                    f"Point coordinates X ({x1:.1f}, {x2:.1f}) exceed native image width ({image_width}px)."
                )
        if image_height is not None and image_height > 0:
            if not (0 <= y1 <= image_height) or not (0 <= y2 <= image_height):
                raise ValueError(
                    f"Point coordinates Y ({y1:.1f}, {y2:.1f}) exceed native image height ({image_height}px)."
                )

        dx = x2 - x1
        dy = y2 - y1
        dist_px = math.sqrt(dx * dx + dy * dy)

        if dist_px < 5.0:
            raise ValueError(
                "Selected points are too close together (distance < 5 px). "
                "Select two distinct reference points to establish a reliable scale."
            )

        pixels_per_mm = dist_px / known_distance_mm
        if not math.isfinite(pixels_per_mm) or pixels_per_mm <= 0:
            raise ValueError("Derived scale is not mathematically finite or positive.")

        return {
            "pixel_distance": round(dist_px, 2),
            "known_distance_mm": round(known_distance_mm, 2),
            "pixels_per_mm": round(pixels_per_mm, 4),
            "status": CalibrationStatus.CALIBRATED,
        }

    @staticmethod
    def resolve_pdp_context(
        inspection: Dict[str, Any],
        custom_pdp_area_cm2: Optional[float] = None,
        package_construction_type: Optional[str] = None
    ) -> Tuple[Optional[float], Optional[float], str]:
        """
        Resolves PDP Area in cm2 and Rule 7 Table-I minimum character height in mm.
        Returns: (pdp_area_cm2, min_height_mm, threshold_label)
        Never fabricates a default 320 cm2 if no real data exists.
        """
        pkg_const = (
            package_construction_type
            or inspection.get("package_construction_type")
            or "NORMAL"
        )

        # 1. Custom verified PDP area provided by user/officer
        if custom_pdp_area_cm2 is not None and custom_pdp_area_cm2 > 0:
            area_cm2 = round(custom_pdp_area_cm2, 2)
            min_h, label = pdp_measurement_service.resolve_rule_7_threshold(area_cm2, pkg_const)
            return area_cm2, min_h, label

        # 2. Existing calculated pdp_data on inspection
        pdp_data = inspection.get("pdp_data")
        if isinstance(pdp_data, dict) and pdp_data.get("areaCm2"):
            area_cm2 = float(pdp_data["areaCm2"])
            min_h, label = pdp_measurement_service.resolve_rule_7_threshold(area_cm2, pkg_const)
            return area_cm2, min_h, label

        # 3. Known physical package dimensions
        pkg_dims = inspection.get("package_dimensions") or inspection.get("dimensions_mm")
        if isinstance(pkg_dims, dict):
            area_cm2, conf = pdp_measurement_service.calculate_pdp_area(
                package_type=inspection.get("package_type", "RECTANGULAR"),
                dimensions_mm=pkg_dims
            )
            if area_cm2:
                min_h, label = pdp_measurement_service.resolve_rule_7_threshold(area_cm2, pkg_const)
                return area_cm2, min_h, label

        # Honest unverified state: no dimensions or calibrated bounding box
        return None, None, "UNKNOWN_PDP_AREA"

    @staticmethod
    def derive_declaration_character_measurements(
        declarations: List[Dict[str, Any]],
        pixels_per_mm: float,
        min_height_mm: Optional[float] = None
    ) -> List[Dict[str, Any]]:
        """
        Calculates physical character height and Rule 7 proportion for declarations.
        """
        results = []
        if pixels_per_mm <= 0:
            return results

        for d in declarations:
            field_name = d.get("field_name")
            bbox = d.get("bbox")
            if not bbox or not isinstance(bbox, dict):
                continue

            raw_char_height = d.get("char_height_px")
            raw_char_width = d.get("char_width_px")
            if raw_char_height is None:
                results.append({
                    "declaration_id": d.get("id") or "",
                    "field_name": field_name,
                    "verified_value": d.get("verified_value") or d.get("ai_value") or "",
                    "pixel_height": 0.0,
                    "physical_height_mm": 0.0,
                    "required_min_height_mm": min_height_mm,
                    "difference_mm": 0.0,
                    "status": "UNVERIFIED",
                    "explanation": "No CV-measured character components are available; line-box height was not used as a substitute.",
                    "source_image_id": d.get("source_image_id"),
                })
                continue

            char_h_px = float(raw_char_height)
            char_w_px = float(raw_char_width or 0.0)
            if char_h_px <= 0:
                continue

            phys_h_mm = round(char_h_px / pixels_per_mm, 2)
            phys_w_mm = round(char_w_px / pixels_per_mm, 2)
            ratio = round(char_w_px / max(1.0, char_h_px), 3)

            is_pass = (min_height_mm is not None) and (phys_h_mm >= min_height_mm)
            status = "PASS" if is_pass else ("VIOLATION" if min_height_mm is not None else "UNVERIFIED")
            difference = round(phys_h_mm - min_height_mm, 2) if min_height_mm is not None else 0.0

            results.append({
                "declaration_id": d.get("id") or "",
                "field_name": field_name,
                "display_name": field_name.replace("_", " ").title() if field_name else "Declaration",
                "verified_value": d.get("verified_value") or d.get("ai_value") or "",
                "pixel_height": round(char_h_px, 1),
                "physical_height_mm": phys_h_mm,
                "difference_mm": difference,
                "char_pixel_height": round(char_h_px, 1),
                "char_pixel_width": round(char_w_px, 1),
                "measured_height_mm": phys_h_mm,
                "measured_width_mm": phys_w_mm,
                "width_to_height_ratio": ratio,
                "required_min_height_mm": min_height_mm,
                "status": status,
                "source_image_id": d.get("source_image_id")
            })

        return results

calibration_service = CalibrationService()
