import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/product_list_web_layout.dart';

final productsListProvider = FutureProvider<List<dynamic>>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get(ApiConstants.products);
    if (response.statusCode == 200 && response.data is List) {
      return response.data as List<dynamic>;
    }
  } catch (e) {
    debugPrint('Error fetching product registry: $e');
  }
  return [];
});

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ResponsiveLayout.isWebDesktop(context)) {
      return const ProductListWebLayout();
    }

    final productsAsync = ref.watch(productsListProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Product Intelligence'),
            SizedBox(width: 8),
            ContextHelpButton(pageId: 'products', color: Colors.white, size: 15),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Registry',
            onPressed: () => ref.refresh(productsListProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Informational Banner on Legal Metrology Fingerprints
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.infoBg,
            child: Row(
              children: [
                const Icon(Icons.fingerprint, color: AppColors.secondary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Identity Fingerprints & Label Evolution Tracking',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.neutral900),
                      ),
                      Text(
                        'Tracks SKU label versions across time. Detects silent shrinkflation, price increments, and undeclared font alterations.',
                        style: TextStyle(fontSize: 11, color: AppColors.neutral700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.neutral200.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.neutral500),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No products have been registered yet.',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.neutral800),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Products will appear here as they are identified and recorded through inspections.',
                            style: TextStyle(fontSize: 13, color: AppColors.neutral600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.qr_code_scanner, size: 18),
                            label: const Text('Start New Inspection', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => context.push('/new-inspection'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = products[index] as Map<String, dynamic>;
                    final id = p['id'] ?? 'prod-$index';
                    final brand = p['brand'] ?? 'Commodity';
                    final name = p['name'] ?? 'Product SKU';
                    final category = p['category'] ?? 'Packaged Commodity';
                    final gtin = p['gtin'] ?? p['barcode'] ?? 'Not available';
                    final qty = p['declared_net_quantity'] ?? p['net_quantity'] ?? 'Not captured';
                    final mrp = p['declared_mrp'] ?? p['mrp'] ?? 'Not captured';
                    final ver = p['active_version'] ?? 'v1.0';
                    final fpStatus = p['fingerprint_status'] ?? 'Verified';
                    final compliance = p['compliance_status'] ?? 'NOT_EVALUATED';
                    final lastDate = p['last_inspection_date'];

                    return AppCard(
                      onTap: () => context.push('/products/$id'),
                      padding: const EdgeInsets.all(14),
                      borderRadius: AppRadii.md,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryNavy.withValues(alpha: 0.08),
                                  borderRadius: AppRadii.xs,
                                ),
                                child: Text(
                                  brand,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                                      borderRadius: AppRadii.full,
                                      border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2), width: 0.8),
                                    ),
                                    child: Text(
                                      'Active: $ver',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accentBlue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildComplianceBadge(compliance),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.neutral600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.qr_code, size: 14, color: AppColors.neutral400),
                              const SizedBox(width: 4),
                              Text(
                                'GTIN: $gtin',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                              ),
                              const SizedBox(width: 14),
                              const Icon(Icons.scale, size: 14, color: AppColors.neutral400),
                              const SizedBox(width: 4),
                              Text(
                                qty,
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                              ),
                              const SizedBox(width: 14),
                              const Icon(Icons.currency_rupee, size: 14, color: AppColors.neutral400),
                              Text(
                                mrp,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                              ),
                            ],
                          ),
                          const Divider(height: 18, color: AppColors.borderLight),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  _buildFingerprintBadge(fpStatus),
                                  if (lastDate != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      'Last: ${lastDate.toString().split("T").first}',
                                      style: const TextStyle(fontSize: 10.5, color: AppColors.neutral500),
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Product Detail',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accentBlue,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.accentBlue),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading products: $e')),
            ),
          ),
        ],
      ),
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
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 3),
          Text(
            status,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
