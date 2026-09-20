from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Dict, Any, List, Optional
from app.repositories import get_repository
from app.core.security import get_current_user_payload
from app.services.label_change.label_change_service import label_change_service
from app.services.product.product_intelligence_service import product_intelligence_service

router = APIRouter(prefix="/api/products", tags=["Product Intelligence & Registry"])

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

@router.post("/sync", response_model=Dict[str, Any])
async def sync_inspections(user_payload: dict = Depends(get_current_user_payload)):
    """
    Reconciles all unlinked inspection cases in the database, automatically extracting
    product identities and linking them to the Product Intelligence Registry.
    """
    synced = await product_intelligence_service.sync_unlinked_inspections()
    return {"success": True, "synced_inspections_count": synced}

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
