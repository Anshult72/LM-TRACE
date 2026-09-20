import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/responsive/web_page_container.dart';
import '../../core/responsive/responsive_layout.dart';
import 'models/reference_product_models.dart';

// Provider family for searching reference library
final referenceSearchFilterProvider = StateProvider<Map<String, String>>((ref) {
  return {
    'commodity': '',
    'category': 'ALL',
    'pack_size': '',
    'status': 'ALL',
    'sort_by': 'relevance',
  };
});

final referenceSearchResultsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final filters = ref.watch(referenceSearchFilterProvider);
  final client = ref.watch(apiClientProvider);

  try {
    final queryParams = <String, dynamic>{};
    if (filters['commodity']!.isNotEmpty) queryParams['commodity'] = filters['commodity'];
    if (filters['category']!.isNotEmpty && filters['category'] != 'ALL') queryParams['category'] = filters['category'];
    if (filters['pack_size']!.isNotEmpty) queryParams['pack_size'] = filters['pack_size'];
    if (filters['status']!.isNotEmpty && filters['status'] != 'ALL') queryParams['status'] = filters['status'];
    if (filters['sort_by']!.isNotEmpty) queryParams['sort_by'] = filters['sort_by'];

    final response = await client.get(
      ApiConstants.referenceLibrarySearch,
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data is Map) {
      final data = response.data as Map<String, dynamic>;
      final rawResults = data['results'] as List<dynamic>? ?? [];
      final results = rawResults.map((e) => ReferenceProductSummary.fromJson(e as Map<String, dynamic>)).toList();
      final categories = (data['categories_available'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      return {
        'results': results,
        'categories': categories,
        'total': data['total_results'] ?? results.length,
      };
    }
  } catch (e) {
    debugPrint('Error searching reference library: $e');
  }

  return {'results': <ReferenceProductSummary>[], 'categories': <String>[], 'total': 0};
});

class ReferenceLibraryScreen extends ConsumerStatefulWidget {
  const ReferenceLibraryScreen({super.key});

  @override
  ConsumerState<ReferenceLibraryScreen> createState() => _ReferenceLibraryScreenState();
}

class _ReferenceLibraryScreenState extends ConsumerState<ReferenceLibraryScreen> {
  final _commodityController = TextEditingController();
  final _packSizeController = TextEditingController();
  String _selectedCategory = 'ALL';
  String _selectedStatus = 'ALL';
  String _selectedSort = 'relevance';

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(referenceSearchFilterProvider);
    _commodityController.text = currentFilters['commodity'] ?? '';
    _packSizeController.text = currentFilters['pack_size'] ?? '';
    _selectedCategory = currentFilters['category'] ?? 'ALL';
    _selectedStatus = currentFilters['status'] ?? 'ALL';
    _selectedSort = currentFilters['sort_by'] ?? 'relevance';
  }

  @override
  void dispose() {
    _commodityController.dispose();
    _packSizeController.dispose();
    super.dispose();
  }

  void _applySearch() {
    ref.read(referenceSearchFilterProvider.notifier).state = {
      'commodity': _commodityController.text.trim(),
      'category': _selectedCategory,
      'pack_size': _packSizeController.text.trim(),
      'status': _selectedStatus,
      'sort_by': _selectedSort,
    };
  }

  void _resetSearch() {
    _commodityController.clear();
    _packSizeController.clear();
    setState(() {
      _selectedCategory = 'ALL';
      _selectedStatus = 'ALL';
      _selectedSort = 'relevance';
    });
    ref.read(referenceSearchFilterProvider.notifier).state = {
      'commodity': '',
      'category': 'ALL',
      'pack_size': '',
      'status': 'ALL',
      'sort_by': 'relevance',
    };
  }

  @override
  Widget build(BuildContext context) {
    final searchDataAsync = ref.watch(referenceSearchResultsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: ResponsiveLayout.isMobile(context)
          ? AppBar(
              title: const Text('Reference Library'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.refresh(referenceSearchResultsProvider),
                ),
              ],
            )
          : null,
      body: WebPageContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Navigation Breadcrumb / Section Header
              _buildTopSectionHeader(context),
              const SizedBox(height: 16),

              // 2. Mandatory Statutory Legal Non-Certification Disclaimer Banner (Section 20)
              _buildDisclaimerBanner(),
              const SizedBox(height: 20),

              // 3. Search & Filter Panel
              searchDataAsync.maybeWhen(
                data: (data) => _buildSearchPanel(context, data['categories'] as List<String>),
                orElse: () => _buildSearchPanel(context, []),
              ),
              const SizedBox(height: 24),

              // 4. Search Results Content
              searchDataAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.violationRed),
                        const SizedBox(height: 12),
                        Text('Failed to query reference library: $err', style: const TextStyle(color: AppColors.neutral700)),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _applySearch, child: const Text('Retry Search')),
                      ],
                    ),
                  ),
                ),
                data: (data) {
                  final results = data['results'] as List<ReferenceProductSummary>;
                  final total = data['total'] as int;

                  if (results.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Found $total Reference Product Example${total == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                          ),
                          Text(
                            'Sorted by: ${_selectedSort.toUpperCase()}',
                            style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildResultsGrid(context, results),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSectionHeader(BuildContext context) {
    return Column(
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
              InkWell(
                onTap: () => context.go('/products'),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: const [
                      Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.neutral700),
                      SizedBox(width: 8),
                      Text('Product Registry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.neutral700)),
                    ],
                  ),
                ),
              ),
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
                    Icon(Icons.auto_stories, size: 16, color: AppColors.primaryNavy),
                    SizedBox(width: 8),
                    Text('Compliance Reference Library', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Compliance Reference Library',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Explore previously inspected products, recorded label declarations, and statutory Legal Metrology evaluations as design reference examples.',
                    style: TextStyle(fontSize: 13, color: AppColors.neutral600),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text('Check My Product', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              onPressed: () => context.push('/scanner'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisclaimerBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Soft Blue
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline, color: Color(0xFF1D4ED8), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Statutory Notice & Reference Disclaimer: Reference examples are based strictly on previously recorded inspection and compliance data in LM-TRACE. They are provided for design guidance and statutory reference purposes and do not constitute legal certification or a guarantee that the same label layout is compliant for a different product, formulation, or market context.',
              style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel(BuildContext context, List<String> categories) {
    final categoryItems = ['ALL', ...categories];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral300),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What product are you developing?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;

              return Column(
                children: [
                  Row(
                    children: [
                      // Commodity Input
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _commodityController,
                          decoration: InputDecoration(
                            labelText: 'Commodity / Product Name',
                            hintText: 'e.g. Wheat Flour, Basmati Rice, Shampoo',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onSubmitted: (_) => _applySearch(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Pack Size Input
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _packSizeController,
                          decoration: InputDecoration(
                            labelText: 'Target Pack Size',
                            hintText: 'e.g. 500 g, 1 kg, 200 ml',
                            prefixIcon: const Icon(Icons.scale_outlined, size: 20),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onSubmitted: (_) => _applySearch(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Category Dropdown
                      Expanded(
                        flex: isNarrow ? 1 : 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: categoryItems.contains(_selectedCategory) ? _selectedCategory : 'ALL',
                          decoration: InputDecoration(
                            labelText: 'Category',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: categoryItems.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat == 'ALL' ? 'All Categories' : cat, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                              _applySearch();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status Dropdown
                      Expanded(
                        flex: isNarrow ? 1 : 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Reference Status',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('All Inspection Statuses', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'COMPLIANT', child: Text('Compliant Reference Only', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'NEEDS_REVIEW', child: Text('Observations / Needs Review', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'ELIGIBLE_ONLY', child: Text('Verified Eligible Only', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedStatus = val);
                              _applySearch();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Action Buttons
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _applySearch,
                        child: const Text('Find References', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Reset Filters',
                        icon: const Icon(Icons.refresh, color: AppColors.neutral600),
                        onPressed: _resetSearch,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsGrid(BuildContext context, List<ReferenceProductSummary> results) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 3;
        if (constraints.maxWidth < 650) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1050) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.72,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: results.length,
          itemBuilder: (context, idx) {
            return _buildReferenceCard(context, results[idx]);
          },
        );
      },
    );
  }

  Widget _buildReferenceCard(BuildContext context, ReferenceProductSummary item) {
    // Determine status badge color
    Color statusBg = const Color(0xFFF1F5F9);
    Color statusText = const Color(0xFF475569);
    IconData statusIcon = Icons.info_outline;

    if (item.referenceStatus == 'COMPLIANT') {
      statusBg = const Color(0xFFECFDF5);
      statusText = const Color(0xFF047857);
      statusIcon = Icons.check_circle_outline;
    } else if (item.referenceStatus == 'NEEDS_REVIEW') {
      statusBg = const Color(0xFFFFFBEB);
      statusText = const Color(0xFFB45309);
      statusIcon = Icons.warning_amber_outlined;
    } else if (item.referenceStatus == 'VIOLATION') {
      statusBg = const Color(0xFFFEF2F2);
      statusText = const Color(0xFFB91C1C);
      statusIcon = Icons.error_outline;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.neutral300.withValues(alpha: 0.8)),
      ),
      child: InkWell(
        onTap: () => context.push('/reference-library/${item.productId}'),
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Label Image / Photo Thumbnail
            Container(
              height: 140,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              ),
              child: Stack(
                children: [
                  (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                          child: Image.network(
                            item.thumbnailUrl!,
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Text('Label image unavailable', style: TextStyle(fontSize: 11, color: AppColors.neutral500)),
                            ),
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported_outlined, size: 32, color: AppColors.neutral400),
                              SizedBox(height: 4),
                              Text('Label image unavailable', style: TextStyle(fontSize: 11, color: AppColors.neutral500)),
                            ],
                          ),
                        ),
                  // Version badge overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.activeVersion,
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Card Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand & Category
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.brand.toUpperCase(),
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.accentBlue, letterSpacing: 0.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.neutral200, borderRadius: BorderRadius.circular(4)),
                          child: Text(item.category, style: const TextStyle(fontSize: 9.5, color: AppColors.neutral700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Product Name
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Pack Size & MRP
                    Row(
                      children: [
                        const Icon(Icons.scale_outlined, size: 14, color: AppColors.neutral600),
                        const SizedBox(width: 4),
                        Text(item.packSize, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.neutral800)),
                        const SizedBox(width: 12),
                        const Icon(Icons.currency_rupee, size: 14, color: AppColors.neutral600),
                        Text(item.declaredMrp, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.neutral800)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Reference Status Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusText.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 13, color: statusText),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              item.referenceStatusLabel,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Applicable Requirements Tags
                    const Text('EVALUATED REQUIREMENTS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.neutral500)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: item.applicableRequirements.take(2).map((req) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                          child: Text(req, style: const TextStyle(fontSize: 10, color: Color(0xFF334155))),
                        );
                      }).toList(),
                    ),
                    const Spacer(),

                    // Explainable Match Reason (Section 30)
                    if (item.matchReasons.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Why matched: ${item.matchReasons[0]}',
                          style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.neutral500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: AppColors.accentBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 14, color: AppColors.accentBlue),
                        label: const Text('View Reference', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentBlue)),
                        onPressed: () => context.push('/reference-library/${item.productId}'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 550),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neutral300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(Icons.search_off_outlined, size: 48, color: AppColors.neutral500),
            ),
            const SizedBox(height: 16),
            const Text(
              'No matching reference products found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 8),
            const Text(
              'No previously inspected products match your current search query. Try searching with a broader commodity term, choosing "All Categories", or removing pack size restrictions.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.neutral600, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _resetSearch,
                  child: const Text('Clear All Filters'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy, foregroundColor: Colors.white),
                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                  label: const Text('Check My Product'),
                  onPressed: () => context.push('/scanner'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
