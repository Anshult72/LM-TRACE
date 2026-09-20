import re
from typing import Any, Dict, List, Optional, Tuple

from app.schemas.domain import ExtractedDeclarationsPayload, SemanticDeclarationField
from app.services.declaration.cross_field_consistency import cross_field_consistency_service
from app.services.declaration.unit_validation import unit_validation_service


def _safe_field(field: Optional[SemanticDeclarationField], name: str) -> SemanticDeclarationField:
    return field or SemanticDeclarationField(field_name=name, value=None, confidence=0.0)


class IDeclarationCorrectnessService:
    def evaluate_correctness(self, extracted: ExtractedDeclarationsPayload, ocr_blocks: List[Any], is_imported: bool = False) -> Dict[str, Any]:
        raise NotImplementedError


class DeclarationCorrectnessService(IDeclarationCorrectnessService):
    DATE_PATTERN = re.compile(
        r"^\s*(?:(?P<day>\d{1,2})[/-])?(?P<month>\d{1,2})[/-](?P<year>\d{2}|\d{4})\s*$"
        r"|^\s*(?P<iso_year>\d{4})[-/](?P<iso_month>\d{1,2})(?:[-/](?P<iso_day>\d{1,2}))?\s*$"
    )
    PHONE_PATTERN = re.compile(r"(?:\+?91[-\s]?)?(?:1800[-\s]?\d{3}[-\s]?\d{3,4}|[6-9]\d{9}|\d{3,4}[-\s]\d{3,4}[-\s]\d{3,4})")
    EMAIL_PATTERN = re.compile(r"[\w.+-]+@[\w.-]+\.\w+")
    PIN_PATTERN = re.compile(r"\b[1-9]\d{5}\b")

    @staticmethod
    def _value(field: Optional[SemanticDeclarationField]) -> str:
        return str(getattr(field, "value", "") or "").strip()

    @staticmethod
    def _failure_status(field: SemanticDeclarationField) -> str:
        return "INVALID" if field.confidence >= 0.75 else "REVIEW"

    @classmethod
    def _valid_calendar_date(cls, value: str) -> bool:
        match = cls.DATE_PATTERN.match(value or "")
        if not match:
            return False
        month = int(match.group("month") or match.group("iso_month"))
        day_text = match.group("day") or match.group("iso_day")
        return 1 <= month <= 12 and (not day_text or 1 <= int(day_text) <= 31)

    @staticmethod
    def _address_status(value: str, require_indian_pin: bool) -> Tuple[str, str]:
        if not value:
            return "MISSING", "Complete postal address is absent."
        has_location_detail = len(value) >= 10 and ("," in value or len(value.split()) >= 3)
        has_pin = bool(DeclarationCorrectnessService.PIN_PATTERN.search(value))
        if has_location_detail and (has_pin or not require_indian_pin):
            return "VALID", "Complete address structure detected."
        return "REVIEW", "Verify street/locality, city, State and PIN/postal code."

    @staticmethod
    def _matrix_item(field_name: str, declaration: str, field: SemanticDeclarationField, correctness: str, details: str) -> Dict[str, Any]:
        present = bool(field.value and str(field.value).strip())
        if not present:
            correctness = "NOT_APPLICABLE"
        final_check = "PASS" if present and correctness == "VALID" else (
            "REVIEW" if present and correctness == "REVIEW" else "POTENTIAL_VIOLATION"
        )
        return {
            "declaration": declaration,
            "field_name": field_name,
            "presence": present,
            "completeness": "COMPLETE" if correctness == "VALID" else "INCOMPLETE",
            "correctness": correctness,
            "details": details,
            "confidence": field.confidence,
            "value": field.value,
            "canonical_unit": field.canonical_unit,
            "source_block_id": field.source_block_id,
            "source_image_id": field.source_image_id,
            "source_text": field.source_text,
            "bbox": field.bbox.model_dump() if field.bbox else None,
            "final_check": final_check,
        }

    def evaluate_correctness(self, extracted: ExtractedDeclarationsPayload, ocr_blocks: List[Any], is_imported: bool = False) -> Dict[str, Any]:
        matrix: List[Dict[str, Any]] = []

        commodity = _safe_field(extracted.commodity_name, "commodity_name")
        commodity_status = "VALID" if len(self._value(commodity)) >= 2 else self._failure_status(commodity)
        matrix.append(self._matrix_item("commodity_name", "Common / Generic Commodity Name", commodity, commodity_status,
                                        "Commodity identity detected." if commodity_status == "VALID" else "Commodity identity is blank or ambiguous."))

        mrp = _safe_field(extracted.mrp, "mrp")
        mrp_value = self._value(mrp)
        number_match = re.search(r"(?<![-\d])(\d+(?:\.\d{1,2})?)", mrp_value)
        has_label = bool(re.search(r"\b(?:MRP|MAXIMUM\s+RETAIL\s+PRICE|RETAIL\s+SALE\s+PRICE)\b", mrp_value, re.I))
        has_currency = bool(re.search(r"₹|\bRS\.?\b|\bINR\b", mrp_value, re.I))
        tax_inclusive = bool(re.search(r"INCLUSIVE\s+OF\s+(?:ALL\s+)?TAX(?:ES)?|INCL\.?\s*(?:OF\s+)?TAX", mrp_value, re.I))
        if not mrp_value:
            mrp_status, mrp_details = "NOT_APPLICABLE", "MRP declaration is absent."
        elif re.search(r"-\s*\d", mrp_value) or not number_match or float(number_match.group(1)) <= 0:
            mrp_status, mrp_details = "INVALID", "MRP must contain a positive monetary value."
        elif has_label and has_currency and tax_inclusive:
            mrp_status, mrp_details = "VALID", "MRP label, currency, price and tax-inclusive wording detected."
        else:
            mrp_status, mrp_details = self._failure_status(mrp), "MRP label, rupee indication or 'inclusive of all taxes' wording is incomplete."
        matrix.append(self._matrix_item("mrp", "MRP / Retail Sale Price", mrp, mrp_status, mrp_details))

        quantity = _safe_field(extracted.net_quantity, "net_quantity")
        number, canonical_unit, legal_unit = unit_validation_service.parse_quantity(self._value(quantity))
        if not self._value(quantity):
            qty_status, qty_details = "NOT_APPLICABLE", "Net quantity declaration is absent."
        elif not legal_unit:
            qty_status, qty_details = self._failure_status(quantity), "Recognized standard quantity unit or number notation is missing."
        elif number is None or number <= 0:
            qty_status, qty_details = "INVALID", "Net quantity must be positive."
        else:
            qty_status, qty_details = "VALID", f"Positive net quantity in standard unit {canonical_unit}."
            quantity.canonical_unit = canonical_unit
        matrix.append(self._matrix_item("net_quantity", "Net Quantity", quantity, qty_status, qty_details))

        role_specs = (
            ("manufacturer", "Manufacturer", extracted.manufacturer_name, extracted.manufacturer_address, not is_imported),
            ("packer", "Packer", extracted.packer_name, extracted.packer_address, True),
            ("importer", "Importer", extracted.importer_name, extracted.importer_address, True),
        )
        for key, label, raw_name, raw_address, require_pin in role_specs:
            name, address = _safe_field(raw_name, f"{key}_name"), _safe_field(raw_address, f"{key}_address")
            name_value, address_value = self._value(name), self._value(address)
            address_status, address_details = self._address_status(address_value, require_pin)
            name_status = "VALID" if len(name_value) >= 2 else self._failure_status(name)
            normalized_address_status = "VALID" if address_status == "VALID" else self._failure_status(address)
            matrix.append(self._matrix_item(
                f"{key}_name", f"{label} Name", name, name_status,
                f"{label} name detected." if name_status == "VALID" else f"{label} name is absent or ambiguous.",
            ))
            matrix.append(self._matrix_item(
                f"{key}_address", f"{label} Address", address, normalized_address_status, address_details,
            ))
            combined = SemanticDeclarationField(
                field_name=key,
                value=f"{name_value} - {address_value}".strip(" -") or None,
                confidence=max(name.confidence, address.confidence),
                source_block_id=name.source_block_id or address.source_block_id,
                source_image_id=name.source_image_id or address.source_image_id,
                source_text=name.source_text or address.source_text,
                bbox=name.bbox or address.bbox,
            )
            if not combined.value:
                status, details = "NOT_APPLICABLE", f"{label} identity is absent."
            elif len(name_value) >= 2 and address_status == "VALID":
                status, details = "VALID", f"{label} name and complete address detected."
            else:
                status, details = self._failure_status(combined), f"{label} details are incomplete. {address_details}"
            role_item = self._matrix_item(key, f"{label} Name & Address", combined, status, details)
            if combined.value:
                if status != "VALID" and ((key == "importer" and is_imported) or key == "manufacturer"):
                    role_item["final_check"] = "POTENTIAL_VIOLATION"
            matrix.append(role_item)

        date_candidates = [
            _safe_field(extracted.manufacturing_date, "manufacturing_date"),
            _safe_field(extracted.packing_date, "packing_date"),
            _safe_field(extracted.import_date, "import_date"),
        ]
        selected_date = next((item for item in date_candidates if self._value(item)), date_candidates[0])
        date_valid = self._valid_calendar_date(self._value(selected_date))
        matrix.append(self._matrix_item("manufacturing_packing_date", "Month / Year of Manufacture, Packing or Import", selected_date,
                                        "VALID" if date_valid else self._failure_status(selected_date),
                                        "Valid calendar date detected." if date_valid else "Date must contain a valid month/year or calendar date."))

        consumer = _safe_field(extracted.consumer_care, "consumer_care")
        consumer_value = self._value(consumer)
        consumer_parts = (
            bool(self.PHONE_PATTERN.search(consumer_value)), bool(self.EMAIL_PATTERN.search(consumer_value)),
            bool(self.PIN_PATTERN.search(consumer_value)) or len(consumer_value.split(",")) >= 3,
            bool(re.search(r"CONSUMER\s+CARE|CUSTOMER\s+CARE|COMPLAINT|GRIEVANCE|CONTACT", consumer_value, re.I)),
        )
        consumer_valid = all(consumer_parts)
        matrix.append(self._matrix_item("consumer_care", "Consumer Care Details", consumer, "VALID" if consumer_valid else self._failure_status(consumer),
                                        "Contact office/name, address, telephone and e-mail detected." if consumer_valid else "Verify contact office/name, complete address, telephone and e-mail."))

        origin = _safe_field(extracted.country_of_origin, "country_of_origin")
        origin_value = self._value(origin)
        if origin_value and is_imported and origin_value.lower() in {"india", "ind", "bharat"}:
            origin_status, origin_details = "INVALID", "Imported commodity cannot declare India as the foreign country of origin."
        elif len(origin_value) >= 3:
            origin_status, origin_details = "VALID", "Country of origin detected."
        else:
            origin_status, origin_details = self._failure_status(origin), "Country-of-origin value is absent or ambiguous."
        matrix.append(self._matrix_item("country_of_origin", "Country of Origin", origin, origin_status, origin_details))

        for field_name, label, raw_field in (
            ("best_before", "Best Before", extracted.best_before), ("use_by", "Use By", extracted.use_by),
            ("expiry_date", "Expiry Date", extracted.expiry_date),
        ):
            field, value = _safe_field(raw_field, field_name), self._value(raw_field)
            valid = self._valid_calendar_date(value) or bool(re.search(r"\b\d+\s*(?:DAY|MONTH|YEAR)S?\b", value, re.I))
            matrix.append(self._matrix_item(field_name, label, field, "VALID" if valid else self._failure_status(field),
                                            "Usable shelf-life declaration detected." if valid else "Shelf-life must contain a date or unambiguous duration."))

        dimensions = _safe_field(extracted.dimensions, "dimensions")
        dimension_valid = bool(re.search(r"\d+(?:\.\d+)?\s*(?:MM|CM|M)\s*[X×]\s*\d+(?:\.\d+)?", self._value(dimensions), re.I))
        matrix.append(self._matrix_item("dimensions", "Commodity Dimensions", dimensions, "VALID" if dimension_valid else self._failure_status(dimensions),
                                        "Numeric dimensions with standard units detected." if dimension_valid else "Dimensions must use numeric measurements and standard length units."))

        unit_price = _safe_field(extracted.unit_sale_price, "unit_sale_price")
        unit_price_match = re.search(r"(?:₹|RS\.?|INR)\s*(\d+(?:\.\d{1,2})?)\s*(?:/|PER)\s*(G|KG|ML|L|CM|M|UNIT|U)\b", self._value(unit_price), re.I)
        unit_price_valid = bool(unit_price_match)
        unit_price_details = "Currency, unit price and reference unit detected."
        if unit_price_match and number_match and number and canonical_unit:
            displayed_price = float(unit_price_match.group(1))
            displayed_unit = unit_price_match.group(2).upper()
            mrp_amount = float(number_match.group(1))
            factors = {"G": ("G", 1.0), "KG": ("G", 1000.0), "ML": ("ML", 1.0), "L": ("ML", 1000.0), "CM": ("CM", 1.0), "M": ("CM", 100.0), "U": ("U", 1.0)}
            qty_base_unit, qty_factor = factors.get(canonical_unit, (canonical_unit, 1.0))
            price_base_unit, price_factor = factors.get(displayed_unit, (displayed_unit, 1.0))
            if qty_base_unit != price_base_unit:
                unit_price_valid = False
                unit_price_details = "Unit sale price reference unit is incompatible with the declared net quantity."
            else:
                expected = mrp_amount / (number * qty_factor / price_factor)
                if abs(displayed_price - expected) > max(0.02, expected * 0.01):
                    unit_price_valid = False
                    unit_price_details = f"Displayed unit sale price does not reconcile with MRP and net quantity (expected approximately ₹{expected:.2f} per {displayed_unit})."
        matrix.append(self._matrix_item("unit_sale_price", "Unit Sale Price", unit_price, "VALID" if unit_price_valid else self._failure_status(unit_price),
                                        unit_price_details if unit_price_valid or unit_price_match else "Unit sale price must state rupee price per prescribed reference unit."))

        block_by_id = {str(getattr(block, "block_id", None) or (block.get("block_id") if isinstance(block, dict) else "")): block for block in ocr_blocks}
        for item in matrix:
            block = block_by_id.get(str(item.get("source_block_id") or ""))
            if block is not None:
                item["source_surface"] = str(getattr(block, "surface_type", None) or (block.get("surface_type") if isinstance(block, dict) else "UNKNOWN"))
                item["source_image_id"] = item.get("source_image_id") or getattr(block, "image_id", None)
                if not item.get("bbox"):
                    bbox = getattr(block, "bbox", None)
                    item["bbox"] = bbox.model_dump() if hasattr(bbox, "model_dump") else bbox

        conflicts = cross_field_consistency_service.detect_conflicts(matrix, ocr_blocks)
        return {"matrix": matrix, "conflicts": [item.model_dump() for item in conflicts]}


declaration_correctness_service = DeclarationCorrectnessService()
