"""
LM-TRACE — Historical Product Intelligence Backfill & Migration Script

This script safely and idempotently processes historical inspection records stored in the database,
extracts real product declarations, establishes canonical product identities, generates SHA-256 fingerprints,
and links historical inspections to chronological label versions in Product Intelligence.

Usage:
    python -m scripts.backfill_product_intelligence
    or
    python backend/scripts/backfill_product_intelligence.py
"""

import sys
import os
import asyncio

# Ensure backend root is on sys.path
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from app.core.logging import setup_logging, logger
from app.services.product.product_intelligence_service import product_intelligence_service

async def run_backfill():
    setup_logging()
    logger.info("Starting LM-TRACE Historical Product Intelligence Backfill...")
    result = await product_intelligence_service.backfill_historical_inspections()
    
    print("\n=======================================================")
    print("LM-TRACE HISTORICAL PRODUCT INTELLIGENCE BACKFILL RESULT")
    print("=======================================================")
    print(f"Total Inspections Evaluated : {result.get('total_inspections', 0)}")
    print(f"Newly Linked to Products    : {result.get('inspections_linked', 0)}")
    print(f"Already Linked Inspections  : {result.get('already_linked', 0)}")
    print(f"New Products Created        : {result.get('products_created', 0)}")
    print(f"Label Versions Recorded     : {result.get('label_versions_recorded', 0)}")
    print(f"Skipped (Insufficient Data) : {result.get('skipped_insufficient_data', 0)}")
    print("=======================================================\n")
    
    details = result.get("details", [])
    if details:
        print("Sample Processed Records:")
        for item in details[:10]:
            print(f"  - Case {item.get('inspection_code')}: Status={item.get('status')}, ProductID={item.get('product_id')}")
        if len(details) > 10:
            print(f"  ... and {len(details) - 10} more records.")
    print("\nBackfill successfully finished.\n")

if __name__ == "__main__":
    asyncio.run(run_backfill())
