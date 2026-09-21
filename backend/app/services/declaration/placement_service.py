from typing import Any, Dict, List, Optional, Tuple


class DeclarationPlacementService:
    """Evidence-grounded Rule 9 placement checks for physical packages."""

    @staticmethod
    def _bbox_metrics(record: Dict[str, Any], image: Dict[str, Any]) -> Dict[str, Any]:
        bbox = record.get("bbox")
        if not isinstance(bbox, dict):
            return {"valid": False, "reason": "OCR bounding box is missing."}
        try:
            x, y = float(bbox.get("x", 0)), float(bbox.get("y", 0))
            width, height = float(bbox.get("width", 0)), float(bbox.get("height", 0))
        except (TypeError, ValueError):
            return {"valid": False, "reason": "OCR bounding box contains invalid coordinates."}
        if width <= 0 or height <= 0 or x < 0 or y < 0:
            return {"valid": False, "reason": "OCR bounding box has non-positive or negative geometry."}

        image_width, image_height = image.get("width"), image.get("height")
        if not image_width or not image_height:
            return {
                "valid": True, "bounds_verified": False, "clipped_fraction": None,
                "reason": "OCR box is valid, but image dimensions were unavailable for boundary verification.",
            }
        try:
            image_width, image_height = float(image_width), float(image_height)
        except (TypeError, ValueError):
            return {"valid": False, "reason": "Captured image dimensions are invalid."}
        if image_width <= 0 or image_height <= 0:
            return {"valid": False, "reason": "Captured image dimensions are invalid."}

        intersection_width = max(0.0, min(x + width, image_width) - max(x, 0.0))
        intersection_height = max(0.0, min(y + height, image_height) - max(y, 0.0))
        visible_fraction = (intersection_width * intersection_height) / (width * height)
        edge_margin = min(x, y, image_width - (x + width), image_height - (y + height))
        return {
            "valid": visible_fraction >= 0.98,
            "bounds_verified": True,
            "visible_fraction": round(visible_fraction, 4),
            "clipped_fraction": round(1.0 - visible_fraction, 4),
            "touches_edge": edge_margin <= 1.0,
            "relative_area": round((width * height) / (image_width * image_height), 6),
            "reason": (
                "OCR bounding box lies inside the captured image."
                if visible_fraction >= 0.98
                else f"Only {visible_fraction * 100:.1f}% of the OCR bounding box lies inside the captured image."
            ),
        }

    @staticmethod
    def _containment(inner: Dict[str, Any], outer: Dict[str, Any]) -> Optional[float]:
        try:
            ix1, iy1 = float(inner["x"]), float(inner["y"])
            ix2, iy2 = ix1 + float(inner["width"]), iy1 + float(inner["height"])
            ox1, oy1 = float(outer["x"]), float(outer["y"])
            ox2, oy2 = ox1 + float(outer["width"]), oy1 + float(outer["height"])
            intersection = max(0.0, min(ix2, ox2) - max(ix1, ox1)) * max(0.0, min(iy2, oy2) - max(iy1, oy1))
            area = max(0.0, (ix2 - ix1) * (iy2 - iy1))
            return round(intersection / area, 4) if area > 0 else None
        except (KeyError, TypeError, ValueError):
            return None

    @staticmethod
    def _occurrence_surfaces(record: Dict[str, Any], surface_by_image: Dict[str, str]) -> set[str]:
        occurrences = record.get("occurrences") if isinstance(record.get("occurrences"), list) else []
        image_ids = {record.get("source_image_id")}
        image_ids.update(item.get("source_image_id") for item in occurrences if isinstance(item, dict))
        return {
            str(surface_by_image.get(image_id) or "").upper()
            for image_id in image_ids if image_id and surface_by_image.get(image_id)
        }

    def _evaluate_record(
        self,
        record: Dict[str, Any],
        requirement: Dict[str, Any],
        context: Dict[str, Any],
        image_by_id: Dict[str, Dict[str, Any]],
        surface_by_image: Dict[str, str],
    ) -> Tuple[str, str, float, Dict[str, Any]]:
        image_id, block_id = record.get("source_image_id"), record.get("source_block_id")
        image = image_by_id.get(image_id) or {}
        surface = str(surface_by_image.get(image_id) or "UNKNOWN").upper()
        metrics = self._bbox_metrics(record, image)
        if not image_id or not block_id or not image:
            return "UNVERIFIED", "Declaration is not tied to a stored package image and OCR block.", 0.0, metrics
        if not metrics.get("valid"):
            return "UNVERIFIED", metrics.get("reason", "OCR geometry is invalid."), 0.15, metrics

        quality = str(image.get("quality_assessment") or "").upper()
        if quality in {"NEEDS_RETAKE", "UNVERIFIED"}:
            return "REVIEW", f"Declaration is located on {surface}, but the source image quality is {quality}.", 0.45, metrics

        occurrence_surfaces = self._occurrence_surfaces(record, surface_by_image)
        opaque_wrapper = bool(context.get("hasOuterWrapper")) and not bool(context.get("outerWrapperTransparent"))
        if opaque_wrapper and "OUTER_WRAPPER" not in occurrence_surfaces:
            return "POTENTIAL_VIOLATION", "Opaque outer wrapper is present, but this declaration was not found on it.", 0.96, metrics

        if requirement.get("package_scope") == "OUTER_AND_EACH_INNER_RETAIL_PACKAGE":
            captured = {str(value or "").upper() for value in surface_by_image.values()}
            if "INNER_PACKAGE" not in captured:
                return "REVIEW", "Inner retail-package surface was not captured, so repeated declaration placement cannot be verified.", 0.4, metrics
            required_scopes = {"INNER_PACKAGE"}
            if opaque_wrapper or "OUTER_WRAPPER" in captured:
                required_scopes.add("OUTER_WRAPPER")
            missing_scopes = sorted(required_scopes - occurrence_surfaces)
            if missing_scopes:
                return "POTENTIAL_VIOLATION", f"Declaration was not detected on required package scope(s): {', '.join(missing_scopes)}.", 0.94, metrics

        pdp_bbox, pdp_image_id = context.get("pdpBbox"), context.get("pdpImageId")
        if requirement.get("must_be_on_pdp"):
            if not isinstance(pdp_bbox, dict) or not pdp_image_id:
                return "UNVERIFIED", "A measured PDP boundary is required to verify this declaration's PDP placement.", 0.35, metrics
            if image_id != pdp_image_id:
                return "POTENTIAL_VIOLATION", "Declaration was detected outside the captured Principal Display Panel image.", 0.95, metrics
            containment = self._containment(record.get("bbox") or {}, pdp_bbox)
            metrics["pdp_containment"] = containment
            if containment is None:
                return "UNVERIFIED", "PDP containment could not be calculated from the recorded geometry.", 0.3, metrics
            if containment < 0.95:
                return "POTENTIAL_VIOLATION", f"Only {containment * 100:.1f}% of the declaration lies within the measured PDP boundary.", 0.95, metrics

        if metrics.get("touches_edge"):
            return "REVIEW", f"Declaration is OCR-grounded on {surface}, but its crop touches the image edge and may be clipped.", 0.65, metrics
        confidence = 0.98 if metrics.get("bounds_verified") else 0.82
        return "PASS", f"Declaration is OCR-grounded within the captured {surface} package surface.", confidence, metrics

    def evaluate(
        self,
        requirements: Dict[str, Dict[str, Any]],
        declarations: List[Dict[str, Any]],
        context: Dict[str, Any],
        images: List[Dict[str, Any]] | None = None,
    ) -> List[Dict[str, Any]]:
        results: List[Dict[str, Any]] = []
        by_field = {item.get("field_name"): item for item in declarations if isinstance(item, dict)}
        image_by_id = {item.get("id"): item for item in (images or []) if isinstance(item, dict) and item.get("id")}
        surface_by_image = {image_id: item.get("surface_type") for image_id, item in image_by_id.items()}

        for field, requirement in requirements.items():
            if not requirement.get("required"):
                continue
            candidates = [field] + list(requirement.get("alternatives") or [])
            record = next((by_field.get(candidate) for candidate in candidates if by_field.get(candidate, {}).get("ai_value")), None)
            if not record:
                continue
            surface = str(surface_by_image.get(record.get("source_image_id")) or "UNKNOWN").upper()
            status, explanation, confidence, metrics = self._evaluate_record(
                record, requirement, context, image_by_id, surface_by_image
            )
            results.append({
                "field_name": field, "matched_field": record.get("field_name"), "status": status,
                "confidence": confidence, "surface": surface, "explanation": explanation,
                "source_image_id": record.get("source_image_id"), "source_block_id": record.get("source_block_id"),
                "bbox": record.get("bbox"), "geometry": metrics,
                "rule_code": "RULE-009-PLACEMENT",
                "statutory_reference": "Rule 9, Legal Metrology (Packaged Commodities) Rules, 2011",
            })

        if context.get("declarationReadThroughLiquid"):
            results.append({
                "field_name": "package_declarations", "status": "POTENTIAL_VIOLATION", "confidence": 0.99,
                "surface": "PACKAGE", "explanation": "Declarations are recorded as requiring reading through the liquid commodity.",
                "rule_code": "RULE-009-PLACEMENT", "statutory_reference": "Rule 9(2), Legal Metrology (Packaged Commodities) Rules, 2011",
            })
        return results


declaration_placement_service = DeclarationPlacementService()
