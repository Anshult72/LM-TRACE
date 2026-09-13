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
    if (response.statusCode == 200) {
      return response.data as List<dynamic>;
    }
  } catch (e) {
    // Fallback demo products if offline
  }
  return [
    {
      'id': 'prod-001',
      'brand': 'Heritage Foods',
      'name': 'Heritage Pure Cow Ghee 1L',
      'gtin': '8901234567890',
      'category': 'Edible Oils & Fats',
      'declared_net_quantity': '1 L',
      'declared_mrp': '₹650',
      'active_version': 'v2',
      'fingerprint_hash': 'sha256:7b92f...a10',
    },
    {
      'id': 'prod-002',
      'brand': 'Greenfield Organics',
      'name': 'Greenfield Premium Whole Wheat Atta 5kg',
      'gtin': '8909876543210',
      'category': 'Packaged Food',
      'declared_net_quantity': '5 kg',
      'declared_mrp': '₹340',
      'active_version': 'v3',
      'fingerprint_hash': 'sha256:9c41a...d94',
    },
    {
      'id': 'prod-003',
      'brand': 'Kisan Shakti',
      'name': 'Kisan Shakti Refined Mustard Oil 500ml',
      'gtin': '8905544332211',
      'category': 'Edible Oils & Fats',
      'declared_net_quantity': '500 ml',
      'declared_mrp': '₹110',
      'active_version': 'v1',
      'fingerprint_hash': 'sha256:3e218...f82',
    }
  ];
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
        title: const Text('Product Intelligence & Fingerprints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
                        'Tracks SKU label versions across time. Detects silent shrinkflation, price increments, and undeclared font size alterations.',
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
                  return const Center(
                    child: Text('No registered commodities found in registry.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = products[index] as Map<String, dynamic>;
                    final brand = p['brand'] ?? 'Commodity';
                    final name = p['name'] ?? 'Product SKU';
                    final gtin = p['gtin'] ?? 'N/A';
                    final qty = p['declared_net_quantity'] ?? '';
                    final mrp = p['declared_mrp'] ?? '';
                    final ver = p['active_version'] ?? 'v1';
                    final id = p['id'] ?? 'prod-001';

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
                          const SizedBox(height: 6),
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
                                  const Icon(Icons.security, size: 14, color: AppColors.passGreen),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Fingerprint: ${p['fingerprint_hash'] ?? 'Verified'}',
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Version History & Diff',
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
}
