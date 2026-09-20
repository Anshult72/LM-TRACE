from typing import Any, Dict, Tuple

from app.schemas.domain import ExtractedDeclarationsPayload


class DeclarationApplicabilityService:
    """Builds a deterministic Legal Metrology applicability context.

    Explicit officer facts win. UNKNOWN values may be inferred from extracted
    package declarations, and every inference is returned with its reason so it
    can be audited and corrected before finalisation.
    """

    PERISHABLE_CATEGORY_TERMS = {
        "food", "beverage", "juice", "milk", "baby food", "edible oil",
        "supplement", "nutraceutical",
    }

    @staticmethod
    def _field_value(extracted: ExtractedDeclarationsPayload, field: str) -> str:
        value = getattr(extracted, field, None)
        return str(getattr(value, "value", "") or "").strip()

    def build_context(
        self,
        inspection: Dict[str, Any],
        extracted: ExtractedDeclarationsPayload,
    ) -> Tuple[Dict[str, Any], Dict[str, str]]:
        snapshot = inspection.get("rule_snapshot") or {}
        explicit = snapshot.get("applicability_context") or inspection.get("applicability_context") or {}
        category = str(snapshot.get("product_category") or inspection.get("product_category") or "General Packaged Commodity")
        category_lower = category.lower()
        inference: Dict[str, str] = {}

        market_scope = str(explicit.get("market_scope") or "RETAIL").upper()
        if market_scope not in {"RETAIL", "INDUSTRIAL", "INSTITUTIONAL"}:
            market_scope = "RETAIL"
            inference["market_scope"] = "Invalid stored market scope was ignored; officer confirmation is required."
        rules_applicable = market_scope not in {"INDUSTRIAL", "INSTITUTIONAL"}

        origin_type = str(explicit.get("origin_type") or "UNKNOWN").upper()
        if origin_type not in {"DOMESTIC", "IMPORTED", "UNKNOWN"}:
            origin_type = "UNKNOWN"
            inference["origin_type"] = "Invalid stored origin classification was ignored; officer confirmation is required."
        if origin_type == "UNKNOWN":
            importer_evidence = self._field_value(extracted, "importer_name") or self._field_value(extracted, "importer_address")
            if importer_evidence:
                origin_type = "IMPORTED"
                inference["origin_type"] = "Inferred as IMPORTED from an OCR-grounded importer declaration."
            else:
                country = self._field_value(extracted, "country_of_origin").lower()
                if country and country not in {"india", "ind", "bharat"}:
                    origin_type = "IMPORTED"
                    inference["origin_type"] = "Inferred as IMPORTED from a non-India country-of-origin declaration."
                else:
                    origin_type = "UNKNOWN"
                    inference["origin_type"] = "Origin could not be proven from OCR; officer confirmation is required."

        packer_flag = explicit.get("is_packer_distinct")
        if packer_flag is None:
            manufacturer = self._field_value(extracted, "manufacturer_name").lower()
            packer = self._field_value(extracted, "packer_name").lower()
            packer_flag = bool(packer and manufacturer and packer != manufacturer)
            inference["is_packer_distinct"] = "Derived by comparing OCR-grounded manufacturer and packer identities."

        shelf_flag = explicit.get("shelf_life_declaration_required")
        if shelf_flag is None:
            has_shelf_declaration = any(self._field_value(extracted, field) for field in ("best_before", "use_by", "expiry_date"))
            category_implies_shelf_life = any(term in category_lower for term in self.PERISHABLE_CATEGORY_TERMS)
            shelf_flag = bool(has_shelf_declaration or category_implies_shelf_life)
            inference["shelf_life_declaration_required"] = (
                "Derived from the commodity category or detected best-before/use-by/expiry declaration."
            )

        dimensions_flag = explicit.get("dimensions_declaration_required")
        if dimensions_flag is None:
            dimensions_flag = bool(self._field_value(extracted, "dimensions"))
            inference["dimensions_declaration_required"] = "Enabled only when dimensions were detected; officer may override when size is relevant."

        usp_flag = explicit.get("unit_sale_price_required")
        if usp_flag is None:
            usp_flag = rules_applicable and market_scope == "RETAIL"
            inference["unit_sale_price_required"] = "Defaulted for a retail pre-packaged commodity; officer may record a statutory exemption."

        context = {
            "inspectionDate": inspection.get("inspection_date"),
            "productCategory": category,
            "isCommodityPackaged": True,
            "marketScope": market_scope,
            "saleChannel": "ECOMMERCE" if inspection.get("inspection_type") == "ONLINE_LISTING" else "RETAIL",
            "isEcommerce": inspection.get("inspection_type") == "ONLINE_LISTING",
            "rulesApplicable": rules_applicable,
            "countryOfOriginType": origin_type,
            "originTypeConfirmed": origin_type in {"DOMESTIC", "IMPORTED"},
            "isImported": origin_type == "IMPORTED",
            "isPackerDistinct": bool(packer_flag),
            "bestBeforeApplicable": bool(shelf_flag),
            "dimensionsRelevant": bool(dimensions_flag),
            "unitSalePriceApplicable": bool(usp_flag),
            "isMultiPiecePackage": bool(explicit.get("is_multi_piece_package", False)),
            "electronicDeclarationsViaQr": bool(explicit.get("electronic_declarations_via_qr", False)),
            "hasOuterWrapper": bool(explicit.get("has_outer_wrapper", False)),
            "outerWrapperTransparent": bool(explicit.get("outer_wrapper_transparent", False)),
            "declarationReadThroughLiquid": bool(explicit.get("declaration_read_through_liquid", False)),
            "packageType": inspection.get("package_type") or "RECTANGULAR",
            "packageConstructionType": inspection.get("package_construction_type") or "NORMAL",
            "calibrationStatus": inspection.get("calibration_status") or "NOT_CALIBRATED",
        }
        return context, inference


declaration_applicability_service = DeclarationApplicabilityService()
