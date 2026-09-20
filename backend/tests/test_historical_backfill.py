import pytest
from app.repositories import get_repository
from app.services.product.product_intelligence_service import product_intelligence_service
from app.services.fingerprint.fingerprint_service import fingerprint_service

@pytest.mark.asyncio
async def test_historical_inspections_backfill_end_to_end():
    """
    Test that historical inspections (created prior to product intelligence linking)
    are successfully reconciled and backfilled into Product Intelligence.
    """
    repo = get_repository()

    # 1. Create historical inspections simulating older inspections with product_id = None
    # Inspection A1: Conducted on 2025-11-10 for "Everest Cumin Seeds 100g"
    ins_old_1 = await repo.create({
        "id": "ins-hist-001",
        "inspection_code": "INS-2025-HIST-001",
        "inspector_id": "u-insp-1",
        "product_id": None,
        "inspection_type": "PHYSICAL",
        "inspection_date": "2025-11-10T09:30:00Z",
        "location": "Old Delhi Spice Market",
        "seller_name": "Delhi Spice Traders",
        "business_name": "Spice Bazar",
        "status": "FINALIZED",
        "score": 98.0,
        "declarations": [
            {"field_name": "commodity_name", "verified_value": "Everest Cumin Seeds 100g", "source_text": "Cumin Seeds"},
            {"field_name": "brand_name", "verified_value": "Everest", "source_text": "Everest"},
            {"field_name": "net_quantity", "verified_value": "100", "canonical_unit": "G"},
            {"field_name": "mrp", "verified_value": "₹65.00"},
            {"field_name": "barcode", "verified_value": "8901234111222"},
            {"field_name": "manufacturer_name", "verified_value": "Everest Food Products Pvt Ltd"},
            {"field_name": "country_of_origin", "verified_value": "India"}
        ],
        "images": [
            {"id": "img-hist-01", "surface_type": "FRONT", "original_path": "/storage/sample_cumin.jpg"}
        ],
        "checks": [
            {"id": "chk-h1", "field_name": "mrp", "result": "PASS", "explanation": "Rule 6 compliant"}
        ],
        "violations": []
    })

    # Inspection A2: Conducted 3 months later (2026-02-15) on the SAME product with a price revision (MRP ₹75)
    ins_old_2 = await repo.create({
        "id": "ins-hist-002",
        "inspection_code": "INS-2026-HIST-002",
        "inspector_id": "u-insp-2",
        "product_id": None,
        "inspection_type": "PHYSICAL",
        "inspection_date": "2026-02-15T14:15:00Z",
        "location": "Modern Bazaar, Vasant Vihar, New Delhi",
        "seller_name": "Modern Retail Ltd",
        "status": "FINALIZED",
        "score": 94.0,
        "declarations": [
            {"field_name": "commodity_name", "verified_value": "Everest Cumin Seeds 100g"},
            {"field_name": "brand_name", "verified_value": "Everest"},
            {"field_name": "net_quantity", "verified_value": "100", "canonical_unit": "G"},
            {"field_name": "mrp", "verified_value": "₹75.00"},  # Price increased from ₹65 to ₹75
            {"field_name": "barcode", "verified_value": "8901234111222"},
            {"field_name": "manufacturer_name", "verified_value": "Everest Food Products Pvt Ltd"}
        ],
        "images": [
            {"id": "img-hist-02", "surface_type": "FRONT", "original_path": "/storage/sample_cumin_v2.jpg"}
        ],
        "checks": [],
        "violations": []
    })

    # Inspection B: Conducted for an incomplete historical record (missing barcode and manufacturer)
    ins_old_sparse = await repo.create({
        "id": "ins-hist-sparse",
        "inspection_code": "INS-2025-HIST-SPARSE",
        "inspector_id": "u-insp-1",
        "product_id": None,
        "inspection_type": "PHYSICAL",
        "inspection_date": "2025-10-01T10:00:00Z",
        "location": "Local Kirana Store",
        "seller_name": "Kirana General Store",
        "status": "FINALIZED",
        "score": 85.0,
        "declarations": [
            {"field_name": "commodity_name", "verified_value": "Desi Mustard Oil 1L"},
            {"field_name": "brand_name", "verified_value": "Desi Gold"}
        ],
        "images": []
    })

    # 2. Run the historical backfill
    backfill_report = await product_intelligence_service.backfill_historical_inspections()
    assert backfill_report["success"] is True
    assert backfill_report["inspections_linked"] >= 3

    # 3. Requirement 1: Verify inspection records are NOT modified/deleted except linking product_id
    rec1 = await repo.get_by_id("ins-hist-001")
    assert rec1 is not None
    assert rec1["inspection_code"] == "INS-2025-HIST-001"
    assert rec1["status"] == "FINALIZED"
    assert rec1["score"] == 98.0
    assert rec1["location"] == "Old Delhi Spice Market"
    assert rec1["seller_name"] == "Delhi Spice Traders"
    assert rec1["product_id"] is not None
    everest_prod_id = rec1["product_id"]

    rec2 = await repo.get_by_id("ins-hist-002")
    assert rec2 is not None
    assert rec2["inspection_code"] == "INS-2026-HIST-002"
    assert rec2["score"] == 94.0

    # 4. Requirement 2 & 4: Verify entity resolution linked both inspections to the SAME product without duplication
    assert rec2["product_id"] == everest_prod_id

    # 5. Requirement 3: Build product identity from historical declarations
    prod_detail = await product_intelligence_service.get_product_detail(everest_prod_id)
    assert prod_detail is not None
    assert prod_detail["product"]["name"] == "Everest Cumin Seeds 100g"
    assert prod_detail["product"]["brand"] == "Everest"
    assert prod_detail["product"]["barcode"] == "8901234111222"
    assert prod_detail["product"]["manufacturer_name"] == "Everest Food Products Pvt Ltd"

    # 6. Requirement 5: Verify chronological label version timeline
    # Inspection 1 (2025-11-10) was v1.0 (MRP ₹65)
    # Inspection 2 (2026-02-15) was v2.0 (MRP ₹75)
    lvs = prod_detail["label_versions"]
    assert len(lvs) == 2
    # label_versions are sorted newest first for the inspection timeline
    assert lvs[0]["label_version"] == "v2.0"
    assert "75" in str(lvs[0]["mrp"])
    assert lvs[0]["source_inspection_id"] == "ins-hist-002"

    assert lvs[1]["label_version"] == "v1.0"
    assert "65" in str(lvs[1]["mrp"])
    assert lvs[1]["source_inspection_id"] == "ins-hist-001"

    # 7. Verify version comparison reflects real difference between the two historical inspections
    diff = await product_intelligence_service.compare_versions(everest_prod_id)
    assert diff["has_multiple_versions"] is True
    mrp_diff = next((d for d in diff["diff_matrix"] if d["parameter"] == "Declared MRP"), None)
    assert mrp_diff is not None
    assert mrp_diff["status"] == "CHANGED"
    assert "65" in mrp_diff["previous_value"]
    assert "75" in mrp_diff["current_value"]

    # 8. Requirement 5 & 6: Historical product with sparse data does NOT fabricate fake fields
    rec_sparse = await repo.get_by_id("ins-hist-sparse")
    assert rec_sparse["product_id"] is not None
    sparse_prod_id = rec_sparse["product_id"]
    sparse_detail = await product_intelligence_service.get_product_detail(sparse_prod_id)
    assert sparse_detail is not None
    assert sparse_detail["product"]["name"] == "Desi Mustard Oil 1L"
    assert sparse_detail["product"]["barcode"] in [None, "Not available"]
    assert sparse_detail["product"]["manufacturer_name"] in [None, "Not captured", "Not available"]

    # 9. Requirement 8: Safe, idempotent, and repeatable backfill
    # Running backfill a second time must produce 0 duplicate products and 0 new versions
    prods_count_1 = len(await repo.list_products())
    second_backfill = await product_intelligence_service.backfill_historical_inspections()
    prods_count_2 = len(await repo.list_products())
    assert prods_count_1 == prods_count_2
    assert second_backfill["products_created"] == 0
    assert second_backfill["inspections_linked"] == 0
    assert second_backfill["already_linked"] >= 3

    # 10. Requirement 9: Verify historical product appears in registry listing alongside modern inspections
    registry = await product_intelligence_service.get_product_registry(search_query="Everest")
    assert len(registry) >= 1
    found_everest = next((p for p in registry if p["id"] == everest_prod_id), None)
    assert found_everest is not None
    assert found_everest["name"] == "Everest Cumin Seeds 100g"
    assert found_everest["inspection_count"] == 2
    assert found_everest["last_inspection_code"] == "INS-2026-HIST-002"
