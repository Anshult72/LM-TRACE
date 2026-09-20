from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Dict, Any, Optional
from app.core.security import get_current_user_payload
from app.services.product.reference_library_service import reference_library_service

router = APIRouter(prefix="/api/reference-library", tags=["Compliance Reference Library"])

@router.get("/search", response_model=Dict[str, Any])
async def search_reference_products(
    commodity: Optional[str] = Query(None, description="Commodity or product name, e.g. 'Wheat Flour'"),
    category: Optional[str] = Query(None, description="Product category filter, e.g. 'Packaged Food'"),
    pack_size: Optional[str] = Query(None, description="Pack size or declared quantity, e.g. '500 g'"),
    brand: Optional[str] = Query(None, description="Brand name filter"),
    status: Optional[str] = Query("ALL", description="Status filter: ALL, COMPLIANT, NEEDS_REVIEW, ELIGIBLE_ONLY"),
    sort_by: Optional[str] = Query("relevance", description="Sorting option: relevance, recent, completeness"),
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Search previously inspected products and their recorded compliance data to serve as statutory reference examples.
    Provides explainable match reasons, actual evidence thumbnails, and evaluated Legal Metrology rules.
    """
    return await reference_library_service.search_reference_products(
        commodity=commodity,
        category=category,
        pack_size=pack_size,
        brand=brand,
        status_filter=status,
        sort_by=sort_by
    )

@router.get("/{product_id}", response_model=Dict[str, Any])
async def get_reference_product_detail(
    product_id: str,
    version: Optional[str] = Query(None, description="Specific label version to inspect, e.g. 'v1.0'"),
    user_payload: dict = Depends(get_current_user_payload)
):
    """
    Returns complete 9-section compliance reference detail for a product:
    - Product Overview
    - Real Captured Label Images
    - Recorded Declarations Matrix with presence & correctness
    - Applicable Statutory Rules evaluated from Rule Engine
    - Granular Compliance Checks & Observations
    - Source Inspection Traceability
    - Label Version Context & Evidence Gallery
    - Mandatory Legal Non-Guarantee Disclaimer
    """
    detail = await reference_library_service.get_reference_detail(
        product_id=product_id,
        version_id=version
    )
    if not detail:
        raise HTTPException(status_code=404, detail=f"Reference product '{product_id}' not found in registry.")
    return detail
