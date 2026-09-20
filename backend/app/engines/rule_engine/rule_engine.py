from typing import List, Dict, Any, Optional
from app.engines.rule_engine.condition_evaluator import condition_evaluator
from app.repositories import get_repository

class RuleEngine:
    async def get_applicable_rules(self, context: Dict[str, Any]) -> List[Dict[str, Any]]:
        repo = get_repository()
        inspection_date = context.get("inspectionDate") or "2026-09-08T00:00:00Z"
        
        active_versions = await repo.get_active_versions_for_date(inspection_date)
        applicable = []

        for v in active_versions:
            conditions = v.get("conditions", {})
            is_matched = condition_evaluator.evaluate_group(conditions, context)
            if is_matched:
                applicable.append(v)

        return applicable

    def get_rule_by_code_or_category(
        self,
        applicable_rules: List[Dict[str, Any]],
        code_prefix_or_code: str,
        category: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """Finds matching active rule version from applicable list by code or category."""
        for r in applicable_rules:
            r_code = r.get("rule_code", "")
            if r_code == code_prefix_or_code or r_code.startswith(code_prefix_or_code):
                return r
        if category:
            for r in applicable_rules:
                if r.get("category") == category:
                    return r
        return None

    def determine_required_declarations(
        self,
        applicable_rules: List[Dict[str, Any]],
        context: Dict[str, Any]
    ) -> Dict[str, Dict[str, Any]]:
        """
        Dynamically returns a dict of required declarations with statutory applicability reasons
        derived from active database rule definitions.
        """
        if context.get("rulesApplicable") is False:
            return {}

        # Map fields to their respective statutory rule codes
        field_rule_mapping = {
            "commodity_name": ("RULE-006-COMMODITY", "Rule 6(1)(b), LM (Packaged Commodities) Rules, 2011", "Mandatory generic identity under Rule 6(1)(b)"),
            "net_quantity": ("RULE-006-NET-QTY", "Rule 6(1)(c) & Rule 12, LM Rules, 2011", "Mandatory net quantity declaration under Rule 6(1)(c)"),
            "mrp": ("RULE-006-MRP", "Rule 6(1)(e), LM (Packaged Commodities) Rules, 2011", "Mandatory Maximum Retail Price (inclusive of all taxes) under Rule 6(1)(e)"),
            "manufacturer_name": ("RULE-006-NAME-ADDR", "Rule 6(1)(a) & Rule 10, LM Rules, 2011", "Mandatory manufacturer identity under Rule 6(1)(a)"),
            "manufacturer_address": ("RULE-006-NAME-ADDR", "Rule 6(1)(a) & Rule 10, LM Rules, 2011", "Mandatory complete manufacturer address under Rule 6(1)(a) & Rule 10"),
            "manufacture_pack_import_date": ("RULE-006-DATES", "Rule 6(1)(d), LM (Packaged Commodities) Rules, 2011", "Mandatory month and year of manufacture, packing or import"),
            "consumer_care": ("RULE-006-CONSUMER-CARE", "Rule 6(2), LM (Packaged Commodities) Rules, 2011", "Mandatory consumer grievance contact details")
        }

        default_mandatory = [
            "commodity_name", "net_quantity", "mrp",
            "manufacturer_name", "manufacturer_address",
            "manufacture_pack_import_date", "consumer_care"
        ]

        requirements: Dict[str, Dict[str, Any]] = {}
        for f in default_mandatory:
            code, default_ref, default_reason = field_rule_mapping[f]
            rule = self.get_rule_by_code_or_category(applicable_rules, code, "DECLARATIONS")
            requirements[f] = {
                "required": True,
                "reason": default_reason,
                "rule_code": rule.get("rule_code", code) if rule else code,
                "rule_version": rule.get("version", "2.0") if rule else "2.0",
                "statutory_reference": rule.get("statutory_reference", default_ref) if rule else default_ref
            }
            if f == "manufacture_pack_import_date":
                requirements[f]["alternatives"] = ["manufacturing_date", "packing_date", "import_date"]

        # Conditional declarations evaluation
        is_imported = context.get("isImported", False)
        origin_rule = self.get_rule_by_code_or_category(applicable_rules, "RULE-006-ORIGIN", "DECLARATIONS")
        importer_rule = self.get_rule_by_code_or_category(applicable_rules, "RULE-006-NAME-ADDR", "DECLARATIONS")

        if is_imported:
            requirements["country_of_origin"] = {
                "required": True,
                "reason": "Mandatory Country of Origin for imported commodities under Rule 6(1)(b) Proviso",
                "rule_code": origin_rule.get("rule_code", "RULE-006-ORIGIN") if origin_rule else "RULE-006-ORIGIN",
                "statutory_reference": origin_rule.get("statutory_reference", "Rule 6(1)(b)") if origin_rule else "Rule 6(1)(b)"
            }
            requirements["importer_name"] = {
                "required": True,
                "reason": "Mandatory importer identity under Rule 6(1)(a)",
                "rule_code": importer_rule.get("rule_code", "RULE-006-NAME-ADDR") if importer_rule else "RULE-006-NAME-ADDR",
                "statutory_reference": importer_rule.get("statutory_reference", "Rule 6(1)(a)") if importer_rule else "Rule 6(1)(a)"
            }
            requirements["importer_address"] = {
                "required": True,
                "reason": "Mandatory complete importer address under Rule 6(1)(a)",
                "rule_code": importer_rule.get("rule_code", "RULE-006-NAME-ADDR") if importer_rule else "RULE-006-NAME-ADDR",
                "statutory_reference": importer_rule.get("statutory_reference", "Rule 6(1)(a)") if importer_rule else "Rule 6(1)(a)"
            }
        else:
            requirements["country_of_origin"] = {"required": False, "reason": "Not applicable for domestic commodities"}
            requirements["importer_name"] = {"required": False, "reason": "Not applicable for domestic commodities"}
            requirements["importer_address"] = {"required": False, "reason": "Not applicable for domestic commodities"}

        if context.get("isPackerDistinct", False):
            requirements["packer_name"] = {
                "required": True,
                "reason": "Packer identity is mandatory where the manufacturer is not the packer",
                "rule_code": importer_rule.get("rule_code", "RULE-006-NAME-ADDR") if importer_rule else "RULE-006-NAME-ADDR",
                "statutory_reference": importer_rule.get("statutory_reference", "Rule 6(1)(a)") if importer_rule else "Rule 6(1)(a)",
            }
            requirements["packer_address"] = {
                "required": True,
                "reason": "Complete packer address is mandatory where the manufacturer is not the packer",
                "rule_code": importer_rule.get("rule_code", "RULE-006-NAME-ADDR") if importer_rule else "RULE-006-NAME-ADDR",
                "statutory_reference": importer_rule.get("statutory_reference", "Rule 6(1)(a)") if importer_rule else "Rule 6(1)(a)",
            }

        if context.get("bestBeforeApplicable", False):
            dates_rule = self.get_rule_by_code_or_category(applicable_rules, "RULE-006-DATES", "DECLARATIONS")
            requirements["best_before"] = {
                "required": True,
                "reason": "Mandatory Best Before / Use By date for commodities that may become unfit for human consumption under Rule 6(1)(da)",
                "rule_code": dates_rule.get("rule_code", "RULE-006-DATES") if dates_rule else "RULE-006-DATES",
                "statutory_reference": dates_rule.get("statutory_reference", "Rule 6(1)(da)") if dates_rule else "Rule 6(1)(da)",
                "alternatives": ["best_before", "use_by", "expiry_date"],
            }
        else:
            requirements["best_before"] = {"required": False, "reason": "Best before/use by not applicable to this commodity"}

        if context.get("dimensionsRelevant", False):
            qty_rule = self.get_rule_by_code_or_category(applicable_rules, "RULE-006-NET-QUANTITY", "DECLARATIONS")
            requirements["dimensions"] = {
                "required": True,
                "reason": "Mandatory dimensions declaration under Rule 6(1)(c) when size is relevant to consumer",
                "rule_code": qty_rule.get("rule_code", "RULE-006-NET-QUANTITY") if qty_rule else "RULE-006-NET-QUANTITY",
                "statutory_reference": qty_rule.get("statutory_reference", "Rule 6(1)(c)") if qty_rule else "Rule 6(1)(c)"
            }
        else:
            requirements["dimensions"] = {"required": False, "reason": "Dimensions not applicable"}

        # Unit Sale Price check (Rule 6(11) / RULE-006-UNIT-SALE-PRICE)
        usp_rule = self.get_rule_by_code_or_category(applicable_rules, "RULE-006-UNIT-SALE-PRICE", "MRP")
        if context.get("unitSalePriceApplicable", False):
            requirements["unit_sale_price"] = {
                "required": True,
                "reason": "Mandatory Unit Sale Price (USP) declaration under Rule 6(11) (2021 Amendment)",
                "rule_code": usp_rule.get("rule_code", "RULE-006-UNIT-SALE-PRICE") if usp_rule else "RULE-006-UNIT-SALE-PRICE",
                "statutory_reference": usp_rule.get("statutory_reference", "Legal Metrology (Packaged Commodities) Rules, 2011 - Rule 6(11)") if usp_rule else "Rule 6(11)"
            }
        else:
            requirements["unit_sale_price"] = {"required": False, "reason": "Unit sale price not applicable for this packaging"}

        if context.get("isMultiPiecePackage", False):
            for requirement in requirements.values():
                if requirement.get("required"):
                    requirement["package_scope"] = "OUTER_AND_EACH_INNER_RETAIL_PACKAGE"

        return requirements

rule_engine = RuleEngine()
