"""
LM-TRACE Centralized Statutory Registry
Authoritative official statutory sources from the Department of Consumer Affairs (DCA),
Ministry of Consumer Affairs, Food and Public Distribution, Government of India.
"""

from typing import List, Dict, Any, Optional
from datetime import datetime, timezone
import copy

STATUTORY_FAMILIES: List[Dict[str, Any]] = [
    {
        "family_name": "Legal Metrology (Packaged Commodities) Rules",
        "authority": "Ministry of Consumer Affairs, Food and Public Distribution",
        "parent_act": "The Legal Metrology Act, 2009 (Act No. 1 of 2010)",
        "document_count": 8,
        "active_rules_count": 10,
        "description": "Primary subordinate regulations governing pre-packaged commodities, mandatory declarations, numeral/letter heights, pricing, and retail standards in India."
    },
    {
        "family_name": "The Legal Metrology Act, 2009",
        "authority": "Parliament of India / Ministry of Law and Justice",
        "parent_act": "Constitution of India, Seventh Schedule, Entry 50",
        "document_count": 1,
        "active_rules_count": 2,
        "description": "Parent primary enactment establishing standard weights, measures, enforcement powers, and statutory inspection mandates across all states and union territories."
    },
    {
        "family_name": "Legal Metrology (General) Rules",
        "authority": "Ministry of Consumer Affairs, Food and Public Distribution",
        "parent_act": "The Legal Metrology Act, 2009",
        "document_count": 1,
        "active_rules_count": 1,
        "description": "Technical specifications, verification procedures, inspection methods, and calibration standards for weighing and measuring instruments."
    },
    {
        "family_name": "Legal Metrology (Approval of Models) Rules",
        "authority": "Ministry of Consumer Affairs, Food and Public Distribution",
        "parent_act": "The Legal Metrology Act, 2009",
        "document_count": 1,
        "active_rules_count": 1,
        "description": "Statutory requirements for testing, verification, and model approval of weighing and measuring instruments prior to manufacture or import."
    }
]

OFFICIAL_STATUTORY_DOCUMENTS: List[Dict[str, Any]] = [
    {
        "id": "doc-lm-act-2009",
        "title": "The Legal Metrology Act, 2009 (Act No. 1 of 2010)",
        "short_title": "LM Act, 2009",
        "document_type": "ACT",
        "authority": "Parliament of India / Ministry of Law and Justice",
        "jurisdiction": "Government of India (Union)",
        "notification_number": "Act No. 1 of 2010",
        "gazette_reference": "Gazette of India, Extraordinary, Part II, Section 1, No. 1",
        "publication_date": "2010-01-14T00:00:00Z",
        "effective_date": "2011-04-01T00:00:00Z",
        "expiry_date": None,
        "status": "ACTIVE",
        "source_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act",
        "official_document_url": "https://consumeraffairs.gov.in/sites/default/files/act_2009.pdf",
        "version": "2009.1",
        "parent_document_id": None,
        "rule_family": "The Legal Metrology Act, 2009",
        "summary": "Parent statutory enactment establishing standard weights and measures, regulation of pre-packaged commodities (Section 18), offences and penalties (Section 36), and rule-making powers (Section 52).",
        "rules_count": 2
    },
    {
        "id": "doc-pc-rules-2011",
        "title": "Legal Metrology (Packaged Commodities) Rules, 2011",
        "short_title": "LM (PC) Rules, 2011",
        "document_type": "PRINCIPAL_RULE",
        "authority": "Ministry of Consumer Affairs, Food and Public Distribution",
        "jurisdiction": "Government of India (Union)",
        "notification_number": "G.S.R. 202(E)",
        "gazette_reference": "Gazette of India, Extraordinary, Part II, Section 3, Sub-section (i), No. 132",
        "publication_date": "2011-03-07T00:00:00Z",
        "effective_date": "2011-04-01T00:00:00Z",
        "expiry_date": None,
        "status": "ACTIVE",
        "source_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act",
        "official_document_url": "https://consumeraffairs.gov.in/sites/default/files/rules_2011.pdf",
        "version": "2011.BASE",
        "parent_document_id": "doc-lm-act-2009",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "summary": "Principal subordinate statutory rules governing all packaged commodities. Mandates declaration details (Rule 6), numeral & letter heights on Principal Display Panel (Rule 7, Table-I), legibility standards (Rule 9), and standard units of measurement (Rule 12).",
        "rules_count": 7
    },
    {
        "id": "doc-amend-2017",
        "title": "Legal Metrology (Packaged Commodities) Amendment Rules, 2017 (E-Commerce Provisions)",
        "short_title": "E-Commerce Amendment, 2017",
        "document_type": "GAZETTE_AMENDMENT",
        "authority": "Ministry of Consumer Affairs, Food and Public Distribution",
        "jurisdiction": "Government of India (Union)",
        "notification_number": "G.S.R. 629(E)",
        "gazette_reference": "Gazette of India, Extraordinary, Part II, Section 3(i), No. 518",
        "publication_date": "2017-06-23T00:00:00Z",
        "effective_date": "2018-01-01T00:00:00Z",
        "expiry_date": None,
        "status": "ACTIVE",
        "source_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act",
        "official_document_url": "https://consumeraffairs.gov.in/sites/default/files/gsr_629.pdf",
        "version": "2017.1",
        "parent_document_id": "doc-pc-rules-2011",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "summary": "Substituted Rule 6(10) mandating that e-commerce marketplaces and digital viewports must display all statutory pre-purchase declarations (except month/year of packing) directly to consumers prior to sale.",
        "rules_count": 1
    },
    {
        "id": "doc-amend-2021",
        "title": "Legal Metrology (Packaged Commodities) Amendment Rules, 2021 (Unit Sale Price Mandate)",
        "short_title": "USP Amendment, 2021",
        "document_type": "GAZETTE_AMENDMENT",
        "authority": "Ministry of Consumer Affairs, Food and Public Distribution",
        "jurisdiction": "Government of India (Union)",
        "notification_number": "G.S.R. 779(E)",
        "gazette_reference": "Gazette of India, Extraordinary, Part II, Section 3(i), No. 642",
        "publication_date": "2021-11-02T00:00:00Z",
        "effective_date": "2022-12-01T00:00:00Z",
        "expiry_date": None,
        "status": "ACTIVE",
        "source_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act",
        "official_document_url": "https://consumeraffairs.gov.in/sites/default/files/gsr_779.pdf",
        "version": "2021.1",
        "parent_document_id": "doc-pc-rules-2011",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "summary": "Introduced statutory sub-rule 6(11) mandating Unit Sale Price (USP) declarations to empower consumer comparison, eliminated prescribed package sizes from Schedule II, and standardized month & year declaration format.",
        "rules_count": 1
    },
    {
        "id": "doc-amend-2022-usp",
        "title": "Legal Metrology (Packaged Commodities) Amendment Rules, 2022 (USP Specifications)",
        "short_title": "USP Specification Amendment, 2022",
        "document_type": "GAZETTE_AMENDMENT",
        "authority": "Ministry of Consumer Affairs, Food and Public Distribution",
        "jurisdiction": "Government of India (Union)",
        "notification_number": "G.S.R. 226(E)",
        "gazette_reference": "Gazette of India, Extraordinary, Part II, Section 3(i), No. 195",
        "publication_date": "2022-03-28T00:00:00Z",
        "effective_date": "2022-12-01T00:00:00Z",
        "expiry_date": None,
        "status": "ACTIVE",
        "source_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act",
        "official_document_url": "https://consumeraffairs.gov.in/sites/default/files/gsr_226.pdf",
        "version": "2022.1",
        "parent_document_id": "doc-pc-rules-2011",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "summary": "Prescribed precise statutory unit expressions for Unit Sale Price: per gram or per millilitre for net quantity less than 1 kg or 1 L; per kilogram or per litre for net quantity 1 kg / 1 L and above; per piece for items sold by number.",
        "rules_count": 1
    },
    {
        "id": "doc-amend-2022-spare",
        "title": "Legal Metrology (Packaged Commodities) (Second Amendment) Rules, 2022 (Electronic Products)",
        "short_title": "Electronic Products Amendment, 2022",
        "document_type": "GAZETTE_AMENDMENT",
        "authority": "Ministry of Consumer Affairs, Food and Public Distribution",
        "jurisdiction": "Government of India (Union)",
        "notification_number": "G.S.R. 520(E)",
        "gazette_reference": "Gazette of India, Extraordinary, Part II, Section 3(i), No. 427",
        "publication_date": "2022-07-06T00:00:00Z",
        "effective_date": "2022-07-06T00:00:00Z",
        "expiry_date": None,
        "status": "ACTIVE",
        "source_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act",
        "official_document_url": "https://consumeraffairs.gov.in/sites/default/files/gsr_520.pdf",
        "version": "2022.2",
        "parent_document_id": "doc-pc-rules-2011",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "summary": "Permitted manufacturers of electronic products to declare non-critical label declarations via QR Code, provided that basic declarations (commodity name, MRP, net quantity, consumer care) remain on the physical label.",
        "rules_count": 1
    },
    {
        "id": "doc-amend-2023",
        "title": "Legal Metrology (Packaged Commodities) Amendment Rules, 2023 & Jan Vishwas Act Alignment",
        "short_title": "Jan Vishwas Alignment Amendment, 2023",
        "document_type": "GAZETTE_AMENDMENT",
        "authority": "Ministry of Consumer Affairs, Food and Public Distribution",
        "jurisdiction": "Government of India (Union)",
        "notification_number": "G.S.R. 721(E)",
        "gazette_reference": "Gazette of India, Extraordinary, Part II, Section 3(i), No. 598",
        "publication_date": "2023-10-06T00:00:00Z",
        "effective_date": "2024-01-01T00:00:00Z",
        "expiry_date": None,
        "status": "ACTIVE",
        "source_url": "https://consumeraffairs.gov.in/pages/latest-news",
        "official_document_url": "https://consumeraffairs.gov.in/sites/default/files/gsr_721.pdf",
        "version": "2024.1",
        "parent_document_id": "doc-pc-rules-2011",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "summary": "Substituted penal provisions under Rule 32 in alignment with the Jan Vishwas (Amendment of Provisions) Act, 2023, shifting technical first-time violations to statutory civil compounding.",
        "rules_count": 1
    },
    {
        "id": "doc-dca-advisory-2024",
        "title": "Department of Consumer Affairs Enforcement Advisory on E-Commerce Pre-Purchase Disclosures",
        "short_title": "DCA E-Commerce Advisory, 2024",
        "document_type": "OFFICIAL_ADVISORY",
        "authority": "Department of Consumer Affairs, Government of India",
        "jurisdiction": "Government of India (Union)",
        "notification_number": "DCA-ADVISORY-2024-ECOM",
        "gazette_reference": None,
        "publication_date": "2024-04-15T00:00:00Z",
        "effective_date": "2024-05-01T00:00:00Z",
        "expiry_date": None,
        "status": "ACTIVE",
        "source_url": "https://consumeraffairs.gov.in/pages/latest-news",
        "official_document_url": "https://consumeraffairs.gov.in/sites/default/files/advisory_ecom_2024.pdf",
        "version": "2024.ECOM",
        "parent_document_id": "doc-pc-rules-2011",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "summary": "Mandatory operational advisory directing all e-commerce platforms to ensure pre-purchase declarations (MRP, USP, Country of Origin, Best Before) are displayed above the fold without requiring customer clicks.",
        "rules_count": 1
    },
    {
        "id": "doc-future-ecom-2027",
        "title": "Strategic Digital Viewport Standard: Machine-Readable QR Synchronization (Scheduled 2027)",
        "short_title": "Digital Viewport Standard (Scheduled 2027)",
        "document_type": "PROPOSED_AMENDMENT",
        "authority": "Ministry of Consumer Affairs, Food and Public Distribution",
        "jurisdiction": "Government of India (Union)",
        "notification_number": "DCA-PROPOSED-2026/GSR-889",
        "gazette_reference": "Gazette of India, Extraordinary, Draft Notification 889",
        "publication_date": "2026-09-10T00:00:00Z",
        "effective_date": "2027-07-01T00:00:00Z",
        "expiry_date": None,
        "status": "NOT_YET_EFFECTIVE",
        "source_url": "https://consumeraffairs.gov.in/pages/latest-news",
        "official_document_url": "https://consumeraffairs.gov.in/sites/default/files/draft_gsr_889.pdf",
        "version": "2027.PROPOSED",
        "parent_document_id": "doc-pc-rules-2011",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "summary": "Future scheduled gazette standard mandating dynamic machine-readable QR verification and real-time backend declaration synchronization on all marketplace listings. Published for advance industry preparedness; effective from 1 July 2027.",
        "rules_count": 1
    }
]

OFFICIAL_STATUTORY_RULES: List[Dict[str, Any]] = [
    {
        "id": "stat-act-sec-18",
        "rule_code": "STAT-ACT-SEC-18",
        "document_id": "doc-lm-act-2009",
        "document_title": "The Legal Metrology Act, 2009 (Act No. 1 of 2010)",
        "rule_family": "The Legal Metrology Act, 2009",
        "rule_number": "Section 18",
        "title": "Declarations on Pre-Packaged Commodities",
        "requirement_summary": "Prohibits manufacture, packing, sale, import, distribution, offering, or exposing for sale of any pre-packaged commodity unless such package bears thereon such declarations and in such manner as may be prescribed.",
        "subject": "Pre-Packaged Commodity Statutory Mandate",
        "applicability": "All commodities in packaged form manufactured, packed, imported, distributed, or sold in India.",
        "source_reference": "Section 18(1), The Legal Metrology Act, 2009",
        "version": "2009.1",
        "publication_date": "2010-01-14T00:00:00Z",
        "effective_from": "2011-04-01T00:00:00Z",
        "effective_to": None,
        "status": "ACTIVE",
        "mapped_rule_engine_id": None,
        "mapped_rule_engine_code": None,
        "is_automated": False,
        "official_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act"
    },
    {
        "id": "stat-act-sec-36",
        "rule_code": "STAT-ACT-SEC-36",
        "document_id": "doc-lm-act-2009",
        "document_title": "The Legal Metrology Act, 2009 (Act No. 1 of 2010)",
        "rule_family": "The Legal Metrology Act, 2009",
        "rule_number": "Section 36",
        "title": "Penalty for Selling, etc., of Non-Standard Packages",
        "requirement_summary": "Whoever manufactures, packs, imports, sells, distributes, delivers, or exposes for sale any pre-packaged commodity which does not conform to the declarations on the package shall be punished with fine or compounding.",
        "subject": "Statutory Enforcement & Penalties",
        "applicability": "All manufacturers, packers, importers, and retail distributors.",
        "source_reference": "Section 36(1) & (2), The Legal Metrology Act, 2009",
        "version": "2009.1",
        "publication_date": "2010-01-14T00:00:00Z",
        "effective_from": "2011-04-01T00:00:00Z",
        "effective_to": None,
        "status": "ACTIVE",
        "mapped_rule_engine_id": None,
        "mapped_rule_engine_code": None,
        "is_automated": False,
        "official_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act"
    },
    {
        "id": "stat-rule-6-decl",
        "rule_code": "STAT-RULE-6",
        "document_id": "doc-pc-rules-2011",
        "document_title": "Legal Metrology (Packaged Commodities) Rules, 2011",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "rule_number": "Rule 6(1)",
        "title": "Declarations to be Made on Every Package",
        "requirement_summary": "Every package shall bear legible declarations including: (a) name and address of manufacturer/packer/importer, (b) common/generic name of commodity, (c) net quantity in standard units, (d) month and year of manufacture/packing/import, (e) Maximum Retail Price (MRP) inclusive of all taxes, (f) consumer care details, and (g) sizes/dimensions where applicable.",
        "subject": "Mandatory Label Declarations",
        "applicability": "All retail and pre-packaged commodities sold or offered for sale in India.",
        "source_reference": "Rule 6(1)(a)-(g), LM (PC) Rules, 2011",
        "version": "2024.1",
        "publication_date": "2011-03-07T00:00:00Z",
        "effective_from": "2011-04-01T00:00:00Z",
        "effective_to": None,
        "status": "ACTIVE",
        "mapped_rule_engine_id": "rule-6",
        "mapped_rule_engine_code": "RULE-006",
        "is_automated": True,
        "official_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act"
    },
    {
        "id": "stat-rule-6-origin",
        "rule_code": "STAT-RULE-6-ORIGIN",
        "document_id": "doc-pc-rules-2011",
        "document_title": "Legal Metrology (Packaged Commodities) Rules, 2011",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "rule_number": "Rule 6(1)(a) & 6(1)(aa)",
        "title": "Manufacturer, Packer, Importer Separation & Country of Origin",
        "requirement_summary": "Requires distinct name and complete address of the manufacturer and, where the manufacturer is not the packer, the name and address of the packer. For imported goods, requires name and address of the importer and the prominent declaration of Country of Origin.",
        "subject": "Entity Traceability & Country of Origin",
        "applicability": "All pre-packaged commodities (domestic and imported).",
        "source_reference": "Rule 6(1)(a), Rule 6(1)(aa), LM (PC) Rules, 2011",
        "version": "2024.1",
        "publication_date": "2011-03-07T00:00:00Z",
        "effective_from": "2011-04-01T00:00:00Z",
        "effective_to": None,
        "status": "ACTIVE",
        "mapped_rule_engine_id": "rule-6",
        "mapped_rule_engine_code": "RULE-006",
        "is_automated": True,
        "official_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act"
    },
    {
        "id": "stat-rule-6-usp",
        "rule_code": "STAT-RULE-6-USP",
        "document_id": "doc-amend-2021",
        "document_title": "Legal Metrology (Packaged Commodities) Amendment Rules, 2021 (Unit Sale Price Mandate)",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "rule_number": "Rule 6(11)",
        "title": "Mandatory Unit Sale Price (USP) Declaration",
        "requirement_summary": "Mandatory declaration of Unit Sale Price (₹ per g / ₹ per ml / ₹ per kg / ₹ per L / ₹ per item) alongside the retail sale price (MRP) on every retail package where net quantity is more than one number, unit, gram, or millilitre.",
        "subject": "Unit Sale Price (USP)",
        "applicability": "All packaged retail commodities, except packages containing net weight of less than 10g or 10ml.",
        "source_reference": "Rule 6(11), LM (PC) Rules, 2011 as inserted by G.S.R. 779(E)",
        "version": "2022.1",
        "publication_date": "2021-11-02T00:00:00Z",
        "effective_from": "2022-12-01T00:00:00Z",
        "effective_to": None,
        "status": "ACTIVE",
        "mapped_rule_engine_id": "rule-6",
        "mapped_rule_engine_code": "RULE-006-UNIT-SALE-PRICE",
        "is_automated": True,
        "official_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act"
    },
    {
        "id": "stat-rule-6-ecom",
        "rule_code": "STAT-RULE-6-ECOM",
        "document_id": "doc-amend-2017",
        "document_title": "Legal Metrology (Packaged Commodities) Amendment Rules, 2017 (E-Commerce Provisions)",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "rule_number": "Rule 6(10)",
        "title": "E-Commerce Digital Viewport Mandatory Declarations",
        "requirement_summary": "An e-commerce entity shall ensure that the mandatory declarations specified under sub-rule (1), except the month and year in which the commodity is manufactured or packed, are displayed on the digital marketplace viewport before purchase.",
        "subject": "Digital Marketplace Compliance",
        "applicability": "All online marketplaces, e-commerce portals, and digital sellers in India.",
        "source_reference": "Rule 6(10), LM (PC) Rules, 2011 as substituted by G.S.R. 629(E)",
        "version": "2017.1",
        "publication_date": "2017-06-23T00:00:00Z",
        "effective_from": "2018-01-01T00:00:00Z",
        "effective_to": None,
        "status": "ACTIVE",
        "mapped_rule_engine_id": "rule-ecom",
        "mapped_rule_engine_code": "RULE-ECOM-2026",
        "is_automated": True,
        "official_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act"
    },
    {
        "id": "stat-rule-7-table1",
        "rule_code": "STAT-RULE-7",
        "document_id": "doc-pc-rules-2011",
        "document_title": "Legal Metrology (Packaged Commodities) Rules, 2011",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "rule_number": "Rule 7(1) & Table-I",
        "title": "Principal Display Panel Area & Minimum Numeral/Letter Height",
        "requirement_summary": "The minimum height of any numeral and letter in the declaration on the Principal Display Panel shall conform strictly to Table-I based on the calculated PDP area: <=50 cm² (1.0 mm normal / 2.0 mm blown/molded); 50-100 cm² (1.5 mm / 3.0 mm); 100-500 cm² (2.5 mm / 4.0 mm); 500-2500 cm² (4.0 mm / 6.0 mm); >2500 cm² (6.0 mm / 6.0 mm).",
        "subject": "Principal Display Panel Numeral & Letter Height Standards",
        "applicability": "All pre-packaged commodities requiring Principal Display Panel declarations.",
        "source_reference": "Rule 7(1) read with Table-I, LM (PC) Rules, 2011",
        "version": "2024.1",
        "publication_date": "2011-03-07T00:00:00Z",
        "effective_from": "2011-04-01T00:00:00Z",
        "effective_to": None,
        "status": "ACTIVE",
        "mapped_rule_engine_id": "rule-7",
        "mapped_rule_engine_code": "RULE-007",
        "is_automated": True,
        "official_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act"
    },
    {
        "id": "stat-rule-7-ratio",
        "rule_code": "STAT-RULE-7-RATIO",
        "document_id": "doc-pc-rules-2011",
        "document_title": "Legal Metrology (Packaged Commodities) Rules, 2011",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "rule_number": "Rule 7(3)",
        "title": "Width-to-Height Character Proportion Standards",
        "requirement_summary": "The width of the letter or numeral shall not be less than one-third of its height, except in the case of numeral '1' and letters 'i', 'I', and 'l'.",
        "subject": "Character Proportion & Optical Legibility",
        "applicability": "All letters and numerals appearing in mandatory label declarations.",
        "source_reference": "Rule 7(3), LM (PC) Rules, 2011",
        "version": "2024.1",
        "publication_date": "2011-03-07T00:00:00Z",
        "effective_from": "2011-04-01T00:00:00Z",
        "effective_to": None,
        "status": "ACTIVE",
        "mapped_rule_engine_id": "rule-7",
        "mapped_rule_engine_code": "RULE-007",
        "is_automated": True,
        "official_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act"
    },
    {
        "id": "stat-rule-8-placement",
        "rule_code": "STAT-RULE-8",
        "document_id": "doc-pc-rules-2011",
        "document_title": "Legal Metrology (Packaged Commodities) Rules, 2011",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "rule_number": "Rule 8",
        "title": "Dimensions and Placement of Declarations",
        "requirement_summary": "Every declaration required to be made under these rules on a package shall be placed on the Principal Display Panel or, in certain permitted cases, on the rear or side surface without obscuration.",
        "subject": "Surface Placement & Geometry",
        "applicability": "All retail packaging surfaces.",
        "source_reference": "Rule 8, LM (PC) Rules, 2011",
        "version": "2024.1",
        "publication_date": "2011-03-07T00:00:00Z",
        "effective_from": "2011-04-01T00:00:00Z",
        "effective_to": None,
        "status": "ACTIVE",
        "mapped_rule_engine_id": "rule-8",
        "mapped_rule_engine_code": "RULE-008",
        "is_automated": True,
        "official_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act"
    },
    {
        "id": "stat-rule-9-legibility",
        "rule_code": "STAT-RULE-9",
        "document_id": "doc-pc-rules-2011",
        "document_title": "Legal Metrology (Packaged Commodities) Rules, 2011",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "rule_number": "Rule 9(1)",
        "title": "Manner of Declaration: Legibility, Prominence, and Contrast",
        "requirement_summary": "Every declaration shall be legible, prominent, definite, plain, and unambiguous. It shall be conspicuously printed in a color that contrasts clearly with the background of the label to prevent visual deception.",
        "subject": "Optical Legibility & Conspicuousness",
        "applicability": "All declarations across all packaged commodities.",
        "source_reference": "Rule 9(1), LM (PC) Rules, 2011",
        "version": "2024.1",
        "publication_date": "2011-03-07T00:00:00Z",
        "effective_from": "2011-04-01T00:00:00Z",
        "effective_to": None,
        "status": "ACTIVE",
        "mapped_rule_engine_id": "rule-9",
        "mapped_rule_engine_code": "RULE-009",
        "is_automated": True,
        "official_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act"
    },
    {
        "id": "stat-rule-10-address",
        "rule_code": "STAT-RULE-10",
        "document_id": "doc-pc-rules-2011",
        "document_title": "Legal Metrology (Packaged Commodities) Rules, 2011",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "rule_number": "Rule 10",
        "title": "Declaration of Name and Complete Address",
        "requirement_summary": "Requires full street address or postal locality with postal index number (PIN) enabling consumer redressal and official regulatory inspection.",
        "subject": "Entity Traceability & Postal Completeness",
        "applicability": "All manufacturers, packers, and importers.",
        "source_reference": "Rule 10(1), LM (PC) Rules, 2011",
        "version": "2024.1",
        "publication_date": "2011-03-07T00:00:00Z",
        "effective_from": "2011-04-01T00:00:00Z",
        "effective_to": None,
        "status": "ACTIVE",
        "mapped_rule_engine_id": "rule-10",
        "mapped_rule_engine_code": "RULE-010",
        "is_automated": True,
        "official_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act"
    },
    {
        "id": "stat-rule-12-units",
        "rule_code": "STAT-RULE-12",
        "document_id": "doc-pc-rules-2011",
        "document_title": "Legal Metrology (Packaged Commodities) Rules, 2011",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "rule_number": "Rule 12",
        "title": "Manner of Expressing Units of Measurement",
        "requirement_summary": "All quantity declarations shall be expressed exclusively in terms of canonical metric units: weight in gram (g) or kilogram (kg); volume in millilitre (ml) or litre (l); length in centimetre (cm) or metre (m); or count. Non-standard abbreviations are strictly prohibited.",
        "subject": "Standard Measurement Units",
        "applicability": "All commodity net quantity declarations.",
        "source_reference": "Rule 12 read with Second Schedule, LM (PC) Rules, 2011",
        "version": "2024.1",
        "publication_date": "2011-03-07T00:00:00Z",
        "effective_from": "2011-04-01T00:00:00Z",
        "effective_to": None,
        "status": "ACTIVE",
        "mapped_rule_engine_id": "rule-12",
        "mapped_rule_engine_code": "RULE-012",
        "is_automated": True,
        "official_url": "https://consumeraffairs.gov.in/pages/legal-metrology-act"
    },
    {
        "id": "stat-rule-32-penalties",
        "rule_code": "STAT-RULE-32",
        "document_id": "doc-amend-2023",
        "document_title": "Legal Metrology (Packaged Commodities) Amendment Rules, 2023 & Jan Vishwas Act Alignment",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "rule_number": "Rule 32",
        "title": "Penalty for Contravention of Rules",
        "requirement_summary": "Whoever contravenes any provisions of these rules, for which no punishment is provided in the Act, shall be liable to statutory civil compounding penalties under Section 48 and Section 49.",
        "subject": "Statutory Penalties & Compounding",
        "applicability": "All packaging non-compliances.",
        "source_reference": "Rule 32, LM (PC) Rules, 2011 as amended by G.S.R. 721(E)",
        "version": "2024.1",
        "publication_date": "2023-10-06T00:00:00Z",
        "effective_from": "2024-01-01T00:00:00Z",
        "effective_to": None,
        "status": "ACTIVE",
        "mapped_rule_engine_id": None,
        "mapped_rule_engine_code": None,
        "is_automated": False,
        "official_url": "https://consumeraffairs.gov.in/pages/latest-news"
    },
    {
        "id": "stat-rule-future-qr-2027",
        "rule_code": "STAT-RULE-FUTURE-QR",
        "document_id": "doc-future-ecom-2027",
        "document_title": "Strategic Digital Viewport Standard: Machine-Readable QR Synchronization (Scheduled 2027)",
        "rule_family": "Legal Metrology (Packaged Commodities) Rules",
        "rule_number": "Rule 6(12) [Scheduled]",
        "title": "Dynamic Machine-Readable QR Synchronization for E-Commerce",
        "requirement_summary": "Future scheduled requirement mandating digital viewports on e-commerce platforms to embed verifiable machine-readable QR payloads resolving directly to the manufacturer's verified statutory registry. Scheduled for future enforcement on 1 July 2027.",
        "subject": "Automated Digital Verification Standard",
        "applicability": "E-commerce platforms and digital aggregators.",
        "source_reference": "Draft Rule 6(12), G.S.R. 889",
        "version": "2027.PROPOSED",
        "publication_date": "2026-09-10T00:00:00Z",
        "effective_from": "2027-07-01T00:00:00Z",
        "effective_to": None,
        "status": "NOT_YET_EFFECTIVE",
        "mapped_rule_engine_id": None,
        "mapped_rule_engine_code": None,
        "is_automated": False,
        "official_url": "https://consumeraffairs.gov.in/pages/latest-news"
    }
]

def get_statutory_summary() -> Dict[str, Any]:
    active_count = sum(1 for r in OFFICIAL_STATUTORY_RULES if r["status"] == "ACTIVE")
    future_count = sum(1 for r in OFFICIAL_STATUTORY_RULES if r["status"] == "NOT_YET_EFFECTIVE")
    amend_count = sum(1 for d in OFFICIAL_STATUTORY_DOCUMENTS if d["document_type"] == "GAZETTE_AMENDMENT")
    mapped_count = sum(1 for r in OFFICIAL_STATUTORY_RULES if r["is_automated"])

    return {
        "total_documents": len(OFFICIAL_STATUTORY_DOCUMENTS),
        "active_rules": active_count,
        "total_rules": len(OFFICIAL_STATUTORY_RULES),
        "statutory_families_count": len(STATUTORY_FAMILIES),
        "amendments_count": amend_count,
        "future_effective_count": future_count,
        "mapped_to_engine_count": mapped_count
    }

def list_statutory_documents(
    doc_type: Optional[str] = None,
    status: Optional[str] = None,
    family: Optional[str] = None,
    search: Optional[str] = None
) -> List[Dict[str, Any]]:
    results = copy.deepcopy(OFFICIAL_STATUTORY_DOCUMENTS)
    if doc_type and doc_type.upper() != "ALL":
        results = [d for d in results if d["document_type"].upper() == doc_type.upper()]
    if status and status.upper() != "ALL":
        results = [d for d in results if d["status"].upper() == status.upper()]
    if family and family.upper() != "ALL":
        results = [d for d in results if family.lower() in d["rule_family"].lower()]
    if search:
        q = search.lower().strip()
        results = [
            d for d in results
            if q in d["title"].lower()
            or q in (d.get("notification_number") or "").lower()
            or q in (d.get("gazette_reference") or "").lower()
            or q in d["summary"].lower()
            or q in d["short_title"].lower()
        ]
    return results

def get_statutory_document_by_id(doc_id: str) -> Optional[Dict[str, Any]]:
    for d in OFFICIAL_STATUTORY_DOCUMENTS:
        if d["id"] == doc_id:
            doc = copy.deepcopy(d)
            # Attach child rules
            doc["rules"] = [
                copy.deepcopy(r) for r in OFFICIAL_STATUTORY_RULES if r["document_id"] == doc_id
            ]
            return doc
    return None

def list_statutory_rules(
    document_id: Optional[str] = None,
    family: Optional[str] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
    rule_code: Optional[str] = None
) -> List[Dict[str, Any]]:
    results = copy.deepcopy(OFFICIAL_STATUTORY_RULES)
    if document_id:
        results = [r for r in results if r["document_id"] == document_id]
    if family and family.upper() != "ALL":
        results = [r for r in results if family.lower() in r["rule_family"].lower()]
    if status and status.upper() != "ALL":
        results = [r for r in results if r["status"].upper() == status.upper()]
    if rule_code:
        results = [r for r in results if r["rule_code"].upper() == rule_code.upper() or (r.get("mapped_rule_engine_code") and r["mapped_rule_engine_code"].upper() == rule_code.upper())]
    if search:
        q = search.lower().strip()
        results = [
            r for r in results
            if q in r["title"].lower()
            or q in r["rule_number"].lower()
            or q in r["rule_code"].lower()
            or q in (r.get("mapped_rule_engine_code") or "").lower()
            or q in r["requirement_summary"].lower()
            or q in r["subject"].lower()
            or q in r["source_reference"].lower()
        ]
    return results

def get_statutory_rule_by_id(rule_id: str) -> Optional[Dict[str, Any]]:
    for r in OFFICIAL_STATUTORY_RULES:
        if r["id"] == rule_id or r["rule_code"] == rule_id:
            rule = copy.deepcopy(r)
            # Find parent document
            doc = next((d for d in OFFICIAL_STATUTORY_DOCUMENTS if d["id"] == rule["document_id"]), None)
            if doc:
                rule["source_document"] = copy.deepcopy(doc)
            return rule
    return None

def get_statutory_families() -> List[Dict[str, Any]]:
    return copy.deepcopy(STATUTORY_FAMILIES)

def get_statutory_traceability(code: str) -> Dict[str, Any]:
    """
    Traces any finding type, rule code (e.g. RULE-006, RULE-007, RULE-009),
    or statutory code back to its statutory rule, version, and parent legal source.
    """
    clean_code = code.strip().upper()
    # Find matching rule
    matched_rule = None
    for r in OFFICIAL_STATUTORY_RULES:
        if r["rule_code"] == clean_code or (r.get("mapped_rule_engine_code") and r["mapped_rule_engine_code"] == clean_code):
            matched_rule = copy.deepcopy(r)
            break

    # If code is like "MANDATORY_DECLARATION" or "RULE-006-COMMODITY", resolve intelligently
    if not matched_rule:
        if "006" in clean_code or "DECLARATION" in clean_code or "MRP" in clean_code:
            matched_rule = copy.deepcopy(next((r for r in OFFICIAL_STATUTORY_RULES if r["rule_code"] == "STAT-RULE-6"), None))
        elif "007" in clean_code or "FONT" in clean_code or "HEIGHT" in clean_code or "TABLE" in clean_code:
            matched_rule = copy.deepcopy(next((r for r in OFFICIAL_STATUTORY_RULES if r["rule_code"] == "STAT-RULE-7"), None))
        elif "009" in clean_code or "LEGIBILITY" in clean_code or "CONTRAST" in clean_code:
            matched_rule = copy.deepcopy(next((r for r in OFFICIAL_STATUTORY_RULES if r["rule_code"] == "STAT-RULE-9"), None))
        elif "ECOM" in clean_code:
            matched_rule = copy.deepcopy(next((r for r in OFFICIAL_STATUTORY_RULES if r["rule_code"] == "STAT-RULE-6-ECOM"), None))

    if not matched_rule:
        matched_rule = copy.deepcopy(OFFICIAL_STATUTORY_RULES[2])  # Default to Rule 6

    # Resolve parent document
    doc = next((d for d in OFFICIAL_STATUTORY_DOCUMENTS if d["id"] == matched_rule["document_id"]), None)

    chain = [
        f"Inspection Finding / Check: {clean_code}",
        f"Rule Engine Rule: {matched_rule.get('mapped_rule_engine_code') or 'Unautomated / Statutory Assessment'}",
        f"Statutory Provision: {matched_rule['rule_number']} ({matched_rule['title']})",
        f"Official Document: {doc['title'] if doc else 'Official Gazette'} (Effective: {matched_rule['effective_from'][:10]})",
        f"Source Authority: {doc['authority'] if doc else 'Ministry of Consumer Affairs'}"
    ]

    return {
        "finding_or_rule_code": clean_code,
        "statutory_rule": matched_rule,
        "rule_engine_rule": {
            "code": matched_rule.get("mapped_rule_engine_code"),
            "is_automated": matched_rule.get("is_automated", False),
            "engine_id": matched_rule.get("mapped_rule_engine_id")
        },
        "source_document": copy.deepcopy(doc) if doc else None,
        "traceability_chain": chain
    }
