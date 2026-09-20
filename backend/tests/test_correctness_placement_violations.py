import pytest

from app.engines.compliance_engine.compliance_engine import compliance_engine
from app.schemas.domain import BoundingBox, ExtractedDeclarationsPayload, OcrBlock, SemanticDeclarationField
from app.services.declaration.correctness_service import declaration_correctness_service
from app.services.declaration.placement_service import declaration_placement_service


def semantic(name, value, confidence=0.98, block="b1", image="img-back"):
    return SemanticDeclarationField(
        field_name=name,
        value=value,
        confidence=confidence,
        source_block_id=block,
        source_image_id=image,
        bbox=BoundingBox(x=10, y=20, width=200, height=40),
    )


def test_complete_statutory_formats_are_validated():
    payload = ExtractedDeclarationsPayload(
        commodity_name=semantic("commodity_name", "Basmati Rice"),
        net_quantity=semantic("net_quantity", "1 kg"),
        mrp=semantic("mrp", "MRP ₹180.00 Inclusive of all taxes"),
        manufacturer_name=semantic("manufacturer_name", "Bharat Foods Ltd"),
        manufacturer_address=semantic("manufacturer_address", "Plot 4, Delhi 110001"),
        manufacturing_date=semantic("manufacturing_date", "08/2026"),
        consumer_care=semantic("consumer_care", "Consumer Care: Bharat Foods, Delhi 110001; 1800-111-2222; care@bharat.in"),
        dimensions=semantic("dimensions", "20 cm x 10 cm"),
        unit_sale_price=semantic("unit_sale_price", "₹180.00 per kg"),
        best_before=semantic("best_before", "12 months"),
    )
    result = declaration_correctness_service.evaluate_correctness(payload, [])
    by_field = {item["field_name"]: item for item in result["matrix"]}

    for field in ("commodity_name", "net_quantity", "mrp", "manufacturer", "manufacturing_packing_date", "consumer_care", "dimensions", "unit_sale_price", "best_before"):
        assert by_field[field]["correctness"] == "VALID"
        assert by_field[field]["completeness"] == "COMPLETE"


def test_opaque_wrapper_requires_declarations_on_outer_wrapper():
    requirements = {"mrp": {"required": True}}
    declarations = [{
        "field_name": "mrp", "ai_value": "MRP ₹100 Inclusive of all taxes", "source_image_id": "img-back",
        "source_block_id": "b1", "bbox": {"x": 10, "y": 10, "width": 100, "height": 30},
    }]
    images = [{"id": "img-back", "surface_type": "BACK"}]
    results = declaration_placement_service.evaluate(
        requirements, declarations, {"hasOuterWrapper": True, "outerWrapperTransparent": False}, images
    )
    assert results[0]["status"] == "POTENTIAL_VIOLATION"


def test_transparent_wrapper_allows_visible_underlying_declaration():
    requirements = {"mrp": {"required": True}}
    declarations = [{
        "field_name": "mrp", "ai_value": "MRP ₹100 Inclusive of all taxes", "source_image_id": "img-back",
        "source_block_id": "b1", "bbox": {"x": 10, "y": 10, "width": 100, "height": 30},
    }]
    results = declaration_placement_service.evaluate(
        requirements, declarations, {"hasOuterWrapper": True, "outerWrapperTransparent": True},
        [{"id": "img-back", "surface_type": "BACK"}],
    )
    assert results[0]["status"] == "PASS"


def test_missing_bbox_never_auto_passes_placement():
    results = declaration_placement_service.evaluate(
        {"mrp": {"required": True}},
        [{"field_name": "mrp", "ai_value": "MRP ₹100", "source_image_id": "img-back", "source_block_id": "b1"}],
        {},
        [{"id": "img-back", "surface_type": "BACK"}],
    )
    assert results[0]["status"] == "UNVERIFIED"


def test_reading_declarations_through_liquid_is_flagged():
    results = declaration_placement_service.evaluate({}, [], {"declarationReadThroughLiquid": True}, [])
    assert results[0]["status"] == "POTENTIAL_VIOLATION"
    assert results[0]["field_name"] == "package_declarations"


def test_equivalent_quantities_on_different_surfaces_do_not_conflict():
    blocks = [
        OcrBlock(block_id="q1", text="Net Qty: 500 g", confidence=0.99, bbox=BoundingBox(x=0, y=0, width=10, height=10), image_id="i1", surface_type="FRONT"),
        OcrBlock(block_id="q2", text="Net Qty: 0.5 kg", confidence=0.99, bbox=BoundingBox(x=0, y=0, width=10, height=10), image_id="i2", surface_type="BACK"),
    ]
    result = declaration_correctness_service.evaluate_correctness(ExtractedDeclarationsPayload(), blocks)
    assert not any(item["issue_type"] == "INCONSISTENT_QUANTITY" for item in result["conflicts"])


def test_unit_sale_price_must_reconcile_with_mrp_and_quantity():
    payload = ExtractedDeclarationsPayload(
        mrp=semantic("mrp", "MRP ₹180.00 Inclusive of all taxes"),
        net_quantity=semantic("net_quantity", "1 kg"),
        unit_sale_price=semantic("unit_sale_price", "₹90.00 per kg"),
    )
    result = declaration_correctness_service.evaluate_correctness(payload, [])
    unit_price = next(item for item in result["matrix"] if item["field_name"] == "unit_sale_price")
    assert unit_price["correctness"] == "INVALID"
    assert "reconcile" in unit_price["details"]


@pytest.mark.asyncio
async def test_missing_individual_address_is_a_missing_declaration_violation():
    payload = ExtractedDeclarationsPayload(
        manufacturer_name=semantic("manufacturer_name", "Bharat Foods Ltd"),
        manufacturer_address=semantic("manufacturer_address", None),
    )
    correctness = declaration_correctness_service.evaluate_correctness(payload, [])
    context = {
        "inspectionDate": "2026-09-20T00:00:00Z", "rulesApplicable": True,
        "originTypeConfirmed": True, "isImported": False, "isPackerDistinct": False,
        "bestBeforeApplicable": False, "dimensionsRelevant": False, "unitSalePriceApplicable": False,
        "calibrationStatus": "NOT_CALIBRATED",
    }
    assessment = await compliance_engine.evaluate_compliance(payload.model_dump(), correctness, context)
    assert any(item.get("type") == "MISSING_DECLARATION" and item.get("field") == "manufacturer_address" for item in assessment.potential_violations)
    assert not any(item.get("field") == "manufacturer_name" for item in assessment.potential_violations)


@pytest.mark.asyncio
async def test_invalid_present_mrp_becomes_non_compliant_violation():
    payload = ExtractedDeclarationsPayload(mrp=semantic("mrp", "₹450.00"))
    correctness = declaration_correctness_service.evaluate_correctness(payload, [])
    context = {
        "inspectionDate": "2026-09-20T00:00:00Z", "rulesApplicable": True,
        "originTypeConfirmed": True, "isImported": False, "isPackerDistinct": False,
        "bestBeforeApplicable": False, "dimensionsRelevant": False, "unitSalePriceApplicable": False,
        "calibrationStatus": "NOT_CALIBRATED",
    }
    assessment = await compliance_engine.evaluate_compliance(payload.model_dump(), correctness, context)
    assert any(item.get("type") == "NON_COMPLIANT_DECLARATION" and item.get("field") == "mrp" for item in assessment.potential_violations)
