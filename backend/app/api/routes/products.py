from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Dict, Any, List, Optional
from app.repositories import get_repository
from app.core.security import get_current_user_payload
from app.services.label_change.label_change_service import label_change_service
from app.services.product.product_intelligence_service import product_intelligence_service
from app.services.analytics.compliance_analytics import classify_inspection

router = APIRouter(prefix="/api/products", tags=["Product Intelligence & Registry"])


@router.get("/registry/summary", response_model=Dict[str, Any])
async def get_registry_summary(user_payload: dict = Depends(get_current_user_payload)):
    """Operational coverage of the persisted scanned-product repository."""
    repo = get_repository()
    products = await repo.list_products()
    inspections = await repo.list_inspections()
    linked = [item for item in inspections if item.get("product_id")]
    products_with_history = 0
    label_version_count = 0
    for product in products:
        versions = await repo.get_label_versions(product.get("id"))
        label_version_count += len(versions)
        if len(await repo.get_inspections_for_product(product.get("id"))) > 1:
            products_with_history += 1
    outcomes: Dict[str, int] = {}
    for item in linked:
        value = classify_inspection(item)["outcome"]
        outcomes[value] = outcomes.get(value, 0) + 1
    return {
        "product_count": len(products),
        "inspection_count": len(inspections),
        "linked_inspection_count": len(linked),
        "unlinked_inspection_count": len(inspections) - len(linked),
        "products_with_repeat_history": products_with_history,
        "label_version_count": label_version_count,
        "compliance_outcomes": outcomes,
    }

@router.get("", response_model=List[Dict[str, Any]])
async def list_products(
    query: Optional[str] = Query(None, description="Search by product name, brand, commodity, GTIN barcode, or ID"),
    category: Optional[str] = Query(None, description="Filter by product category"),
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Returns the real Product Registry backed by database inspection records.
    Each item includes active label version, fingerprint status, last inspection date,
    and current compliance status.
    """
    return await product_intelligence_service.get_product_registry(
        search_query=query,
        category_filter=category
    )

@router.post("/backfill", response_model=Dict[str, Any])
@router.post("/sync", response_model=Dict[str, Any])
async def backfill_historical_products(user_payload: dict = Depends(get_current_user_payload)):
    """
    Backfill / Migration endpoint for historical inspection data:
    Scans all historical inspection records in the database, extracts actual product declarations,
    establishes canonical product identities, generates fingerprints without fabrication,
    links historical inspections, builds chronological label version progression, and returns detailed metrics.
    Safe, idempotent, and repeatable.
    """
    res = await product_intelligence_service.backfill_historical_inspections()
    res["synced_inspections_count"] = res.get("inspections_linked", 0)
    return res

@router.get("/{product_id}", response_model=Dict[str, Any])
async def get_product(
    product_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Returns full Product Intelligence detail view:
    Overview, Identity, Fingerprint, Current Version, Label History, Inspection History,
    Compliance History, and Evidence References.
    """
    detail = await product_intelligence_service.get_product_detail(product_id)
    if not detail:
        raise HTTPException(status_code=404, detail=f"Product '{product_id}' not found in registry.")
    return detail

@router.get("/{product_id}/history")
async def get_product_history(
    product_id: str,
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Detailed history endpoint for product detail screens, including version timeline,
    inspection history, compliance history, and evidence.
    """
    detail = await product_intelligence_service.get_product_detail(product_id)
    if not detail:
        raise HTTPException(status_code=404, detail=f"Product '{product_id}' not found in registry.")
    return detail


@router.get("/{product_id}/timeline", response_model=Dict[str, Any])
async def get_product_timeline(product_id: str, user_payload: dict = Depends(get_current_user_payload)):
    """Chronological, evidence-linked history for enforcement and audit review."""
    detail = await product_intelligence_service.get_product_detail(product_id)
    if not detail:
        raise HTTPException(status_code=404, detail=f"Product '{product_id}' not found in registry.")
    events = []
    for item in detail.get("inspection_history", []):
        events.append({"event_type": "INSPECTION", "date": item.get("inspection_date"), **item})
    for item in detail.get("label_versions", []):
        events.append({"event_type": "LABEL_VERSION", "date": item.get("effective_from"), **item})
    for item in detail.get("compliance_history", []):
        events.append({"event_type": "COMPLIANCE_OUTCOME", **item})
    events.sort(key=lambda item: str(item.get("date") or ""), reverse=True)
    evidence = detail.get("evidence", [])
    return {
        "product_id": product_id,
        "event_count": len(events),
        "events": events,
        "evidence_count": len(evidence),
        "evidence_with_sha256": sum(1 for item in evidence if item.get("sha256")),
        "evidence": evidence,
    }

@router.get("/{product_id}/diff")
async def get_version_diff(
    product_id: str,
    v1: Optional[str] = Query(None, description="Older label version ID"),
    v2: Optional[str] = Query(None, description="Newer label version ID"),
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Compares two recorded label versions for this product.
    If only 1 version exists, returns baseline information without fabricating differences.
    """
    return await product_intelligence_service.compare_versions(product_id, v1, v2)

@router.post("/{product_id}/label-compare")
async def compare_label_versions(
    product_id: str,
    req: Dict[str, Any],
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Backwards-compatible legacy comparison endpoint for direct parameter diffing.
    """
    current_mrp = req.get("current_mrp", "₹449")
    current_qty = req.get("current_quantity", "5 KG")
    summary = req.get("ocr_summary", "Updated packaging 2026")

    comparison = await label_change_service.compare_with_previous_version(
        product_id=product_id,
        current_mrp=current_mrp,
        current_quantity=current_qty,
        current_ocr_summary=summary
    )
    return comparison.model_dump()
