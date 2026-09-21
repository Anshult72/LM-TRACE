import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/responsive/web_page_container.dart';
import '../../../core/widgets/widgets.dart';
import '../product_list_screen.dart';

/// Desktop enterprise layout for Product Intelligence & Fingerprint Registry.
class ProductListWebLayout extends ConsumerStatefulWidget {
  const ProductListWebLayout({super.key});

  @override
  ConsumerState<ProductListWebLayout> createState() => _ProductListWebLayoutState();
}

class _ProductListWebLayoutState extends ConsumerState<ProductListWebLayout> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider);

    return WebPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab switcher allowing instant navigation between Product Registry and Reference Library
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.neutral200.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1)),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primaryNavy),
                      SizedBox(width: 8),
                      Text('Product Registry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => context.go('/reference-library'),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: const [
                        Icon(Icons.auto_stories, size: 16, color: AppColors.neutral700),
                        SizedBox(width: 8),
                        Text('Compliance Reference Library', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.neutral700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 1. Header & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Product Intelligence & Fingerprint Registry',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                      SizedBox(width: 8),
                      ContextHelpButton(pageId: 'products', size: 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Persistent pre-packaged SKU identities, label version evolution, and statutory compliance history',
                    style: TextStyle(fontSize: 13, color: AppColors.neutral600),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      side: const BorderSide(color: AppColors.neutral300),
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh Registry', style: TextStyle(fontSize: 12)),
                    onPressed: () => ref.refresh(productsListProvider),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Inspection', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    onPressed: () => context.push('/new-inspection'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Informational Banner on Label Evolution & Shrinkflation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: const [
                Icon(Icons.fingerprint, color: AppColors.secondaryBlue, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Deterministic Identity Fingerprint Engine: Hashing pre-packaged specifications across inspection cases detects silent shrinkflation, price increments, and undeclared font alterations over time.',
                    style: TextStyle(fontSize: 12, color: AppColors.neutral800, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products by GTIN barcode, brand, commodity name, or product ID...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.neutral400),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.neutral500),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.neutral300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.neutral300),
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          const SizedBox(height: 18),

          // 4. Products Table
          productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inventory_2_outlined, size: 52, color: AppColors.neutral400),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No products have been registered yet.',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Products will appear here as they are identified and recorded through inspections.',
                        style: TextStyle(fontSize: 13, color: AppColors.neutral600),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.qr_code_scanner, size: 18),
                        label: const Text('Start New Inspection', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => context.push('/new-inspection'),
                      ),
                    ],
                  ),
                );
              }

              final filtered = products.where((p) {
                if (_searchQuery.isEmpty) return true;
                final q = _searchQuery.toLowerCase();
                final name = (p['name'] ?? '').toString().toLowerCase();
                final brand = (p['brand'] ?? '').toString().toLowerCase();
                final gtin = (p['gtin'] ?? p['barcode'] ?? '').toString().toLowerCase();
                final id = (p['id'] ?? '').toString().toLowerCase();
                return name.contains(q) || brand.contains(q) || gtin.contains(q) || id.contains(q);
              }).toList();

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.neutral200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header Row (Per Section 6: PRODUCT, CATEGORY, GTIN, PACK SIZE/MRP, ACTIVE VERSION, FINGERPRINT, LAST INSPECTION, COMPLIANCE STATUS, ACTIONS)
                    Container(
                      color: AppColors.neutral100,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: const [
                          Expanded(flex: 3, child: Text('PRODUCT & COMMODITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700))),
                          Expanded(flex: 2, child: Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700))),
                          Expanded(flex: 2, child: Text('GTIN BARCODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700))),
                          Expanded(flex: 2, child: Text('PACK SIZE / MRP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700))),
                          Expanded(flex: 2, child: Text('ACTIVE VERSION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700))),
                          Expanded(flex: 2, child: Text('FINGERPRINT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700))),
                          Expanded(flex: 2, child: Text('LAST INSPECTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700))),
                          Expanded(flex: 2, child: Text('COMPLIANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700))),
                          Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700)))),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.neutral200),

                    // Product Rows
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text('No products match your search query.', style: TextStyle(color: AppColors.neutral500)),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.neutral200),
                        itemBuilder: (context, index) {
                          final prod = filtered[index];
                          final id = prod['id'] ?? 'prod-$index';
                          final brand = prod['brand'] ?? 'Brand';
                          final name = prod['name'] ?? 'Product';
                          final category = prod['category'] ?? 'Packaged Commodity';
                          final gtin = prod['gtin'] ?? prod['barcode'] ?? 'Not available';
                          final qty = prod['declared_net_quantity'] ?? prod['net_quantity'] ?? 'Not captured';
                          final mrp = prod['declared_mrp'] ?? prod['mrp'] ?? 'Not captured';
                          final version = prod['active_version'] ?? 'v1.0';
                          final fpStatus = prod['fingerprint_status'] ?? 'Verified';
                          final fpHash = prod['fingerprint_hash'] ?? 'sha256:verified';
                          final lastDate = prod['last_inspection_date'];
                          final lastCode = prod['last_inspection_code'];
                          final compliance = prod['compliance_status'] ?? 'NOT_EVALUATED';

                          return InkWell(
                            onTap: () => context.push('/products/$id'),
                            hoverColor: AppColors.neutral50,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              child: Row(
                                children: [
                                  // Product & Commodity
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryNavy)),
                                        const SizedBox(height: 2),
                                        Text(brand, style: const TextStyle(fontSize: 11.5, color: AppColors.neutral600)),
                                      ],
                                    ),
                                  ),
                                  // Category
                                  Expanded(
                                    flex: 2,
                                    child: Text(category, style: const TextStyle(fontSize: 12, color: AppColors.neutral700)),
                                  ),
                                  // GTIN Barcode
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.qr_code, size: 14, color: AppColors.neutral500),
                                        const SizedBox(width: 4),
                                        Text(
                                          gtin,
                                          style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', color: AppColors.neutral800),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Pack Size / MRP
                                  Expanded(
                                    flex: 2,
                                    child: Text('$qty • $mrp', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.neutral800)),
                                  ),
                                  // Active Version
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryBlue.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(version, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondaryBlue)),
                                      ),
                                    ),
                                  ),
                                  // Fingerprint
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFingerprintBadge(fpStatus),
                                        const SizedBox(height: 2),
                                        Text(
                                          fpHash,
                                          style: const TextStyle(fontSize: 9.5, fontFamily: 'monospace', color: AppColors.neutral500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Last Inspection
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lastDate != null ? lastDate.toString().split("T").first : "Not inspected",
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.neutral800),
                                        ),
                                        if (lastCode != null)
                                          Text(
                                            lastCode,
                                            style: const TextStyle(fontSize: 10, color: AppColors.neutral500),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Compliance
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: _buildComplianceBadge(compliance),
                                    ),
                                  ),
                                  // Actions
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: const Text('View Detail', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                            onPressed: () => context.push('/products/$id'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Center(child: Text('Error loading product registry: $err')),
            ),
          ),
          const SizedBox(height: 32),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
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
