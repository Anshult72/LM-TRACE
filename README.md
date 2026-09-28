<div align="center">

# LM-TRACE
### AI-Assisted Legal Metrology Inspection & Statutory Compliance Platform

*A cloud-native, computer-vision and rule-engine powered platform designed to assist Legal Metrology enforcement officers in statutory label audits, e-commerce marketplace monitoring, evidence generation, and prosecution-grade compliance reporting.*

[![Platform](https://img.shields.io/badge/Platform-Flutter%20Web%20%7C%20Android%20APK-02569B?logo=flutter)](https://flutter.dev)
[![Backend](https://img.shields.io/badge/Backend-FastAPI%20%7C%20Python%203.11-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Database](https://img.shields.io/badge/Database-Neon%20PostgreSQL-00E599?logo=postgresql)](https://neon.tech)
[![Object Storage](https://img.shields.io/badge/Evidence%20Storage-Cloudinary%20CDN-3448C5?logo=cloudinary)](https://cloudinary.com)
[![Deployment](https://img.shields.io/badge/Deployment-Railway%20%2B%20Vercel-black?logo=vercel)](https://vercel.com)
[![Statutory Framework](https://img.shields.io/badge/Framework-Legal%20Metrology%20Act%202009-1E3A8A)](https://consumeraffairs.nic.in)

[Live Web Application](https://maanak-nu.vercel.app) • [Production API Documentation](https://maanak-production.up.railway.app/docs) • [API Health Status](https://maanak-production.up.railway.app/health)

</div>

---

## Table of Contents

1. [Project Title](#1-project-title)
2. [Project Overview](#2-project-overview)
3. [Problem Statement](#3-problem-statement)
4. [Solution](#4-solution)
5. [Key Features](#5-key-features)
6. [System Architecture](#6-system-architecture)
7. [Technology Stack](#7-technology-stack)
8. [Inspection Workflow](#8-inspection-workflow)
9. [Required Image Validation](#9-required-image-validation)
10. [AI & Intelligence Layer](#10-ai--intelligence-layer)
11. [Evidence Generation & Provenance](#11-evidence-generation--provenance)
12. [Legal Metrology Rule Registry](#12-legal-metrology-rule-registry)
13. [Role-Based Access Control (RBAC)](#13-role-based-access-control-rbac)
14. [Admin-Only Delete Inspection](#14-admin-only-delete-inspection)
15. [Enforcement Dashboard](#15-enforcement-dashboard)
16. [Reporting (PDF & DOCX)](#16-reporting-pdf--docx)
17. [Cloud Storage & CDN (Cloudinary)](#17-cloud-storage--cdn-cloudinary)
18. [Database Schema & Entities](#18-database-schema--entities)
19. [API Reference](#19-api-reference)
20. [Repository Structure](#20-repository-structure)
21. [Installation & Local Setup](#21-installation--local-setup)
22. [Environment Variables](#22-environment-variables)
23. [Running the Application](#23-running-the-application)
24. [Deployment Architecture](#24-deployment-architecture)
25. [Application Interface & Workflows](#25-application-interface--workflows)
26. [Live Demo & Test Credentials](#26-live-demo--test-credentials)
27. [Security & Compliance Architecture](#27-security--compliance-architecture)
28. [Future Scope](#28-future-scope)
29. [Team & Credits](#29-team--credits)
30. [License](#30-license)

---

## 1. Project Title

**LM-TRACE** — *Legal Metrology Traceability, Regulatory Analysis & Compliance Engine*

---

## 2. Project Overview

**LM-TRACE** is an enterprise-grade Legal Metrology inspection and compliance automation platform built to assist government enforcement officers, state controllers, and inspectors in monitoring packaged commodities. Developed according to the statutory provisions of the **Legal Metrology Act, 2009** and the **Legal Metrology (Packaged Commodities) Rules, 2011**, LM-TRACE transforms time-consuming manual field audits into standardized, defensible, evidence-backed inspection records.

### Who Uses LM-TRACE?
- **Legal Metrology Field Inspectors**: Conduct on-site retail and warehouse audits, capture standardized multi-surface photos, run automated OCR and CV checks, verify declaration correctness, and issue findings.
- **Supervisors & Assistant Controllers**: Oversee district-wide inspection queues, evaluate borderline reviews, track non-compliant commodities, and monitor enforcement performance.
- **System Administrators**: Manage user access, configure statutory rule versions and amendments, review audit trails, and maintain statutory references.
- **E-Commerce Compliance Teams**: Audit digital marketplace product pages against mandatory online disclosure requirements (Rule 6(10) / Rule 49).

### Why LM-TRACE Matters
Consumer packaging laws mandate explicit declaration standards—including manufacturer details, net weight/volume, Maximum Retail Price (MRP), Unit Sale Price (USP), consumer care coordinates, date of manufacture/import, and strict font height-to-surface-area proportions. Manual checking with rulers and magnifying sheets in retail stores is prone to human error, inconsistent measurements, and lack of reproducible evidence in court. LM-TRACE introduces algorithmic precision, visual calibration, cryptographic evidence hashing, and tamper-evident audit logging.

---

## 3. Problem Statement

Field enforcement of Legal Metrology regulations faces critical practical challenges:

1. **Subjective Font Size & Proportion Measurement**: Rule 7 Table-I mandates exact minimum numeral and letter heights (from 1.0 mm up to 6.0 mm) depending on Principal Display Panel (PDP) surface area, alongside a mandatory 1/3 character width-to-height ratio (Rule 9(1)(b)). Inspectors cannot reliably measure millimeter fractions on curved, flexible, or reflective packaging by eye.
2. **Missing & Fragmented Declarations**: Packaged products frequently split mandatory disclosures across front, back, top, bottom, and side panels. Incomplete inspections risk overlooking mandatory items (e.g., absence of consumer care email, incomplete importer address, or missing country of origin).
3. **Misleading Pricing & Unit Sale Price Violations**: Dual MRP declarations, missing "inclusive of all taxes" statements, and missing or mathematically inconsistent Unit Sale Prices (USP per g, kg, ml, or piece) are widespread in retail and online marketplaces.
4. **Weak Evidentiary Chains**: Traditional inspection memos rely on handwritten notes and uncalibrated phone snapshots that struggle to withstand legal scrutiny when challenged by corporate legal teams.
5. **E-Commerce Blind Spots**: Millions of stock-keeping units (SKUs) sold on digital platforms fail to display mandatory pre-packaged declarations before purchase, presenting an enforcement challenge beyond manual monitoring capacity.

---

## 4. Solution

LM-TRACE addresses these challenges through a closed-loop digital inspection pipeline:

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ 1. Capture      │       │ 2. Validate     │       │ 3. Extract      │
│ Multi-Surface   │ ────> │ Surface Rules   │ ────> │ High-Precision  │
│ Package Photos  │       │ (Strict Gate)   │       │ OCR Text Blocks │
└─────────────────┘       └─────────────────┘       └─────────────────┘
                                                             │
                                                             ▼
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ 6. Defensible   │       │ 5. Deterministic│       │ 4. Computer     │
│ Evidence & Docs │ <──── │ Legal Engine    │ <──── │ Vision & Scale  │
│ (Cloudinary/PDF)│       │ (Rule 6,7,8,9)  │       │ (px/mm & PDP)   │
└─────────────────┘       └─────────────────┘       └─────────────────┘
```

- **Structured Surface Capture**: Guarantees that inspections capture all required package faces before automated analysis is permitted.
- **Two-Point Optical Calibration**: Allows inspectors to calibrate physical dimensions against a reference marker or ruler, deriving exact `pixels_per_millimeter` scale factors.
- **Hybrid OCR & LLM Semantic Normalization**: Combines optical character extraction with structured LLM normalization to identify manufacturer, packer, importer, net quantity, MRP, dates, and consumer helpline coordinates.
- **Automated Rule 7 & Rule 9 Computer Vision**: Analyzes lower-quartile character geometry, inter-quartile range (IQR) stability, text-background contrast ratios, Laplacian blur variance, and aspect ratios.
- **Cryptographic Evidence Archival**: Crops every declaration with bounding boxes, computes SHA-256 digests, and stores immutable evidence on Cloudinary.
- **Dual Prosecution Reports**: Generates formal, tamper-evident inspection reports in both PDF (via ReportLab / Flutter) and editable DOCX formats.

---

## 5. Key Features

Every feature listed below is fully implemented and accessible within the current repository:

### Field & Digital Inspection
- **New Inspection Case Workflow**: Create physical retail or wholesale inspection records with unique auto-generated codes (`INS-2026-XXXXX`), officer ID, establishment details, location, and packaging construction types.
- **Direct Scan Mode**: Fast-track inspection flow directly from camera or file picker into surface capture.
- **Required Image Surface Validation**: Authoritative enforcement that analysis cannot start until all required package surfaces (`FRONT`, `BACK`, `SIDE`, `MRP_AREA`) are captured.
- **Online E-Commerce Listing Audit**: Input public e-commerce listing URLs with Server-Side Request Forgery (SSRF) protection; extracts JSON-LD, metadata, and product specs, or evaluates screenshot uploads under Rule 49 / Rule 6(10).

### Computer Vision & Measurement Engine
- **Image Quality Diagnostics**: Computes Laplacian blur variance, standard deviation contrast scores, brightness histograms, glare ratios, and shadow ratios with automated retake advisories.
- **2-Point Measurement Calibration**: Interactive canvas tool allowing inspectors to set known physical distances (e.g., ruler markings) to derive persistent `pixels_per_mm`.
- **Principal Display Panel (PDP) Area Calculation**: Computes square centimeter areas for rectangular and cylindrical packaging to determine statutory thresholds.
- **Rule 7 Table-I Numeral Height Verification**: Measures connected components with IQR outlier rejection to verify minimum character heights across five statutory PDP tiers ($\le 50\text{ cm}^2$ up to $> 2500\text{ cm}^2$).
- **Character Proportion Verification**: Evaluates mandatory 1/3 character width-to-height ratios under Rule 9(1)(b), automatically exempting tall/narrow glyphs (`1`, `I`, `i`, `l`).
- **Readability & Contrast Evaluation**: Evaluates text-to-background tonal separation via percentile dynamic range ($P_{95} - P_{05}$) and Canny edge density.

### Legal Metrology Rule & Compliance Engine
- **Statutory Rule Registry**: Centralized catalog of statutory rules with code, legal reference, category, active status, effective dates, thresholds, and conditions.
- **Rule Categories Supported**:
  - `DECLARATIONS` (Rule 6(1) mandatory commodity statements)
  - `PDP_FONT_SIZE` (Rule 7 Table-I numeral & letter heights)
  - `MRP` (Rule 6(1)(e) inclusive-of-taxes & Rule 6(11) Unit Sale Price)
  - `E_COMMERCE` (Rule 49 / Rule 6(10) marketplace disclosures)
  - `OTHER` (Rule 8 PDP placement, Rule 9 prominence and contrast)
- **Rule Versioning & Amendment History**: Tracks version numbers (`1.0`, `2.0`), draft/active/superseded lifecycles, and formal Gazette amendment logs.
- **Deterministic Compliance Matrix**: Categorizes each statutory parameter as `PASS`, `REVIEW`, `POTENTIAL_VIOLATION`, or `UNVERIFIED` (never fabricating passes on uncalibrated data).
- **Declaration Correctness & Cross-Check**: Validates net quantity units against Schedule-II standards and cross-verifies Unit Sale Price against declared MRP and net weight.

### Evidence & Product Intelligence
- **Cropped & Annotated Evidence**: Generates targeted crops of every declaration bounding box, annotated boundary overlays, and Rule 7 measurement crops.
- **Cloudinary Evidence Storage**: Uploads preprocessed evidence images over secure HTTPS with cryptographic SHA-256 checksums, etags, and metadata.
- **Product Identity Fingerprint**: Computes deterministic SHA-256 hashes of immutable product attributes (`brand`, `name`, `manufacturer`, `category`, `net_quantity`, `barcode`), filtering out volatile fields like dates and prices.
- **Label Change Detection**: Maintains multi-version label histories (`LabelVersion`) per product, detecting changes in MRP, net quantity, manufacturer declarations, or visual layouts across recurring audits.
- **Reference Library**: Searchable benchmark database of verified compliant product packaging for inspector reference.

### Role-Based Access Control & Governance
- **Three-Tier User Hierarchy**: Dedicated operational interfaces and privileges for `INSPECTOR`, `SUPERVISOR`, and `ADMIN`.
- **Strict Admin-Only Delete Inspection**: Complete UI suppression and backend HTTP 403 authorization rejecting non-admin attempts; performs cascading database cleanup, removes Cloudinary evidence assets, and logs audit events.
- **Immutable Audit Trail**: Authoritative event logging recording actor ID, name, role, action, resource, timestamp, and before/after payloads for all system operations.
- **Comprehensive Dashboards**:
  - *Executive Summary*: Total audited, statutory pass rate, active violations count, category compliance breakdown, monthly trends, and rule health monitor.
  - *Inspector Dashboard*: Daily audit queue, action-required reviews, and recent inspections.
  - *Supervisor Dashboard*: Team-wide inspection metrics, escalation queue, and repeated violation alerts.
  - *Admin Dashboard*: System health, engine readiness, user counts, rule registries, and audit logs.
- **Formal Reporting**: Server-side ReportLab PDF generation, client-side Flutter dynamic A4 PDF rendering, and structured DOCX export for court-ready enforcement filings.

---

## 6. System Architecture

The following diagram illustrates the production architecture implemented across Flutter Web, FastAPI, Neon PostgreSQL, Cloudinary, and AI services:

```mermaid
graph TD
    subgraph Client ["Client Presentation Layer (Flutter 3.x)"]
        UI_Web["Flutter Web (Canvaskit / HTML5 SPA) - Hosted on Vercel"]
        UI_Mob["Flutter Android Native APK"]
        Router["GoRouter (Clean URLs & Route Guards)"]
        State["Riverpod State Management"]
        UI_Web --> Router --> State
        UI_Mob --> Router --> State
    end

    subgraph API_GW ["Backend Application Layer (FastAPI on Railway)"]
        FastAPI["FastAPI 0.115 Engine (ASGI / Uvicorn)"]
        AuthMid["JWT Auth & RBAC Middleware"]
        AuditMid["Authoritative Audit Logger"]
        CORS["CORS Policy Engine (Vercel Origins)"]
        FastAPI --> CORS --> AuthMid --> AuditMid
    end

    State -- "HTTPS REST / JSON (Bearer JWT)" --> FastAPI

    subgraph Engines ["Core Analytical & Rule Processing Engines"]
        SurfVal["Surface Validator (4 Required Surfaces Gate)"]
        OCR_Serv["OCR Engine (Groq Vision / PaddleOCR / Mock)"]
        LLM_Norm["LLM Semantic Normalizer (Groq Qwen 27B / Gemini)"]
        CV_Engine["OpenCV Engine (Laplacian Blur, Contrast, Edge Density)"]
        Calib_Engine["Calibration & Scale Engine (px/mm, PDP Area cm²)"]
        Rule_Engine["Statutory Rule Engine (Versioned Gazette Rules)"]
        Comp_Engine["Compliance Engine (Deterministic Statutory Matrix)"]
        Evid_Engine["Evidence Generator (SHA-256 & Bounding Crops)"]
        Doc_Gen["Report Generator (ReportLab PDF & python-docx)"]

        AuditMid --> SurfVal
        SurfVal --> OCR_Serv --> LLM_Norm --> Comp_Engine
        SurfVal --> CV_Engine --> Calib_Engine --> Comp_Engine
        Rule_Engine --> Comp_Engine
        Comp_Engine --> Evid_Engine --> Doc_Gen
    end

    subgraph Persistence ["Data & Storage Layer"]
        NeonDB[("Neon Serverless PostgreSQL (SQLAlchemy 2.0 AsyncPG)")]
        Cloudinary[("Cloudinary Object Storage (Evidence Assets CDN)")]
        LocalVol[("Local / Temporary Volume (Storage Fallback)")]

        FastAPI --> NeonDB
        Evid_Engine --> Cloudinary
        Doc_Gen --> LocalVol
    end
```

---

## 7. Technology Stack

| Layer | Technology | Version | Purpose in LM-TRACE |
|---|---|---|---|
| **Frontend Framework** | Flutter Web & Mobile | 3.x (SDK ^3.11.5) | Cross-platform responsive client application |
| **State Management** | Riverpod | ^2.5.1 | Reactive state, dependency injection, and auth caching |
| **Client Routing** | GoRouter | ^14.2.0 | Declarative URL routing, web navigation, and route guards |
| **HTTP Client** | Dio | ^5.5.0 | Backend communication, JWT interception, and multi-part upload |
| **Backend Framework** | FastAPI | >= 0.115.0 | High-performance asynchronous REST API framework |
| **ASGI Server** | Uvicorn | >= 0.30.0 | Production ASGI HTTP server |
| **Database** | PostgreSQL (Neon) | Serverless v16 | Primary relational persistence store |
| **Database ORM** | SQLAlchemy | >= 2.0.30 | Asynchronous ORM utilizing `asyncpg` driver |
| **Migrations** | Alembic | >= 1.13.0 | Schema migration and version tracking |
| **Authentication** | PyJWT + Pwdlib [Argon2] | PyJWT 2.9, Argon2 | Cryptographic password hashing and JWT issuance |
| **Computer Vision** | OpenCV Headless + NumPy | OpenCV 4.10, NumPy 1.26 | Laplacian blur, contrast, connected components, and character geometry |
| **Image Processing** | Pillow (PIL) | >= 10.4.0 | High-fidelity bounding box cropping, format conversion, and byte buffers |
| **AI / Vision OCR** | Groq SDK | >= 0.31.0 | Fast Vision OCR (`qwen/qwen3.8-27b`) and declaration structuring |
| **AI Fallback** | Google Generative AI | Gemini 2.5 Flash Lite | Optional alternative multimodal extraction provider |
| **Local OCR** | PaddleOCR | Latest stable | On-device / container-based optical character recognition |
| **Cloud Object Storage** | Cloudinary Python SDK | >= 1.41.0 | Permanent evidence asset storage, CDN delivery, and SHA-256 tracking |
| **PDF Reporting** | ReportLab + Printing | ReportLab >= 4.0.0 | Server-side and client-side A4 prosecution-grade PDF generation |
| **DOCX Reporting** | python-docx | >= 1.1.2 | Editable inspection document generation for court proceedings |
| **Frontend Hosting** | Vercel | Production | Static global CDN hosting with SPA rewrite rules |
| **Backend Hosting** | Railway | Production Docker | Containerized FastAPI host with health monitoring |

---

## 8. Inspection Workflow

The operational life-cycle of an inspection in LM-TRACE follows an enforcement sequence designed to prevent incomplete or unverified violation reports:

```
[Start Inspection] ──> [Upload 4 Required Surfaces] ──> [Required Surfaces Gate]
                                                                │
                                      ┌─────────────────────────┘
                                      ▼
                        [Optional Scale Calibration]
                                      │
                                      ▼
                      [Run Automated AI/CV Pipeline]
                         ├── Step 1: OCR Extraction
                         ├── Step 2: Semantic Normalization
                         ├── Step 3: Correctness Evaluation
                         ├── Step 4: Rule Version Resolution
                         ├── Step 5: CV Readability & Font Sizing
                         └── Step 6: Deterministic Compliance Matrix
                                      │
                                      ▼
                      [Inspector Review & Verification]
                         ├── Verify/Edit Declarations
                         └── Confirm/Reject Violations & Add Comments
                                      │
                                      ▼
                       [Finalize Inspection Case]
                                      │
                                      ▼
                      [Export Certified PDF / DOCX Reports]
```

### Detailed Workflow Stages:
1. **Creation**: Inspector initiates a case, specifying establishment name, address, product category (e.g., *Packaged Food*, *Cosmetics*, *Electronics*), and package construction (e.g., *Normal* vs. *Blown/Formed/Molded*).
2. **Surface Upload**: Inspector captures or selects photos for all required package sides.
3. **Validation Gate**: The backend evaluates `validate_inspection_surfaces()`. If any required surface is missing, analysis is rejected with `HTTP 400 REQUIRED_IMAGES_MISSING`.
4. **Calibration (Optional but Recommended)**: If statutory font size validation is needed, inspector calibrates image scale using a 2-point reference tool.
5. **Execution of AI/CV Pipeline**:
   - OCR extracts raw text with coordinates across all images.
   - LLM groups extracted text blocks into statutory declaration fields.
   - Correctness engine cross-validates dates, net quantity units, and price expressions.
   - Computer vision measures character geometry and text contrast.
   - Rule engine applies active statutory thresholds.
   - Compliance engine compiles findings.
6. **Officer Review**: Inspector inspects each flagged item, reviews bounding-box crops, confirms or overrides AI findings, and logs official remarks.
7. **Finalization**: Case status transitions to `FINALIZED`. Overall compliance score and findings are locked to preserve evidence integrity.
8. **Report Issuance**: Certified PDF and DOCX reports are generated with cryptographic digests.

---

## 9. Required Image Validation

To prevent incomplete inspections from producing premature violation claims, LM-TRACE enforces a **multi-surface inspection gate**.

### Authoritative Surface Configuration
Configured in `app/services/inspection/surface_validator.py`:

| Surface Code | Surface Name | Statutory Significance | Status |
|---|---|---|---|
| `FRONT` | **Front (PDP)** | Principal Display Panel: Commodity name, brand, net quantity | **MANDATORY** |
| `BACK` | **Back (Declarations)** | Detailed statutory declarations: Manufacturer, packer, ingredient list | **MANDATORY** |
| `SIDE` | **Side (Consumer Care)** | Consumer grievance officer contact, email, telephone, website | **MANDATORY** |
| `MRP_AREA` | **MRP & Date Stamp** | Maximum Retail Price, Unit Sale Price, Date of Packing/Mfg/Import | **MANDATORY** |
| `OUTER_WRAPPER` | Outer Wrapper | Secondary packaging declarations when primary container is opaque | *OPTIONAL* |
| `INNER_PACKAGE` | Inner Retail Package | Constituent retail packaging units | *OPTIONAL* |

### Gate Enforcement Rules
- An inspection image is accepted only if it contains a verified image file on disk, a valid base64 payload, or a positive file size.
- **Analysis Execution Lock**: When `POST /api/inspections/{id}/analyze` is invoked, the engine checks:
  ```json
  {
    "valid": false,
    "required_count": 4,
    "completed_count": 2,
    "missing_surfaces": ["Side (Consumer Care)", "MRP & Date Stamp"],
    "completed_surfaces": ["Front (PDP)", "Back (Declarations)"]
  }
  ```
- If `valid == false`, the engine raises `HTTP 400` with detailed missing surface details. **No OCR, CV, or LLM tokens are consumed until all 4 surfaces are uploaded.**

---

## 10. AI & Intelligence Layer

LM-TRACE enforces a clear architectural separation across its analytical components:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            AI & INTELLIGENCE STACK                          │
├───────────────────────┬─────────────────────────────────────────────────────┤
│ Component             │ Core Technical Responsibility                       │
├───────────────────────┼─────────────────────────────────────────────────────┤
│ 1. OCR Engine         │ "What text is physically printed on the package?"   │
│ 2. Computer Vision    │ "Where and how does the text visually appear?"      │
│ 3. LLM Normalizer     │ "What is the semantic meaning of extracted text?"   │
│ 4. Rule Engine        │ "What exact legal clause and threshold applies?"    │
│ 5. Compliance Engine  │ "Is the statutory legal requirement satisfied?"     │
└───────────────────────┴─────────────────────────────────────────────────────┘
```

### Detailed Functional Breakdown

#### 1. OCR Engine (Optical Character Recognition)
- **Providers**: Groq Vision API (`qwen/qwen3.8-27b`), PaddleOCR local runtime, or Gemini Vision.
- **Output**: Raw string content, block IDs (`blk-01`, `blk-02`), spatial coordinates (`x`, `y`, `width`, `height`), and detection confidence scores.

#### 2. Computer Vision Engine (`OpenCvVisionService` & `PdpMeasurementService`)
- **Image Quality**: Assesses Laplacian blur variance ($\text{var} < 80$ triggers blur warning), lighting bounds ($40 \le \mu \le 230$), and contrast standard deviation.
- **Character Geometry**: Uses morphological operators and connected component segmentation with IQR filtering to isolate lower-quartile character height ($H_{25}$) and width ($W_{25}$).
- **Proportion Check**: Computes character width-to-height ratio ($W / H \ge 0.333$) under Rule 9(1)(b), with automatic exemption for narrow glyphs (`1`, `i`, `I`, `l`).
- **Readability & Contrast**: Computes dynamic range ($P_{95} - P_{05}$), glare ratio ($> 248$), and shadow ratio ($< 12$) to flag unreadable or washed-out labels.
- **Zero Fabrication Rule**: If physical scale calibration is not performed, character height in millimeters is marked `UNVERIFIED` rather than guessing physical dimensions from unscaled pixels.

#### 3. LLM Normalizer (`GroqLlmService` / `GeminiLlmService`)
- Converts fragmented OCR blocks into structured Legal Metrology declaration entities:
  - Commodity name and product category
  - Manufacturer / Packer / Importer name and postal address
  - Net weight/volume and standardized unit (e.g., `g`, `kg`, `ml`, `l`)
  - MRP (numeric value) and currency
  - Unit Sale Price (USP) and reference unit
  - Month and year of manufacture/packaging
  - Consumer helpline telephone and email
  - Country of origin (Rule 6(1)(n))
- Maintains provenance pointers mapping each normalized declaration back to its source OCR block ID.

#### 4. Rule Engine (`RuleEngine`)
- Retrieves active Gazette rules from the database matching commodity type and packaging construction.
- Resolves Rule 7 Table-I minimum character height thresholds based on calculated PDP area:
  - $\text{Area} \le 50\text{ cm}^2 \implies 1.0\text{ mm}$ (Normal) / $2.0\text{ mm}$ (Blown/Molded)
  - $50 < \text{Area} \le 100\text{ cm}^2 \implies 1.5\text{ mm}$ (Normal) / $3.0\text{ mm}$ (Blown/Molded)
  - $100 < \text{Area} \le 500\text{ cm}^2 \implies 2.5\text{ mm}$ (Normal) / $4.0\text{ mm}$ (Blown/Molded)
  - $500 < \text{Area} \le 2500\text{ cm}^2 \implies 4.0\text{ mm}$ (Normal) / $6.0\text{ mm}$ (Blown/Molded)
  - $\text{Area} > 2500\text{ cm}^2 \implies 6.0\text{ mm}$ (Normal) / $6.0\text{ mm}$ (Blown/Molded)

#### 5. Compliance Engine (`ComplianceEngine`)
- Compares normalized declaration values against statutory requirements.
- Performs cross-field validation:
  - Evaluates whether net quantity unit complies with Schedule-II prescribed units.
  - Verifies whether Unit Sale Price matches declared MRP divided by net quantity.
  - Flags declarations missing "inclusive of all taxes" wording.
- Assigns deterministic statuses (`PASS`, `REVIEW`, `POTENTIAL_VIOLATION`, `UNVERIFIED`) and generates statutory explanations with legal citations.

---

## 11. Evidence Generation & Provenance

LM-TRACE treats evidence generation as a court-admissible audit chain:

```
[Raw Image Upload]
       │
       ▼
[Bounding Box Extraction (OCR / CV)]
       │
       ▼
[High-Fidelity Crop Generation (Pillow/OpenCV)]
       │
       ▼
[Cryptographic SHA-256 Checksum Calculation]
       │
       ▼
[Secure Cloudinary CDN Upload (lm_trace/evidence)]
       │
       ▼
[Neon DB Evidence Record Persistence] ──> [Linked to Finding ID & Compliance Check]
```

### Evidence Characteristics:
- **Evidence Types**: `OCR_CROP`, `DECLARATION_CROP`, `MRP_CROP`, `FONT_SIZE_CROP`, `READABILITY_CROP`, `PLACEMENT_CROP`, `ANNOTATED_OVERLAY`, `VIOLATION_EVIDENCE`, and `MANUAL_EVIDENCE`.
- **Integrity Digest**: Every crop calculates a SHA-256 digest (`sha256 = hashlib.sha256(crop_bytes).hexdigest()`) before upload. The digest is stored in the database and printed on inspection reports for tamper verification.
- **Cloudinary Metadata**: Records `cloudinary_public_id`, `cloudinary_secure_url`, image dimensions, format, byte size, and etag.
- **Relational Linkage**: Every evidence record maps to an `inspection_id`, `image_id`, and `finding_id`, allowing inspectors and judges to click from any violation directly to its source visual crop.

---

## 12. Legal Metrology Rule Registry

Statutory rules in LM-TRACE are not hardcoded if-statements; they are managed through a version-controlled **Statutory Rule Registry**:

### Implemented Rule Registry Structure
- **Rule Code**: Unique identifier (e.g., `RULE-006-COMMODITY`, `RULE-007-CHAR-HEIGHT`, `RULE-007-CHAR-RATIO`, `RULE-008-PLACEMENT`, `RULE-009-LEGIBILITY`, `RULE-MRP-INCLUSIVE`, `RULE-USP-MANDATORY`, `RULE-049-ECOMMERCE`).
- **Statutory Reference**: Official citation (e.g., *Rule 6(1), Legal Metrology (Packaged Commodities) Rules, 2011*).
- **Rule Categories**:
  - `DECLARATIONS`
  - `PDP_FONT_SIZE`
  - `MRP`
  - `E_COMMERCE`
  - `OTHER`
- **Rule Versioning**: Tracks versions (`1.0`, `2.0`), publication dates, effective dates (`effective_from`, `effective_to`), and status (`ACTIVE`, `SUPERSEDED`, `DRAFT`, `PENDING_REVIEW`).
- **Gazette Amendment Tracking**: Links to official Gazette notifications, recording amendment type (`TEXTUAL`, `THRESHOLD`, `E_COMMERCE`, `CLARIFICATION`), summary, and source URL.
- **Statutory Rule Coverage Matrix**: Accessible via `/api/rules/coverage`, reporting the operational coverage status (`FULLY_IMPLEMENTED`, `PARTIALLY_IMPLEMENTED`, `NOT_COVERED`) for each rule family.

---

## 13. Role-Based Access Control (RBAC)

The application enforces a three-tier role hierarchy validated on both the Flutter client and the FastAPI backend:

| Capability / Resource | Inspector (`INSPECTOR`) | Supervisor (`SUPERVISOR`) | Administrator (`ADMIN`) |
|---|:---:|:---:|:---:|
| Create & Conduct Inspections | Yes | Yes | Yes |
| Upload & Calibrate Package Photos | Yes | Yes | Yes |
| Execute AI / OCR / CV Analysis | Yes | Yes | Yes |
| Verify & Edit Declaration Findings | Yes | Yes | Yes |
| Finalize Inspection Cases | Yes | Yes | Yes |
| Download PDF & DOCX Reports | Yes | Yes | Yes |
| Run E-Commerce Listing Audits | Yes | Yes | Yes |
| View Personal Inspection Queue | Yes | Yes | Yes |
| View Team-Wide Inspection Queues | No | Yes | Yes |
| Access Supervisor Escalation Queue | No | Yes | Yes |
| Manage Statutory Rules & Versions | No | No | Yes |
| Approve Draft Rule Amendments | No | No | Yes |
| View System Health & User Audits | No | No | Yes |
| **Delete Inspection Case** | **NO** | **NO** | **YES (Strict)** |

---

## 14. Admin-Only Delete Inspection

The deletion of statutory inspection records is restricted to administrators to prevent tampering with active enforcement cases.

```
Inspector / Supervisor                          Administrator
        │                                             │
        ▼                                             ▼
  [Delete Action]                             [Delete Action]
  (Button is NOT rendered                     (Red Trash Icon & Tooltip
   in Web UI or Native App)                    rendered in list & detail)
        │                                             │
        ▼                                             ▼
  [Direct API Call Attempt]                   [Confirmation Modal Dialog]
  DELETE /api/inspections/{id}                Prompt: Enter confirmation
        │                                             │
        ▼                                             ▼
  [Backend RBAC Middleware]                   [Backend RBAC Middleware]
  Checks JWT: role != "ADMIN"                 Checks JWT: role == "ADMIN"
        │                                             │
        ▼                                             ▼
  [HTTP 403 FORBIDDEN]                        [Execute Cascade & Cloud Cleanup]
  "Only administrators can delete              ├── Delete dependent DB records
   inspections. Role not authorized."          ├── Delete Cloudinary assets via API
                                               ├── Remove local disk inspection folder
                                               └── Record INSPECTION_DELETED in audit log
```

### Deletion Mechanics
1. **Frontend Suppression**: The delete icon and confirmation dialog are guarded by `if (isAdmin)` in both the web and mobile UI layouts.
2. **Backend Authorization**: The API route verifies role membership:
   ```python
   user_role = (user_payload.get("role") or "").upper()
   if user_role != "ADMIN":
       raise HTTPException(
           status_code=status.HTTP_403_FORBIDDEN,
           detail={"code": "FORBIDDEN", "message": "Access denied: Only administrators can delete inspections."}
       )
   ```
3. **Cascading Relational Cleanup**: Deletes related records across `inspection_images`, `declarations`, `compliance_checks`, `violations`, `evidence`, `image_calibrations`, and `reports`.
4. **Cloud Asset Cleanup**: Retrieves all associated `cloudinary_public_id` values and calls `cloudinary.uploader.destroy()` to remove orphaned evidence assets from the cloud.
5. **Local Directory Cleanup**: Deletes the local filesystem directory for the inspection (`storage/inspections/{id}/`).
6. **Authoritative Audit Event**: Writes an immutable log entry with action `INSPECTION_DELETED`, recording the administrator's ID, name, inspection code, and deletion timestamp.

---

## 15. Enforcement Dashboard

The dashboard provides real-time operational data computed dynamically from database records:

### Implemented Dashboard Metrics & Views (`/api/dashboard/summary`)
- **Total Audited Cases**: Count of finalized and archived inspection records.
- **Statutory Compliance Rate**: Percentage of passed checks across decided parameters, backed by subtitles indicating total checks evaluated.
- **Active Violations Flagged**: Live count of confirmed and potential statutory violations across inspected packages.
- **Pending Review Queue**: Inspections flagged with borderline or unverified parameters requiring officer sign-off.
- **Action Required Matrix**: Real-time counter of pending reviews, active violations, unverified drafts, and detected label changes.
- **Commodity Category Breakdown**: Categorical spread (e.g., *Packaged Food*, *Cosmetics*, *Beverages*, *Cleaning Products*) showing total cases and category-specific compliance rates.
- **Statutory Rule Health**: Pass/fail breakdown across core rules:
  - `RULE-006`: Mandatory Declarations
  - `RULE-007`: Numeral & Letter Height
  - `RULE-008`: Principal Display Panel
  - `RULE-009`: Contrast & Readability
  - `RULE-049`: E-Commerce Disclosures
- **Monthly Inspection Trends**: Month-by-month compliance distribution.
- **Product Change Alert**: Highlights commodities with multiple detected label versions for visual comparison.

---

## 16. Reporting (PDF & DOCX)

LM-TRACE generates formal, court-admissible inspection records in two standard formats:

### 1. Certified PDF Report (ReportLab & Flutter)
- **Document Header**: Official title *"Legal Metrology Inspection Compliance Report"*, issuing authority, inspection code, and generation timestamp.
- **Metadata Section**: Inspector name, officer ID, establishment name, seller details, inspection date, geographic location, product name, and commodity category.
- **PDP & Calibration Record**: Calculated PDP surface area ($cm^2$), calibration status (`CALIBRATED` / `NOT_CALIBRATED`), and pixels-per-millimeter resolution.
- **Declaration Audit Table**: Full audit matrix comparing detected AI values, verified values, presence status, correctness status, and statutory results.
- **Compliance Check Summary**: Rule code, check type, tested value, statutory threshold, pass/fail result, and statutory citation.
- **Violations & Enforcement Findings**: List of potential/confirmed violations with severity (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`), AI explanations, and inspector notes.
- **Cryptographic Footprint**: SHA-256 document hash printed at the base of every page for anti-tamper verification.

### 2. Prosecution DOCX Document (`python-docx`)
- **Editable Filing Document**: Formatted in standard legal document tables, allowing enforcement legal teams to incorporate inspection findings into formal court complaints or compounding notices.
- **Embedded Evidence Imagery**: Automatically downloads evidence crops and annotated bounding boxes from Cloudinary and embeds them into finding tables.

---

## 17. Cloud Storage & CDN (Cloudinary)

Cloudinary provides permanent, tamper-resistant object storage for inspection evidence assets:

### Why Cloudinary?
Package inspection evidence must remain permanently available across years of prosecution and appeal cycles. Ephemeral server storage on cloud hosts (such as Railway or Render) discards uploaded files on redeployment. Cloudinary provides durable storage, global CDN delivery, and on-the-fly transformations.

### What is Stored on Cloudinary?
- Preprocessed declaration crops (`DECLARATION_CROP`, `MRP_CROP`)
- Numeral height measurement crops (`FONT_SIZE_CROP`)
- Annotated boundary overlays showing exact declaration positions
- Confirmed violation visual evidence

### Security Policy: Zero Secrets in Frontend
- **No Cloudinary credentials are included in the Flutter Web or mobile builds.**
- All uploads and deletions are performed server-side by the FastAPI backend using secure environment variables (`CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`).
- The frontend receives only read-only, signed CDN URLs (`https://res.cloudinary.com/...`).

---

## 18. Database Schema & Entities

The relational database is deployed on **Neon PostgreSQL** via **SQLAlchemy 2.0 AsyncPG**:

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│     users       │       │    products     │       │ legal_documents │
│ (Auth & Roles)  │       │(Commodity Info) │       │ (Gazette Acts)  │
└─────────────────┘       └─────────────────┘       └─────────────────┘
        │                         │                          │
        ▼                         ▼                          ▼
┌───────────────────────────────────────────┐       ┌─────────────────┐
│                inspections                │       │      rules      │
│     (Case Records, Calibration, PDP)      │       │ (Rule Metadata) │
└───────────────────────────────────────────┘       └─────────────────┘
        │                                                    │
        ├──────────────────────┬──────────────────────┐      ▼
        ▼                      ▼                      ▼ ┌─────────────────┐
┌───────────────┐      ┌───────────────┐      ┌───────┐ │  rule_versions  │
│inspection_    │      │ declarations  │      │reports│ │(Version & Cond) │
│images         │      │ (Audit Matrix)│      │       │ └─────────────────┘
└───────────────┘      └───────────────┘      └───────┘      │
        │                      │                             ▼
        ▼                      ▼                        ┌─────────────────┐
┌───────────────┐      ┌───────────────┐                │ rule_amendments │
│  calibrations │      │  compliance_  │ ─────────────> │(Gazette Updates)│
│ (2-pt Scale)  │      │  checks       │                └─────────────────┘
└───────────────┘      └───────────────┘
                               │
                               ▼
                       ┌───────────────┐
                       │  violations   │
                       │(Enforcement)  │
                       └───────────────┘
                               │
                               ▼
                       ┌───────────────┐
                       │   evidence    │ ──> [Cloudinary CDN Assets]
                       │(SHA-256 Crops)│
                       └───────────────┘
```

### Primary Database Tables
- **`users`**: Officer credentials, full name, officer badge ID, department, role (`INSPECTOR`, `SUPERVISOR`, `ADMIN`), active status.
- **`products`**: Commodity catalog, manufacturer/packer/importer names and addresses, standard net quantity, barcode, product identity fingerprint.
- **`inspections`**: Inspection cases, unique code, inspector ID, product ID, inspection type (`PHYSICAL`, `ONLINE_LISTING`), location, seller, status (`DRAFT`, `ANALYSING`, `NEEDS_REVIEW`, `READY`, `FINALIZED`, `ARCHIVED`), compliance score, calibration data, PDP measurement, listing URL.
- **`inspection_images`**: Multi-surface package photos, surface type (`FRONT`, `BACK`, `SIDE`, `MRP_AREA`, etc.), disk path, dimensions, quality assessment, and blur scores.
- **`declarations`**: Field name, extracted AI value, officer-verified value, confidence, bounding box coordinates, presence status, correctness status, verification status, and provenance.
- **`rules`**: Rule code, statutory citation, title, category, validation type, parameters, and coverage status.
- **`rule_versions`**: Version string, condition trees, threshold schemas, severity, Gazette publication/effective dates, and approval status.
- **`legal_documents`**: Primary Acts, statutory rules, Gazette amendments, notification numbers, and source document URLs.
- **`rule_amendments`**: Historical amendment records connecting predecessor and successor rule versions.
- **`compliance_checks`**: Evaluation results (`PASS`, `REVIEW`, `POTENTIAL_VIOLATION`, `UNVERIFIED`), input values, expected statutory conditions, and explanations.
- **`violations`**: Confirmed or AI-detected statutory infringements, severity, confidence, officer comments, confirmation status, and timestamps.
- **`evidence`**: Evidence artifacts, evidence type, bounding boxes, Cloudinary public IDs, secure CDN URLs, dimensions, file size, SHA-256 checksums, and etags.
- **`image_calibrations`**: Two-point reference calibration records, pixel distance, known metric distance, derived pixels-per-mm, image hash, and validity status.
- **`reports`**: PDF and DOCX generated report metadata, version numbers, file paths, SHA-256 hashes, and archival status.
- **`audit_logs`**: Immutable security and operational audit trail recording actor ID, name, role, action, resource, correlation ID, old/new values, and timestamps.
- **`label_versions`**: Historical record of commodity packaging labels tracking MRP, net quantity, visual hashes, and text changes across inspections.
- **`rule_coverage`**: Statutory rule family implementation coverage matrix.

---

## 19. API Reference

All routes are versioned under `/api` and require a valid Bearer JWT token (except `/api/auth/login`, `/health`, and `/ready`).

### Authentication & Profiles (`/api/auth`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `POST` | `/api/auth/login` | Public | Authenticates officer credentials; returns JWT access token |
| `GET` | `/api/auth/me` | Authenticated | Retrieves current authenticated officer profile and role |
| `POST` | `/api/auth/logout` | Authenticated | Terminates session; records `USER_LOGOUT` in audit log |

### Inspections (`/api/inspections`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `POST` | `/api/inspections` | Inspector+ | Creates a new physical or online inspection case |
| `GET` | `/api/inspections` | Inspector+ | Lists inspections with status, query, and officer filters |
| `GET` | `/api/inspections/{id}` | Inspector+ | Retrieves full inspection details and child records |
| `PATCH` | `/api/inspections/{id}` | Inspector+ | Updates inspection metadata, notes, or establishment details |
| `DELETE` | `/api/inspections/{id}` | **Admin Only** | Deletes inspection, cascades DB records, and purges Cloudinary evidence |
| `POST` | `/api/inspections/{id}/images` | Inspector+ | Uploads package photo for a designated surface type |
| `DELETE` | `/api/inspections/{id}/images/{img_id}` | Inspector+ | Deletes an uploaded surface image |
| `GET` | `/api/inspections/{id}/required-surfaces` | Inspector+ | Returns real-time 4-surface completeness validation |
| `POST` | `/api/inspections/{id}/analyze` | Inspector+ | Executes OCR, CV, LLM, Rule, and Compliance pipeline |
| `POST` | `/api/inspections/{id}/finalize` | Inspector+ | Locks inspection case, finalizes score, and seals findings |

### Declarations & Verification (`/api/declarations`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/inspections/{id}/declarations` | Inspector+ | Lists all extracted and verified declaration entities |
| `PATCH` | `/api/declarations/{id}` | Inspector+ | Updates verification status (`VERIFIED`, `REJECTED`, `EDITED`) |
| `POST` | `/api/inspections/{id}/declarations` | Inspector+ | Manually adds an inspector-observed declaration |

### Findings & Violations (`/api/findings`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/inspections/{id}/findings` | Inspector+ | Lists compliance checks and detected violations |
| `PATCH` | `/api/findings/{id}` | Inspector+ | Confirms or rejects a violation; records officer remarks |

### Reports (`/api/reports`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/reports/{id}` | Inspector+ | Retrieves generated report metadata and archival status |
| `POST` | `/api/reports/{id}/pdf` | Inspector+ | Archives client-rendered PDF with SHA-256 verification |
| `GET` | `/api/reports/{id}/pdf/download` | Inspector+ | Downloads official certified inspection PDF report |
| `POST` | `/api/reports/{id}/generate-docx` | Inspector+ | Triggers server-side DOCX prosecution report generation |
| `GET` | `/api/reports/{id}/docx/download` | Inspector+ | Downloads court-ready DOCX inspection document |
| `POST` | `/api/reports/{id}/generate-pdf` | Inspector+ | Triggers server-side ReportLab PDF generation |

### Calibration & Scale (`/api/inspections/{id}/calibrations`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/inspections/{id}/calibrations` | Inspector+ | Lists image scale calibration records |
| `GET` | `/api/inspections/{id}/calibrations/active` | Inspector+ | Gets current active calibration for PDP character checks |
| `POST` | `/api/inspections/{id}/calibrations` | Inspector+ | Records 2-point pixel measurement and known distance |
| `POST` | `/api/calibrations/preview-measurement` | Inspector+ | Computes real-time pixel-to-millimeter distance preview |

### Statutory Rule Management (`/api/rules` & `/api/legal-documents`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/rules` | Inspector+ | Lists statutory rules filtered by category and active status |
| `GET` | `/api/rules/coverage` | Inspector+ | Returns implementation coverage matrix across rule families |
| `GET` | `/api/rules/documents` | Inspector+ | Lists statutory Acts, Gazette amendments, and advisories |
| `GET` | `/api/rules/{id}` | Inspector+ | Retrieves rule details, conditions, and thresholds |
| `GET` | `/api/rules/{id}/versions` | Inspector+ | Lists complete version history for a statutory rule |
| `GET` | `/api/rules/{id}/amendments` | Inspector+ | Lists Gazette amendments associated with a rule |
| `POST` | `/api/rules` | **Admin Only** | Registers a new statutory rule definition |
| `POST` | `/api/rules/versions/{id}/approve` | **Admin Only** | Approves and activates a draft rule version |
| `GET` | `/api/legal-documents` | Inspector+ | Lists legal document library records |

### Dashboards & Analytics (`/api/dashboard`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/dashboard/summary` | Inspector+ | Returns system metrics, queues, trends, and rule health |
| `GET` | `/api/dashboard/inspector` | Inspector+ | Inspector-specific operational workload and recent cases |
| `GET` | `/api/dashboard/supervisor` | Supervisor+ | Team inspection metrics, escalation queue, and repeat cases |
| `GET` | `/api/dashboard/admin` | **Admin Only** | System health, engine readiness, counts, and recent logs |

### Audit Trail (`/api/audit-logs`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/audit-logs` | Supervisor+ | Queries immutable audit trail by actor, action, or date |

### Online E-Commerce Listings (`/api/listings`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `POST` | `/api/listings/fetch` | Inspector+ | Fetches public marketplace URL with SSRF protection |
| `POST` | `/api/listings/analyze-url` | Inspector+ | Analyzes fetched listing text for Rule 49 compliance |
| `POST` | `/api/listings/analyze-screenshot` | Inspector+ | Runs OCR and compliance audit on listing screenshots |

### Products & Intelligence (`/api/products`)
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/products` | Inspector+ | Lists registered commodities and identity fingerprints |
| `GET` | `/api/products/{id}` | Inspector+ | Retrieves product profile and historical inspection cases |
| `GET` | `/api/products/{id}/versions` | Inspector+ | Lists label version timeline for change detection |
| `GET` | `/api/products/{id}/compare` | Inspector+ | Compares two label versions to highlight declaration diffs |

### Reference Library & Statutory Summary
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/api/reference-library` | Inspector+ | Accesses compliant commodity packaging benchmark library |
| `GET` | `/api/statutory/summary` | Inspector+ | Overview of statutory framework and Gazette coverage |
| `GET` | `/api/statutory/rules` | Inspector+ | Detailed statutory rule breakdown |

### System Health
| Method | Endpoint | Access | Description |
|---|---|---|---|
| `GET` | `/health` | Public | Lightweight health monitor (Railway ping) |
| `GET` | `/ready` | Public | Readiness probe: Verifies DB connectivity and OCR ready |

---

## 20. Repository Structure

```
LM-TRACE/
├── .github/
│   └── workflows/
│       └── web-deploy.yml          # GitHub Actions CI/CD to Vercel
├── backend/
│   ├── alembic/                    # Database migration scripts
│   ├── app/
│   │   ├── api/
│   │   │   └── routes/             # FastAPI route controllers
│   │   │       ├── audit_logs.py
│   │   │       ├── auth.py
│   │   │       ├── calibrations.py
│   │   │       ├── dashboard.py
│   │   │       ├── declarations.py
│   │   │       ├── findings.py
│   │   │       ├── inspections.py  # Core inspection lifecycle & admin delete
│   │   │       ├── online_listings.py
│   │   │       ├── products.py
│   │   │       ├── reference_library.py
│   │   │       ├── reports.py
│   │   │       ├── rules.py
│   │   │       ├── settings.py
│   │   │       └── statutory.py
│   │   ├── core/                   # Security, configuration, logging, database
│   │   │   ├── config.py
│   │   │   ├── database.py
│   │   │   ├── logging.py
│   │   │   └── security.py
│   │   ├── engines/                # Compliance & rule calculation engines
│   │   │   ├── compliance_engine/
│   │   │   │   └── compliance_engine.py
│   │   │   └── rule_engine/
│   │   │       ├── condition_evaluator.py
│   │   │       └── rule_engine.py
│   │   ├── models/                 # SQLAlchemy ORM entities
│   │   │   └── entities.py
│   │   ├── repositories/           # Repository pattern (PostgreSQL & In-Memory Demo)
│   │   │   ├── in_memory_demo.py
│   │   │   ├── interfaces.py
│   │   │   └── neon_postgres.py
│   │   ├── schemas/                # Pydantic v2 domain schemas
│   │   │   └── domain.py
│   │   ├── services/               # Core business services
│   │   │   ├── analytics/          # Compliance aggregation & statistics
│   │   │   ├── audit/              # Authoritative event logging
│   │   │   ├── declaration/        # Applicability, correctness, placement
│   │   │   ├── evidence/           # Crop generation & SHA-256 hashing
│   │   │   ├── fingerprint/        # Canonical product identity hashing
│   │   │   ├── inspection/         # Surface validator (4-surface gate)
│   │   │   ├── label_change/       # Multi-version label comparison
│   │   │   ├── listing/            # E-commerce fetch & SSRF protection
│   │   │   ├── llm/                # Groq & Gemini semantic extractors
│   │   │   ├── ocr/                # Vision OCR & PaddleOCR services
│   │   │   ├── product/            # Product intelligence service
│   │   │   ├── reports/            # ReportLab PDF & python-docx generators
│   │   │   ├── storage/            # Cloudinary & local storage adapters
│   │   │   └── vision/             # OpenCV diagnostics & PDP measurement
│   │   └── main.py                 # FastAPI application factory & lifespan
│   ├── .env.example                # Backend environment template
│   ├── Dockerfile                  # Container definition for Railway
│   ├── requirements.txt            # Python dependencies
│   └── seed_data.py                # Database seeder script
├── frontend/
│   ├── assets/
│   │   └── images/logo/            # Official LM-TRACE logos and brand marks
│   ├── lib/
│   │   ├── core/                   # App theme, networking, routing, responsive shell
│   │   │   ├── constants/          # Brand constants & API endpoints
│   │   │   ├── network/            # Dio API client & auth interceptor
│   │   │   ├── responsive/         # Desktop web shell & mobile navigation
│   │   │   ├── routing/            # GoRouter configuration & route guards
│   │   │   └── theme/              # Official Legal Metrology design system
│   │   ├── features/               # Feature-based presentation modules
│   │   │   ├── about/              # Statutory references & Act details
│   │   │   ├── ai_analysis/        # Pipeline execution & progress visualizer
│   │   │   ├── audit/              # Audit trail viewer
│   │   │   ├── auth/               # Login screen & session controllers
│   │   │   ├── calibration/        # 2-point interactive calibration canvas
│   │   │   ├── dashboard/          # Enforcement metrics & queues
│   │   │   ├── evidence/           # Evidence gallery & crop viewer
│   │   │   ├── inspections/        # Inspection list, creation, detail, finalization
│   │   │   │   └── widgets/        # Delete dialog & responsive layouts
│   │   │   ├── landing/            # Public web portal & showcase
│   │   │   ├── online_listing/     # E-commerce marketplace scan
│   │   │   ├── products/           # Product registry & version diff
│   │   │   ├── profile/            # Officer credentials & badge details
│   │   │   ├── reference_library/  # Benchmark packaging reference library
│   │   │   ├── reports/            # PDF previewer & DOCX export
│   │   │   ├── rule_management/    # Rule catalog & amendment administration
│   │   │   ├── scanner/            # Multi-surface photo capture screen
│   │   │   ├── settings/           # Operational settings & preferences
│   │   │   └── supervisor/         # Supervisor team oversight screen
│   │   └── main.dart               # Flutter application entry point
│   ├── pubspec.yaml                # Flutter dependencies & metadata
│   ├── vercel.json                 # Vercel SPA routing rewrites
│   └── web/                        # Web assembly, icons, manifest
├── railway.json                    # Railway deployment configuration
├── vercel.json                     # Root Vercel configuration
├── WEB_DEPLOYMENT.md               # Production deployment manual
└── README.md                       # Comprehensive platform documentation
```

---

## 21. Installation & Local Setup

### Prerequisites
- **Git** (>= 2.38)
- **Python** (>= 3.11)
- **Flutter SDK** (>= 3.19, recommended 3.24+)
- **PostgreSQL** (Optional; project defaults to In-Memory Demo mode if `DATABASE_URL` is omitted)
- **Google Chrome** (For local Flutter Web debugging)

---

### Step 1: Clone Repository
```bash
git clone https://github.com/Anshult72/LM-TRACE.git
cd LM-TRACE
```

---

### Step 2: Backend Setup
```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows (PowerShell):
.\venv\Scripts\Activate.ps1
# Linux / macOS:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

---

### Step 3: Configure Backend Environment
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Open `.env` and configure your credentials (see [Environment Variables](#22-environment-variables) below).

*(Note: If you do not supply `DATABASE_URL`, the backend operates in Demo Data Mode using built-in mock records).*

---

### Step 4: Seed Database (Optional for PostgreSQL)
If using Neon or local PostgreSQL:
```bash
python seed_data.py
```

---

### Step 5: Frontend Setup
In a new terminal window:
```bash
cd frontend

# Fetch Flutter dependencies
flutter pub get

# Verify environment readiness
flutter doctor
```

---

## 22. Environment Variables

### Backend Configuration (`backend/.env`)

```ini
# ─── Environment & Runtime ──────────────────────────────────────────────────
APP_ENV=development
ENVIRONMENT=development
DEBUG=true
PORT=8000

# ─── Neon Serverless PostgreSQL ──────────────────────────────────────────────
# Leave blank to run in In-Memory Demo Mode with preloaded statutory test cases
DATABASE_URL=postgresql+asyncpg://USER:PASSWORD@ep-sample-pool.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
DEMO_DATA_MODE=false

# ─── AI Services (Groq) ──────────────────────────────────────────────────────
# Required for live OCR reading and LLM declaration extraction
GROQ_API_KEY=your_groq_api_key_here
GROQ_VISION_MODEL=qwen/qwen3.8-27b
GROQ_TEXT_MODEL=openai/gpt-oss-20b
MOCK_AI_MODE=false

# ─── AI Services (Google Gemini - Optional Alternative) ──────────────────────
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-2.5-flash-lite

# ─── Security & Authentication ───────────────────────────────────────────────
# Generate a strong 64-character random string for production
JWT_SECRET=replace_with_a_secure_random_jwt_secret_key_minimum_32_chars
ACCESS_TOKEN_EXPIRE_MINUTES=480

# ─── Cross-Origin Resource Sharing (CORS) ───────────────────────────────────
# Comma-separated list of permitted frontend origins
CORS_ORIGINS=http://localhost:*,http://127.0.0.1:*,https://maanak-nu.vercel.app

# ─── Local Storage ───────────────────────────────────────────────────────────
STORAGE_ROOT=storage

# ─── Cloudinary Evidence Object Storage ──────────────────────────────────────
# Cloudinary credentials for permanent evidence storage (NEVER expose to frontend)
CLOUDINARY_ENABLED=true
CLOUDINARY_CLOUD_NAME=your_cloudinary_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
CLOUDINARY_FOLDER=lm_trace/evidence
CLOUDINARY_SECURE=true
MAX_EVIDENCE_IMAGE_SIZE_MB=15
```

### Frontend Configuration (Flutter `--dart-define`)
The Flutter Web and mobile applications require no local `.env` files. Connection parameters are passed at build or launch time:

| Parameter | Default Value | Description |
|---|---|---|
| `API_BASE_URL` | `https://maanak-production.up.railway.app` | Target backend REST API URL |

---

## 23. Running the Application

### 1. Launch FastAPI Backend
From the `backend/` directory with virtual environment activated:
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
- API root: `http://localhost:8000`
- Swagger UI Documentation: `http://localhost:8000/docs`
- ReDoc Documentation: `http://localhost:8000/redoc`
- Health probe: `http://localhost:8000/health`

### 2. Launch Flutter Web Application
From the `frontend/` directory:

```bash
# Connect to local FastAPI backend
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000

# OR connect to production Railway backend
flutter run -d chrome --dart-define=API_BASE_URL=https://maanak-production.up.railway.app
```

### 3. Run on Physical Android Device
```bash
# Connect device via USB debugging
flutter run -d android --dart-define=API_BASE_URL=https://maanak-production.up.railway.app
```

### 4. Build Production Artifacts
```bash
# Generate release Web bundle
flutter build web --release --dart-define=API_BASE_URL=https://maanak-production.up.railway.app
# Output located at: frontend/build/web/

# Generate release Android APK
flutter build apk --release --dart-define=API_BASE_URL=https://maanak-production.up.railway.app
# Output located at: frontend/build/app/outputs/flutter-apk/app-release.apk
```

---

## 24. Deployment Architecture

The production environment separates client presentation from compute and persistence:

```
┌────────────────────────────────────────────────────────┐
│ 1. Frontend Host: Vercel (Global Edge Network)         │
│    - Flutter Web compiled to HTML5/Canvaskit           │
│    - SPA URL Rewrites via vercel.json                  │
│    - Global CDN latency < 30ms                         │
│    - Live URL: https://maanak-nu.vercel.app            │
└────────────────────────────────────────────────────────┘
                           │
                           ▼ HTTPS REST (JWT Bearer)
┌────────────────────────────────────────────────────────┐
│ 2. Backend Host: Railway (Containerized Service)       │
│    - Python 3.11 + FastAPI + Uvicorn                   │
│    - Managed Docker runtime via railway.json           │
│    - Automated health checks (/health)                 │
│    - Live URL: https://maanak-production.up.railway.app│
└────────────────────────────────────────────────────────┘
          │                                  │
          ▼                                  ▼
┌──────────────────────┐           ┌──────────────────────┐
│ 3. Database: Neon    │           │ 4. CDN: Cloudinary   │
│    - Serverless PG   │           │    - Evidence Storage│
│    - Autoscaling     │           │    - SHA-256 Crops   │
│    - Encrypted at    │           │    - Annotated Over- │
│      rest and transit│           │      lays            │
└──────────────────────┘           └──────────────────────┘
```

- **Vercel SPA Handling (`vercel.json`)**: Configured with rewrites directing application URLs (`/dashboard`, `/inspections`, `/scanner`, `/products`, `/rules`) to `/index.html` while safeguarding static assets (`*.js`, `*.wasm`, `canvaskit/*`, `assets/*`).
- **Railway Configuration (`railway.json`)**: Configured with Dockerfile builder, restart-on-failure policy, and automated `/health` liveness checks.

---

## 25. Application Interface & Workflows

### 1. Public Portal & Authentication Screen
*Modern governmental landing page with official brand assets, statutory mission statements, role-based quick-access chips (`Inspector`, `Supervisor`, `Admin`), and biometric/password authentication.*

```
+--------------------------------------------------------------------------+
|  [LM-TRACE LOGO]  Legal Metrology Inspection & Compliance Platform       |
|                                                                          |
|  [ Role: Inspector ]  [ Role: Supervisor ]  [ Role: Admin (Full Access) ]|
|  Email:    inspector@demo.gov.in                                         |
|  Password: ••••••••••••                                                  |
|                                                                          |
|                   [ AUTHORIZE OFFICIAL ACCESS ]                          |
+--------------------------------------------------------------------------+
```

### 2. Multi-Surface Package Scanner & Validation Gate
*Interactive 4-surface capture interface showing real-time completeness status (`FRONT`, `BACK`, `SIDE`, `MRP_AREA`). The "Run AI Analysis" action remains locked until all four required surfaces are verified.*

```
+--------------------------------------------------------------------------+
|  INSPECTION: INS-2026-F982A               STATUS: DRAFT                  |
|                                                                          |
|  [ Front (PDP) ]       [ Back (Declarations) ]   [ Side (Consumer Care) ]|
|  [✓ Uploaded]          [✓ Uploaded]              [✓ Uploaded]            |
|                                                                          |
|  [ MRP & Date Stamp ]  [ Outer Wrapper (Opt) ]   [ Inner Pack (Opt) ]    |
|  [✓ Uploaded]          [+ Optional]              [+ Optional]            |
|                                                                          |
|  STATUS: All 4 mandatory surfaces verified.                              |
|  [ EXECUTE STATUTORY AI/CV COMPLIANCE ANALYSIS ]                         |
+--------------------------------------------------------------------------+
```

### 3. Two-Point Scale Calibration Canvas
*Precision calibration tool where the officer places two markers across a reference ruler or dimension to calculate `pixels_per_mm` scale factor.*

```
+--------------------------------------------------------------------------+
|  CALIBRATION CANVAS — IMAGE: FRONT_PDP.JPG                               |
|                                                                          |
|       Point A (X: 120, Y: 450) o─────────────────o Point B (X: 520, Y: 450)
|                                                                          |
|  Measured Pixels: 400.0 px                                               |
|  Known Metric Distance: 50.0 mm                                          |
|  Derived Optical Scale: 8.00 pixels/mm (CALIBRATED)                      |
|  Estimated PDP Area: 142.50 sq cm  ──> Rule 7 Tier: 100 < A <= 500 cm²   |
|  Statutory Minimum Character Height: 2.50 mm (Normal Container)          |
+--------------------------------------------------------------------------+
```

### 4. Statutory Compliance Audit Matrix
*Detailed parameter-by-parameter compliance table displaying extracted declaration values, officer-verified values, bounding-box crops, and legal citations.*

```
+--------------------------------------------------------------------------+
| STATUTORY PARAMETER      DETECTED VALUE      STATUS    CITATION          |
+--------------------------------------------------------------------------+
| Commodity Identity       Basmati Rice        PASS      Rule 6(1)(a)      |
| Net Quantity             5 kg (Schedule II)  PASS      Rule 6(1)(b)      |
| Manufacturer / Packer    ABC Agro Foods Ltd  PASS      Rule 6(1)(d)      |
| Maximum Retail Price     Rs. 450.00 (Incl.)  PASS      Rule 6(1)(e)      |
| Unit Sale Price (USP)    Rs. 90.00 / kg      PASS      Rule 6(11)        |
| Month & Year of Packing  01/2026             PASS      Rule 6(1)(f)      |
| Consumer Care Contact    1800-XXX-XXXX       PASS      Rule 6(1)(h)      |
| Numeral Height (Net Qty) 3.10 mm (Min: 2.5)  PASS      Rule 7 Table-I    |
| 1/3 Character Proportion Ratio: 0.42 (>=0.33)PASS      Rule 9(1)(b)      |
+--------------------------------------------------------------------------+
```

---

## 26. Live Demo & Test Credentials

The platform is deployed and accessible on production infrastructure. Pre-seeded test accounts represent the three operational tiers:

### Live Application URLs
- **Web Application Portal**: [https://maanak-nu.vercel.app](https://maanak-nu.vercel.app)
- **FastAPI Production Engine**: [https://maanak-production.up.railway.app](https://maanak-production.up.railway.app)
- **Interactive Swagger Documentation**: [https://maanak-production.up.railway.app/docs](https://maanak-production.up.railway.app/docs)
- **API Health Check**: [https://maanak-production.up.railway.app/health](https://maanak-production.up.railway.app/health)

### Test Accounts

| Role | Email | Password | Officer ID & Jurisdiction | Assigned Capabilities |
|---|---|---|---|---|
| **Inspector** | `inspector@demo.gov.in` | `Inspector@123` | `LM-UP-2026-042`<br>Lucknow District | Field inspection, photo upload, calibration, AI analysis, declaration verification, PDF/DOCX reports |
| **Supervisor** | `supervisor@demo.gov.in` | `Supervisor@123` | `LM-UP-SUP-012`<br>State Headquarters | Inspector oversight, team-wide queue monitoring, escalation queue review, audit trail review |
| **Administrator** | `admin@demo.gov.in` | `Admin@123` | `LM-HQ-ADM-001`<br>Directorate HQ, New Delhi | Full system governance, statutory rule management, rule version approval, **exclusive inspection deletion** |

*(Note: Clicking the role chip buttons on the login screen automatically populates these credentials).*

---

## 27. Security & Compliance Architecture

LM-TRACE implements institutional security controls suitable for government regulatory enforcement:

1. **Defense-in-Depth Authentication**: Passwords hashed using modern **Argon2id** through `pwdlib`. Session tokens issued as signed **HMAC-SHA256 JWTs** with strict expiration and signature verification on every protected route.
2. **Server-Side Authorization**: Every API route validates role permissions using `require_role()` dependencies. Administrative operations (such as inspection deletion or rule version approval) reject unauthorized calls with `HTTP 403 Forbidden` regardless of client-side states.
3. **Zero Frontend Secrets Architecture**: No database connection strings, Cloudinary API secrets, or LLM tokens exist in the compiled Flutter JavaScript or mobile binaries. Sensitive API keys remain strictly on the backend.
4. **Server-Side Request Forgery (SSRF) Protection**: The e-commerce listing fetcher (`online_listing_service.py`) validates target URLs, resolving IP addresses and blocking loopback (`127.0.0.1`, `localhost`), link-local (`169.254.0.0/16`), and private RFC 1918 subnets (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`).
5. **Cryptographic Evidence Hashing**: Image crops and PDF documents compute cryptographic SHA-256 digests at generation time, creating an anti-tamper chain from upload to court filing.
6. **Immutable Audit Trail**: Key lifecycle events (`USER_LOGIN`, `INSPECTION_CREATED`, `ANALYSIS_EXECUTED`, `DECLARATION_VERIFIED`, `VIOLATION_CONFIRMED`, `INSPECTION_FINALIZED`, `INSPECTION_DELETED`) generate append-only audit records storing timestamps, actor identity, role, and before/after payloads.

---

## 28. Future Scope

The following enhancements represent planned architectural extensions:

> [!NOTE]
> Items in this section represent the development roadmap and are not claimed as currently implemented in the codebase.

- **Automated Barcode & QR Code GS1 Verification**: Decode 2D DataMatrix and GS1 Digital Link barcodes to cross-verify manufacturer GTIN databases against packaging claims.
- **Multilingual Regional Declaration Extraction**: Extend the OCR pipeline with regional Indian language models (e.g., Hindi, Tamil, Telugu, Bengali) to evaluate bilingual packaging requirements under Rule 9(3).
- **Automated Web Crawler for Marketplace Surveillance**: Autonomous background crawlers to continuously audit top Indian e-commerce platforms for missing MRP, USP, or manufacturer disclosures.
- **Offline-First Synchronization Engine**: SQLite local caching on Android devices allowing inspectors in remote rural areas with zero cellular connectivity to capture photos and queue inspections for automatic cloud synchronization upon reconnection.
- **State Legal Metrology Court Integration**: Integration with the e-Courts portal for direct electronic filing of compounding notices and formal prosecution complaints under Section 53 of the Legal Metrology Act.

---

## 29. Team & Credits

- **Repository**: [Anshult72 / LM-TRACE](https://github.com/Anshult72/LM-TRACE)
- **Project Domain**: Legal Metrology Packaging Inspection & Statutory Compliance Automation
- **Statutory Framework**: Ministry of Consumer Affairs, Food and Public Distribution, Government of India
- **Reference Statutes**:
  - The Legal Metrology Act, 2009 (Act No. 1 of 2010)
  - The Legal Metrology (Packaged Commodities) Rules, 2011 (G.S.R. 202(E))
  - The Legal Metrology (Packaged Commodities) Amendment Rules, 2021 & 2022 (Unit Sale Price & E-Commerce Amendments)

---

## 30. License

This repository is maintained for evaluation and demonstration purposes. Source code access and deployment rights are subject to project repository guidelines. For licensing inquiries, refer to repository management or the project maintainer.

---

<div align="center">

**LM-TRACE — Legal Metrology Compliance & Inspection Platform**  
*Scan Today • Comply Tomorrow*

</div>
