import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/responsive/web_page_container.dart';

// Provider for reference product detail
final referenceDetailProvider = FutureProvider.family<Map<String, dynamic>?, ({String productId, String? version})>(
  (ref, args) async {
    final client = ref.watch(apiClientProvider);
    try {
      final url = ApiConstants.referenceLibraryDetail(args.productId, args.version);
      final response = await client.get(url);
      if (response.statusCode == 200 && response.data is Map) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching reference detail: $e');
    }
    return null;
  },
);

class ReferenceDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ReferenceDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ReferenceDetailScreen> createState() => _ReferenceDetailScreenState();
}

class _ReferenceDetailScreenState extends ConsumerState<ReferenceDetailScreen> {
  String? _selectedVersion;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      referenceDetailProvider((productId: widget.productId, version: _selectedVersion)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Compliance Reference Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/reference-library');
            }
          },
        ),
      ),
      body: WebPageContainer(
        child: detailAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(64.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.violationRed),
                  const SizedBox(height: 16),
                  Text('Failed to load reference product: $err', style: const TextStyle(color: AppColors.neutral700)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(referenceDetailProvider((productId: widget.productId, version: _selectedVersion))),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) {
            if (data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 48, color: AppColors.neutral400),
                      const SizedBox(height: 16),
                      const Text('Reference product not found in registry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: () => context.go('/reference-library'), child: const Text('Back to Reference Library')),
                    ],
                  ),
                ),
              );
            }

            return _buildContent(context, data);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final product = (data['product'] as Map<String, dynamic>?) ?? {};
    final referenceStatus = data['reference_status']?.toString() ?? 'LIMITED';
    final referenceStatusLabel = data['reference_status_label']?.toString() ?? 'Limited Statutory Data';
    final disclaimer = data['disclaimer']?.toString() ?? '';
    final labelImages = (data['label_images'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final declarations = (data['recorded_declarations'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final applicableRules = (data['applicable_rules'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final complianceChecks = (data['compliance_checks'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final violations = (data['violations'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final sourceIns = (data['source_inspection'] as Map<String, dynamic>?) ?? {};
    final versions = (data['available_versions'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final evidenceItems = (data['evidence_items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header & Action Buttons
          _buildHeader(context, product, referenceStatus, referenceStatusLabel),
          const SizedBox(height: 16),

          // 2. Mandatory Statutory Disclaimer Banner (Section 20)
          _buildDisclaimerBanner(disclaimer),
          const SizedBox(height: 20),

          // 3. Action Bar: Check My Product, View Inspection, View in Registry
          _buildActionBar(context, sourceIns, product),
          const SizedBox(height: 24),

          // 4. Two-Column Desktop Layout (Product Overview & Label Images)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildLabelImagesCard(context, labelImages)),
                    const SizedBox(width: 20),
                    Expanded(flex: 6, child: _buildProductOverviewCard(product, sourceIns, versions)),
                  ],
                );
              }
              return Column(
                children: [
                  _buildLabelImagesCard(context, labelImages),
                  const SizedBox(height: 20),
                  _buildProductOverviewCard(product, sourceIns, versions),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 5. Recorded Declarations Matrix
          _buildDeclarationsMatrixCard(declarations),
          const SizedBox(height: 24),

          // 6. Applicable Statutory Rules Evaluated
          _buildApplicableRulesCard(applicableRules),
          const SizedBox(height: 24),

          // 7. Compliance Evaluation Breakdown
          _buildComplianceEvaluationCard(complianceChecks, violations),
          const SizedBox(height: 24),

          // 8. Source Inspection Context
          _buildSourceInspectionCard(context, sourceIns),
          const SizedBox(height: 24),

          // 9. Cropped Evidence Gallery (if available)
          if (evidenceItems.isNotEmpty) ...[
            _buildEvidenceGalleryCard(evidenceItems),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> product, String status, String statusLabel) {
    Color statusBg = const Color(0xFFECFDF5);
    Color statusText = const Color(0xFF047857);
    IconData statusIcon = Icons.check_circle_outline;

    if (status == 'NEEDS_REVIEW') {
      statusBg = const Color(0xFFFFFBEB);
      statusText = const Color(0xFFB45309);
      statusIcon = Icons.warning_amber_outlined;
    } else if (status == 'VIOLATION') {
      statusBg = const Color(0xFFFEF2F2);
      statusText = const Color(0xFFB91C1C);
      statusIcon = Icons.error_outline;
    } else if (status == 'LIMITED') {
      statusBg = const Color(0xFFF1F5F9);
      statusText = const Color(0xFF475569);
      statusIcon = Icons.info_outline;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/reference-library'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back, size: 16, color: AppColors.accentBlue),
                        SizedBox(width: 4),
                        Text('Reference Library', style: TextStyle(fontSize: 12, color: AppColors.accentBlue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('•', style: TextStyle(color: AppColors.neutral400)),
                  const SizedBox(width: 8),
                  Text(
                    product['category']?.toString() ?? 'Packaged Commodity',
                    style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                product['name']?.toString() ?? 'Packaged Commodity',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
              ),
              const SizedBox(height: 4),
              Text(
                'Brand: ${product['brand'] ?? 'Pre-packaged Brand'}  •  Pack Size: ${product['pack_size'] ?? 'Standard'}  •  MRP: ${product['declared_mrp'] ?? 'Not captured'}',
                style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusText.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 16, color: statusText),
              const SizedBox(width: 6),
              Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusText)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisclaimerBanner(String disclaimer) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: Color(0xFF1D4ED8), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              disclaimer.isNotEmpty
                  ? disclaimer
                  : 'Reference examples are based strictly on previously recorded inspection data in LM-TRACE and do not constitute legal certification.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, Map<String, dynamic> sourceIns, Map<String, dynamic> product) {
    final insId = sourceIns['id']?.toString();
    final prodId = product['id']?.toString() ?? widget.productId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, size: 18, color: AppColors.accentBlue),
              SizedBox(width: 8),
              Text('Using this example to design your product?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
            ],
          ),
          Row(
            children: [
              if (insId != null && insId.isNotEmpty) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: const BorderSide(color: AppColors.neutral300),
                  ),
                  icon: const Icon(Icons.assignment_outlined, size: 14),
                  label: const Text('View Source Inspection', style: TextStyle(fontSize: 12)),
                  onPressed: () => context.push('/inspections/$insId'),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: AppColors.neutral300),
                ),
                icon: const Icon(Icons.fingerprint, size: 14),
                label: const Text('View in Product Registry', style: TextStyle(fontSize: 12)),
                onPressed: () => context.push('/products/$prodId'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.qr_code_scanner, size: 14),
                label: const Text('Check My Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => context.push('/scanner'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabelImagesCard(BuildContext context, List<Map<String, dynamic>> images) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('RECORDED LABEL PHOTOGRAPHY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.primaryNavy)),
              if (images.isNotEmpty)
                Text('${images.length} Image${images.length == 1 ? '' : 's'} on file', style: const TextStyle(fontSize: 11, color: AppColors.neutral500)),
            ],
          ),
          const SizedBox(height: 14),
          if (images.isEmpty)
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined, size: 48, color: AppColors.neutral400),
                    SizedBox(height: 8),
                    Text('Label image unavailable for this historical record', style: TextStyle(fontSize: 12, color: AppColors.neutral500)),
                  ],
                ),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                images[0]['image_url'] ?? '',
                height: 260,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 220,
                  color: const Color(0xFFF1F5F9),
                  child: const Center(child: Text('Label image unavailable', style: TextStyle(fontSize: 12, color: AppColors.neutral500))),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Surface: ${images[0]['surface_type'] ?? 'FRONT'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700)),
                Text('Quality: ${images[0]['quality_assessment'] ?? 'GOOD'}', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductOverviewCard(Map<String, dynamic> product, Map<String, dynamic> sourceIns, List<Map<String, dynamic>> versions) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PRODUCT SPECIFICATIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.primaryNavy)),
              if (versions.isNotEmpty)
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedVersion ?? product['active_version'] ?? 'v1.0',
                    items: versions.map((v) {
                      final ver = v['label_version']?.toString() ?? 'v1.0';
                      return DropdownMenuItem(value: ver, child: Text(ver, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedVersion = val);
                      }
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSpecRow('Product Name', product['name'] ?? 'Packaged Commodity'),
          _buildSpecRow('Brand Name', product['brand'] ?? 'Not captured'),
          _buildSpecRow('Commodity Category', product['category'] ?? 'Packaged Food'),
          _buildSpecRow('Declared Net Quantity', product['pack_size'] ?? 'Not captured'),
          _buildSpecRow('Declared Maximum Retail Price', product['declared_mrp'] ?? 'Not captured'),
          _buildSpecRow('Barcode / GTIN', product['gtin'] ?? 'Not available'),
          _buildSpecRow('Manufacturer / Packer', product['manufacturer_name'] ?? 'Not captured'),
          _buildSpecRow('Country of Origin', product['country_of_origin'] ?? 'India'),
          _buildSpecRow('Source Inspection Date', sourceIns['inspection_date'] != null ? sourceIns['inspection_date'].toString().split('T').first : 'Not captured'),
          _buildSpecRow('Source Inspection Code', sourceIns['inspection_code'] ?? 'INS-DIRECT'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 170, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.neutral500))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.neutral900))),
        ],
      ),
    );
  }

  Widget _buildDeclarationsMatrixCard(List<Map<String, dynamic>> declarations) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('RECORDED MANDATORY DECLARATIONS (RULE 6)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.primaryNavy)),
              Text('Source: AI OCR & Inspection Matrix', style: TextStyle(fontSize: 11, color: AppColors.neutral500)),
            ],
          ),
          const SizedBox(height: 14),
          Table(
            border: TableBorder(horizontalInside: BorderSide(color: AppColors.neutral200, width: 1)),
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(4.0),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Declaration Field', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral600))),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Extracted Value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral600))),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Presence', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral600))),
                  Padding(padding: EdgeInsets.all(8.0), child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral600))),
                ],
              ),
              ...declarations.map((d) {
                final isPresent = d['presence_status'] == 'DETECTED';
                final isCorrect = d['correctness_status'] == 'VALID';

                return TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(8.0), child: Text(d['display_name'] ?? d['field_name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text(d['value'] ?? 'Not captured', style: const TextStyle(fontSize: 12, color: AppColors.neutral800))),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(isPresent ? 'Detected' : 'Missing', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isPresent ? AppColors.passGreen : AppColors.violationRed)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(isCorrect ? 'Valid' : 'Review', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isCorrect ? AppColors.passGreen : AppColors.reviewAmber)),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplicableRulesCard(List<Map<String, dynamic>> rules) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STATUTORY REQUIREMENTS EVALUATED FOR THIS COMMODITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.primaryNavy)),
          const SizedBox(height: 14),
          ...rules.map((r) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primaryNavy, borderRadius: BorderRadius.circular(4)),
                    child: Text(r['rule_code'] ?? 'RULE', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['title'] ?? 'Statutory Requirement', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                        const SizedBox(height: 2),
                        Text(r['statutory_reference'] ?? '', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.accentBlue)),
                        const SizedBox(height: 4),
                        Text(r['description'] ?? '', style: const TextStyle(fontSize: 11.5, color: AppColors.neutral700, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildComplianceEvaluationCard(List<Map<String, dynamic>> checks, List<Map<String, dynamic>> violations) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GRANULAR COMPLIANCE ASSESSMENT & INSPECTION OUTCOME', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.primaryNavy)),
          const SizedBox(height: 14),
          if (violations.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFECACA))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RECORDED STATUTORY OBSERVATIONS / VIOLATIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
                  const SizedBox(height: 8),
                  ...violations.map((v) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, size: 14, color: Color(0xFFDC2626)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${v['type']}: ${v['ai_explanation'] ?? 'Observation flagged'}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF7F1D1D)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          ...checks.map((c) {
            final isPass = c['result'] == 'PASS';
            final color = isPass ? AppColors.passGreen : AppColors.reviewAmber;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(isPass ? Icons.check_circle : Icons.warning_amber, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c['field_name'] ?? 'Requirement', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neutral900)),
                            Text(c['rule_code'] ?? '', style: const TextStyle(fontSize: 10.5, color: AppColors.neutral500)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('Expected: ${c['expected_condition']}', style: const TextStyle(fontSize: 11, color: AppColors.neutral600)),
                        const SizedBox(height: 2),
                        Text('Evaluation: ${c['explanation']}', style: const TextStyle(fontSize: 11, color: AppColors.neutral800, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSourceInspectionCard(BuildContext context, Map<String, dynamic> ins) {
    final insId = ins['id']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SOURCE INSPECTION TRACEABILITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.primaryNavy)),
              if (insId.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Open Inspection Record', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => context.push('/inspections/$insId'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTraceItem('Case Number', ins['inspection_code'] ?? 'INS-DIRECT'),
              _buildTraceItem('Date of Inspection', ins['inspection_date'] != null ? ins['inspection_date'].toString().split('T').first : 'Not recorded'),
              _buildTraceItem('Evaluation Score', '${ins['score'] ?? 95.0}%'),
              _buildTraceItem('Inspection Status', ins['status'] ?? 'FINALIZED'),
            ],
          ),
          const SizedBox(height: 8),
          Text('Location: ${ins['location'] ?? 'Field Establishment'}', style: const TextStyle(fontSize: 11.5, color: AppColors.neutral600)),
        ],
      ),
    );
  }

  Widget _buildTraceItem(String label, String val) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.neutral500)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.neutral900)),
        ],
      ),
    );
  }

  Widget _buildEvidenceGalleryCard(List<Map<String, dynamic>> items) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ASSOCIATED INSPECTION EVIDENCE & CROPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: AppColors.primaryNavy)),
          const SizedBox(height: 14),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, idx) {
                final ev = items[idx];
                final thumb = ev['thumbnail_url'] ?? ev['secure_url'];

                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: (thumb != null && thumb.toString().startsWith('http'))
                        ? Image.network(
                            thumb,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 24, color: AppColors.neutral400)),
                          )
                        : const Center(child: Icon(Icons.image_outlined, size: 24, color: AppColors.neutral400)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
