import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/responsive/web_page_container.dart';

final productHistoryProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, productId) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get("${ApiConstants.products}/$productId/history");
    if (response.statusCode == 200 && response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    }
  } catch (e) {
    debugPrint('Error loading product history for $productId: $e');
  }
  throw Exception('Failed to load product intelligence details for product $productId');
});

class ProductHistoryScreen extends ConsumerWidget {
  final String productId;

  const ProductHistoryScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(productHistoryProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Product Intelligence Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Registry',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/products');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Intelligence',
            onPressed: () => ref.refresh(productHistoryProvider(productId)),
          ),
        ],
      ),
      body: historyAsync.when(
        data: (data) {
          final product = (data['product'] as Map<String, dynamic>?) ?? {};
          final identity = (data['identity'] as Map<String, dynamic>?) ?? {};
          final fingerprint = (data['fingerprint'] as Map<String, dynamic>?) ?? {};
          final currentVersion = (data['current_version'] as Map<String, dynamic>?) ?? {};
          final labelVersions = (data['label_versions'] as List?) ?? [];
          final inspectionHistory = (data['inspection_history'] as List?) ?? [];
          final complianceHistory = (data['compliance_history'] as List?) ?? [];
          final evidenceList = (data['evidence'] as List?) ?? [];
          final versionDiff = (data['version_diff'] as Map<String, dynamic>?) ?? {};

          if (ResponsiveLayout.isWebDesktop(context)) {
            return WebPageContainer(
              child: _buildContent(
                context,
                product: product,
                identity: identity,
                fingerprint: fingerprint,
                currentVersion: currentVersion,
                labelVersions: labelVersions,
                inspectionHistory: inspectionHistory,
                complianceHistory: complianceHistory,
                evidenceList: evidenceList,
                versionDiff: versionDiff,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildContent(
              context,
              product: product,
              identity: identity,
              fingerprint: fingerprint,
              currentVersion: currentVersion,
              labelVersions: labelVersions,
              inspectionHistory: inspectionHistory,
              complianceHistory: complianceHistory,
              evidenceList: evidenceList,
              versionDiff: versionDiff,
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.violationRed),
                const SizedBox(height: 16),
                Text(
                  'Error loading Product Intelligence: $e',
                  style: const TextStyle(fontSize: 14, color: AppColors.neutral800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Return to Registry'),
                  onPressed: () => context.go('/products'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required Map<String, dynamic> product,
    required Map<String, dynamic> identity,
    required Map<String, dynamic> fingerprint,
    required Map<String, dynamic> currentVersion,
    required List<dynamic> labelVersions,
    required List<dynamic> inspectionHistory,
    required List<dynamic> complianceHistory,
    required List<dynamic> evidenceList,
    required Map<String, dynamic> versionDiff,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb & Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => context.go('/products'),
                      child: const Text('Product Registry', style: TextStyle(fontSize: 12, color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: AppColors.neutral400),
                    Text(
                      identity['brand'] ?? product['brand'] ?? 'Commodity',
                      style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  identity['name'] ?? product['name'] ?? 'Packaged Product SKU',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                ),
              ],
            ),
            _buildComplianceBadge(product['compliance_status'] ?? 'NOT_EVALUATED'),
          ],
        ),
        const SizedBox(height: 18),

        // 1. PRODUCT OVERVIEW
        _buildSectionHeader('1. Product Overview', Icons.dashboard_outlined),
        const SizedBox(height: 8),
        _buildOverviewCard(product, currentVersion),
        const SizedBox(height: 20),

        // 2. PRODUCT IDENTITY & DECLARATIONS
        _buildSectionHeader('2. Product Identity & Declared Entities', Icons.verified_user_outlined),
        const SizedBox(height: 8),
        _buildIdentityCard(identity),
        const SizedBox(height: 20),

        // 3. PRODUCT FINGERPRINT
        _buildSectionHeader('3. Deterministic Identity Fingerprint', Icons.fingerprint),
        const SizedBox(height: 8),
        _buildFingerprintCard(context, fingerprint),
        const SizedBox(height: 20),

        // 4. CURRENT LABEL VERSION
        _buildSectionHeader('4. Current Label Version', Icons.label_outline),
        const SizedBox(height: 8),
        _buildCurrentVersionCard(context, currentVersion),
        const SizedBox(height: 20),

        // 5. LABEL VERSION HISTORY & TIMELINE
        _buildSectionHeader('5. Label Version History', Icons.history),
        const SizedBox(height: 8),
        _buildVersionHistoryList(context, labelVersions),
        const SizedBox(height: 20),

        // 6. VERSION COMPARISON & DIFF
        _buildSectionHeader('6. Version Comparison & Alteration Diff', Icons.compare_arrows),
        const SizedBox(height: 8),
        _buildVersionDiffSection(versionDiff),
        const SizedBox(height: 20),

        // 7. INSPECTION HISTORY (CRITICAL SECTION)
        _buildSectionHeader('7. Inspection History', Icons.fact_check_outlined),
        const SizedBox(height: 8),
        _buildInspectionHistoryList(context, inspectionHistory),
        const SizedBox(height: 20),

        // 8. COMPLIANCE HISTORY
        _buildSectionHeader('8. Statutory Compliance History', Icons.gavel_outlined),
        const SizedBox(height: 8),
        _buildComplianceHistoryList(complianceHistory),
        const SizedBox(height: 20),

        // 9. EVIDENCE TRACEABILITY
        _buildSectionHeader('9. Packaging Evidence & Image Traceability', Icons.photo_library_outlined),
        const SizedBox(height: 8),
        _buildEvidenceSection(context, evidenceList),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryNavy),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
        ),
      ],
    );
  }

  // 1. OVERVIEW CARD
  Widget _buildOverviewCard(Map<String, dynamic> prod, Map<String, dynamic> curVer) {
    final brand = prod['brand'] ?? 'Not available';
    final name = prod['name'] ?? 'Not available';
    final cat = prod['category'] ?? 'Packaged Commodity';
    final gtin = prod['gtin'] ?? prod['barcode'] ?? 'Not available';
    final qty = prod['declared_net_quantity'] ?? prod['net_quantity'] ?? 'Not captured';
    final mrp = prod['declared_mrp'] ?? prod['mrp'] ?? 'Not captured';
    final ver = prod['active_version'] ?? 'v1.0';
    final fpStatus = prod['fingerprint_status'] ?? 'Verified';
    final lastDate = prod['last_inspected_date'];
    final compliance = prod['compliance_status'] ?? 'NOT_EVALUATED';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildParamTile('COMMODITY / SKU', name, isBold: true),
              ),
              Expanded(
                child: _buildParamTile('BRAND', brand, isBadge: true),
              ),
              Expanded(
                child: _buildParamTile('CATEGORY', cat),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.neutral200),
          Row(
            children: [
              Expanded(
                child: _buildParamTile('GTIN / BARCODE', gtin, isMono: true),
              ),
              Expanded(
                child: _buildParamTile('PACK SIZE', qty),
              ),
              Expanded(
                child: _buildParamTile('DECLARED MRP', mrp, isBold: true),
              ),
              Expanded(
                child: _buildParamTile('ACTIVE VERSION', ver),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.neutral200),
          Row(
            children: [
              Expanded(
                child: _buildParamTile('FINGERPRINT STATUS', fpStatus, isFpBadge: true),
              ),
              Expanded(
                child: _buildParamTile(
                  'LAST INSPECTED',
                  lastDate != null ? lastDate.toString().split("T").first : 'Not inspected',
                ),
              ),
              Expanded(
                child: _buildParamTile('CURRENT COMPLIANCE', compliance, isCompBadge: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. IDENTITY CARD
  Widget _buildIdentityCard(Map<String, dynamic> iden) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildParamTile('MANUFACTURER NAME', iden['manufacturer_name'] ?? 'Not available'),
              ),
              Expanded(
                child: _buildParamTile('MANUFACTURER ADDRESS', iden['manufacturer_address'] ?? 'Not available'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildParamTile('PACKER DETAILS', iden['packer_name'] != null ? '${iden['packer_name']} - ${iden['packer_address'] ?? ''}' : 'Same as Manufacturer'),
              ),
              Expanded(
                child: _buildParamTile('IMPORTER DETAILS', iden['importer_name'] != null ? '${iden['importer_name']} - ${iden['importer_address'] ?? ''}' : 'Domestic commodity (Not imported)'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildParamTile('COUNTRY OF ORIGIN', iden['country_of_origin'] ?? 'India'),
              ),
              Expanded(
                child: _buildParamTile('PERSISTENT PRODUCT ID', iden['product_id'] ?? 'Not assigned', isMono: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. FINGERPRINT CARD
  Widget _buildFingerprintCard(BuildContext context, Map<String, dynamic> fp) {
    final sha256 = fp['sha256'] ?? 'Unavailable';
    final status = fp['status'] ?? 'Verified';
    final statutoryNote = fp['statutory_note'] ??
        'A cryptographic fingerprint establishes deterministic identity and detects specification changes across production batches; it does not in itself certify statutory legal compliance.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.fingerprint, size: 20, color: AppColors.secondaryBlue),
                  const SizedBox(width: 8),
                  const Text('SHA-256 Identity Digest', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neutral800)),
                ],
              ),
              _buildFingerprintBadge(status),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.neutral300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    sha256,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.neutral800),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: AppColors.neutral600),
                  tooltip: 'Copy SHA-256 Hash',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: sha256));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SHA-256 fingerprint copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Metrological disclaimer
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.secondaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statutoryNote,
                    style: const TextStyle(fontSize: 11, color: AppColors.neutral700, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. CURRENT LABEL VERSION CARD
  Widget _buildCurrentVersionCard(BuildContext context, Map<String, dynamic> curVer) {
    final verId = curVer['version_id'] ?? 'v1.0';
    final effDate = curVer['effective_from'] ?? curVer['captured_at'] ?? 'Established';
    final mrp = curVer['mrp'] ?? 'Not captured';
    final qty = curVer['net_quantity'] ?? 'Not captured';
    final summary = curVer['ocr_summary'] ?? curVer['summary'] ?? 'Standard packaging declarations.';
    final srcId = curVer['source_inspection_id'];
    final srcCode = curVer['source_inspection_code'] ?? srcId;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Version $verId', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondaryBlue)),
                  ),
                  const SizedBox(width: 10),
                  Text('Captured: ${effDate.toString().split("T").first}', style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
                ],
              ),
              if (srcId != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.arrow_outward, size: 14),
                  label: Text('Source: $srcCode', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => context.push('/inspections/$srcId'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildParamTile('DECLARED MRP', mrp, isBold: true)),
              Expanded(child: _buildParamTile('NET QUANTITY', qty, isBold: true)),
            ],
          ),
          const SizedBox(height: 10),
          Text(summary, style: const TextStyle(fontSize: 12, color: AppColors.neutral700)),
        ],
      ),
    );
  }

  // 5. VERSION HISTORY LIST
  Widget _buildVersionHistoryList(BuildContext context, List<dynamic> versions) {
    if (versions.isEmpty || versions.length == 1) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Version: v1.0 • Single baseline packaging.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 4),
            const Text(
              'Only one version recorded. As this product is identified in subsequent inspections, specification updates and packaging evolution will be tracked chronologically here.',
              style: TextStyle(fontSize: 12, color: AppColors.neutral600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: versions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final v = versions[idx] as Map<String, dynamic>;
        final verId = v['version_id'] ?? 'v${versions.length - idx}.0';
        final isLatest = idx == 0;
        final date = v['effective_from'] ?? 'Established';
        final mrp = v['mrp'] ?? 'N/A';
        final qty = v['net_quantity'] ?? 'N/A';
        final summary = v['ocr_summary'] ?? '';
        final srcId = v['source_inspection_id'];
        final srcCode = v['source_inspection_code'] ?? srcId;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLatest ? AppColors.secondaryBlue.withValues(alpha: 0.5) : AppColors.neutral200,
              width: isLatest ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLatest ? AppColors.secondaryBlue : AppColors.neutral200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  verId,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isLatest ? Colors.white : AppColors.neutral700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recorded: ${date.toString().split("T").first}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neutral800)),
                        if (srcId != null)
                          InkWell(
                            onTap: () => context.push('/inspections/$srcId'),
                            child: Text(
                              'Inspection: $srcCode →',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentBlue),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('MRP: $mrp • Net Qty: $qty', style: const TextStyle(fontSize: 12, color: AppColors.neutral700)),
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(summary, style: const TextStyle(fontSize: 11, color: AppColors.neutral500), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 6. VERSION DIFF SECTION
  Widget _buildVersionDiffSection(Map<String, dynamic> diff) {
    final hasMultiple = diff['has_multiple_versions'] == true;
    final diffMatrix = (diff['diff_matrix'] as List?) ?? [];

    if (!hasMultiple || diffMatrix.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: const [
            Icon(Icons.info_outline, size: 18, color: AppColors.neutral500),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Only one label version has been captured for this product. Comparative parameter diffs will activate automatically when sequential batches are inspected.',
                style: TextStyle(fontSize: 12, color: AppColors.neutral600),
              ),
            ),
          ],
        ),
      );
    }

    final vOld = diff['older_version'] ?? 'v1.0';
    final vNew = diff['newer_version'] ?? 'v2.0';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('PARAMETER', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700))),
                Expanded(flex: 2, child: Text('BASELINE ($vOld)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700))),
                Expanded(flex: 2, child: Text('OBSERVED ($vNew)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700))),
                Expanded(flex: 2, child: Text('STATUS', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700))),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: diffMatrix.length,
            separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.neutral200),
            itemBuilder: (context, idx) {
              final d = diffMatrix[idx] as Map<String, dynamic>;
              final param = d['parameter'] ?? '';
              final oldVal = d['previous_value'] ?? 'N/A';
              final newVal = d['current_value'] ?? 'N/A';
              final status = d['status'] ?? 'UNCHANGED';
              final alert = d['alert'] ?? 'NORMAL';
              final note = d['note'] ?? '';

              final isChanged = status == 'CHANGED';
              final isViolation = alert == 'VIOLATION';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(param, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neutral800)),
                          if (note.isNotEmpty)
                            Text(note, style: TextStyle(fontSize: 10.5, color: isViolation ? AppColors.violationRed : AppColors.neutral500)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(oldVal, style: const TextStyle(fontSize: 12, color: AppColors.neutral700)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        newVal,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isChanged ? FontWeight.bold : FontWeight.normal,
                          color: isViolation ? AppColors.violationRed : (isChanged ? AppColors.neutral900 : AppColors.neutral700),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isViolation
                                ? AppColors.violationBg
                                : (isChanged ? AppColors.reviewAmber.withValues(alpha: 0.15) : AppColors.compliantBg),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isViolation ? AppColors.violation : (isChanged ? const Color(0xFFB45309) : AppColors.compliant),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 7. INSPECTION HISTORY (CRITICAL)
  Widget _buildInspectionHistoryList(BuildContext context, List<dynamic> inspections) {
    if (inspections.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: const Text('No inspection records linked to this product yet.', style: TextStyle(fontSize: 12, color: AppColors.neutral600)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: inspections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final ins = inspections[idx] as Map<String, dynamic>;
        final insId = ins['inspection_id'] ?? '';
        final insCode = ins['inspection_code'] ?? insId;
        final date = ins['inspection_date'] ?? '';
        final seller = ins['seller_name'] ?? ins['business_name'] ?? 'Retail Store';
        final location = ins['location'] ?? 'Field Location';
        final status = ins['status'] ?? 'FINALIZED';
        final score = ins['score'];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_outlined, size: 22, color: AppColors.primaryNavy),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          insCode,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                        ),
                        _buildComplianceBadge(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('$seller • $location', style: const TextStyle(fontSize: 12, color: AppColors.neutral700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Date: ${date.toString().split("T").first}', style: const TextStyle(fontSize: 11, color: AppColors.neutral500)),
                        if (score != null) ...[
                          const SizedBox(width: 12),
                          Text('Score: ${score.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.neutral700)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neutral100,
                  foregroundColor: AppColors.primaryNavy,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.neutral300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 14),
                label: const Text('View Inspection', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => context.push('/inspections/$insId'),
              ),
            ],
          ),
        );
      },
    );
  }

  // 8. COMPLIANCE HISTORY
  Widget _buildComplianceHistoryList(List<dynamic> history) {
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: const Text('No compliance evaluations recorded yet.', style: TextStyle(fontSize: 12, color: AppColors.neutral600)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final h = history[idx] as Map<String, dynamic>;
        final outcome = h['outcome'] ?? 'COMPLIANT';
        final rule = h['rule'] ?? 'Statutory Standard';
        final desc = h['description'] ?? '';
        final date = h['date'] ?? '';
        final insCode = h['inspection_code'] ?? '';

        final isViolation = outcome == 'VIOLATION';
        final isReview = outcome == 'NEEDS_REVIEW';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isViolation ? AppColors.violation : (isReview ? AppColors.reviewAmber : AppColors.neutral200),
              width: (isViolation || isReview) ? 1.2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isViolation ? Icons.error_outline : (isReview ? Icons.warning_amber_rounded : Icons.check_circle_outline),
                size: 18,
                color: isViolation ? AppColors.violation : (isReview ? const Color(0xFFB45309) : AppColors.compliant),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(rule, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neutral900)),
                        Text('${date.toString().split("T").first} • $insCode', style: const TextStyle(fontSize: 10.5, color: AppColors.neutral500)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(desc, style: const TextStyle(fontSize: 11.5, color: AppColors.neutral700)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 9. EVIDENCE SECTION
  Widget _buildEvidenceSection(BuildContext context, List<dynamic> evidence) {
    if (evidence.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: const Text('No packaging image evidence recorded for this product.', style: TextStyle(fontSize: 12, color: AppColors.neutral600)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: evidence.length,
      itemBuilder: (context, idx) {
        final ev = evidence[idx] as Map<String, dynamic>;
        final thumb = ev['thumbnail_url'];
        final insId = ev['inspection_id'];
        final insCode = ev['inspection_code'] ?? 'Inspection';
        final desc = ev['description'] ?? ev['evidence_type'] ?? 'Evidence';

        return InkWell(
          onTap: () {
            if (insId != null) {
              context.push('/inspections/$insId');
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                    ),
                    child: (thumb != null && thumb.toString().startsWith('http'))
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                            child: Image.network(
                              thumb,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: AppColors.neutral400)),
                            ),
                          )
                        : const Center(child: Icon(Icons.image_outlined, size: 36, color: AppColors.neutral400)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(desc, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral800), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('Case: $insCode', style: const TextStyle(fontSize: 10, color: AppColors.accentBlue)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParamTile(String label, String value, {bool isBold = false, bool isBadge = false, bool isMono = false, bool isFpBadge = false, bool isCompBadge = false}) {
    Widget valueWidget;
    if (isFpBadge) {
      valueWidget = _buildFingerprintBadge(value);
    } else if (isCompBadge) {
      valueWidget = _buildComplianceBadge(value);
    } else if (isBadge) {
      valueWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primaryNavy.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
      );
    } else {
      valueWidget = Text(
        value,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          fontFamily: isMono ? 'monospace' : null,
          color: isBold ? AppColors.primaryNavy : AppColors.neutral800,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neutral500)),
        const SizedBox(height: 4),
        valueWidget,
      ],
    );
  }

  Widget _buildFingerprintBadge(String status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status.toUpperCase()) {
      case 'VERIFIED':
        bg = AppColors.passGreen.withValues(alpha: 0.1);
        fg = AppColors.passGreen;
        icon = Icons.check_circle_outline;
        break;
      case 'CHANGED':
        bg = AppColors.reviewAmber.withValues(alpha: 0.15);
        fg = const Color(0xFFB45309);
        icon = Icons.warning_amber_rounded;
        break;
      case 'NEW':
        bg = AppColors.accentBlue.withValues(alpha: 0.1);
        fg = AppColors.accentBlue;
        icon = Icons.fiber_new_outlined;
        break;
      default:
        bg = AppColors.neutral200;
        fg = AppColors.neutral700;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(
            status,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceBadge(String status) {
    Color bg;
    Color fg;
    String label = status;

    switch (status.toUpperCase()) {
      case 'COMPLIANT':
        bg = AppColors.compliantBg;
        fg = AppColors.compliant;
        label = 'Compliant';
        break;
      case 'VIOLATION':
        bg = AppColors.violationBg;
        fg = AppColors.violation;
        label = 'Violation';
        break;
      case 'NEEDS_REVIEW':
        bg = AppColors.reviewAmber.withValues(alpha: 0.15);
        fg = const Color(0xFFB45309);
        label = 'Needs Review';
        break;
      case 'IN_PROGRESS':
        bg = AppColors.neutral100;
        fg = AppColors.neutral700;
        label = 'In Progress';
        break;
      default:
        bg = AppColors.neutral100;
        fg = AppColors.neutral600;
        label = 'Unverified';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
