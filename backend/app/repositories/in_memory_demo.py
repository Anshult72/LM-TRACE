from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
import copy
from app.core.security import get_password_hash
from app.core.statutory_registry import (
    OFFICIAL_STATUTORY_DOCUMENTS,
    OFFICIAL_STATUTORY_RULES,
    STATUTORY_FAMILIES,
    get_statutory_summary,
    list_statutory_documents,
    get_statutory_document_by_id,
    list_statutory_rules,
    get_statutory_rule_by_id,
    get_statutory_families,
    get_statutory_traceability,
)
from app.repositories.interfaces import (
    IUserRepository, IProductRepository, IInspectionRepository,
    IRuleRepository, IReportRepository, IAuditLogRepository
)

def get_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()

class DemoInMemoryRepository(
    IUserRepository, IProductRepository, IInspectionRepository,
    IRuleRepository, IReportRepository, IAuditLogRepository
):
    def __init__(self):
        self._seed_data()

    def _seed_data(self):
        # 1. Users
        pwd_inspector = get_password_hash("Inspector@123")
        pwd_supervisor = get_password_hash("Supervisor@123")
        pwd_admin = get_password_hash("Admin@123")

        self.users: Dict[str, Dict[str, Any]] = {
            "u-insp-1": {
                "id": "u-insp-1",
                "email": "inspector@demo.gov.in",
                "full_name": "Ramesh Verma",
                "officer_id": "LM-UP-2026-042",
                "department": "Legal Metrology Department, Lucknow",
                "hashed_password": pwd_inspector,
                "role": "INSPECTOR",
                "active": True,
                "created_at": get_now_iso()
            },
            "u-sup-1": {
                "id": "u-sup-1",
                "email": "supervisor@demo.gov.in",
                "full_name": "Sunita Sharma",
                "officer_id": "LM-UP-SUP-012",
                "department": "Legal Metrology Headquarters, Lucknow",
                "hashed_password": pwd_supervisor,
                "role": "SUPERVISOR",
                "active": True,
                "created_at": get_now_iso()
            },
            "u-admin-1": {
                "id": "u-admin-1",
                "email": "admin@demo.gov.in",
                "full_name": "Rajesh Gupta",
                "officer_id": "LM-HQ-ADM-001",
                "department": "Directorate of Legal Metrology, New Delhi",
                "hashed_password": pwd_admin,
                "role": "ADMIN",
                "active": True,
                "created_at": get_now_iso()
            }
        }

        # 2. Products
        self.products: Dict[str, Dict[str, Any]] = {
            "prod-rice-01": {
                "id": "prod-rice-01",
                "name": "ABC Premium Basmati Rice",
                "brand": "ABC Heritage",
                "category": "Packaged Food",
                "manufacturer_name": "ABC Agro Foods Ltd.",
                "manufacturer_address": "Plot 42, Food Industrial Estate, Karnal, Haryana - 132001",
                "packer_name": "ABC Agro Foods Ltd.",
                "packer_address": "Plot 42, Food Industrial Estate, Karnal, Haryana - 132001",
                "importer_name": None,
                "importer_address": None,
                "net_quantity": "5",
                "net_quantity_unit": "KG",
                "barcode": "8901234567890",
                "country_of_origin": "India",
                "product_identity_fingerprint": "a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6",
                "created_at": "2026-08-15T10:00:00Z",
                "updated_at": "2026-08-15T10:00:00Z"
            },
            "prod-shampoo-02": {
                "id": "prod-shampoo-02",
                "name": "XYZ Herbal Shampoo 200 ml",
                "brand": "XYZ Naturals",
                "category": "Cosmetic / Personal Care",
                "manufacturer_name": "XYZ Organics Care Pvt. Ltd.",
                "manufacturer_address": "Sector 3, SIDCUL Industrial Area, Haridwar, Uttarakhand - 249403",
                "packer_name": "XYZ Organics Care Pvt. Ltd.",
                "packer_address": "Sector 3, SIDCUL Industrial Area, Haridwar, Uttarakhand - 249403",
                "importer_name": None,
                "importer_address": None,
                "net_quantity": "200",
                "net_quantity_unit": "ML",
                "barcode": "8909876543210",
                "country_of_origin": "India",
                "product_identity_fingerprint": "b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3",
                "created_at": "2026-08-20T11:30:00Z",
                "updated_at": "2026-08-20T11:30:00Z"
            },
            "prod-serum-03": {
                "id": "prod-serum-03",
                "name": "Luxe Parisian Glow Serum 50 ml",
                "brand": "Luxe Paris",
                "category": "Imported Cosmetic",
                "manufacturer_name": "Laboratoires Paris Beaute S.A.",
                "manufacturer_address": "15 Rue de la Paix, 75002 Paris, France",
                "packer_name": None,
                "packer_address": None,
                "importer_name": "Luxe India Cosmetics Impex Ltd.",
                "importer_address": "Incomplete address on packaging",  # Deliberate finding
                "net_quantity": "50",
                "net_quantity_unit": "ML",
                "barcode": "3600523456781",
                "country_of_origin": "France",
                "product_identity_fingerprint": "c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4",
                "created_at": "2026-08-25T14:15:00Z",
                "updated_at": "2026-08-25T14:15:00Z"
            }
        }

        # 3. Label Versions
        self.label_versions: List[Dict[str, Any]] = [
            {
                "id": "lbl-rice-v1",
                "product_id": "prod-rice-01",
                "inspection_id": "ins-demo-001",
                "label_version": "v1.0-2025",
                "visual_hash": "phash_99a12b3c4d5e",
                "ocr_summary": "ABC Premium Basmati Rice 5kg MRP Rs 399",
                "mrp": "₹399",
                "net_quantity": "5 KG",
                "captured_at": "2025-11-10T09:00:00Z"
            },
            {
                "id": "lbl-rice-v2",
                "product_id": "prod-rice-01",
                "inspection_id": "ins-demo-004",
                "label_version": "v2.0-2026",
                "visual_hash": "phash_88b13c4d5e6f",
                "ocr_summary": "ABC Premium Basmati Rice 5kg MRP Rs 449",
                "mrp": "₹449",
                "net_quantity": "5 KG",
                "captured_at": "2026-09-01T10:00:00Z"
            }
        ]

        # 4. Rules & Rule Versions
        self.rules: Dict[str, Dict[str, Any]] = {
            "RULE-006": {
                "id": "rule-6",
                "code": "RULE-006",
                "title": "Mandatory Declarations on Pre-Packaged Commodities",
                "description": "Rule 6 of the Legal Metrology (Packaged Commodities) Rules, 2011 mandates specific declarations including name, quantity, MRP, manufacturer details, dates, and consumer care.",
                "category": "MANDATORY_DECLARATIONS",
                "active": True,
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z",
                "versions": [
                    {
                        "id": "ver-rule-6-2024",
                        "rule_id": "rule-6",
                        "version": "2024.1",
                        "description": "Statutory requirements under Legal Metrology (Packaged Commodities) Rules, 2011 (as amended).",
                        "conditions": {
                            "conditionGroup": "ALL",
                            "conditions": [
                                {"field": "isCommodityPackaged", "operator": "EQUALS", "value": True}
                            ]
                        },
                        "thresholds": {
                            "mandatoryFields": [
                                "commodity_name", "net_quantity", "mrp",
                                "manufacturer_packer_importer", "manufacturing_packing_date",
                                "consumer_care"
                            ],
                            "conditionalFields": {
                                "country_of_origin": {"field": "isImported", "operator": "EQUALS", "value": True},
                                "best_before": {"field": "bestBeforeApplicable", "operator": "EQUALS", "value": True},
                                "dimensions": {"field": "dimensionsRelevant", "operator": "EQUALS", "value": True}
                            }
                        },
                        "severity": "POTENTIAL_VIOLATION",
                        "source_name": "Ministry of Consumer Affairs, Food and Public Distribution",
                        "source_reference": "Legal Metrology (Packaged Commodities) Rules, 2011, Rule 6",
                        "source_url": "https://consumeraffairs.nic.in",
                        "effective_from": "2011-03-01T00:00:00Z",
                        "effective_to": None,
                        "is_demo_rule": False,
                        "created_at": "2024-01-01T00:00:00Z"
                    }
                ]
            },
            "RULE-007": {
                "id": "rule-7",
                "code": "RULE-007",
                "title": "Principal Display Panel Area & Character/Numeral Height (Table-I)",
                "description": "Rule 7 Table-I mandates minimum character and numeral heights based on the Area of Principal Display Panel (PDP) and packaging construction type.",
                "category": "FONT_SIZE_AND_PROPORTIONS",
                "active": True,
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z",
                "versions": [
                    {
                        "id": "ver-rule-7-2024",
                        "rule_id": "rule-7",
                        "version": "2024.1",
                        "description": "Table-I height standards and 1/3 width proportion check.",
                        "conditions": {
                            "conditionGroup": "ALL",
                            "conditions": [
                                {"field": "calibrationStatus", "operator": "EQUALS", "value": "CALIBRATED"}
                            ]
                        },
                        "thresholds": {
                            "table1": [
                                {"range": "A_LE_50", "max_area": 50.0, "normal_min_mm": 1.0, "blown_min_mm": 2.0},
                                {"range": "50_LT_A_LE_100", "min_area": 50.0, "max_area": 100.0, "normal_min_mm": 1.5, "blown_min_mm": 3.0},
                                {"range": "100_LT_A_LE_500", "min_area": 100.0, "max_area": 500.0, "normal_min_mm": 2.5, "blown_min_mm": 4.0},
                                {"range": "500_LT_A_LE_2500", "min_area": 500.0, "max_area": 2500.0, "normal_min_mm": 4.0, "blown_min_mm": 6.0},
                                {"range": "GT_2500", "min_area": 2500.0, "normal_min_mm": 6.0, "blown_min_mm": 6.0}
                            ],
                            "character_proportion": {
                                "min_width_to_height_ratio": 0.333,
                                "exempt_characters": ["1", "i", "I", "l"]
                            }
                        },
                        "severity": "POTENTIAL_VIOLATION",
                        "source_name": "Ministry of Consumer Affairs, Food and Public Distribution",
                        "source_reference": "Legal Metrology (Packaged Commodities) Rules, 2011, Rule 7 (Table-I)",
                        "source_url": "https://consumeraffairs.nic.in",
                        "effective_from": "2011-03-01T00:00:00Z",
                        "effective_to": None,
                        "is_demo_rule": False,
                        "created_at": "2024-01-01T00:00:00Z"
                    }
                ]
            },
            "RULE-009": {
                "id": "rule-9",
                "code": "RULE-009",
                "title": "Manner of Declaration: Legibility and Prominence",
                "description": "Rule 9 requires declarations to be legible, prominent, conspicuous, and clearly readable with adequate contrast against package background.",
                "category": "LEGIBILITY",
                "active": True,
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z",
                "versions": [
                    {
                        "id": "ver-rule-9-2024",
                        "rule_id": "rule-9",
                        "version": "2024.1",
                        "description": "Computer Vision legibility and text-background contrast evaluation.",
                        "conditions": {
                            "conditionGroup": "ALL",
                            "conditions": [
                                {"field": "isCommodityPackaged", "operator": "EQUALS", "value": True}
                            ]
                        },
                        "thresholds": {
                            "min_contrast_ratio": 0.45,
                            "min_sharpness_score": 0.50,
                            "max_blur_threshold": 100.0
                        },
                        "severity": "REVIEW",
                        "source_name": "Ministry of Consumer Affairs, Food and Public Distribution",
                        "source_reference": "Legal Metrology (Packaged Commodities) Rules, 2011, Rule 9",
                        "source_url": "https://consumeraffairs.nic.in",
                        "effective_from": "2011-03-01T00:00:00Z",
                        "effective_to": None,
                        "is_demo_rule": False,
                        "created_at": "2024-01-01T00:00:00Z"
                    }
                ]
            },
            "RULE-ECOM-2026": {
                "id": "rule-ecom",
                "code": "RULE-ECOM-2026",
                "title": "E-Commerce Country-of-Origin & Mandatory Declarations (Amended 2026)",
                "description": "Requires e-commerce marketplaces and digital listings to display mandatory declarations including origin filter. Effective from 1 July 2027.",
                "category": "E_COMMERCE",
                "active": True,
                "created_at": "2026-01-15T00:00:00Z",
                "updated_at": "2026-01-15T00:00:00Z",
                "versions": [
                    {
                        "id": "ver-rule-ecom-2027",
                        "rule_id": "rule-ecom",
                        "version": "2026.1",
                        "description": "Date-gated requirement: applies to digital listings on or after 2027-07-01.",
                        "conditions": {
                            "conditionGroup": "ALL",
                            "conditions": [
                                {"field": "isEcommerce", "operator": "EQUALS", "value": True},
                                {"field": "isImported", "operator": "EQUALS", "value": True},
                                {"field": "inspectionDate", "operator": "GREATER_THAN_OR_EQUAL", "value": "2027-07-01"}
                            ]
                        },
                        "thresholds": {
                            "mandatoryListingFields": ["country_of_origin", "mrp", "net_quantity", "manufacturer_importer"]
                        },
                        "severity": "POTENTIAL_VIOLATION",
                        "source_name": "Department of Consumer Affairs Notification G.S.R.",
                        "source_reference": "Consumer Protection (E-Commerce) Rules & LM Amendments 2026",
                        "source_url": "https://consumeraffairs.nic.in",
                        "effective_from": "2027-07-01T00:00:00Z",
                        "effective_to": None,
                        "is_demo_rule": False,
                        "created_at": "2026-01-15T00:00:00Z"
                    }
                ]
            },
            "DEMO-RULE-PROMO": {
                "id": "demo-rule-promo",
                "code": "DEMO-RULE-PROMO",
                "title": "Promotional Claim Text Size vs Statutory MRP Balance (DEMO RULE)",
                "description": "Simulated prototype guideline to verify promotional banner text does not visually overwhelm or obscure mandatory pricing declarations.",
                "category": "PRESENTATION",
                "active": True,
                "created_at": "2026-01-01T00:00:00Z",
                "updated_at": "2026-01-01T00:00:00Z",
                "versions": [
                    {
                        "id": "ver-demo-promo-v1",
                        "rule_id": "demo-rule-promo",
                        "version": "1.0",
                        "description": "Demo simulated rule checking promotional font prominence ratio.",
                        "conditions": {
                            "conditionGroup": "ALL",
                            "conditions": [
                                {"field": "hasPromotionalText", "operator": "EQUALS", "value": True}
                            ]
                        },
                        "thresholds": {"max_promo_to_mrp_height_ratio": 3.0},
                        "severity": "REVIEW",
                        "source_name": "MAANAK Research Demo Guideline",
                        "source_reference": "DEMO_RULE - Prototype Reference Only",
                        "source_url": None,
                        "effective_from": "2026-01-01T00:00:00Z",
                        "effective_to": None,
                        "is_demo_rule": True,
                        "created_at": "2026-01-01T00:00:00Z"
                    }
                ]
            }
        }

        # 5. Rule Coverage Registry
        self.rule_coverage: List[Dict[str, Any]] = [
            {
                "id": "cov-6",
                "rule_family": "Rule 6",
                "rule_codes": ["RULE-006"],
                "coverage_status": "FULLY_IMPLEMENTED",
                "supported_checks": ["Mandatory declaration presence", "Role-separated entity addresses", "Conditional origin & dates"],
                "limitations": "Prototype validates syntax and completeness; physical validation requires inspector sign-off.",
                "source_reference": "Legal Metrology (Packaged Commodities) Rules, 2011, Rule 6",
                "last_verified_at": "2026-08-01T00:00:00Z",
                "is_demo_rule": False
            },
            {
                "id": "cov-7",
                "rule_family": "Rule 7",
                "rule_codes": ["RULE-007"],
                "coverage_status": "FULLY_IMPLEMENTED",
                "supported_checks": ["Table-I PDP area thresholds", "1/3 width-to-height ratio", "Calibration-aware verification"],
                "limitations": "Requires valid 2-point scale calibration; uncalibrated images yield UNVERIFIED.",
                "source_reference": "Legal Metrology (Packaged Commodities) Rules, 2011, Rule 7",
                "last_verified_at": "2026-08-01T00:00:00Z",
                "is_demo_rule": False
            },
            {
                "id": "cov-8",
                "rule_family": "Rule 8",
                "rule_codes": ["RULE-008"],
                "coverage_status": "PARTIALLY_IMPLEMENTED",
                "supported_checks": ["Principal Display Panel placement vs rear surface placement"],
                "limitations": "Surface classification assisted by inspector-tagged images.",
                "source_reference": "Legal Metrology (Packaged Commodities) Rules, 2011, Rule 8",
                "last_verified_at": "2026-08-01T00:00:00Z",
                "is_demo_rule": False
            },
            {
                "id": "cov-9",
                "rule_family": "Rule 9",
                "rule_codes": ["RULE-009"],
                "coverage_status": "FULLY_IMPLEMENTED",
                "supported_checks": ["Visual contrast ratio", "Sharpness", "Laplacian blur detection"],
                "limitations": "Calculated via computer vision; serves as investigative indicator.",
                "source_reference": "Legal Metrology (Packaged Commodities) Rules, 2011, Rule 9",
                "last_verified_at": "2026-08-01T00:00:00Z",
                "is_demo_rule": False
            },
            {
                "id": "cov-10",
                "rule_family": "Rule 10",
                "rule_codes": ["RULE-010"],
                "coverage_status": "PARTIALLY_IMPLEMENTED",
                "supported_checks": ["Postal PIN code & city completeness indicators"],
                "limitations": "NLP indicators; postal directory cross-referencing not fully exhaustive.",
                "source_reference": "Legal Metrology (Packaged Commodities) Rules, 2011, Rule 10",
                "last_verified_at": "2026-08-01T00:00:00Z",
                "is_demo_rule": False
            },
            {
                "id": "cov-11-15",
                "rule_family": "Rules 11 to 15",
                "rule_codes": ["RULE-011", "RULE-012", "RULE-013"],
                "coverage_status": "PARTIALLY_IMPLEMENTED",
                "supported_checks": ["Canonical unit symbols (G, KG, ML, L) normalization"],
                "limitations": "Unit Sale Price evaluated where applicable; non-standard units flagged.",
                "source_reference": "Legal Metrology (Packaged Commodities) Rules, 2011, Rules 11-15",
                "last_verified_at": "2026-08-01T00:00:00Z",
                "is_demo_rule": False
            }
        ]

        # 5b. Statutory Documents & Rules
        self.legal_documents = {d["id"]: copy.deepcopy(d) for d in OFFICIAL_STATUTORY_DOCUMENTS}
        self.statutory_rules = {r["id"]: copy.deepcopy(r) for r in OFFICIAL_STATUTORY_RULES}
        self.statutory_families = copy.deepcopy(STATUTORY_FAMILIES)
        self.rule_amendments = {}
        self.rule_audit_logs = []

        # 6. Inspections
        self.inspections: Dict[str, Dict[str, Any]] = {
            "ins-demo-001": {
                "id": "ins-demo-001",
                "inspection_code": "INS-2026-00101",
                "inspector_id": "u-insp-1",
                "product_id": "prod-rice-01",
                "inspection_type": "PHYSICAL",
                "inspection_date": "2026-09-07T10:15:00Z",
                "location": "Maanak Supermarket, Sector 18, Noida, Uttar Pradesh",
                "seller_name": "Maanak Retail Stores Pvt Ltd",
                "business_name": "Maanak Retail Enterprise",
                "status": "FINALIZED",
                "score": 96.5,
                "package_type": "RECTANGULAR",
                "package_construction_type": "NORMAL",
                "calibration_status": "CALIBRATED",
                "calibration_data": {
                    "method": "KNOWN_DISTANCE",
                    "point1": {"x": 100, "y": 450},
                    "point2": {"x": 400, "y": 450},
                    "knownDistance": 150.0,
                    "pixelsPerMm": 2.0
                },
                "pdp_data": {"areaCm2": 320.0, "confidence": 0.94},
                "applied_rule_version": "2024.1",
                "rule_snapshot": {"rules_evaluated": ["RULE-006", "RULE-007", "RULE-009"]},
                "notes": "Compliant packaging inspection. All Rule 6 mandatory declarations verified on Principal Display Panel.",
                "created_at": "2026-09-07T10:15:00Z",
                "updated_at": "2026-09-07T10:45:00Z",
                "finalized_at": "2026-09-07T10:45:00Z",
                "images": [
                    {
                        "id": "img-001-front",
                        "inspection_id": "ins-demo-001",
                        "surface_type": "FRONT",
                        "original_path": "storage/inspections/demo/rice_front.jpg",
                        "thumbnail_path": "storage/inspections/demo/thumb_rice_front.jpg",
                        "width": 1200,
                        "height": 1600,
                        "quality_assessment": "GOOD",
                        "quality_score": 0.92,
                        "quality_details": {"blur_variance": 340.0, "contrast": 0.88, "sharpness": 0.91},
                        "created_at": "2026-09-07T10:16:00Z"
                    },
                    {
                        "id": "img-001-back",
                        "inspection_id": "ins-demo-001",
                        "surface_type": "BACK",
                        "original_path": "storage/inspections/demo/rice_back.jpg",
                        "thumbnail_path": "storage/inspections/demo/thumb_rice_back.jpg",
                        "width": 1200,
                        "height": 1600,
                        "quality_assessment": "GOOD",
                        "quality_score": 0.90,
                        "quality_details": {"blur_variance": 310.0, "contrast": 0.85, "sharpness": 0.89},
                        "created_at": "2026-09-07T10:17:00Z"
                    }
                ],
                "declarations": [
                    {
                        "id": "dec-001-1",
                        "inspection_id": "ins-demo-001",
                        "field_name": "commodity_name",
                        "ai_value": "ABC Premium Basmati Rice",
                        "verified_value": "ABC Premium Basmati Rice",
                        "unit": None,
                        "confidence": 0.99,
                        "source_image_id": "img-001-front",
                        "source_block_id": "blk-01",
                        "source_text": "ABC Premium Basmati Rice",
                        "bbox": {"x": 120, "y": 200, "width": 800, "height": 80},
                        "presence_status": "DETECTED",
                        "correctness_status": "VALID",
                        "verification_status": "VERIFIED",
                        "provenance": "INSPECTOR_VERIFIED"
                    },
                    {
                        "id": "dec-001-2",
                        "inspection_id": "ins-demo-001",
                        "field_name": "net_quantity",
                        "ai_value": "5 kg",
                        "verified_value": "5 kg",
                        "unit": "KG",
                        "confidence": 0.98,
                        "source_image_id": "img-001-front",
                        "source_block_id": "blk-02",
                        "source_text": "Net Qty: 5 kg",
                        "bbox": {"x": 150, "y": 1100, "width": 300, "height": 60},
                        "presence_status": "DETECTED",
                        "correctness_status": "VALID",
                        "verification_status": "VERIFIED",
                        "provenance": "INSPECTOR_VERIFIED"
                    },
                    {
                        "id": "dec-001-3",
                        "inspection_id": "ins-demo-001",
                        "field_name": "mrp",
                        "ai_value": "₹450.00",
                        "verified_value": "₹450.00",
                        "unit": "INR",
                        "confidence": 0.99,
                        "source_image_id": "img-001-back",
                        "source_block_id": "blk-03",
                        "source_text": "MRP ₹ 450.00 (Incl. of all taxes)",
                        "bbox": {"x": 200, "y": 300, "width": 450, "height": 55},
                        "presence_status": "DETECTED",
                        "correctness_status": "VALID",
                        "verification_status": "VERIFIED",
                        "provenance": "INSPECTOR_VERIFIED"
                    },
                    {
                        "id": "dec-001-4",
                        "inspection_id": "ins-demo-001",
                        "field_name": "manufacturer_name",
                        "ai_value": "ABC Agro Foods Ltd.",
                        "verified_value": "ABC Agro Foods Ltd.",
                        "unit": None,
                        "confidence": 0.97,
                        "source_image_id": "img-001-back",
                        "source_block_id": "blk-04",
                        "source_text": "Manufactured & Packed by: ABC Agro Foods Ltd., Plot 42, Food Industrial Estate, Karnal, Haryana - 132001",
                        "bbox": {"x": 200, "y": 420, "width": 750, "height": 110},
                        "presence_status": "DETECTED",
                        "correctness_status": "VALID",
                        "verification_status": "VERIFIED",
                        "provenance": "INSPECTOR_VERIFIED"
                    },
                    {
                        "id": "dec-001-5",
                        "inspection_id": "ins-demo-001",
                        "field_name": "consumer_care",
                        "ai_value": "customercare@abcagro.com, 1800-111-2222",
                        "verified_value": "customercare@abcagro.com, 1800-111-2222",
                        "unit": None,
                        "confidence": 0.96,
                        "source_image_id": "img-001-back",
                        "source_block_id": "blk-05",
                        "source_text": "Consumer Care: Call 1800-111-2222 or email customercare@abcagro.com",
                        "bbox": {"x": 200, "y": 600, "width": 650, "height": 60},
                        "presence_status": "DETECTED",
                        "correctness_status": "VALID",
                        "verification_status": "VERIFIED",
                        "provenance": "INSPECTOR_VERIFIED"
                    }
                ],
                "checks": [
                    {
                        "id": "chk-001-1",
                        "inspection_id": "ins-demo-001",
                        "check_type": "MANDATORY_DECLARATION",
                        "field_name": "commodity_name",
                        "rule_code": "RULE-006",
                        "rule_version": "2024.1",
                        "input_value": "ABC Premium Basmati Rice",
                        "expected_condition": "Presence on packaging",
                        "result": "PASS",
                        "confidence": 0.99,
                        "explanation": "Common or generic name is prominently displayed.",
                        "source_reference": "Rule 6(1)(a)"
                    },
                    {
                        "id": "chk-001-2",
                        "inspection_id": "ins-demo-001",
                        "check_type": "CHARACTER_HEIGHT",
                        "field_name": "net_quantity",
                        "rule_code": "RULE-007",
                        "rule_version": "2024.1",
                        "input_value": "Measured height: 3.2 mm",
                        "expected_condition": "Minimum 2.5 mm for PDP area 320 cm² (Table-I)",
                        "result": "PASS",
                        "confidence": 0.92,
                        "explanation": "Character height 3.2 mm satisfies required 2.5 mm threshold.",
                        "source_reference": "Rule 7 Table-I"
                    },
                    {
                        "id": "chk-001-3",
                        "inspection_id": "ins-demo-001",
                        "check_type": "CHARACTER_PROPORTION",
                        "field_name": "mrp",
                        "rule_code": "RULE-007",
                        "rule_version": "2024.1",
                        "input_value": "Width/Height ratio: 0.58",
                        "expected_condition": "Width must be >= 1/3 (0.333) of height",
                        "result": "PASS",
                        "confidence": 0.94,
                        "explanation": "Numeral width-to-height ratio 0.58 exceeds 1/3 requirement.",
                        "source_reference": "Rule 7"
                    },
                    {
                        "id": "chk-001-4",
                        "inspection_id": "ins-demo-001",
                        "check_type": "READABILITY",
                        "field_name": "mrp",
                        "rule_code": "RULE-009",
                        "rule_version": "2024.1",
                        "input_value": "Contrast 88%, Sharpness 91%",
                        "expected_condition": "Adequate contrast and prominence",
                        "result": "PASS",
                        "confidence": 0.95,
                        "explanation": "High text-to-background contrast with crisp character boundaries.",
                        "source_reference": "Rule 9"
                    }
                ],
                "violations": []
            },
            "ins-demo-002": {
                "id": "ins-demo-002",
                "inspection_code": "INS-2026-00102",
                "inspector_id": "u-insp-1",
                "product_id": "prod-shampoo-02",
                "inspection_type": "PHYSICAL",
                "inspection_date": "2026-09-07T14:20:00Z",
                "location": "Wellness Pharmacy & Superstore, Gomti Nagar, Lucknow",
                "seller_name": "Wellness Retail Ltd",
                "business_name": "Wellness Stores",
                "status": "NEEDS_REVIEW",
                "score": 82.0,
                "package_type": "CYLINDRICAL",
                "package_construction_type": "NORMAL",
                "calibration_status": "CALIBRATED",
                "calibration_data": {
                    "method": "KNOWN_DISTANCE",
                    "point1": {"x": 50, "y": 300},
                    "point2": {"x": 250, "y": 300},
                    "knownDistance": 100.0,
                    "pixelsPerMm": 2.0
                },
                "pdp_data": {"areaCm2": 95.0, "confidence": 0.88},
                "applied_rule_version": "2024.1",
                "notes": "Consumer grievance telephone number absent. Consumer care details only provide an email address.",
                "created_at": "2026-09-07T14:20:00Z",
                "updated_at": "2026-09-07T14:40:00Z",
                "finalized_at": None,
                "images": [],
                "declarations": [],
                "checks": [],
                "violations": [
                    {
                        "id": "viol-002-1",
                        "inspection_id": "ins-demo-002",
                        "type": "INCOMPLETE_DECLARATION",
                        "severity": "LOW",
                        "confidence": 0.89,
                        "status": "REVIEW_REQUIRED",
                        "provenance": "AI_DETECTED",
                        "ai_explanation": "Consumer Care declaration provides email only; telephone contact is absent or illegible.",
                        "inspector_comment": None,
                        "created_at": "2026-09-07T14:25:00Z"
                    }
                ]
            },
            "ins-demo-003": {
                "id": "ins-demo-003",
                "inspection_code": "INS-2026-00103",
                "inspector_id": "u-insp-1",
                "product_id": "prod-serum-03",
                "inspection_type": "PHYSICAL",
                "inspection_date": "2026-09-07T16:00:00Z",
                "location": "Duty Free Luxury Imports, Terminal 2, IGI Airport, New Delhi",
                "seller_name": "Luxe Retail Impex",
                "business_name": "Airport Luxury Arcade",
                "status": "NEEDS_REVIEW",
                "score": 64.0,
                "package_type": "RECTANGULAR",
                "package_construction_type": "NORMAL",
                "calibration_status": "UNCERTAIN",
                "applied_rule_version": "2024.1",
                "notes": "Imported product lacking complete importer address. Font size for net quantity is unverified.",
                "created_at": "2026-09-07T16:00:00Z",
                "updated_at": "2026-09-07T16:30:00Z",
                "finalized_at": None,
                "images": [],
                "declarations": [],
                "checks": [],
                "violations": [
                    {
                        "id": "viol-003-1",
                        "inspection_id": "ins-demo-003",
                        "type": "MISSING_IMPORTER_ADDRESS",
                        "severity": "HIGH",
                        "confidence": 0.96,
                        "status": "CONFIRMED",
                        "provenance": "INSPECTOR_VERIFIED",
                        "ai_explanation": "Name of importer is present but mandatory complete Indian registered address is absent.",
                        "inspector_comment": "Confirmed upon physical package examination. In violation of Rule 6(1)(b).",
                        "created_at": "2026-09-07T16:10:00Z"
                    }
                ]
            },
            "ins-demo-004": {
                "id": "ins-demo-004",
                "inspection_code": "INS-2026-00104",
                "inspector_id": "u-insp-1",
                "product_id": "prod-rice-01",
                "inspection_type": "PHYSICAL",
                "inspection_date": "2026-09-12T01:00:00Z",
                "location": "Heritage Fresh Supermarket, Khan Market, New Delhi",
                "seller_name": "Retail Traders Pvt Ltd",
                "business_name": "Heritage Fresh Supermarket",
                "status": "DRAFT",
                "score": None,
                "package_type": "RECTANGULAR",
                "package_construction_type": "NORMAL",
                "calibration_status": "NOT_CALIBRATED",
                "applied_rule_version": "2024.1",
                "notes": "Draft package case ready for multi-surface scanning & OCR verification.",
                "created_at": "2026-09-12T01:00:00Z",
                "updated_at": "2026-09-12T01:00:00Z",
                "finalized_at": None,
                "images": [],
                "declarations": [],
                "checks": [],
                "violations": []
            }
        }

        # 7. Reports
        self.reports: Dict[str, Dict[str, Any]] = {
            "rep-001": {
                "id": "rep-001",
                "inspection_id": "ins-demo-001",
                "report_version": 1,
                "pdf_path": "storage/reports/MAANAK_REPORT_ins-demo-001_v1.pdf",
                "pdf_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
                "docx_path": "storage/reports/MAANAK_REPORT_ins-demo-001_v1.docx",
                "docx_sha256": "c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855e3b0",
                "archival_status": "ARCHIVED",
                "generated_by": "u-insp-1",
                "created_at": "2026-09-07T10:46:00Z"
            }
        }

        # 8. Audit Logs (Chronological Operational Trail)
        self.audit_logs: List[Dict[str, Any]] = [
            {
                "id": "aud-uuid-001",
                "event_id": "AUD-000101",
                "event_type": "AUTH",
                "action": "USER_LOGIN",
                "user_id": "u-insp-1",
                "actor_id": "u-insp-1",
                "actor_name": "Ramesh Verma",
                "role": "INSPECTOR",
                "resource_type": "AUTH",
                "resource_id": "u-insp-1",
                "target_type": "AUTH",
                "target_id": "u-insp-1",
                "inspection_id": None,
                "result": "SUCCESS",
                "description": "Officer Ramesh Verma authenticated into LM-TRACE inspection console.",
                "old_value": None,
                "new_value": None,
                "before_data": None,
                "after_data": None,
                "metadata": {"officer_id": "LM-DL-2026-042", "ip_address": "10.0.1.42", "auth_method": "PASSWORD"},
                "correlation_id": "TRACE-AUTH-u-insp-1",
                "timestamp": "2026-09-07T09:30:00Z",
                "source": "WEB_APP"
            },
            {
                "id": "aud-uuid-002",
                "event_id": "AUD-000102",
                "event_type": "INSPECTION",
                "action": "INSPECTION_CREATED",
                "user_id": "u-insp-1",
                "actor_id": "u-insp-1",
                "actor_name": "Ramesh Verma",
                "role": "INSPECTOR",
                "resource_type": "INSPECTION",
                "resource_id": "ins-demo-001",
                "target_type": "INSPECTION",
                "target_id": "ins-demo-001",
                "inspection_id": "ins-demo-001",
                "result": "SUCCESS",
                "description": "Created new physical package inspection for ABC Premium Basmati Rice (INS-2026-00101) at Sector 18, Noida.",
                "old_value": None,
                "new_value": {"code": "INS-2026-00101", "product_category": "Packaged Food", "location": "Sector 18, Noida"},
                "before_data": None,
                "after_data": {"code": "INS-2026-00101", "product_category": "Packaged Food", "location": "Sector 18, Noida"},
                "metadata": {"business_name": "Spencer Retail Ltd", "category": "Food & Beverages"},
                "correlation_id": "TRACE-ins-demo-001",
                "timestamp": "2026-09-07T09:35:10Z",
                "source": "WEB_APP"
            },
            {
                "id": "aud-uuid-003",
                "event_id": "AUD-000103",
                "event_type": "EVIDENCE",
                "action": "EVIDENCE_UPLOADED",
                "user_id": "u-insp-1",
                "actor_id": "u-insp-1",
                "actor_name": "Ramesh Verma",
                "role": "INSPECTOR",
                "resource_type": "EVIDENCE",
                "resource_id": "img-demo-001-f",
                "target_type": "EVIDENCE",
                "target_id": "img-demo-001-f",
                "inspection_id": "ins-demo-001",
                "result": "SUCCESS",
                "description": "Captured and uploaded front principal display panel evidence image for INS-2026-00101.",
                "old_value": None,
                "new_value": {"surface_type": "FRONT", "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"},
                "before_data": None,
                "after_data": {"surface_type": "FRONT", "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"},
                "metadata": {"surface": "FRONT", "dimensions": "1920x1080", "file_size_bytes": 1048576},
                "correlation_id": "TRACE-ins-demo-001",
                "timestamp": "2026-09-07T09:38:22Z",
                "source": "WEB_APP"
            },
            {
                "id": "aud-uuid-004",
                "event_id": "AUD-000104",
                "event_type": "OCR",
                "action": "OCR_COMPLETED",
                "user_id": "system",
                "actor_id": "system",
                "actor_name": "Multi-Surface OCR Engine",
                "role": "SYSTEM",
                "resource_type": "OCR",
                "resource_id": "ocr-ins-demo-001",
                "target_type": "OCR",
                "target_id": "ocr-ins-demo-001",
                "inspection_id": "ins-demo-001",
                "result": "COMPLETED",
                "description": "Optical Character Recognition processed 2 package surfaces and extracted 18 declaration text blocks.",
                "old_value": None,
                "new_value": {"surfaces_count": 2, "blocks_count": 18, "mean_confidence": 0.96},
                "before_data": None,
                "after_data": {"surfaces_count": 2, "blocks_count": 18, "mean_confidence": 0.96},
                "metadata": {"engine": "MultiSurfaceOCR_v2", "surfaces": ["FRONT", "BACK"]},
                "correlation_id": "TRACE-ins-demo-001",
                "timestamp": "2026-09-07T09:40:05Z",
                "source": "SYSTEM_ENGINE"
            },
            {
                "id": "aud-uuid-005",
                "event_id": "AUD-000105",
                "event_type": "CALIBRATION",
                "action": "CALIBRATION_CREATED",
                "user_id": "u-insp-1",
                "actor_id": "u-insp-1",
                "actor_name": "Ramesh Verma",
                "role": "INSPECTOR",
                "resource_type": "CALIBRATION",
                "resource_id": "cal-demo-001",
                "target_type": "CALIBRATION",
                "target_id": "cal-demo-001",
                "inspection_id": "ins-demo-001",
                "result": "SUCCESS",
                "description": "Established optical scale calibration at 2.05 px/mm using a 100.0 mm reference standard.",
                "old_value": None,
                "new_value": {"pixels_per_mm": 2.05, "known_distance_mm": 100.0, "pixel_distance": 205.0},
                "before_data": None,
                "after_data": {"pixels_per_mm": 2.05, "known_distance_mm": 100.0, "pixel_distance": 205.0},
                "metadata": {"reference_type": "STANDARD_SCALE", "confidence": 0.98},
                "correlation_id": "TRACE-ins-demo-001",
                "timestamp": "2026-09-07T09:42:15Z",
                "source": "WEB_APP"
            },
            {
                "id": "aud-uuid-006",
                "event_id": "AUD-000106",
                "event_type": "CV",
                "action": "CV_ANALYSIS_COMPLETED",
                "user_id": "system",
                "actor_id": "system",
                "actor_name": "Computer Vision Service",
                "role": "SYSTEM",
                "resource_type": "CV",
                "resource_id": "cv-ins-demo-001",
                "target_type": "CV",
                "target_id": "cv-ins-demo-001",
                "inspection_id": "ins-demo-001",
                "result": "COMPLETED",
                "description": "Computed Table-I character font height proportions and contrast metrics across package surfaces.",
                "old_value": None,
                "new_value": {"pdp_area_cm2": 320.0, "font_height_mm": 3.2, "contrast_ratio": 4.8},
                "before_data": None,
                "after_data": {"pdp_area_cm2": 320.0, "font_height_mm": 3.2, "contrast_ratio": 4.8},
                "metadata": {"rule_reference": "Rule 7 & Table-I, LM (PC) Rules, 2011"},
                "correlation_id": "TRACE-ins-demo-001",
                "timestamp": "2026-09-07T09:43:00Z",
                "source": "SYSTEM_ENGINE"
            },
            {
                "id": "aud-uuid-007",
                "event_id": "AUD-000107",
                "event_type": "RULE_ENGINE",
                "action": "RULE_EVALUATION_COMPLETED",
                "user_id": "system",
                "actor_id": "system",
                "actor_name": "Statutory Rule Engine",
                "role": "SYSTEM",
                "resource_type": "RULE_ENGINE",
                "resource_id": "rule-eval-ins-demo-001",
                "target_type": "RULE_ENGINE",
                "target_id": "rule-eval-ins-demo-001",
                "inspection_id": "ins-demo-001",
                "result": "COMPLETED",
                "description": "Statutory Rule Engine evaluated 8 applicable legal rules under LM (PC) Rules, 2011 (Version 2024.1).",
                "old_value": None,
                "new_value": {"applicable_rules_count": 8, "rule_version": "2024.1"},
                "before_data": None,
                "after_data": {"applicable_rules_count": 8, "rule_version": "2024.1"},
                "metadata": {"act": "The Legal Metrology Act, 2009", "rules": "LM (PC) Rules, 2011"},
                "correlation_id": "TRACE-ins-demo-001",
                "timestamp": "2026-09-07T09:43:45Z",
                "source": "SYSTEM_ENGINE"
            },
            {
                "id": "aud-uuid-008",
                "event_id": "AUD-000108",
                "event_type": "COMPLIANCE",
                "action": "COMPLIANCE_EVALUATION_COMPLETED",
                "user_id": "system",
                "actor_id": "system",
                "actor_name": "Compliance Assessment Engine",
                "role": "SYSTEM",
                "resource_type": "COMPLIANCE",
                "resource_id": "cmp-ins-demo-001",
                "target_type": "COMPLIANCE",
                "target_id": "cmp-ins-demo-001",
                "inspection_id": "ins-demo-001",
                "result": "COMPLETED",
                "description": "Compliance Engine completed statutory assessment: 14 checks passed, 1 potential violation flagged.",
                "old_value": None,
                "new_value": {"passed_checks": 14, "violations_detected": 1, "compliance_score": 96.5},
                "before_data": None,
                "after_data": {"passed_checks": 14, "violations_detected": 1, "compliance_score": 96.5},
                "metadata": {"status": "NEEDS_REVIEW"},
                "correlation_id": "TRACE-ins-demo-001",
                "timestamp": "2026-09-07T09:44:20Z",
                "source": "SYSTEM_ENGINE"
            },
            {
                "id": "aud-uuid-009",
                "event_id": "AUD-000109",
                "event_type": "FINDING",
                "action": "FINDING_CONFIRMED",
                "user_id": "u-insp-1",
                "actor_id": "u-insp-1",
                "actor_name": "Ramesh Verma",
                "role": "INSPECTOR",
                "resource_type": "VIOLATION",
                "resource_id": "viol-demo-001",
                "target_type": "VIOLATION",
                "target_id": "viol-demo-001",
                "inspection_id": "ins-demo-001",
                "result": "SUCCESS",
                "description": "Inspector verified and confirmed violation: Net Quantity numeral height is below Table-I requirement.",
                "old_value": {"status": "AI_DETECTED"},
                "new_value": {"status": "CONFIRMED", "comment": "Verified via optical calibration; font height is 2.8 mm vs 4.0 mm requirement."},
                "before_data": {"status": "AI_DETECTED"},
                "after_data": {"status": "CONFIRMED", "comment": "Verified via optical calibration; font height is 2.8 mm vs 4.0 mm requirement."},
                "metadata": {"rule_code": "RULE-007", "severity": "MEDIUM"},
                "correlation_id": "TRACE-ins-demo-001",
                "timestamp": "2026-09-07T09:50:10Z",
                "source": "WEB_APP"
            },
            {
                "id": "aud-uuid-010",
                "event_id": "AUD-000110",
                "event_type": "REPORT",
                "action": "PDF_REPORT_GENERATED",
                "user_id": "u-insp-1",
                "actor_id": "u-insp-1",
                "actor_name": "Ramesh Verma",
                "role": "INSPECTOR",
                "resource_type": "REPORT",
                "resource_id": "rep-ins-demo-001",
                "target_type": "REPORT",
                "target_id": "rep-ins-demo-001",
                "inspection_id": "ins-demo-001",
                "result": "SUCCESS",
                "description": "Generated and archived statutory PDF inspection report (v1) with digital hash.",
                "old_value": None,
                "new_value": {"report_version": 1, "sha256": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"},
                "before_data": None,
                "after_data": {"report_version": 1, "sha256": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"},
                "metadata": {"archival_status": "ARCHIVED", "format": "PDF"},
                "correlation_id": "TRACE-ins-demo-001",
                "timestamp": "2026-09-07T10:10:00Z",
                "source": "WEB_APP"
            },
            {
                "id": "aud-uuid-011",
                "event_id": "AUD-000111",
                "event_type": "INSPECTION",
                "action": "INSPECTION_FINALIZED",
                "user_id": "u-insp-1",
                "actor_id": "u-insp-1",
                "actor_name": "Ramesh Verma",
                "role": "INSPECTOR",
                "resource_type": "INSPECTION",
                "resource_id": "ins-demo-001",
                "target_type": "INSPECTION",
                "target_id": "ins-demo-001",
                "inspection_id": "ins-demo-001",
                "result": "SUCCESS",
                "description": "Finalized statutory inspection INS-2026-00101 with compliance score 96.5% under Rule 6 & 7.",
                "old_value": {"status": "READY"},
                "new_value": {"status": "FINALIZED", "score": 96.5},
                "before_data": {"status": "READY"},
                "after_data": {"status": "FINALIZED", "score": 96.5},
                "metadata": {"applied_rule_version": "2024.1", "final_outcome": "NOTICE_ISSUED"},
                "correlation_id": "TRACE-ins-demo-001",
                "timestamp": "2026-09-07T10:45:00Z",
                "source": "WEB_APP"
            },
            {
                "id": "aud-uuid-012",
                "event_id": "AUD-000112",
                "event_type": "AUTH",
                "action": "USER_LOGIN",
                "user_id": "u-sup-1",
                "actor_id": "u-sup-1",
                "actor_name": "Anjali Sharma",
                "role": "SUPERVISOR",
                "resource_type": "AUTH",
                "resource_id": "u-sup-1",
                "target_type": "AUTH",
                "target_id": "u-sup-1",
                "inspection_id": None,
                "result": "SUCCESS",
                "description": "Supervisor Anjali Sharma authenticated into supervisory review portal.",
                "old_value": None,
                "new_value": None,
                "before_data": None,
                "after_data": None,
                "metadata": {"officer_id": "LM-SUP-2026-009", "auth_method": "PASSWORD"},
                "correlation_id": "TRACE-AUTH-u-sup-1",
                "timestamp": "2026-09-07T11:00:00Z",
                "source": "WEB_APP"
            },
            {
                "id": "aud-uuid-013",
                "event_id": "AUD-000113",
                "event_type": "SUPERVISOR",
                "action": "SUPERVISOR_REVIEW_COMPLETED",
                "user_id": "u-sup-1",
                "actor_id": "u-sup-1",
                "actor_name": "Anjali Sharma",
                "role": "SUPERVISOR",
                "resource_type": "INSPECTION",
                "resource_id": "ins-demo-001",
                "target_type": "INSPECTION",
                "target_id": "ins-demo-001",
                "inspection_id": "ins-demo-001",
                "result": "SUCCESS",
                "description": "Supervisory review completed for INS-2026-00101: findings endorsed and statutory show-cause notice approved.",
                "old_value": {"review_status": "PENDING"},
                "new_value": {"review_status": "APPROVED", "decision": "ENDORSED"},
                "before_data": {"review_status": "PENDING"},
                "after_data": {"review_status": "APPROVED", "decision": "ENDORSED"},
                "metadata": {"review_notes": "Violation confirmed by photographic calibration overlay. Notice issuance approved."},
                "correlation_id": "TRACE-ins-demo-001",
                "timestamp": "2026-09-07T11:20:00Z",
                "source": "WEB_APP"
            }
        ]

        # 9. Legal Documents, Amendments, and Rule Audit Logs
        self.legal_documents: Dict[str, Dict[str, Any]] = {}
        self.rule_amendments: Dict[str, Dict[str, Any]] = {}
        self.rule_audit_logs: List[Dict[str, Any]] = []
        self.calibrations: Dict[str, Dict[str, Any]] = {}

    # --- IUserRepository ---
    async def get_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        for user in self.users.values():
            if user["email"].lower() == email.lower():
                return copy.deepcopy(user)
        return None

    async def get_by_id(self, user_id: str) -> Optional[Dict[str, Any]]:
        user = self.users.get(user_id)
        return copy.deepcopy(user) if user else None

    async def list_users(self) -> List[Dict[str, Any]]:
        return copy.deepcopy(list(self.users.values()))

    # --- IProductRepository ---
    async def get_product_by_id(self, product_id: str) -> Optional[Dict[str, Any]]:
        prod = self.products.get(product_id)
        return copy.deepcopy(prod) if prod else None

    async def get_by_fingerprint(self, fingerprint_sha256: str) -> Optional[Dict[str, Any]]:
        for prod in self.products.values():
            if prod.get("product_identity_fingerprint") == fingerprint_sha256:
                return copy.deepcopy(prod)
        return None

    async def list_products(self) -> List[Dict[str, Any]]:
        return copy.deepcopy(list(self.products.values()))

    async def create_or_update(self, product_data: Dict[str, Any]) -> Dict[str, Any]:
        p_id = product_data.get("id") or f"prod-{len(self.products) + 1}"
        product_data["id"] = p_id
        if "created_at" not in product_data:
            product_data["created_at"] = get_now_iso()
        product_data["updated_at"] = get_now_iso()
        self.products[p_id] = copy.deepcopy(product_data)
        return copy.deepcopy(self.products[p_id])

    async def add_label_version(self, label_version_data: Dict[str, Any]) -> Dict[str, Any]:
        lv_id = label_version_data.get("id") or f"lbl-{len(self.label_versions) + 1}"
        label_version_data["id"] = lv_id
        if "captured_at" not in label_version_data:
            label_version_data["captured_at"] = get_now_iso()
        self.label_versions.append(copy.deepcopy(label_version_data))
        return copy.deepcopy(label_version_data)

    async def get_label_versions(self, product_id: str) -> List[Dict[str, Any]]:
        return [copy.deepcopy(lv) for lv in self.label_versions if lv.get("product_id") == product_id]

    async def get_inspections_for_product(self, product_id: str) -> List[Dict[str, Any]]:
        res = [copy.deepcopy(ins) for ins in self.inspections.values() if ins.get("product_id") == product_id]
        res.sort(key=lambda x: x.get("inspection_date") or x.get("created_at") or "", reverse=True)
        return res

    # --- IInspectionRepository ---
    async def create(self, inspection_data: Dict[str, Any]) -> Dict[str, Any]:
        ins_id = inspection_data.get("id") or f"ins-{len(self.inspections) + 1}"
        inspection_data["id"] = ins_id
        if "created_at" not in inspection_data:
            inspection_data["created_at"] = get_now_iso()
        inspection_data["updated_at"] = get_now_iso()
        if "images" not in inspection_data:
            inspection_data["images"] = []
        if "declarations" not in inspection_data:
            inspection_data["declarations"] = []
        if "checks" not in inspection_data:
            inspection_data["checks"] = []
        if "violations" not in inspection_data:
            inspection_data["violations"] = []
        if "evidence_items" not in inspection_data:
            inspection_data["evidence_items"] = []
        self.inspections[ins_id] = copy.deepcopy(inspection_data)
        return copy.deepcopy(self.inspections[ins_id])

    async def get_by_id(self, entity_id: str) -> Optional[Dict[str, Any]]:
        # 1. Product check
        if entity_id in self.products:
            return copy.deepcopy(self.products[entity_id])
        # 2. Inspection check
        if entity_id in self.inspections:
            return copy.deepcopy(self.inspections[entity_id])
        for ins in self.inspections.values():
            if ins.get("inspection_code") == entity_id:
                return copy.deepcopy(ins)
        # 3. User check
        if entity_id in self.users:
            return copy.deepcopy(self.users[entity_id])
        return None


    async def update(self, inspection_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        if inspection_id not in self.inspections:
            return None
        self.inspections[inspection_id].update(updates)
        self.inspections[inspection_id]["updated_at"] = get_now_iso()
        return copy.deepcopy(self.inspections[inspection_id])

    async def list_inspections(self, inspector_id: Optional[str] = None, status: Optional[str] = None, query: Optional[str] = None) -> List[Dict[str, Any]]:
        results = []
        for ins in self.inspections.values():
            if inspector_id and ins.get("inspector_id") != inspector_id:
                continue
            if status and ins.get("status") != status:
                continue
            if query:
                q = query.lower()
                code = ins.get("inspection_code", "").lower()
                loc = ins.get("location", "").lower()
                seller = (ins.get("seller_name") or "").lower()
                if q not in code and q not in loc and q not in seller:
                    continue
            results.append(copy.deepcopy(ins))
        results.sort(key=lambda x: x.get("created_at", ""), reverse=True)
        return results

    async def add_image(self, inspection_id: str, image_data: Dict[str, Any]) -> Dict[str, Any]:
        ins = self.inspections.get(inspection_id)
        if not ins:
            raise ValueError(f"Inspection {inspection_id} not found")
        img_id = image_data.get("id") or f"img-{len(ins['images']) + 1}"
        image_data["id"] = img_id
        image_data["inspection_id"] = inspection_id
        if "created_at" not in image_data:
            image_data["created_at"] = get_now_iso()
        ins["images"].append(copy.deepcopy(image_data))
        return copy.deepcopy(image_data)

    async def delete_image(self, inspection_id: str, image_id: str) -> bool:
        ins = self.inspections.get(inspection_id)
        if not ins:
            return False
        orig_len = len(ins["images"])
        ins["images"] = [img for img in ins["images"] if img["id"] != image_id]
        return len(ins["images"]) < orig_len

    async def save_declarations(self, inspection_id: str, declarations: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        ins = self.inspections.get(inspection_id)
        if not ins:
            raise ValueError(f"Inspection {inspection_id} not found")
        ins["declarations"] = copy.deepcopy(declarations)
        return copy.deepcopy(ins["declarations"])

    async def update_declaration(self, declaration_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        for ins in self.inspections.values():
            for dec in ins.get("declarations", []):
                if dec.get("id") == declaration_id:
                    dec.update(updates)
                    return copy.deepcopy(dec)
        return None

    async def save_compliance_results(self, inspection_id: str, checks: List[Dict[str, Any]], violations: List[Dict[str, Any]]) -> None:
        ins = self.inspections.get(inspection_id)
        if not ins:
            raise ValueError(f"Inspection {inspection_id} not found")
        ins["checks"] = copy.deepcopy(checks)
        ins["violations"] = copy.deepcopy(violations)

    async def update_finding(self, finding_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        for ins in self.inspections.values():
            for viol in ins.get("violations", []):
                if viol["id"] == finding_id:
                    viol.update(updates)
                    return copy.deepcopy(viol)
        return None

    async def finalize_inspection(self, inspection_id: str, snapshot_data: Dict[str, Any], additional_updates: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        ins = self.inspections.get(inspection_id)
        if not ins:
            raise ValueError(f"Inspection {inspection_id} not found")
        ins["status"] = "FINALIZED"
        ins["finalized_at"] = get_now_iso()
        ins["rule_snapshot"] = copy.deepcopy(snapshot_data)
        if additional_updates:
            for k, v in additional_updates.items():
                if v is not None:
                    ins[k] = v
        return copy.deepcopy(ins)


    async def save_evidence_items(self, inspection_id: str, evidence_items: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        ins = self.inspections.get(inspection_id)
        if not ins:
            raise ValueError(f"Inspection {inspection_id} not found")
        if "evidence_items" not in ins:
            ins["evidence_items"] = []

        saved = []
        for item in evidence_items:
            ev_id = item.get("id") or f"ev-{uuid.uuid4().hex[:8]}"
            clean = copy.deepcopy(item)
            clean["id"] = ev_id
            clean["inspection_id"] = inspection_id
            if "created_at" not in clean:
                clean["created_at"] = get_now_iso()
            if not clean.get("thumbnail_url") and clean.get("cloudinary_secure_url"):
                sec = clean["cloudinary_secure_url"]
                clean["thumbnail_url"] = sec.replace("/upload/", "/upload/c_thumb,w_300,h_300/") if "/upload/" in sec else sec

            # Find existing or append
            idx = next((i for i, e in enumerate(ins["evidence_items"]) if e["id"] == ev_id), None)
            if idx is not None:
                ins["evidence_items"][idx].update(clean)
                saved.append(copy.deepcopy(ins["evidence_items"][idx]))
            else:
                ins["evidence_items"].append(clean)
                saved.append(copy.deepcopy(clean))

        return saved

    async def list_evidence(self, inspection_id: str) -> List[Dict[str, Any]]:
        ins = self.inspections.get(inspection_id)
        if not ins:
            return []
        return copy.deepcopy(ins.get("evidence_items", []))

    async def get_evidence_by_id(self, evidence_id: str) -> Optional[Dict[str, Any]]:
        for ins in self.inspections.values():
            for ev in ins.get("evidence_items", []):
                if ev.get("id") == evidence_id:
                    return copy.deepcopy(ev)
        return None

    async def update_evidence(self, evidence_id: str, updates: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        for ins in self.inspections.values():
            for ev in ins.get("evidence_items", []):
                if ev.get("id") == evidence_id:
                    ev.update(updates)
                    return copy.deepcopy(ev)
        return None

    # --- Calibration Methods ---
    async def save_calibration(self, inspection_id: str, calibration_data: Dict[str, Any]) -> Dict[str, Any]:
        ins = self.inspections.get(inspection_id)
        if not ins:
            ins = next((i for i in self.inspections.values() if i.get("inspection_code") == inspection_id), None)
            if not ins:
                raise ValueError(f"Inspection {inspection_id} not found.")

        cal_id = calibration_data.get("id") or f"cal-{uuid.uuid4().hex[:8]}"
        cal_record = dict(calibration_data)
        cal_record["id"] = cal_id
        cal_record["inspection_id"] = ins["id"]
        if "created_at" not in cal_record:
            cal_record["created_at"] = get_now_iso()
        cal_record["updated_at"] = get_now_iso()

        # Mark previous active calibrations for this inspection and surface image as SUPERSEDED
        target_img_id = cal_record.get("image_id")
        for c in self.calibrations.values():
            if c.get("inspection_id") == ins["id"] and c.get("calibration_status") == "VALID":
                if not target_img_id or c.get("image_id") == target_img_id:
                    c["calibration_status"] = "SUPERSEDED"
                    c["updated_at"] = get_now_iso()

        self.calibrations[cal_id] = copy.deepcopy(cal_record)

        # Update inspection object for backwards compatibility
        ins["calibration_status"] = "CALIBRATED"
        ins["calibration_data"] = {
            "method": cal_record.get("reference_type", "KNOWN_DISTANCE"),
            "reference_type": cal_record.get("reference_type", "RULER"),
            "reference_description": cal_record.get("reference_description"),
            "point1": {"x": cal_record.get("point_a_x"), "y": cal_record.get("point_a_y")},
            "point2": {"x": cal_record.get("point_b_x"), "y": cal_record.get("point_b_y")},
            "knownDistance": cal_record.get("known_distance"),
            "pixelsPerMm": cal_record.get("pixels_per_unit"),
            "pixelDistance": cal_record.get("pixel_distance"),
            "calibration_id": cal_id,
            "image_id": cal_record.get("image_id"),
        }
        ins["updated_at"] = get_now_iso()

        return copy.deepcopy(cal_record)

    async def get_calibrations(self, inspection_id: str, image_id: Optional[str] = None) -> List[Dict[str, Any]]:
        ins = self.inspections.get(inspection_id)
        actual_id = ins["id"] if ins else inspection_id
        results = [
            copy.deepcopy(c) for c in self.calibrations.values()
            if c.get("inspection_id") == actual_id
            and (not image_id or c.get("image_id") == image_id)
        ]
        results.sort(key=lambda x: x.get("created_at", ""), reverse=True)
        return results

    async def get_calibration_by_id(self, calibration_id: str) -> Optional[Dict[str, Any]]:
        c = self.calibrations.get(calibration_id)
        return copy.deepcopy(c) if c else None

    # --- IRuleRepository ---
    async def list_rules(self, category: Optional[str] = None, active_only: bool = True) -> List[Dict[str, Any]]:
        res = []
        for r in self.rules.values():
            if active_only and not r.get("active"):
                continue
            if category and category.upper() != "ALL":
                norm_cat = category.strip().upper().replace(" ", "_").replace("/", "_")
                rule_cat = (r.get("category") or "").upper()
                if "DECLARATION" in norm_cat and "DECLARATION" not in rule_cat:
                    continue
                elif ("PDP" in norm_cat or "FONT" in norm_cat) and ("PDP" not in rule_cat and "FONT" not in rule_cat):
                    continue
                elif "MRP" in norm_cat and "MRP" not in rule_cat:
                    continue
                elif ("ECOM" in norm_cat or "E_COMMERCE" in norm_cat) and ("ECOM" not in rule_cat and "E_COMMERCE" not in rule_cat):
                    continue
                elif "OTHER" in norm_cat and rule_cat in ["DECLARATIONS", "PDP_FONT_SIZE", "MRP", "E_COMMERCE", "MANDATORY_DECLARATIONS"]:
                    continue
                elif norm_cat not in ["DECLARATIONS", "PDP_FONT_SIZE", "MRP", "E_COMMERCE", "OTHER"] and rule_cat != norm_cat:
                    continue
            
            latest_v = r.get("versions", [])[-1] if r.get("versions") else None
            r_copy = copy.deepcopy(r)
            r_copy["current_version"] = latest_v["version"] if latest_v else "1.0"
            r_copy["current_version_id"] = latest_v["id"] if latest_v else None
            r_copy["status"] = latest_v.get("status", "ACTIVE") if latest_v else ("ACTIVE" if r.get("active") else "INACTIVE")
            r_copy["effective_from"] = latest_v.get("effective_from") if latest_v else None
            r_copy["source_name"] = latest_v.get("source_name", "Department of Consumer Affairs") if latest_v else "Department of Consumer Affairs"
            r_copy["source_reference"] = latest_v.get("source_reference", r.get("statutory_reference", "LM Rules 2011")) if latest_v else r.get("statutory_reference", "LM Rules 2011")
            r_copy["source_url"] = latest_v.get("source_url", "https://consumeraffairs.gov.in/pages/legal-metrology-act") if latest_v else "https://consumeraffairs.gov.in/pages/legal-metrology-act"
            r_copy["coverage_status"] = r.get("coverage_status", "FULLY_IMPLEMENTED")
            r_copy["versions_count"] = len(r.get("versions", []))
            res.append(r_copy)
        return res

    async def get_rule_by_id(self, rule_id: str) -> Optional[Dict[str, Any]]:
        r = self.rules.get(rule_id)
        if not r:
            for item in self.rules.values():
                if item.get("code") == rule_id or item.get("id") == rule_id:
                    r = item
                    break
        if not r:
            return None
        r_copy = copy.deepcopy(r)
        latest_v = r_copy.get("versions", [])[-1] if r_copy.get("versions") else None
        r_copy["current_version"] = latest_v["version"] if latest_v else "1.0"
        r_copy["status"] = latest_v.get("status", "ACTIVE") if latest_v else ("ACTIVE" if r_copy.get("active") else "INACTIVE")
        r_copy["effective_from"] = latest_v.get("effective_from") if latest_v else None
        r_copy["coverage_status"] = r_copy.get("coverage_status", "FULLY_IMPLEMENTED")
        r_copy["source_name"] = latest_v.get("source_name", "Department of Consumer Affairs") if latest_v else "Department of Consumer Affairs"
        r_copy["source_reference"] = latest_v.get("source_reference", r_copy.get("statutory_reference", "LM Rules 2011")) if latest_v else r_copy.get("statutory_reference", "LM Rules 2011")
        r_copy["source_url"] = latest_v.get("source_url", "https://consumeraffairs.gov.in/pages/legal-metrology-act") if latest_v else "https://consumeraffairs.gov.in/pages/legal-metrology-act"
        r_copy["amendments"] = [copy.deepcopy(a) for a in self.rule_amendments.values() if a.get("rule_id") == r_copy["id"]]
        return r_copy

    async def get_active_versions_for_date(self, inspection_date_iso: str) -> List[Dict[str, Any]]:
        active_versions = []
        for r in self.rules.values():
            if not r.get("active"):
                continue
            for v in r.get("versions", []):
                eff_from = v.get("effective_from")
                eff_to = v.get("effective_to")
                status = v.get("status", "ACTIVE")
                if status not in ["ACTIVE", "APPROVED", "SCHEDULED"]:
                    continue
                if eff_from and inspection_date_iso < eff_from:
                    continue
                if eff_to and inspection_date_iso >= eff_to:
                    continue
                v_copy = copy.deepcopy(v)
                v_copy["rule_code"] = r["code"]
                v_copy["rule_title"] = r["title"]
                v_copy["rule_category"] = r["category"]
                v_copy["statutory_reference"] = r.get("statutory_reference") or v.get("source_reference")
                v_copy["validation_type"] = r.get("validation_type")
                v_copy["parameters"] = r.get("parameters_json") or {}
                v_copy["evidence_requirements"] = r.get("evidence_requirements_json") or []
                v_copy["coverage_status"] = r.get("coverage_status") or "FULLY_IMPLEMENTED"
                active_versions.append(v_copy)
        return active_versions

    async def create_rule(self, rule_data: Dict[str, Any]) -> Dict[str, Any]:
        r_id = rule_data.get("id") or f"rule-{len(self.rules) + 1}"
        rule_data["id"] = r_id
        if "created_at" not in rule_data:
            rule_data["created_at"] = get_now_iso()
        rule_data["updated_at"] = get_now_iso()
        if "versions" not in rule_data:
            rule_data["versions"] = []
        self.rules[r_id] = copy.deepcopy(rule_data)
        return copy.deepcopy(self.rules[r_id])

    async def create_version(self, rule_id: str, version_data: Dict[str, Any]) -> Dict[str, Any]:
        rule = self.rules.get(rule_id)
        if not rule:
            for item in self.rules.values():
                if item.get("code") == rule_id or item.get("id") == rule_id:
                    rule = item
                    break
        if not rule:
            raise ValueError(f"Rule {rule_id} not found")
        v_id = version_data.get("id") or f"ver-{rule['id']}-{len(rule['versions']) + 1}"
        version_data["id"] = v_id
        version_data["rule_id"] = rule["id"]
        if "created_at" not in version_data:
            version_data["created_at"] = get_now_iso()
        rule["versions"].append(copy.deepcopy(version_data))
        return copy.deepcopy(version_data)

    async def list_rule_versions(self, rule_id: str) -> List[Dict[str, Any]]:
        rule = await self.get_rule_by_id(rule_id)
        return copy.deepcopy(rule.get("versions", [])) if rule else []

    async def list_rule_amendments(self, rule_id: str) -> List[Dict[str, Any]]:
        rule = await self.get_rule_by_id(rule_id)
        target_id = rule["id"] if rule else rule_id
        return [copy.deepcopy(a) for a in self.rule_amendments.values() if a.get("rule_id") == target_id]

    async def approve_rule_version(self, rule_id: str, version_id: str, approved_by: str) -> Optional[Dict[str, Any]]:
        rule = await self.get_rule_by_id(rule_id)
        if not rule:
            return None
        for v in rule.get("versions", []):
            if v["id"] == version_id:
                eff_from = v.get("effective_from")
                now = get_now_iso()
                is_future = eff_from and eff_from > now
                v["status"] = "SCHEDULED" if is_future else "ACTIVE"
                v["approved_by"] = approved_by
                v["approved_at"] = now
                return copy.deepcopy(v)
        return None

    async def list_legal_documents(self) -> List[Dict[str, Any]]:
        return list(self.legal_documents.values())

    async def save_legal_document(self, doc_data: Dict[str, Any]) -> Dict[str, Any]:
        self.legal_documents[doc_data["id"]] = copy.deepcopy(doc_data)
        return copy.deepcopy(doc_data)

    async def save_amendment(self, amendment_data: Dict[str, Any]) -> Dict[str, Any]:
        a_id = amendment_data.get("id") or f"amend-{len(self.rule_amendments) + 1}"
        amendment_data["id"] = a_id
        self.rule_amendments[a_id] = copy.deepcopy(amendment_data)
        return copy.deepcopy(amendment_data)

    async def save_rule_audit_log(self, audit_data: Dict[str, Any]) -> Dict[str, Any]:
        l_id = audit_data.get("id") or f"rule-log-{len(self.rule_audit_logs) + 1}"
        audit_data["id"] = l_id
        if "timestamp" not in audit_data:
            audit_data["timestamp"] = get_now_iso()
        self.rule_audit_logs.append(copy.deepcopy(audit_data))
        return copy.deepcopy(audit_data)

    async def get_rule_coverage(self) -> List[Dict[str, Any]]:
        return copy.deepcopy(self.rule_coverage)

    async def get_statutory_summary(self) -> Dict[str, Any]:
        return get_statutory_summary()

    async def list_statutory_documents(
        self,
        doc_type: Optional[str] = None,
        status: Optional[str] = None,
        family: Optional[str] = None,
        search: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        return list_statutory_documents(doc_type=doc_type, status=status, family=family, search=search)

    async def get_statutory_document_by_id(self, doc_id: str) -> Optional[Dict[str, Any]]:
        return get_statutory_document_by_id(doc_id)

    async def list_statutory_rules(
        self,
        document_id: Optional[str] = None,
        family: Optional[str] = None,
        status: Optional[str] = None,
        search: Optional[str] = None,
        rule_code: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        return list_statutory_rules(document_id=document_id, family=family, status=status, search=search, rule_code=rule_code)

    async def get_statutory_rule_by_id(self, rule_id: str) -> Optional[Dict[str, Any]]:
        return get_statutory_rule_by_id(rule_id)

    async def get_statutory_families(self) -> List[Dict[str, Any]]:
        return get_statutory_families()

    async def get_statutory_traceability(self, code: str) -> Dict[str, Any]:
        return get_statutory_traceability(code)

    # --- IReportRepository ---
    async def save_report_metadata(self, report_data: Dict[str, Any]) -> Dict[str, Any]:
        rep_id = report_data.get("id") or f"rep-{len(self.reports) + 1}"
        report_data["id"] = rep_id
        if "created_at" not in report_data:
            report_data["created_at"] = get_now_iso()
        self.reports[rep_id] = copy.deepcopy(report_data)
        return copy.deepcopy(self.reports[rep_id])

    async def get_report_by_inspection_id(self, inspection_id: str) -> Optional[Dict[str, Any]]:
        for rep in self.reports.values():
            if rep["inspection_id"] == inspection_id:
                return copy.deepcopy(rep)
        ins = await self.get_by_id(inspection_id)
        if ins and ins.get("id") != inspection_id:
            for rep in self.reports.values():
                if rep["inspection_id"] == ins["id"]:
                    return copy.deepcopy(rep)
        return None

    # --- IAuditLogRepository ---
    async def append_log(self, log_entry: Dict[str, Any]) -> Dict[str, Any]:
        l_id = log_entry.get("id") or f"aud-{len(self.audit_logs) + 1:04d}"
        log_entry["id"] = l_id
        if "event_id" not in log_entry or not log_entry["event_id"]:
            log_entry["event_id"] = f"AUD-{len(self.audit_logs) + 101:06d}"
        if "timestamp" not in log_entry or not log_entry["timestamp"]:
            log_entry["timestamp"] = get_now_iso()
        if "actor_id" not in log_entry:
            log_entry["actor_id"] = log_entry.get("user_id", "system")
        if "target_type" not in log_entry:
            log_entry["target_type"] = log_entry.get("resource_type", "SYSTEM")
        if "target_id" not in log_entry:
            log_entry["target_id"] = str(log_entry.get("resource_id", "0"))
        if "result" not in log_entry:
            log_entry["result"] = "SUCCESS"
        if "before_data" not in log_entry and "old_value" in log_entry:
            log_entry["before_data"] = log_entry["old_value"]
        if "after_data" not in log_entry and "new_value" in log_entry:
            log_entry["after_data"] = log_entry["new_value"]
        if "event_type" not in log_entry:
            log_entry["event_type"] = log_entry.get("resource_type", "SYSTEM")
        if "description" not in log_entry:
            act = log_entry.get("action", "ACTION").replace("_", " ").title()
            log_entry["description"] = f"{act} recorded for {log_entry['target_type']} {log_entry['target_id']}."
        if "source" not in log_entry:
            log_entry["source"] = "WEB_APP" if log_entry.get("role") != "SYSTEM" else "SYSTEM_ENGINE"

        # Prepend so newest is first in memory list
        self.audit_logs.insert(0, copy.deepcopy(log_entry))
        return copy.deepcopy(log_entry)

    async def list_logs(self, limit: int = 100) -> List[Dict[str, Any]]:
        logs = copy.deepcopy(self.audit_logs)
        logs.sort(key=lambda x: str(x.get("timestamp") or ""), reverse=True)
        return logs[:limit]

    async def get_log_by_id(self, log_id: str) -> Optional[Dict[str, Any]]:
        for l in self.audit_logs:
            if l.get("id") == log_id or l.get("event_id") == log_id:
                return copy.deepcopy(l)
        return None

    async def list_logs_filtered(
        self,
        q: Optional[str] = None,
        action: Optional[str] = None,
        event_type: Optional[str] = None,
        actor_id: Optional[str] = None,
        role: Optional[str] = None,
        resource_type: Optional[str] = None,
        inspection_id: Optional[str] = None,
        result: Optional[str] = None,
        date_from: Optional[str] = None,
        date_to: Optional[str] = None,
        correlation_id: Optional[str] = None,
        limit: int = 50,
        offset: int = 0
    ) -> Dict[str, Any]:
        logs = copy.deepcopy(self.audit_logs)

        filtered = []
        q_clean = q.lower().strip() if q else None
        for l in logs:
            if action and l.get("action", "").upper() != action.upper():
                continue
            if event_type and event_type != "ALL":
                et = l.get("event_type") or l.get("resource_type") or ""
                if et.upper() != event_type.upper():
                    continue
            if actor_id and l.get("user_id") != actor_id and l.get("actor_id") != actor_id:
                continue
            if role and role != "ALL" and l.get("role", "").upper() != role.upper():
                continue
            if resource_type and resource_type != "ALL":
                rt = l.get("resource_type") or l.get("target_type") or ""
                if rt.upper() != resource_type.upper():
                    continue
            if inspection_id and l.get("inspection_id") != inspection_id and str(l.get("resource_id")) != inspection_id:
                continue
            if result and result != "ALL" and l.get("result", "").upper() != result.upper():
                continue
            if correlation_id and l.get("correlation_id") != correlation_id:
                continue
            if date_from:
                ts = str(l.get("timestamp") or "")
                if ts and ts < date_from:
                    continue
            if date_to:
                ts = str(l.get("timestamp") or "")
                if ts and ts > date_to:
                    continue
            if q_clean:
                searchable = " ".join([
                    str(l.get("event_id") or ""),
                    str(l.get("action") or ""),
                    str(l.get("description") or ""),
                    str(l.get("actor_name") or ""),
                    str(l.get("inspection_id") or ""),
                    str(l.get("resource_id") or ""),
                    str(l.get("target_id") or ""),
                    str(l.get("correlation_id") or ""),
                ]).lower()
                if q_clean not in searchable:
                    continue

            filtered.append(l)

        filtered.sort(key=lambda x: str(x.get("timestamp") or ""), reverse=True)
        total = len(filtered)
        paged = filtered[offset : offset + limit]
        return {
            "items": paged,
            "total": total,
            "limit": limit,
            "offset": offset
        }

    async def get_audit_summary(self) -> Dict[str, Any]:
        logs = self.audit_logs
        today_prefix = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        total = len(logs)
        today = sum(1 for l in logs if str(l.get("timestamp") or "").startswith(today_prefix))
        ins_events = sum(
            1 for l in logs
            if l.get("event_type") in ("INSPECTION", "EVIDENCE", "OCR", "CV", "CALIBRATION", "COMPLIANCE", "FINDING", "REPORT", "RULE_ENGINE")
            or l.get("inspection_id") is not None
        )
        sec_events = sum(
            1 for l in logs
            if l.get("event_type") in ("AUTH", "SECURITY") or "LOGIN" in str(l.get("action") or "")
        )
        sys_events = sum(
            1 for l in logs
            if l.get("role") == "SYSTEM" or l.get("actor_id") == "system"
        )
        return {
            "total_events": total,
            "today_events": today,
            "inspection_events": ins_events,
            "security_events": sec_events,
            "system_events": sys_events,
        }

    async def get_chain_of_custody(self, inspection_id: str) -> Dict[str, Any]:
        ins = await self.get_by_id(inspection_id)
        ins_code = ins.get("code") if ins else inspection_id

        matching_events = [
            copy.deepcopy(l) for l in self.audit_logs
            if l.get("inspection_id") == inspection_id
            or str(l.get("resource_id") or "") == inspection_id
            or (ins and ins.get("code") and ins["code"] in str(l.get("description") or ""))
            or (l.get("correlation_id") and inspection_id in l["correlation_id"])
        ]
        matching_events.sort(key=lambda x: str(x.get("timestamp") or ""))

        # Defined standard stages for LM-TRACE inspection chain of custody
        stage_definitions = [
            ("INSPECTION_INITIATION", "Inspection Initiation", ["INSPECTION_CREATED"]),
            ("EVIDENCE_INGESTION", "Evidence & Surface Ingestion", ["EVIDENCE_UPLOADED", "IMAGE_UPLOADED"]),
            ("OCR_EXTRACTION", "Multi-Surface AI OCR Extraction", ["OCR_COMPLETED"]),
            ("SCALE_CALIBRATION", "Scale Metric Calibration", ["CALIBRATION_CREATED"]),
            ("CV_MEASUREMENT", "Computer Vision PDP & Typography", ["CV_ANALYSIS_COMPLETED"]),
            ("STATUTORY_EVALUATION", "Statutory Rule Resolution", ["RULE_EVALUATION_COMPLETED", "RULE_RESOLVED"]),
            ("COMPLIANCE_ASSESSMENT", "Compliance Engine Assessment", ["COMPLIANCE_EVALUATION_COMPLETED"]),
            ("SUPERVISOR_VERIFICATION", "Officer & Supervisory Review", ["FINDING_CONFIRMED", "FINDING_REJECTED", "MANUAL_FINDING_ADDED", "SUPERVISOR_REVIEW_COMPLETED"]),
            ("REPORT_FINALIZATION", "Statutory Report Archival", ["PDF_REPORT_GENERATED", "DOCX_REPORT_GENERATED", "INSPECTION_FINALIZED"]),
        ]

        stages = []
        for stage_key, stage_name, target_actions in stage_definitions:
            matched_event = next((e for e in matching_events if e.get("action") in target_actions), None)
            if matched_event:
                stages.append({
                    "stage_key": stage_key,
                    "stage_name": stage_name,
                    "status": "COMPLETED",
                    "actor": matched_event.get("actor_name") or matched_event.get("user_id"),
                    "role": matched_event.get("role"),
                    "timestamp": matched_event.get("timestamp"),
                    "event_id": matched_event.get("event_id"),
                    "details": matched_event.get("description"),
                    "metadata": matched_event.get("metadata"),
                })
            else:
                stages.append({
                    "stage_key": stage_key,
                    "stage_name": stage_name,
                    "status": "PENDING",
                    "actor": None,
                    "role": None,
                    "timestamp": None,
                    "event_id": None,
                    "details": f"{stage_name} pending execution or unrecorded.",
                    "metadata": None,
                })

        return {
            "inspection_id": inspection_id,
            "inspection_code": ins_code,
            "stages": stages,
            "events": matching_events,
        }

demo_repository = DemoInMemoryRepository()

