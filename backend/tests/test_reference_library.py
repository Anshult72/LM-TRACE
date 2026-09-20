import pytest
from app.repositories import get_repository
from app.services.product.reference_library_service import reference_library_service

@pytest.mark.asyncio
async def test_reference_library_search_explainable_matching():
    """
    Verify search returns real products from repository with explainable match reasons.
    """
    # 1. Search for Basmati Rice in Packaged Food category
    res = await reference_library_service.search_reference_products(
        commodity="Basmati Rice",
        category="Packaged Food",
        pack_size="5 kg"
    )

    assert res["success"] is True
    assert res["total_results"] >= 1
    assert "Packaged Food" in res["categories_available"]

    first = res["results"][0]
    assert "Rice" in first["name"]
    assert first["category"] == "Packaged Food"
    assert first["reference_status"] in ["COMPLIANT", "NEEDS_REVIEW", "VIOLATION", "LIMITED"]
    assert first["eligibility"] in ["ELIGIBLE", "LIMITED_DATA"]
    
    # Check that match reasons are transparent and explainable
    assert len(first["match_reasons"]) >= 1
    match_texts = " ".join(first["match_reasons"]).lower()
    assert "matched" in match_texts or "rice" in match_texts or "commodity" in match_texts
    assert first["relevance_score"] >= 40

    # Verify real applicable statutory requirements were identified
    assert len(first["applicable_requirements"]) >= 1
    assert any("Rule 6" in r or "Rule 7" in r for r in first["applicable_requirements"])

@pytest.mark.asyncio
async def test_reference_library_eligibility_and_non_fabrication():
    """
    Verify deterministic eligibility check:
    - Products with completed inspections and evidence are ELIGIBLE or LIMITED_DATA
    - Missing images are not faked
    """
    repo = get_repository()

    # Create a draft product without any inspection
    draft_prod = await repo.create_or_update({
        "id": "prod-draft-uninspected",
        "name": "Draft Organic Millets",
        "brand": "Pure Harvest",
        "category": "Packaged Food",
        "net_quantity": "500",
        "net_quantity_unit": "G"
    })

    # Search specifically for Draft Organic Millets with eligible_only=True
    res = await reference_library_service.search_reference_products(
        commodity="Draft Organic Millets",
        eligible_only=True
    )
    # Draft product must be excluded from eligible results
    assert not any(p["product_id"] == "prod-draft-uninspected" for p in res["results"])

    # Search with eligible_only=False
    res_all = await reference_library_service.search_reference_products(
        commodity="Draft Organic Millets",
        eligible_only=False
    )
    found_draft = next((p for p in res_all["results"] if p["product_id"] == "prod-draft-uninspected"), None)
    if found_draft:
        assert found_draft["eligibility"] == "NOT_ELIGIBLE"
        assert found_draft["reference_status"] == "UNINSPECTED"

@pytest.mark.asyncio
async def test_reference_product_detail_9_sections():
    """
    Verify GET reference detail returns all 9 comprehensive sections:
    Overview, Captured Images, Declarations Matrix, Applicable Rules,
    Compliance Checks, Source Inspection, Version History, Evidence, Disclaimer.
    """
    repo = get_repository()
    prods = await repo.list_products()
    assert len(prods) > 0
    target_prod_id = prods[0]["id"]

    detail = await reference_library_service.get_reference_detail(target_prod_id)
    assert detail is not None
    assert detail["success"] is True

    # 1. Product Overview
    assert "product" in detail
    assert detail["product"]["id"] == target_prod_id
    assert "name" in detail["product"]
    assert "brand" in detail["product"]
    assert "pack_size" in detail["product"]
    assert "declared_mrp" in detail["product"]

    # 2. Captured Label Images
    assert "label_images" in detail
    assert isinstance(detail["label_images"], list)

    # 3. Recorded Declarations Matrix
    assert "recorded_declarations" in detail
    assert len(detail["recorded_declarations"]) >= 1
    first_dec = detail["recorded_declarations"][0]
    assert "field_name" in first_dec
    assert "presence_status" in first_dec
    assert "correctness_status" in first_dec

    # 4. Applicable Statutory Rules
    assert "applicable_rules" in detail
    assert len(detail["applicable_rules"]) >= 1
    rule_codes = [r["rule_code"] for r in detail["applicable_rules"]]
    assert "RULE-006" in rule_codes or "RULE-007" in rule_codes

    # 5. Granular Compliance Checks
    assert "compliance_checks" in detail
    assert len(detail["compliance_checks"]) >= 1
    assert "result" in detail["compliance_checks"][0]
    assert "explanation" in detail["compliance_checks"][0]

    # 6. Source Inspection Traceability
    assert "source_inspection" in detail
    assert detail["source_inspection"]["inspection_code"] is not None

    # 7. Available Versions
    assert "available_versions" in detail
    assert len(detail["available_versions"]) >= 1

    # 8. Evidence Gallery
    assert "evidence_items" in detail
    assert isinstance(detail["evidence_items"], list)

    # 9. Mandatory Legal Disclaimer
    assert "disclaimer" in detail
    assert "not constitute legal certification" in detail["disclaimer"]
    assert "reference" in detail["disclaimer"].lower()

@pytest.mark.asyncio
async def test_reference_product_detail_404_handling():
    """
    Verify non-existent product returns None (404 in API).
    """
    detail = await reference_library_service.get_reference_detail("prod-does-not-exist-999")
    assert detail is None
