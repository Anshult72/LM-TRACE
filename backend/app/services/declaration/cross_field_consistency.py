import re
from typing import List, Dict, Any
from app.schemas.domain import CrossFieldConflictItem

class CrossFieldConsistencyService:
    @staticmethod
    def detect_conflicts(declarations: List[Dict[str, Any]], ocr_blocks: List[Any]) -> List[CrossFieldConflictItem]:
        conflicts = []

        def _get_block_info(block: Any) -> tuple[str, str]:
            if hasattr(block, "text"):
                return str(getattr(block, "text", "") or ""), str(getattr(block, "surface_type", "FRONT") or "FRONT")
            if isinstance(block, dict):
                return str(block.get("text", "") or ""), str(block.get("surface_type", "FRONT") or "FRONT")
            if isinstance(block, str):
                return block, "FRONT"
            return "", "FRONT"

        # 1. Detect conflicting MRPs across surfaces
        mrp_numbers = []
        for blk in ocr_blocks:
            text, surface = _get_block_info(blk)
            if not text:
                continue
            matches = re.findall(r"(?:MRP|Rs\.?|₹)\s*(\d+(?:\.\d{1,2})?)", text, re.IGNORECASE)
            for m in matches:
                try:
                    price = float(m)
                    if price > 0:
                        mrp_numbers.append({"surface": surface, "value": price, "text": text})
                except ValueError:
                    pass

        unique_prices = set(item["value"] for item in mrp_numbers)
        if len(unique_prices) > 1:
            conflicts.append(
                CrossFieldConflictItem(
                    field_name="mrp",
                    issue_type="MULTIPLE_MRPS",
                    description=f"Multiple conflicting retail prices detected across package surfaces: {[p['value'] for p in mrp_numbers]}",
                    source_values=mrp_numbers,
                    severity="POTENTIAL_ISSUE"
                )
            )

        # 2. Detect conflicting net quantities
        qty_values = []
        unit_factors = {"g": ("MASS", 1.0), "kg": ("MASS", 1000.0), "ml": ("VOLUME", 1.0), "l": ("VOLUME", 1000.0)}
        for blk in ocr_blocks:
            text, surface = _get_block_info(blk)
            if not text:
                continue
            matches = re.findall(r"(?:Net\s*(?:Qty|Weight|Volume)?\s*:?\s*)(\d+(?:\.\d+)?)\s*(kg|g|ml|l)", text, re.IGNORECASE)
            for val, unit in matches:
                dimension, factor = unit_factors[unit.lower()]
                qty_values.append({
                    "surface": surface,
                    "value": f"{val} {unit.upper()}",
                    "normalized_value": float(val) * factor,
                    "dimension": dimension,
                    "text": text,
                })

        unique_qtys = {(item["dimension"], round(item["normalized_value"], 6)) for item in qty_values}
        if len(unique_qtys) > 1:
            conflicts.append(
                CrossFieldConflictItem(
                    field_name="net_quantity",
                    issue_type="INCONSISTENT_QUANTITY",
                    description=f"Different net quantities observed across package faces: {list(unique_qtys)}",
                    source_values=qty_values,
                    severity="POTENTIAL_ISSUE"
                )
            )

        # 3. Conflicting country-of-origin declarations across surfaces.
        origins = []
        for blk in ocr_blocks:
            text, surface = _get_block_info(blk)
            match = re.search(r"(?:COUNTRY\s+OF\s+ORIGIN|MADE\s+IN|PRODUCT\s+OF)\s*:?\s*([A-Z][A-Z .'-]{2,})", text, re.IGNORECASE)
            if match:
                value = re.split(r"[|;,\n]", match.group(1))[0].strip().title()
                origins.append({"surface": surface, "value": value, "text": text})
        if len({item["value"].casefold() for item in origins}) > 1:
            conflicts.append(CrossFieldConflictItem(
                field_name="country_of_origin",
                issue_type="CONFLICTING_ORIGIN",
                description=f"Conflicting countries of origin detected: {[item['value'] for item in origins]}",
                source_values=origins,
                severity="POTENTIAL_ISSUE",
            ))

        return conflicts

cross_field_consistency_service = CrossFieldConsistencyService()
