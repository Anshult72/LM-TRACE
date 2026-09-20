from typing import Any, Dict, List


class DeclarationPlacementService:
    """Evaluates Rule 9 placement from captured-surface and OCR provenance."""

    @staticmethod
    def _has_valid_bbox(record: Dict[str, Any]) -> bool:
        bbox = record.get("bbox")
        if not isinstance(bbox, dict):
            return False
        try:
            return float(bbox.get("width", 0)) > 0 and float(bbox.get("height", 0)) > 0
        except (TypeError, ValueError):
            return False

    def evaluate(
        self,
        requirements: Dict[str, Dict[str, Any]],
        declarations: List[Dict[str, Any]],
        context: Dict[str, Any],
        images: List[Dict[str, Any]] | None = None,
    ) -> List[Dict[str, Any]]:
        results: List[Dict[str, Any]] = []
        by_field = {item.get("field_name"): item for item in declarations}
        surface_by_image = {item.get("id"): item.get("surface_type") for item in (images or [])}
        opaque_wrapper = bool(context.get("hasOuterWrapper")) and not bool(context.get("outerWrapperTransparent"))

        for field, requirement in requirements.items():
            if not requirement.get("required"):
                continue
            candidates = [field] + list(requirement.get("alternatives") or [])
            record = next((by_field.get(candidate) for candidate in candidates if by_field.get(candidate, {}).get("ai_value")), None)
            if not record:
                continue
            surface = str(surface_by_image.get(record.get("source_image_id")) or "UNKNOWN").upper()
            grounded = bool(record.get("source_image_id") and record.get("source_block_id") and self._has_valid_bbox(record))
            status, explanation = "PASS", f"Declaration is OCR-grounded on captured {surface} package surface."
            if not grounded:
                status, explanation = "UNVERIFIED", "Declaration text exists, but image/block/bounding-box provenance is incomplete."
            elif opaque_wrapper and surface != "OUTER_WRAPPER":
                status, explanation = "POTENTIAL_VIOLATION", "Opaque outer wrapper is present, but declaration was not found on it."
            results.append({
                "field_name": field, "matched_field": record.get("field_name"), "status": status, "surface": surface,
                "explanation": explanation, "source_image_id": record.get("source_image_id"),
                "source_block_id": record.get("source_block_id"), "bbox": record.get("bbox"),
                "rule_code": "RULE-009-PLACEMENT", "statutory_reference": "Rule 9, Legal Metrology (Packaged Commodities) Rules, 2011",
            })

        if context.get("declarationReadThroughLiquid"):
            results.append({
                "field_name": "package_declarations", "status": "POTENTIAL_VIOLATION", "surface": "PACKAGE",
                "explanation": "Declarations are recorded as requiring reading through the liquid commodity.",
                "rule_code": "RULE-009-PLACEMENT", "statutory_reference": "Rule 9(2), Legal Metrology (Packaged Commodities) Rules, 2011",
            })

        if context.get("isMultiPiecePackage"):
            surfaces = {str(item.get("surface_type") or "").upper() for item in (images or [])}
            if not any(surface.startswith("INNER") for surface in surfaces):
                results.append({
                    "field_name": "inner_retail_packages", "status": "REVIEW", "surface": "NOT_CAPTURED",
                    "explanation": "Multi-piece package recorded, but no inner retail-package declaration surface was captured.",
                    "rule_code": "RULE-004-GROUP-PACKAGE", "statutory_reference": "Rule 4, Legal Metrology (Packaged Commodities) Rules, 2011",
                })
        return results


declaration_placement_service = DeclarationPlacementService()
