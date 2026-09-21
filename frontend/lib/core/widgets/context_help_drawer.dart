import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../responsive/responsive_layout.dart';

/// Structured content definition for an individual LM-TRACE page's contextual help.
class PageHelpContent {
  final String pageId;
  final String pageTitle;
  final String subtitle;
  final String whyExists;
  final List<String> whatYouCanDo;
  final List<String>? workflowSteps;
  final String howItWorks;
  final Map<String, String> resultsMeaning;
  final String dataSources;
  final List<String> importantConsiderations;
  final String howItConnects;
  final String? roleNotes;

  const PageHelpContent({
    required this.pageId,
    required this.pageTitle,
    required this.subtitle,
    required this.whyExists,
    required this.whatYouCanDo,
    this.workflowSteps,
    required this.howItWorks,
    required this.resultsMeaning,
    required this.dataSources,
    required this.importantConsiderations,
    required this.howItConnects,
    this.roleNotes,
  });
}

/// Centralized, audited registry of contextual help content for all 12 major LM-TRACE pages.
class PageHelpRegistry {
  static const Map<String, PageHelpContent> _registry = {
    'dashboard': PageHelpContent(
      pageId: 'dashboard',
      pageTitle: 'Dashboard',
      subtitle: 'Operational enforcement overview and active inspection workload',
      whyExists:
          'The Dashboard gives an at-a-glance operational view of active inspections, review escalations, statutory compliance rates, and priority enforcement queues across jurisdictions.',
      whatYouCanDo: [
        'Review high-level enforcement KPIs across active inspection cases',
        'Inspect the Action-Required Strip to prioritize non-compliant or review-pending commodities',
        'Review compliance breakdown trends categorized by statutory rule family and commodity type',
        'Examine recent field inspections in a live, filterable table',
        'Trigger direct operational shortcuts (New Inspection, Review Cases, or Scan)',
      ],
      workflowSteps: [
        'Case Ingestion',
        'Evidence Classification',
        'Outcome Aggregation',
        'Operational Queues',
        'Executive Summary',
      ],
      howItWorks:
          'Information is aggregated in real-time from backend database records. The server classifies each case using strict statutory checks and violation findings, calculating rates and compiling action queues.',
      resultsMeaning: {
        'Total Cases':
            'Count of all persistent inspection records within the active filter scope or assigned jurisdiction.',
        'Compliance Rate':
            'Calculated as: Compliant / (Compliant + Potential Violations) * 100. Open cases or unresolved reviews are excluded from the denominator to ensure statistical accuracy.',
        'Violations Flagged':
            'Number of cases where automated rule evaluations or officer inspections identified active, unrejected statutory infractions.',
        'Pending Review':
            'Number of cases with ambiguous OCR, borderline contrast, or requiring supervisor sign-off before finalization.',
      },
      dataSources:
          'Real database records served via /api/dashboard/summary and /api/inspections. Inspectors see cases scoped to their beat; Supervisors and Admins see jurisdictional oversight.',
      importantConsiderations: [
        'The dashboard provides high-level operational visibility, not a replacement for full case docket examination.',
        'Compliance rates reflect evaluated cases; they do not extrapolate uninspected market commodities.',
        'Action queues update dynamically as inspectors upload evidence and supervisors complete reviews.',
      ],
      howItConnects:
          'Aggregates outcomes from the Inspections Registry and Scanner; drives workflow handoffs to Supervisor Review and Product Intelligence.',
      roleNotes:
          'Field Inspectors view cases assigned to their beat. Supervisors access divisional review buttons. Admins monitor system-wide throughput.',
    ),

    'inspections': PageHelpContent(
      pageId: 'inspections',
      pageTitle: 'Inspections Registry',
      subtitle: 'Central repository and docket management for all Legal Metrology inspection cases',
      whyExists:
          'Provides an authoritative, searchable, and immutable registry of all field inspections, physical observations, digital evidence files, and compliance outcomes.',
      whatYouCanDo: [
        'Search and filter inspections by case code, establishment, commodity name, date, and status',
        'Initiate a new statutory inspection case with trader details and location tagging',
        'Open complete case dockets to review photographic evidence, OCR extracts, and Rule 7 measurements',
        'Track inspection lifecycle stages from Draft to Supervisory Finalization',
        'Generate and download official PDF and editable DOCX inspection reports',
      ],
      workflowSteps: [
        'Case Registration',
        'Evidence Capture',
        'OCR & CV Analysis',
        'Rule Evaluation',
        'Supervisory Review',
        'Finalized Docket',
      ],
      howItWorks:
          'Every inspection is tracked as a structured legal case docket. Digital evidence captured in the field is evaluated against configured statutory rules, generating verifiable pass/fail checks and violation records.',
      resultsMeaning: {
        'DRAFT / IN PROGRESS':
            'Case file created; evidence images are being captured, uploaded, or analyzed.',
        'COMPLIANT':
            'All mandatory declaration checks passed with zero statutory infractions detected.',
        'POTENTIAL VIOLATION':
            'One or more statutory declarations (MRP, Net Quantity, Manufacturer, Font Height) failed legal thresholds.',
        'NEEDS REVIEW':
            'Low-confidence OCR or ambiguous packaging requiring manual officer verification.',
        'FINALIZED':
            'Case docket formally locked, reviewed, signed, and preserved in the chain of custody.',
      },
      dataSources:
          'Inspection entities, establishment records, and check findings persisted in the backend database (/api/inspections).',
      importantConsiderations: [
        'Case status reflects workflow progression and statutory rule checks at inspection time.',
        'A flagged violation constitutes prima facie findings for officer review; judicial penalties require formal statutory compounding or adjudication.',
        'Finalized cases cannot be edited; amendments require a formal re-inspection docket.',
      ],
      howItConnects:
          'Core hub of LM-TRACE: created via New Inspection, enriched by Scanner & Scale Calibration, audited in Audit Trail, and reviewed in Supervisor Review.',
      roleNotes:
          'Inspectors can create and edit their cases. Supervisors can approve, override, or finalize dockets. Admins retain audit oversight.',
    ),

    'scanner': PageHelpContent(
      pageId: 'scanner',
      pageTitle: 'Scan & Ingestion',
      subtitle: 'Multi-surface photographic capture and computer vision ingestion workspace',
      whyExists:
          'Enables field officers to capture high-resolution package surface photographs, run optical pre-checks, extract declaration text via OCR, and initiate automated compliance audits.',
      whatYouCanDo: [
        'Capture or upload photographs of all 4 mandatory package surfaces: Front (PDP), Back, Side, and MRP Area',
        'Perform real-time alignment and optical quality pre-checks (lighting, glare, blur)',
        'Link captured images directly to an active inspection case file',
        'Load statutory sample packages for verification and training scenarios',
        'Trigger the comprehensive multi-surface OCR extraction and compliance engine',
      ],
      workflowSteps: [
        'Surface Capture',
        'Image Rectification',
        'OCR Text Extraction',
        'Rule 7 CV Sizing',
        'Declaration Mapping',
        'Compliance Finding',
      ],
      howItWorks:
          'Uploaded surface images are stored in secure backend storage and processed through computer vision filters. OCR models identify text blocks, while layout models locate the Principal Display Panel (PDP) and font metrics.',
      resultsMeaning: {
        'OCR Output':
            'Automated text transcription of package labels. OCR is an evidence tool, not a legal verdict.',
        'Surface Coverage':
            'Mandatory requirement: all 4 surfaces (Front, Back, Side, MRP Area) must be present for a complete compliance audit.',
        'Font Height CV':
            'Automated character bounding box measurement for Rule 7 verification against Table-I area thresholds.',
      },
      dataSources:
          'High-resolution digital image evidence uploaded from camera or file system, processed by backend OCR and CV services (/api/inspections/{id}/images).',
      importantConsiderations: [
        'All package surfaces should be photographed as flat as possible under even illumination.',
        'Glares, deep reflections, and crinkled packaging degrade OCR accuracy and letter measurement precision.',
        'OCR extraction is verified against human review before court dockets are signed.',
      ],
      howItConnects:
          'Ingests the raw digital evidence that fuels Scale Calibration, AI Analysis, and the Finalize Inspection docket.',
      roleNotes:
          'Field Inspectors actively capture and ingest images. Supervisors review original high-res evidence during case oversight.',
    ),

    'products': PageHelpContent(
      pageId: 'products',
      pageTitle: 'Product Intelligence',
      subtitle: 'Persistent product identity, label evolution, and Legal Metrology fingerprint registry',
      whyExists:
          'Decouples individual case dockets from persistent commercial product identities. Tracks how a brand\'s packaging declarations, net quantities, and font dimensions evolve across time and markets.',
      whatYouCanDo: [
        'Search and inspect persistent product SKU records by barcode (GTIN), brand, or commodity',
        'Inspect the cryptographic Legal Metrology Fingerprint of registered packaging',
        'Compare historical label versions to detect shrinkflation, price revisions, or font height reductions',
        'Review aggregate compliance history and violation rates for specific manufacturers and packers',
        'Initiate a new inspection directly from an existing product record',
      ],
      workflowSteps: [
        'Field Inspection',
        'Barcode / Brand Indexing',
        'Label Version Synthesis',
        'Fingerprint Hashing',
        'Version Delta Analysis',
      ],
      howItWorks:
          'When an inspection is processed, LM-TRACE links the commodity to a master product record based on GTIN, brand, and commodity description. Extracted declarations are versioned to preserve historical packaging evolution.',
      resultsMeaning: {
        'Product Fingerprint':
            'A cryptographic hash derived from mandatory declaration texts, layout positions, and packaging dimensions.',
        'Label Version':
            'Incremental packaging iteration (e.g. V1, V2) capturing physical design or declaration changes over time.',
        'Version Alert':
            'Notification indicating a change in net quantity, MRP, or font dimensions between consecutive market samples.',
      },
      dataSources:
          'Master product entities, label version history, and linked inspection references (/api/products).',
      importantConsiderations: [
        'A recorded product fingerprint is an analytical identity tracking mechanism, not a government certification.',
        'Products appearing compliant in past versions must still be evaluated independently in new market batches.',
        'Product Intelligence is product-centric, unlike the case-centric Inspections Registry.',
      ],
      howItConnects:
          'Draws data from completed inspections; links to Reference Library and informs repeat-offender analysis in Supervisor Review.',
      roleNotes:
          'Accessible to all officers for search and brand research. Admins manage master product catalog integrity.',
    ),

    'reference_library': PageHelpContent(
      pageId: 'reference_library',
      pageTitle: 'Reference Library',
      subtitle: 'Curated repository of evaluated label declarations and packaging design examples',
      whyExists:
          'Provides field officers, manufacturers, and reviewers with real-world examples of inspected commodities to understand compliant declaration layouts, typography, and presentation formats.',
      whatYouCanDo: [
        'Search reference products by commodity category, pack size, and declaration type',
        'Inspect actual high-resolution label photographs and verified declaration extracts',
        'Review evaluated statutory requirements (Rule 6, Rule 7, Rule 9) on real packaging',
        'Open the originating inspection case docket for complete statutory context',
        'Quickly verify standard industry practices for complex commodities',
      ],
      workflowSteps: [
        'Inspection Finalization',
        'Supervisory Curation',
        'Declaration Tagging',
        'Statutory Mapping',
        'Reference Cataloging',
      ],
      howItWorks:
          'Curated from finalized, high-confidence inspection records. Products in the reference library display extracted declarations alongside their evaluated rule checks.',
      resultsMeaning: {
        'Reference Sample':
            'A previously inspected product displaying verified declaration placement and formatting.',
        'Declaration Checklist':
            'Evaluation status of mandatory items (MRP, Net Wt, Mfg Date, Consumer Care, COO).',
        'Non-Certification Notice':
            'Inclusion in the library does NOT constitute a blanket approval or immunity for future batches.',
      },
      dataSources:
          'Finalized inspection case files and verified product intelligence records (/api/reference-library).',
      importantConsiderations: [
        'Never treat reference packaging as an automatic legal guarantee. New products require individual inspection.',
        'Do not use phrasing like "certified compliant" or "approved label" — each market sample stands on its own.',
        'Statutory amendments may alter requirements after a reference product was cataloged.',
      ],
      howItConnects:
          'Derived from Inspections and Product Intelligence; serves as an educational benchmark for field inspectors.',
      roleNotes:
          'Available to all roles for reference and research. Supervisors curate candidates for reference inclusion.',
    ),

    'rules': PageHelpContent(
      pageId: 'rules',
      pageTitle: 'Statutory Rule Engine',
      subtitle: 'Authoritative rule registry and deterministic compliance evaluation algorithms',
      whyExists:
          'Maintains versioned, deterministic statutory rules derived from the Legal Metrology Act, 2009 and Packaged Commodities Rules, 2011. Ensures rule logic is completely transparent, auditable, and legally faithful.',
      whatYouCanDo: [
        'Inspect all active statutory rules, Rule IDs (e.g. RULE-007-FNT, RULE-006-USP), and statutory citations',
        'Review mathematical evaluation thresholds (e.g. Table-I area vs numeral height brackets)',
        'Examine historical rule versions and gazette amendment applicability dates',
        'Inspect required evidence types and algorithmic detection logic for each requirement',
        'Verify deterministic rule behavior without AI subjectivity',
      ],
      workflowSteps: [
        'Statutory Gazette Ingestion',
        'Rule Versioning (by date)',
        'Parameter Configuration',
        'Deterministic Engine',
        'Compliance Check Evaluation',
      ],
      howItWorks:
          'When an inspection is evaluated, the rule engine resolves active rule versions based on the inspection date. It applies deterministic mathematical conditions to extracted facts (PDP area, letter heights, declarations).',
      resultsMeaning: {
        'Rule Version Status':
            'ACTIVE: Currently enforced for modern inspections. ARCHIVED: Preserved for retroactive historical audit.',
        'Deterministic Logic':
            'Pure mathematical and logical evaluation. AI does NOT decide the law — it only extracts facts for the Rule Engine.',
        'Evidence Requirements':
            'The specific data artifacts (e.g. PDP bbox, px/mm scale, OCR block) required to validate a rule.',
      },
      dataSources:
          'Authoritative statutory rule catalog stored in backend configuration and database tables (/api/rules).',
      importantConsiderations: [
        'The Rule Engine enforces statutory law; algorithms cannot soften or bend legal minimums.',
        'Rule modifications require administrative privileges and are cryptographically recorded in the Audit Trail.',
        'Effective dates must strictly align with Ministry of Consumer Affairs Gazette Notifications.',
      ],
      howItConnects:
          'The analytical core of LM-TRACE: powers Scanner CV checks, AI Analysis evaluations, and Finalize Inspection dockets.',
      roleNotes:
          'Inspectors and Supervisors can view rule specifications. Rule configuration and version authoring require ADMIN privileges.',
    ),

    'calibration': PageHelpContent(
      pageId: 'calibration',
      pageTitle: 'Scale Calibration',
      subtitle: 'Physical pixel-to-millimetre optical scale calibration for Rule 7 verification',
      whyExists:
          'Calibrates 2D digital photographs against a known physical reference marker. Establishes mathematical pixel-to-millimetre traceability required to verify Rule 7 Table-I numeral and letter heights.',
      whatYouCanDo: [
        'Select an inspection case and package surface photograph',
        'Choose a physical reference standard (ruler, reference card, or verified packaging edge)',
        'Place Point A and Point B interactively on the reference standard',
        'Enter the known physical length in millimetres to derive pixels-per-millimetre (px/mm)',
        'Verify the Principal Display Panel (PDP) area and calculate minimum required font heights',
        'Save calibration to lock physical measurement traceability for the case docket',
      ],
      workflowSteps: [
        'Image Selection',
        'Reference Identification',
        'Point A & B Placement',
        'Pixel Distance Derivation',
        'Scale Computation (px/mm)',
        'Rule 7 Verification',
      ],
      howItWorks:
          'Calculates Euclidean pixel distance between Point A and Point B on the image canvas. Dividing pixel distance by the known millimetre dimension yields the optical scale factor (px/mm).',
      resultsMeaning: {
        'Derived Scale (px/mm)':
            'The number of image pixels representing 1.0 physical millimetre on that focal plane (e.g. 2.45 px/mm).',
        'Optical Calibration':
            'This is 2D visual dimensional calibration; it does NOT calibrate physical weighing machines.',
        'Rule 7 Minimum Height':
            'The statutory minimum numeral/letter height determined by comparing PDP area to Table-I brackets.',
      },
      dataSources:
          'Uploaded inspection surface images and persisted calibration records (/api/inspections/{id}/calibration).',
      importantConsiderations: [
        'Reference standard and target declarations must lie on approximately the same optical plane.',
        'Camera perspective angle, lens tilt, and curved packaging surfaces introduce dimensional foreshortening.',
        'If packaging is blown, formed, or molded, ensure the appropriate statutory calculation mode is selected.',
      ],
      howItConnects:
          'Directly enables font height CV checks in Scanner and provides statutory proof for Rule 7 findings in the Inspection Docket.',
      roleNotes:
          'Field Inspectors calibrate their inspection images. Supervisors scrutinize calibration points during case review.',
    ),

    'supervisor': PageHelpContent(
      pageId: 'supervisor',
      pageTitle: 'Supervisor Review',
      subtitle: 'Enforcement command console for case review, finding confirmation, and oversight',
      whyExists:
          'Supports dual-officer integrity and statutory hierarchy by enabling authorized supervisory officers to review, confirm, or override field inspection findings before formal legal action is initiated.',
      whatYouCanDo: [
        'Review inspection cases flagged with potential violations or unresolved checks',
        'Scrutinize photographic evidence, OCR extracts, and Rule 7 measurement overlays',
        'Confirm statutory violations to prepare formal compounding notices or legal dockets',
        'Override false alarms or reject erroneous findings with mandatory documented justification',
        'Monitor divisional enforcement KPIs, escalations, and repeat offender establishments',
      ],
      workflowSteps: [
        'Inspector Submission',
        'Supervisory Review',
        'Evidence Scrutiny',
        'Concur / Override / Remand',
        'Final Case Docket',
      ],
      howItWorks:
          'Cases submitted by field inspectors enter the supervisory queue. Supervisors evaluate evidence, rule citations, and trader responses, then record formal concurrence or modification.',
      resultsMeaning: {
        'Supervisor Concurrence':
            'Formal confirmation that observed non-compliance meets statutory standards for prosecution or compounding.',
        'Override / Rejection':
            'Supervisory dismissal of an automated or field finding. Requires mandatory recorded reason.',
        'Repeat Offender Index':
            'Automated tally of prior statutory infractions linked to the establishment or brand within 12 months.',
      },
      dataSources:
          'Submitted inspection dockets, evidence files, findings, and divisional metrics (/api/dashboard/supervisor).',
      importantConsiderations: [
        'Supervisor review is a mandatory legal stage for contested cases before issuing formal statutory notices.',
        'Every supervisory approval, rejection, or override is permanently sealed in the immutable Audit Trail.',
        'Inspectors cannot self-approve cases flagged for supervisory escalation.',
      ],
      howItConnects:
          'Acts as the final gate between field inspections and formal report generation, court pleadings, and compounding.',
      roleNotes:
          'Restricted to officers with SUPERVISOR or ADMIN credentials. Inspectors are redirected to their field workspace.',
    ),

    'audit_trail': PageHelpContent(
      pageId: 'audit_trail',
      pageTitle: 'Audit Trail',
      subtitle: 'Immutable chronological chain of custody capturing all user and system events',
      whyExists:
          'Establishes an evidentiary chain of custody under Section 65B of the Indian Evidence Act / Bharatiya Sakshya Adhiniyam and Legal Metrology Act, 2009. Guarantees non-repudiation across all enforcement actions.',
      whatYouCanDo: [
        'Search and filter audit events by actor, event code, resource type, date, and outcome',
        'Trace complete lifecycle events for a specific inspection case from inception to final report',
        'Inspect cryptographic event hashes, client IP addresses, actor roles, and payload deltas',
        'Verify user authentications, session terminations, and security configuration changes',
        'Export verifiable audit logs for judicial or administrative inquiries',
      ],
      workflowSteps: [
        'User / System Action',
        'Backend Interceptor',
        'Audit Event Construction',
        'Cryptographic Hashing',
        'Append-Only Trail',
      ],
      howItWorks:
          'All critical platform actions (logins, logouts, case creation, calibration, supervisory decisions, report downloads) pass through an audit interceptor that logs immutable records with UTC timestamps and actor claims.',
      resultsMeaning: {
        'Actor':
            'The authenticated officer ID and role who initiated the action.',
        'Event Code':
            'Standardized action identifier (e.g. USER_LOGIN, USER_LOGOUT, INSPECTION_CREATED, SUPERVISOR_OVERRIDE).',
        'Target Resource':
            'The database entity impacted by the event (Inspection Code, Product ID, Rule ID).',
        'Chain of Custody':
            'Chronological sequence proving digital evidence was untampered from capture to courtroom presentation.',
      },
      dataSources:
          'Append-only backend audit event database records (/api/audit-logs).',
      importantConsiderations: [
        'Audit records cannot be updated, edited, or deleted through normal application operations.',
        'Audit logging runs server-side independently of client-side logging.',
        'Cryptographic hashes verify that digital evidence files and docket records have not been altered.',
      ],
      howItConnects:
          'Monitors and secures every module across LM-TRACE (Auth, Scanner, Inspections, Calibration, Rules, Settings).',
      roleNotes:
          'Dedicated audit management is accessible to Supervisors and Admins. Inspectors can review case-level history.',
    ),

    'statutory_reference': PageHelpContent(
      pageId: 'statutory_reference',
      pageTitle: 'Statutory Reference',
      subtitle: 'Authoritative legal statutes, gazette notifications, and rule mappings',
      whyExists:
          'Provides direct, structured access to official legal texts, ministry notifications, and schedules governing Legal Metrology in India, ensuring every automated check is anchored in statutory law.',
      whatYouCanDo: [
        'Search and browse official statutory documents, sections, and rule schedules',
        'Read exact legal texts of the Legal Metrology Act, 2009 and Packaged Commodities Rules, 2011',
        'Inspect gazette notifications, historical amendments, and future effective dates',
        'Trace bidirectional mappings between statutory sections and automated LM-TRACE Rule IDs',
        'Review official gazette PDFs and download source reference materials',
      ],
      workflowSteps: [
        'Official Gazette Publication',
        'Statutory Text Ingestion',
        'Rule Parsing & Indexing',
        'Rule Engine Mapping',
        'Field Compliance Reference',
      ],
      howItWorks:
          'Stores authoritative digital representations of Ministry of Consumer Affairs statutes. Rules are cross-linked to automated Rule Engine configurations to provide instant statutory backing.',
      resultsMeaning: {
        'Official Source':
            'The primary legislative or gazetted text published in the Gazette of India.',
        'Effective Date':
            'The exact calendar date when an amendment becomes legally enforceable in market inspections.',
        'Rule Mapping':
            'The explicit code link connecting a legal subsection (e.g. Rule 6(1)(k)) to an automated LM-TRACE check.',
      },
      dataSources:
          'Statutory documents, gazette notifications, and rule mapping tables (/api/statutory-references).',
      importantConsiderations: [
        'Publication date and effective date may differ. A published rule cannot be enforced before its gazetted effective date.',
        'LM-TRACE summaries provide operational assistance; in legal disputes, the official Gazette of India takes precedence.',
        'Does not constitute individualized legal advice.',
      ],
      howItConnects:
          'Provides the legal bedrock for the Statutory Rule Engine, Scanner checks, and Inspection Docket citations.',
      roleNotes:
          'Publicly readable by all enforcement roles. Statutory library updates are governed by Directorate Admins.',
    ),

    'settings': PageHelpContent(
      pageId: 'settings',
      pageTitle: 'System Settings',
      subtitle: 'Operational preferences, optical scanner guidance, and administrative configuration',
      whyExists:
          'Configures platform behavior, optical capture guidance, image enhancement parameters, and administrative system policies to support consistent field enforcement operations.',
      whatYouCanDo: [
        'Toggle Surface Alignment Guidance overlays for the package scanner camera',
        'Enable automated contrast enhancement and glare reduction pre-processing',
        'Configure offline storage synchronization for low-connectivity field inspections',
        'Review gazette language settings and institutional light/dark display standards',
        'Manage platform retention, backup policies, and security credentials (Admin only)',
      ],
      workflowSteps: [
        'Preference Selection',
        'Local / Server Sync',
        'Config Storage',
        'Runtime Application',
      ],
      howItWorks:
          'User preferences are saved to local persistent storage for instant offline availability. Administrative parameters are persisted to backend system settings endpoints.',
      resultsMeaning: {
        'Surface Alignment Guidance':
            'Displays viewfinder bounding guides to assist officers in photographing mandatory package panels.',
        'Auto Enhance Contrast':
            'Applies histogram equalization to low-contrast photographs before sending them to the OCR pipeline.',
        'Administrative Settings':
            'Global policies governing audit retention, JWT lifetimes, and system maintenance.',
      },
      dataSources:
          'Local client preferences (SharedPreferences) and backend administrative settings (/api/settings/system).',
      importantConsiderations: [
        'Scanner guidance settings affect client-side camera UX; they do not alter backend compliance thresholds.',
        'Administrative system settings require ADMIN role credentials.',
        'Resetting local preferences does not delete persisted inspection records or audit trail entries.',
      ],
      howItConnects:
          'Governs user experience in the Scanner, Dashboard, and controls platform security.',
      roleNotes:
          'Officers configure personal capture preferences. Administrative settings are restricted to system administrators.',
    ),

    'reports': PageHelpContent(
      pageId: 'reports',
      pageTitle: 'Reports',
      subtitle: 'Inspection case docket generator, previewer, and digital export interface',
      whyExists:
          'Consolidates all photographic evidence, extracted declarations, Rule 7 font measurements, statutory citations, and supervisory signatures into an official, verifiable inspection case docket.',
      whatYouCanDo: [
        'Preview the official multi-page PDF Inspection Case Docket with institutional formatting',
        'Download an editable DOCX report for drafting statutory notices or compounding pleadings',
        'Review itemized statutory check results, observed values, and statutory rule citations',
        'Inspect cryptographic document verification hashes and officer digital signature blocks',
        'Print or share the formal case file directly from the application',
      ],
      workflowSteps: [
        'Case Finalization',
        'Evidence Aggregation',
        'Statutory Citation Binding',
        'PDF / DOCX Generation',
        'Evidentiary Export',
      ],
      howItWorks:
          'Aggregates case data from the inspection database and renders a standardized statutory report. Generates both high-fidelity PDF documents and editable DOCX formats via backend report generators.',
      resultsMeaning: {
        'Inspection Docket':
            'Official institutional record detailing trader identity, inspection date, evidence, and findings.',
        'Finding Citation':
            'Exact section and rule number cited for each non-compliant declaration.',
        'Evidentiary Weight':
            'Forms prima facie evidence for proceedings under Section 49 or compounding under Section 53.',
      },
      dataSources:
          'Finalized inspection records, evidence images, and dynamic report generation services (/api/reports/{id}/docx).',
      importantConsiderations: [
        'A report reflects facts and evidence recorded at the time of inspection.',
        'Subsequent corrective actions by a manufacturer do not alter the historical inspection report findings.',
        'DOCX reports are provided for administrative convenience; official signed PDFs should be preserved for court.',
      ],
      howItConnects:
          'The ultimate operational output of LM-TRACE: produced from Inspections, Scanner, Calibration, and Supervisor Review.',
      roleNotes:
          'Inspectors can generate and preview reports for their cases. Supervisors sign off on final statutory dockets.',
    ),
  };

  /// Resolves the help content for a given pageId or route.
  static PageHelpContent? get(String pageId) {
    return _registry[pageId.toLowerCase().trim()];
  }

  /// Maps a GoRouter location route path to the appropriate PageHelpContent.
  static PageHelpContent? resolveFromRoute(String route) {
    final clean = route.toLowerCase().split('?').first;
    if (clean == '/' || clean.startsWith('/dashboard')) return _registry['dashboard'];
    if (clean.startsWith('/inspections') && !clean.contains('/finalize')) return _registry['inspections'];
    if (clean.startsWith('/scanner') || clean.startsWith('/scan')) return _registry['scanner'];
    if (clean.startsWith('/products')) return _registry['products'];
    if (clean.startsWith('/reference-library')) return _registry['reference_library'];
    if (clean.startsWith('/rules')) return _registry['rules'];
    if (clean.startsWith('/calibration')) return _registry['calibration'];
    if (clean.startsWith('/supervisor')) return _registry['supervisor'];
    if (clean.startsWith('/audit-trail')) return _registry['audit_trail'];
    if (clean.startsWith('/statutory-reference') || clean.startsWith('/about')) return _registry['statutory_reference'];
    if (clean.startsWith('/settings')) return _registry['settings'];
    if (clean.startsWith('/reports')) return _registry['reports'];
    return null;
  }

  /// Exposes all registered page IDs.
  static List<String> get registeredPageIds => _registry.keys.toList();
}

/// Accessible contextual help icon button `[ ⓘ ]` placed near page titles.
class ContextHelpButton extends StatelessWidget {
  final String pageId;
  final Color? color;
  final double size;
  final EdgeInsetsGeometry padding;

  const ContextHelpButton({
    super.key,
    required this.pageId,
    this.color,
    this.size = 18,
    this.padding = const EdgeInsets.all(6),
  });

  @override
  Widget build(BuildContext context) {
    final content = PageHelpRegistry.get(pageId) ?? PageHelpRegistry.resolveFromRoute(pageId);
    if (content == null) return const SizedBox.shrink();

    final effectiveColor = color ?? AppColors.secondaryBlue;

    return Semantics(
      label: 'About this page: ${content.pageTitle}',
      button: true,
      child: Tooltip(
        message: 'About this page',
        preferBelow: true,
        textStyle: const TextStyle(fontSize: 11, color: Colors.white),
        decoration: BoxDecoration(
          color: AppColors.primaryNavy,
          borderRadius: BorderRadius.circular(4),
        ),
        child: InkWell(
          onTap: () => ContextHelpDrawer.show(context, content: content),
          borderRadius: BorderRadius.circular(20),
          hoverColor: effectiveColor.withValues(alpha: 0.08),
          child: Padding(
            padding: padding,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: effectiveColor.withValues(alpha: 0.35), width: 1.2),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: size,
                color: effectiveColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Right-side slide-in contextual help drawer for LM-TRACE.
class ContextHelpDrawer extends StatefulWidget {
  final PageHelpContent content;

  const ContextHelpDrawer({super.key, required this.content});

  /// Opens the contextual help drawer as a modal overlay on top of the current screen.
  static Future<void> show(
    BuildContext context, {
    PageHelpContent? content,
    String? pageId,
  }) async {
    final resolvedContent = content ??
        (pageId != null ? PageHelpRegistry.get(pageId) ?? PageHelpRegistry.resolveFromRoute(pageId) : null);

    if (resolvedContent == null) return;

    final isMobile = ResponsiveLayout.isMobile(context);

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss About This Page Help Drawer',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Align(
          alignment: isMobile ? Alignment.bottomCenter : Alignment.centerRight,
          child: ContextHelpDrawer(content: resolvedContent),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        final offsetTween = isMobile
            ? Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            : Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero);

        return SlideTransition(
          position: offsetTween.animate(curve),
          child: child,
        );
      },
    );
  }

  @override
  State<ContextHelpDrawer> createState() => _ContextHelpDrawerState();
}

class _ContextHelpDrawerState extends State<ContextHelpDrawer> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final width = isMobile ? MediaQuery.of(context).size.width : 440.0;
    final maxHeight = MediaQuery.of(context).size.height;
    final content = widget.content;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          height: isMobile ? maxHeight * 0.88 : maxHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: isMobile
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : const BorderRadius.horizontal(left: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(-4, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                // 1. Drawer Top Header
                _buildHeader(context, content, isMobile),

                const Divider(height: 1, color: AppColors.neutral200),

                // 2. Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section: Why This Page Exists
                        _buildSectionHeader(
                          icon: Icons.lightbulb_outline,
                          title: 'WHY THIS PAGE EXISTS',
                          accentColor: AppColors.secondaryBlue,
                        ),
                        const SizedBox(height: 8),
                        _buildCard(
                          child: Text(
                            content.whyExists,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.neutral800,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Section: What You Can Do Here
                        _buildSectionHeader(
                          icon: Icons.checklist_rounded,
                          title: 'WHAT YOU CAN DO HERE',
                          accentColor: const Color(0xFF0284C7),
                        ),
                        const SizedBox(height: 8),
                        ...content.whatYouCanDo.map((item) => _buildBulletPoint(item)),
                        const SizedBox(height: 18),

                        // Section: How It Works & Workflow Pipeline
                        _buildSectionHeader(
                          icon: Icons.account_tree_outlined,
                          title: 'HOW IT WORKS',
                          accentColor: const Color(0xFF0D9488),
                        ),
                        const SizedBox(height: 8),
                        if (content.workflowSteps != null && content.workflowSteps!.isNotEmpty) ...[
                          _buildWorkflowPipeline(content.workflowSteps!),
                          const SizedBox(height: 10),
                        ],
                        _buildCard(
                          child: Text(
                            content.howItWorks,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.neutral700,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Section: What The Results / Information Mean
                        _buildSectionHeader(
                          icon: Icons.assessment_outlined,
                          title: 'WHAT THE RESULTS MEAN',
                          accentColor: const Color(0xFF4F46E5),
                        ),
                        const SizedBox(height: 8),
                        ...content.resultsMeaning.entries.map(
                          (entry) => _buildDefinitionItem(entry.key, entry.value),
                        ),
                        const SizedBox(height: 18),

                        // Section: Data Sources
                        _buildSectionHeader(
                          icon: Icons.storage_outlined,
                          title: 'DATA COMES FROM',
                          accentColor: const Color(0xFF059669),
                        ),
                        const SizedBox(height: 8),
                        _buildDataSourcesCard(content.dataSources),
                        const SizedBox(height: 18),

                        // Section: Important Considerations & Limitations
                        _buildSectionHeader(
                          icon: Icons.warning_amber_rounded,
                          title: 'IMPORTANT CONSIDERATIONS',
                          accentColor: const Color(0xFFD97706),
                        ),
                        const SizedBox(height: 8),
                        _buildConsiderationsCard(content.importantConsiderations),
                        const SizedBox(height: 18),

                        // Section: How It Connects
                        _buildSectionHeader(
                          icon: Icons.hub_outlined,
                          title: 'HOW IT CONNECTS TO LM-TRACE',
                          accentColor: AppColors.primaryNavy,
                        ),
                        const SizedBox(height: 8),
                        _buildCard(
                          color: const Color(0xFFF1F5F9),
                          borderColor: AppColors.neutral200,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.compare_arrows_rounded, size: 18, color: AppColors.primaryNavy),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  content.howItConnects,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.primaryNavy,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Section: Role-Specific Notes
                        if (content.roleNotes != null) ...[
                          const SizedBox(height: 18),
                          _buildSectionHeader(
                            icon: Icons.badge_outlined,
                            title: 'ROLE-BASED ACCESS',
                            accentColor: AppColors.neutral700,
                          ),
                          const SizedBox(height: 8),
                          _buildCard(
                            color: const Color(0xFFF8FAFC),
                            borderColor: AppColors.neutral200,
                            child: Text(
                              content.roleNotes!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.neutral700,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // 3. Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(top: BorderSide(color: AppColors.neutral200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'LM-TRACE Institutional Guidance',
                          style: TextStyle(fontSize: 11, color: AppColors.neutral500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          side: const BorderSide(color: AppColors.neutral300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close', style: TextStyle(fontSize: 12, color: AppColors.primaryNavy)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PageHelpContent content, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.primaryNavy,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.info_outline, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'ABOUT THIS PAGE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                tooltip: 'Close Help Drawer (Esc)',
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content.pageTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content.subtitle,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: accentColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required Widget child,
    Color color = Colors.white,
    Color borderColor = AppColors.neutral200,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.secondaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.neutral800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowPipeline(List<String> steps) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCFBF1)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: Text(
                '${i + 1}. ${steps[i]}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F766E),
                ),
              ),
            ),
            if (i < steps.length - 1)
              const Icon(
                Icons.arrow_forward_rounded,
                size: 11,
                color: Color(0xFF14B8A6),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefinitionItem(String term, String definition) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            term,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            definition,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutral700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSourcesCard(String sources) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sources,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF166534),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsiderationsCard(List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF92400E),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
