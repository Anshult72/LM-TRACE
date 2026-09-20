import pytest
from app.services.fingerprint.fingerprint_service import fingerprint_service
from app.services.label_change.label_change_service import label_change_service
from app.services.product.product_intelligence_service import product_intelligence_service
from app.repositories import get_repository

def test_product_identity_fingerprint_excludes_mrp():
    prod1 = {
        "brand": "ABC Heritage",
        "name": "ABC Premium Basmati Rice",
        "manufacturer_name": "ABC Agro Foods Ltd.",
        "category": "Packaged Food",
        "net_quantity": "5",
        "net_quantity_unit": "KG",
        "barcode": "8901234567890",
        "mrp": "₹399.00"
    }
    prod2 = {
        "brand": "ABC Heritage",
        "name": "ABC Premium Basmati Rice",
        "manufacturer_name": "ABC Agro Foods Ltd.",
        "category": "Packaged Food",
        "net_quantity": "5",
        "net_quantity_unit": "KG",
        "barcode": "8901234567890",
        "mrp": "₹449.00"  # Different MRP
    }
    hash1, repr1 = fingerprint_service.generate_product_identity_fingerprint(prod1)
    hash2, repr2 = fingerprint_service.generate_product_identity_fingerprint(prod2)

    # Hashes must be identical because MRP is a volatile field and not part of identity fingerprint!
    assert hash1 == hash2
    assert repr1 == repr2

@pytest.mark.asyncio
async def test_label_change_detection_mrp_alteration():
    # Test comparing against existing seed product 'prod-rice-01' which has previous MRP ₹449
    res = await label_change_service.compare_with_previous_version(
        product_id="prod-rice-01",
        current_mrp="₹499",
        current_quantity="5 KG",
        current_ocr_summary="Updated 2026 label text"
    )
    assert res.has_significant_change is True
    assert "MRP altered" in res.diff_summary[0]
    assert res.change_type in ["SEMANTIC_CHANGE", "BOTH"]
    assert res.previous_mrp is not None

@pytest.mark.asyncio
async def test_product_identification_and_linking():
    repo = get_repository()
    # 1. Create a dummy inspection
    ins = await repo.create({
        "id": "ins-test-prod-link",
        "inspection_code": "INS-2026-TEST01",
        "inspector_id": "u-insp-1",
        "product_id": None,
        "location": "Lucknow Market",
        "seller_name": "Test Seller",
        "status": "FINALIZED",
        "score": 92.0
    })

    declarations = [
        {"field_name": "commodity_name", "verified_value": "Shakti Whole Wheat Atta 10kg"},
        {"field_name": "brand_name", "verified_value": "Shakti Foods"},
        {"field_name": "net_quantity", "verified_value": "10", "canonical_unit": "KG"},
        {"field_name": "mrp", "verified_value": "₹420.00"},
        {"field_name": "barcode", "verified_value": "8901122334455"},
        {"field_name": "manufacturer_name", "verified_value": "Shakti Agro Mills Ltd."}
    ]

    # 2. Link product
    detail = await product_intelligence_service.identify_and_link_product(ins, declarations)
    assert detail is not None
    assert detail["product"]["name"] == "Shakti Whole Wheat Atta 10kg"
    assert detail["product"]["brand"] == "Shakti Foods"
    prod_id = detail["product"]["id"]

    # 3. Verify inspection is linked
    updated_ins = await repo.get_by_id("ins-test-prod-link")
    assert updated_ins["product_id"] == prod_id

    # 4. Verify product detail sections
    assert "identity" in detail
    assert "fingerprint" in detail
    assert detail["fingerprint"]["status"] in ["Verified", "New"]
    assert len(detail["inspection_history"]) >= 1
    assert detail["inspection_history"][0]["inspection_code"] == "INS-2026-TEST01"

    # 5. Verify single version comparison does not fabricate diffs
    diff = await product_intelligence_service.compare_versions(prod_id)
    assert diff["has_multiple_versions"] is False
    assert "Only one label version" in diff["message"]

    # 6. Simulate a subsequent inspection with altered MRP (price hike)
    ins2 = await repo.create({
        "id": "ins-test-prod-link-2",
        "inspection_code": "INS-2026-TEST02",
        "inspector_id": "u-insp-1",
        "product_id": None,
        "location": "Delhi Retail Store",
        "seller_name": "Fresh Mart",
        "status": "FINALIZED",
        "score": 95.0
    })

    declarations2 = [
        {"field_name": "commodity_name", "verified_value": "Shakti Whole Wheat Atta 10kg"},
        {"field_name": "brand_name", "verified_value": "Shakti Foods"},
        {"field_name": "net_quantity", "verified_value": "10", "canonical_unit": "KG"},
        {"field_name": "mrp", "verified_value": "₹460.00"},  # Price increased ₹420 -> ₹460
        {"field_name": "barcode", "verified_value": "8901122334455"},
        {"field_name": "manufacturer_name", "verified_value": "Shakti Agro Mills Ltd."}
    ]

    detail2 = await product_intelligence_service.identify_and_link_product(ins2, declarations2)
    assert detail2["product"]["id"] == prod_id
    assert len(detail2["label_versions"]) == 2
    assert detail2["product"]["active_version"] == "v2.0"
    assert len(detail2["inspection_history"]) == 2

    # 7. Verify version comparison detects the MRP change
    diff2 = await product_intelligence_service.compare_versions(prod_id)
    assert diff2["has_multiple_versions"] is True
    mrp_item = next((d for d in diff2["diff_matrix"] if d["parameter"] == "Declared MRP"), None)
    assert mrp_item is not None
    assert mrp_item["status"] == "CHANGED"
    assert "420" in mrp_item["previous_value"]
    assert "460" in mrp_item["current_value"]
