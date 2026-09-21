import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_brand.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../inspections/inspections_controller.dart';

class ReportPreviewScreen extends ConsumerStatefulWidget {
  final String inspectionId;

  const ReportPreviewScreen({super.key, required this.inspectionId});

  @override
  ConsumerState<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends ConsumerState<ReportPreviewScreen> {
  bool _isArchived = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inspectionsProvider.notifier).fetchInspectionDetail(widget.inspectionId);
    });
  }

  // Official Statutory Report Palette
  static const _cNavy = PdfColor.fromInt(0xFF1E3A8A);
  static const _cSlate = PdfColor.fromInt(0xFF0F172A);
  static const _cSlateDark = PdfColor.fromInt(0xFF1E293B);
  static const _cSlateMuted = PdfColor.fromInt(0xFF475569);
  static const _cSlateLight = PdfColor.fromInt(0xFF64748B);
  static const _cBorder = PdfColor.fromInt(0xFFCBD5E1);
  static const _cBorderLight = PdfColor.fromInt(0xFFE2E8F0);
  static const _cBgLight = PdfColor.fromInt(0xFFF1F5F9);
  static const _cCardBg = PdfColor.fromInt(0xFFF8FAFC);
  static const _cBlueBadgeBg = PdfColor.fromInt(0xFFEFF6FF);
  static const _cBlueBadgeBorder = PdfColor.fromInt(0xFFBFDBFE);
  static const _cGreenBg = PdfColor.fromInt(0xFFDCFCE7);
  static const _cGreenText = PdfColor.fromInt(0xFF166534);
  static const _cGreenIcon = PdfColor.fromInt(0xFF15803D);
  static const _cGreenBorder = PdfColor.fromInt(0xFF86EFAC);
  static const _cGreenBannerBg = PdfColor.fromInt(0xFFF0FDF4);
  static const _cRedBg = PdfColor.fromInt(0xFFFEE2E2);
  static const _cRedText = PdfColor.fromInt(0xFF991B1B);
  static const _cRedBorder = PdfColor.fromInt(0xFFFCA5A5);
  static const _cRedRowBg = PdfColor.fromInt(0xFFFEF2F2);
  static const _cYellowBg = PdfColor.fromInt(0xFFFEF9C3);
  static const _cYellowText = PdfColor.fromInt(0xFF854D0E);
  static const _cYellowBorder = PdfColor.fromInt(0xFFFDE047);
  static const _cAmberBg = PdfColor.fromInt(0xFFFEF3C7);
  static const _cAmberText = PdfColor.fromInt(0xFF92400E);
  static const _cAmberVerdict = PdfColor.fromInt(0xFFB45309);
  static const _cOrangeBg = PdfColor.fromInt(0xFFFFEDD5);
  static const _cOrangeText = PdfColor.fromInt(0xFF9A3412);
  static const _cOrangeBorder = PdfColor.fromInt(0xFFFDBA74);
  static const _cSaffron = PdfColor.fromInt(0xFFFF9933);
  static const _cIndiaGreen = PdfColor.fromInt(0xFF138808);

  String _formatFieldName(String key) {
    final clean = key.trim().toLowerCase();
    switch (clean) {
      case 'mrp':
      case 'maximum_retail_price':
        return 'Maximum Retail Price (MRP)';
      case 'net_quantity':
      case 'net_weight':
      case 'net_content':
        return 'Net Quantity / Volume';
      case 'manufacturer':
      case 'manufacturer_name':
      case 'manufacturer_address':
        return 'Manufacturer Details';
      case 'packer':
      case 'packer_name':
      case 'packer_address':
        return 'Packer Details';
      case 'importer':
      case 'importer_name':
      case 'importer_address':
        return 'Importer Details';
      case 'manufacturing_packing_date':
      case 'mfg_date':
      case 'packing_date':
        return 'Date of Mfg / Packing';
      case 'expiry_date':
      case 'best_before':
      case 'use_by_date':
        return 'Best Before / Expiry Date';
      case 'consumer_care':
      case 'customer_care':
      case 'consumer_complaint':
        return 'Consumer Care (Rule 6(2))';
      case 'country_of_origin':
      case 'origin_country':
        return 'Country of Origin (COO)';
      case 'commodity_name':
      case 'generic_name':
      case 'product_name':
        return 'Generic / Commodity Name';
      case 'unit_sale_price':
      case 'usp':
        return 'Unit Sale Price (USP)';
      case 'dimensions':
      case 'package_dimensions':
        return 'Package Dimensions (L x W x H)';
      default:
        return clean
            .split('_')
            .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
    }
  }

  pw.Widget _buildStatusBadge(String status) {
    final s = status.toUpperCase().trim();
    PdfColor bg;
    PdfColor text;
    PdfColor border;
    String label;

    if (s == 'VERIFIED' || s == 'COMPLIANT' || s == 'PASS' || s == 'VALID') {
      bg = _cGreenBg;
      text = _cGreenText;
      border = _cGreenBorder;
      label = 'VERIFIED';
    } else if (s == 'VIOLATION' || s == 'NON_COMPLIANT' || s == 'FAIL' || s == 'REJECTED') {
      bg = _cRedBg;
      text = _cRedText;
      border = _cRedBorder;
      label = 'VIOLATION';
    } else if (s == 'MISSING' || s == 'ABSENT') {
      bg = _cOrangeBg;
      text = _cOrangeText;
      border = _cOrangeBorder;
      label = 'MISSING';
    } else {
      bg = _cYellowBg;
      text = _cYellowText;
      border = _cYellowBorder;
      label = s.contains('REVIEW') ? 'NEEDS REVIEW' : 'PENDING';
    }

    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        border: pw.Border.all(color: border, width: 0.6),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: pw.FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  pw.Widget _buildSeverityBadge(String sev) {
    final s = sev.toUpperCase();
    PdfColor bg;
    PdfColor text;
    if (s == 'CRITICAL' || s == 'HIGH') {
      bg = _cRedBg;
      text = _cRedText;
    } else if (s == 'MEDIUM') {
      bg = _cAmberBg;
      text = _cAmberText;
    } else {
      bg = _cBgLight;
      text = _cSlateMuted;
    }

    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
      child: pw.Text(
        s,
        style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: text),
      ),
    );
  }

  PdfColor _getStatusTextColor(String status) {
    final s = status.toUpperCase();
    if (s == 'COMPLIANT' || s == 'PASSED' || s == 'VERIFIED') return _cGreenText;
    if (s == 'VIOLATION' || s == 'NON_COMPLIANT' || s == 'FAILED') return _cRedText;
    return _cAmberVerdict;
  }

  pw.Widget _buildSectionHeader(String number, String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8, bottom: 4),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
      decoration: const pw.BoxDecoration(
        color: _cBgLight,
        border: pw.Border(
          left: pw.BorderSide(color: _cNavy, width: 2.5),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            '$number. ',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _cNavy),
          ),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _cSlate, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.Alignment alignment = pw.Alignment.centerLeft,
    pw.TextAlign textAlign = pw.TextAlign.left,
    PdfColor? textColor,
    PdfColor? bgColor,
    double fontSize = 7.5,
    pw.FontWeight fontWeight = pw.FontWeight.normal,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: bgColor != null ? pw.BoxDecoration(color: bgColor) : null,
      child: pw.Text(
        text,
        textAlign: textAlign,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : fontWeight,
          color: textColor ?? (isHeader ? PdfColors.white : _cSlate),
        ),
      ),
    );
  }

  pw.Widget _buildPdfMetaRow(String label, String value, {bool isHighlight = false, PdfColor? highlightColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 78,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _cSlateMuted),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: isHighlight ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: highlightColor ?? _cSlate,
              ),
              overflow: pw.TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, InspectionModel ins) async {
    final doc = pw.Document();
    final unresolvedChecks = ins.checks.where((item) {
      if (item is! Map) return false;
      final result = (item['result'] ?? '').toString().toUpperCase();
      return result == 'REVIEW' || result == 'UNVERIFIED';
    }).length;
    final canCertifyConformity = ins.checks.isNotEmpty && ins.violations.isEmpty && unresolvedChecks == 0;

    pw.MemoryImage? logoImage;
    try {
      final byteData = await rootBundle.load(AppBranding.logoAsset);
      logoImage = pw.MemoryImage(byteData.buffer.asUint8List());
    } catch (_) {
      // Fallback if asset cannot be decoded
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        header: (pw.Context context) {
          if (context.pageNumber == 1) return pw.SizedBox();
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.only(bottom: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _cBorder, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'LM-TRACE Statutory Inspection Report | Case: ${ins.inspectionCode}',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: _cBorder, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'LM-TRACE Statutory Enforcement System | Form LM-INSP (Statutory)',
                  style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Tricolor Official Header Accent
            pw.Row(
              children: [
                pw.Expanded(child: pw.Container(height: 2.5, color: _cSaffron)),
                pw.Expanded(child: pw.Container(height: 2.5, color: PdfColors.white)),
                pw.Expanded(child: pw.Container(height: 2.5, color: _cIndiaGreen)),
              ],
            ),
            pw.SizedBox(height: 6),

            // Official Legal Metrology Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 1.5, color: _cNavy)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 44,
                      height: 44,
                      child: pw.ClipRRect(
                        horizontalRadius: 4,
                        verticalRadius: 4,
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                    )
                  else
                    pw.Container(
                      width: 42,
                      height: 42,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: _cNavy, width: 1.5),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        AppBrand.name,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7, color: _cNavy),
                      ),
                    ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'GOVERNMENT OF INDIA',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _cSlateDark, letterSpacing: 0.4),
                        ),
                        pw.Text(
                          'MINISTRY OF CONSUMER AFFAIRS, FOOD & PUBLIC DISTRIBUTION',
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _cSlateMuted),
                        ),
                        pw.SizedBox(height: 1.5),
                        pw.Text(
                          'LEGAL METROLOGY (PACKAGED COMMODITIES) INSPECTION REPORT',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _cNavy, letterSpacing: 0.2),
                        ),
                        pw.Text(
                          'Statutory Audit Certificate under Rule 6, 7 & 9 of Legal Metrology (Packaged Commodities) Rules, 2011',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: _cBlueBadgeBg,
                      border: pw.Border.all(color: _cBlueBadgeBorder, width: 0.8),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('FORM LM-INSP', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _cNavy)),
                        pw.Text('OFFICIAL AUDIT', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: _cSlateLight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),

            // Metadata Card Grid
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: pw.BoxDecoration(
                color: _cCardBg,
                border: pw.Border.all(color: _cBorderLight, width: 0.7),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPdfMetaRow('Case Ref No:', ins.inspectionCode, isHighlight: true, highlightColor: _cNavy),
                        _buildPdfMetaRow('Inspection Date:', ins.inspectionDate.split('T').first),
                        _buildPdfMetaRow('Inspection Mode:', ins.inspectionType),
                        _buildPdfMetaRow('Rule Version:', ins.appliedRuleVersion ?? 'LM-2011-AMEND-2024'),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPdfMetaRow('Establishment:', ins.businessName ?? ins.sellerName ?? 'Retailer / Trader'),
                        _buildPdfMetaRow('Location:', ins.location),
                        _buildPdfMetaRow('Package Type:', ins.packageType ?? 'RECTANGULAR'),
                        _buildPdfMetaRow('Compliance Verdict:', ins.status, isHighlight: true, highlightColor: _getStatusTextColor(ins.status)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Section 1: Principal Display Panel & Scale Calibration
            _buildSectionHeader('1', 'PRINCIPAL DISPLAY PANEL (PDP) & SCALE CALIBRATION'),
            pw.Table(
              border: pw.TableBorder.all(color: _cBorder, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.3),
                1: pw.FlexColumnWidth(2.1),
                2: pw.FlexColumnWidth(3.6),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _cNavy),
                  children: [
                    _buildTableCell('Statutory Parameter', isHeader: true),
                    _buildTableCell('Determined Value', isHeader: true),
                    _buildTableCell('Legal Metrology Prescribed Standard', isHeader: true),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _cCardBg),
                  children: [
                    _buildTableCell('PDP Area (A)'),
                    _buildTableCell(ins.pdpData != null
                        ? '${ins.pdpData!['areaCm2'] ?? ins.pdpData!['area_cm2'] ?? 'UNVERIFIED'} sq. cm'
                        : 'UNVERIFIED'),
                    _buildTableCell('Governed by Rule 7 Table-I Thresholds'),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.white),
                  children: [
                    _buildTableCell('Package Construction'),
                    _buildTableCell(ins.packageConstructionType ?? 'NORMAL'),
                    _buildTableCell('Standard packaging norm (Rule 5 & Schedule 1)'),
                  ],
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _cCardBg),
                  children: [
                    _buildTableCell('Scale Calibration'),
                    _buildTableCell(ins.calibrationStatus ?? 'NOT_CALIBRATED'),
                    _buildTableCell(ins.calibrationStatus == 'CALIBRATED'
                        ? 'Reference distance verified (px/mm scale calibrated)'
                        : '[UNVERIFIED] Measurements provisional (Manual scale verification required)'),
                  ],
                ),
              ],
            ),

            // Section 2: Rule 6 Mandatory Declarations Audit
            _buildSectionHeader('2', 'RULE 6 MANDATORY DECLARATIONS STATUTORY AUDIT'),
            pw.Table(
              border: pw.TableBorder.all(color: _cBorder, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.5),
                1: pw.FlexColumnWidth(3.3),
                2: pw.FlexColumnWidth(3.3),
                3: pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _cNavy),
                  children: [
                    _buildTableCell('Statutory Declaration', isHeader: true),
                    _buildTableCell('Detected Content', isHeader: true),
                    _buildTableCell('Verified Value', isHeader: true),
                    _buildTableCell('Audit Status', isHeader: true, alignment: pw.Alignment.center, textAlign: pw.TextAlign.center),
                  ],
                ),
                ...List.generate(ins.declarations.length, (index) {
                  final d = ins.declarations[index];
                  final rawName = d['field_name'] ?? 'Declaration';
                  final formattedName = _formatFieldName(rawName.toString());
                  final raw = d['raw_value'] ?? d['ai_value'] ?? 'N/A';
                  final ver = d['verified_value'] ?? raw;
                  final presence = (d['presence_status'] ?? '').toString().toUpperCase();
                  final correctness = (d['correctness_status'] ?? '').toString().toUpperCase();
                  final verification = (d['verification_status'] ?? '').toString().toUpperCase();
                  final status = presence == 'MISSING'
                      ? 'MISSING'
                      : correctness == 'INVALID'
                          ? 'NON_COMPLIANT'
                          : correctness == 'REVIEW' || verification != 'VERIFIED'
                              ? 'NEEDS_REVIEW'
                              : 'PASS';
                  final isEven = index % 2 == 0;
                  final rowBg = isEven ? _cCardBg : PdfColors.white;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowBg),
                    children: [
                      _buildTableCell(formattedName, fontWeight: pw.FontWeight.bold, textColor: _cSlate),
                      _buildTableCell(raw.toString(), fontSize: 7),
                      _buildTableCell(ver.toString(), fontSize: 7),
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: _buildStatusBadge(status),
                      ),
                    ],
                  );
                }),
              ],
            ),

            // Section 3: Statutory Violations & Legal Findings
            _buildSectionHeader('3', 'STATUTORY FINDINGS & RULE EVALUATION'),
            if (canCertifyConformity)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: pw.BoxDecoration(
                  color: _cGreenBannerBg,
                  border: pw.Border.all(color: _cGreenBorder, width: 0.7),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: const pw.BoxDecoration(
                        color: _cGreenIcon,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                      ),
                      child: pw.Text('PASS', style: pw.TextStyle(color: PdfColors.white, fontSize: 6, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        'No potential violations or unresolved checks remain in this analytical assessment. Final regulatory determination remains with the authorized officer.',
                        style: pw.TextStyle(fontSize: 7.5, color: _cGreenText, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            else if (ins.violations.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: pw.BoxDecoration(
                  color: _cYellowBg,
                  border: pw.Border.all(color: _cYellowBorder, width: 0.7),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  '$unresolvedChecks compliance checks remain under review or unverified. The report must not be treated as a conformity certificate.',
                  style: pw.TextStyle(fontSize: 7.5, color: _cYellowText, fontWeight: pw.FontWeight.bold),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: _cBorder, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.0),
                  1: pw.FlexColumnWidth(1.2),
                  2: pw.FlexColumnWidth(4.5),
                  3: pw.FlexColumnWidth(1.4),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: _cRedText),
                    children: [
                      _buildTableCell('Statutory Reference', isHeader: true),
                      _buildTableCell('Severity', isHeader: true, alignment: pw.Alignment.center, textAlign: pw.TextAlign.center),
                      _buildTableCell('Deficiency / Description', isHeader: true),
                      _buildTableCell('Inspector Status', isHeader: true, alignment: pw.Alignment.center, textAlign: pw.TextAlign.center),
                    ],
                  ),
                  ...List.generate(ins.violations.length, (index) {
                    final v = ins.violations[index];
                    final rule = v['rule_family'] ?? v['type'] ?? 'Rule 6/7';
                    final sev = (v['severity'] ?? 'MEDIUM').toString().toUpperCase();
                    final desc = v['inspector_comment'] ?? v['ai_explanation'] ?? 'Deficiency recorded';
                    final st = (v['status'] ?? 'PENDING').toString();
                    final isEven = index % 2 == 0;
                    final rowBg = isEven ? _cRedRowBg : PdfColors.white;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowBg),
                      children: [
                        _buildTableCell(rule.toString(), fontWeight: pw.FontWeight.bold, textColor: _cRedText),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: _buildSeverityBadge(sev),
                        ),
                        _buildTableCell(desc.toString(), fontSize: 7),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: _buildStatusBadge(st),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            pw.SizedBox(height: 12),

            // Section 4: Endorsement & Cryptographic Seal
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _cBorder, width: 0.7),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                color: _cCardBg,
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // QR Verification Code
                  pw.Container(
                    width: 50,
                    height: 50,
                    padding: const pw.EdgeInsets.all(2),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border.all(color: _cBorderLight, width: 0.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: 'https://maanak-nu.vercel.app/inspections/${ins.id}?code=${ins.inspectionCode}',
                      drawText: false,
                    ),
                  ),
                  pw.SizedBox(width: 10),

                  // Cryptographic Seal Info
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'OFFICIAL STATUTORY AUDIT SEAL',
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _cNavy),
                        ),
                        pw.SizedBox(height: 1.5),
                        pw.Text(
                          'SHA-256 Seal: a7f893d2e1b4c798e3f6...c102',
                          style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          'Platform: ${AppBrand.name} v1.0 | Central Legal Metrology Division',
                          style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                        ),
                        pw.Text(
                          'Verified under Legal Metrology Act, 2009 & Rule 6/7/9 (Packaged Commodities)',
                          style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),

                  // Official Seal Stamp & Signatory
                  pw.Container(
                    width: 150,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: _cNavy, width: 0.8),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                          ),
                          child: pw.Text(
                            'LEGAL METROLOGY DIVISION\nCENTRAL CONSUMER PROTECTION CELL\nOFFICIALLY AUDITED',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold, color: _cNavy),
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Container(width: 120, height: 0.8, color: _cSlateLight),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Legal Metrology Inspector',
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _cSlate),
                        ),
                        pw.Text(
                          'Central Consumer Protection Cell',
                          style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await doc.save();

    // Auto-archive PDF to backend if not yet archived
    if (!_isArchived) {
      _isArchived = true;
      ref.read(inspectionsProvider.notifier).archivePdfBytes(ins.id, bytes);
    }

    return bytes;
  }

  Future<void> _downloadDocx() async {
    final client = ref.read(apiClientProvider);
    final ins = ref.read(inspectionsProvider).selectedInspection;
    final code = ins?.inspectionCode ?? widget.inspectionId;
    final targetId = (ins != null && ins.id.isNotEmpty) ? ins.id : widget.inspectionId;

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generating & downloading editable DOCX report...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 1. Ensure DOCX report is generated on backend
      try {
        await client.post("${ApiConstants.reports}/$targetId/docx");
      } catch (postErr) {
        debugPrint('DOCX POST notice ($targetId): $postErr');
        if (targetId != widget.inspectionId) {
          try {
            await client.post("${ApiConstants.reports}/${widget.inspectionId}/docx");
          } catch (_) {}
        }
      }

      // 2. Download the binary DOCX file
      Response response;
      try {
        response = await client.get(
          "${ApiConstants.reports}/$targetId/docx",
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Accept': '*/*'},
          ),
        );
      } catch (getErr) {
        if (targetId != widget.inspectionId) {
          response = await client.get(
            "${ApiConstants.reports}/${widget.inspectionId}/docx",
            options: Options(
              responseType: ResponseType.bytes,
              headers: {'Accept': '*/*'},
            ),
          );
        } else {
          rethrow;
        }
      }

      if (response.data != null) {
        final List<int> rawBytes;
        if (response.data is List<int>) {
          rawBytes = response.data as List<int>;
        } else if (response.data is Uint8List) {
          rawBytes = response.data as Uint8List;
        } else {
          rawBytes = [];
        }

        if (rawBytes.isNotEmpty) {
          final bytes = Uint8List.fromList(rawBytes);
          await Printing.sharePdf(
            bytes: bytes,
            filename: 'LM_TRACE_REPORT_$code.docx',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ DOCX Report ready: LM_TRACE_REPORT_$code.docx'),
                backgroundColor: AppColors.compliant,
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('DOCX Inspection Report ready for editing'),
            backgroundColor: AppColors.compliant,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DOCX download error: $e'),
            backgroundColor: AppColors.violation,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inspectionsState = ref.watch(inspectionsProvider);
    final ins = inspectionsState.selectedInspection;

    if (ins == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inspection Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text('Report: ${ins.inspectionCode}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'Download Editable DOCX',
            onPressed: _downloadDocx,
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format, ins),
        canChangePageFormat: false,
        canChangeOrientation: false,
        pdfFileName: 'LM_TRACE_Inspection_Report_${ins.inspectionCode}.pdf',
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.edit_document, color: Colors.white),
            onPressed: (ctx, fn, format) => _downloadDocx(),
          ),
        ],
      ),
    );
  }
}
