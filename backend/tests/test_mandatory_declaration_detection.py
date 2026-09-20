import pytest

from app.engines.compliance_engine.compliance_engine import compliance_engine
from app.engines.rule_engine.rule_engine import rule_engine
from app.schemas.domain import ExtractedDeclarationsPayload, PackageApplicabilityInput, SemanticDeclarationField
from app.services.declaration.applicability_service import declaration_applicability_service


def field(name: str, value: str | None):
    return SemanticDeclarationField(field_name=name, value=value, confidence=0.95)


def payload(**overrides):
    values = {
        "commodity_name": field("commodity_name", "Basmati Rice"),
        "net_quantity": field("net_quantity", "1 kg"),
        "mrp": field("mrp", "MRP Rs 180 inclusive of all taxes"),
        "manufacturer_name": field("manufacturer_name", "Bharat Foods Ltd"),
        "manufacturer_address": field("manufacturer_address", "Delhi 110001"),
        "manufacturing_date": field("manufacturing_date", "08/2026"),
        "consumer_care": field("consumer_care", "1800-111-222 care@example.in"),
    }
    values.update(overrides)
    return ExtractedDeclarationsPayload(**values)


def inspection(context=None, category="Packaged Food"):
    return {
        "inspection_date": "2026-09-20T00:00:00Z",
        "inspection_type": "PHYSICAL",
        "package_type": "RECTANGULAR",
        "package_construction_type": "NORMAL",
        "calibration_status": "NOT_CALIBRATED",
        "rule_snapshot": {
            "product_category": category,
            "applicability_context": context or {},
        },
    }


def test_imported_product_is_inferred_from_importer_ocr():
    extracted = payload(
        importer_name=field("importer_name", "India Imports Pvt Ltd"),
        importer_address=field("importer_address", "Mumbai 400001"),
        country_of_origin=field("country_of_origin", "France"),
    )
    context, inferences = declaration_applicability_service.build_context(inspection(), extracted)

    assert context["isImported"] is True
    assert context["countryOfOriginType"] == "IMPORTED"
    assert "origin_type" in inferences


def test_unknown_origin_is_not_silently_treated_as_domestic():
    context, inferences = declaration_applicability_service.build_context(inspection(), payload())
    assert context["countryOfOriginType"] == "UNKNOWN"
    assert context["originTypeConfirmed"] is False
    assert context["isImported"] is False
    assert "officer confirmation" in inferences["origin_type"].lower()


def test_applicability_input_rejects_unknown_scope_values():
    with pytest.raises(ValueError):
        PackageApplicabilityInput(market_scope="WHOLESALE")


def test_explicit_officer_context_overrides_inference():
    extracted = payload(importer_name=field("importer_name", "Unexpected OCR Text"))
    context, _ = declaration_applicability_service.build_context(
        inspection({
            "market_scope": "RETAIL",
            "origin_type": "DOMESTIC",
            "shelf_life_declaration_required": False,
            "unit_sale_price_required": False,
        }),
        extracted,
    )

    assert context["isImported"] is False
    assert context["bestBeforeApplicable"] is False
    assert context["unitSalePriceApplicable"] is False


def test_institutional_package_is_outside_retail_declaration_scope():
    context, _ = declaration_applicability_service.build_context(
        inspection({"market_scope": "INSTITUTIONAL", "origin_type": "DOMESTIC"}),
        payload(),
    )
    assert context["rulesApplicable"] is False
    assert rule_engine.determine_required_declarations([], context) == {}


@pytest.mark.asyncio
async def test_out_of_scope_package_does_not_generate_declaration_violations():
    context, _ = declaration_applicability_service.build_context(
        inspection({"market_scope": "INDUSTRIAL", "origin_type": "DOMESTIC"}),
        payload(),
    )
    assessment = await compliance_engine.evaluate_compliance(
        extracted_declarations={},
        correctness_data={"matrix": [], "conflicts": []},
        context=context,
    )

    assert assessment.violation_count == 0
    assert assessment.potential_violations == []
    assert assessment.checks[0].check_type == "APPLICABILITY_SCOPE"


def test_complete_imported_perishable_requirement_set():
    context = {
        "rulesApplicable": True,
        "isImported": True,
        "isPackerDistinct": True,
        "bestBeforeApplicable": True,
        "dimensionsRelevant": True,
        "unitSalePriceApplicable": True,
    }
    requirements = rule_engine.determine_required_declarations([], context)

    for required_field in (
        "commodity_name", "net_quantity", "mrp", "manufacturer_name",
        "manufacturer_address", "manufacture_pack_import_date", "consumer_care",
        "country_of_origin", "importer_name", "importer_address", "packer_name",
        "packer_address", "best_before", "dimensions", "unit_sale_price",
    ):
        assert requirements[required_field]["required"] is True

    assert requirements["best_before"]["alternatives"] == ["best_before", "use_by", "expiry_date"]
    assert requirements["manufacture_pack_import_date"]["alternatives"] == [
        "manufacturing_date", "packing_date", "import_date"
    ]


def test_multi_piece_requires_declarations_on_outer_and_inner_retail_packages():
    requirements = rule_engine.determine_required_declarations([], {
        "rulesApplicable": True,
        "isImported": False,
        "isPackerDistinct": False,
        "bestBeforeApplicable": False,
        "dimensionsRelevant": False,
        "unitSalePriceApplicable": False,
        "isMultiPiecePackage": True,
    })

    required = [item for item in requirements.values() if item["required"]]
    assert required
    assert all(item["package_scope"] == "OUTER_AND_EACH_INNER_RETAIL_PACKAGE" for item in required)


@pytest.mark.asyncio
async def test_use_by_satisfies_shelf_life_alternative():
    extracted = payload(use_by=field("use_by", "Use by 09/2026")).model_dump()
    context = {
        "inspectionDate": "2026-09-20T00:00:00Z",
        "rulesApplicable": True,
        "isCommodityPackaged": True,
        "isImported": False,
        "isPackerDistinct": False,
        "bestBeforeApplicable": True,
        "dimensionsRelevant": False,
        "unitSalePriceApplicable": False,
        "calibrationStatus": "NOT_CALIBRATED",
    }
    matrix = [
        {"field_name": name, "presence": True, "correctness": "VALID", "confidence": 0.95}
        for name in (
            "commodity_name", "net_quantity", "mrp", "manufacturer",
            "manufacturing_packing_date", "consumer_care", "use_by",
        )
    ]

    assessment = await compliance_engine.evaluate_compliance(
        extracted_declarations=extracted,
        correctness_data={"matrix": matrix, "conflicts": []},
        context=context,
    )

    shelf_checks = [check for check in assessment.checks if check.field_name == "best_before"]
    assert len(shelf_checks) == 1
    assert shelf_checks[0].result == "PASS"
    assert not any(v.get("field") == "best_before" for v in assessment.potential_violations)
