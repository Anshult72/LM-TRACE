import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/widgets/widgets.dart';
import 'inspections_controller.dart';
import 'widgets/inspections_list_web_layout.dart';

class InspectionsListScreen extends ConsumerStatefulWidget {
  final String? initialStatusFilter;

  const InspectionsListScreen({super.key, this.initialStatusFilter});

  @override
  ConsumerState<InspectionsListScreen> createState() => _InspectionsListScreenState();
}

class _InspectionsListScreenState extends ConsumerState<InspectionsListScreen> {
  String _filter = 'ALL';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialStatusFilter != null && widget.initialStatusFilter!.isNotEmpty) {
      final f = widget.initialStatusFilter!.toUpperCase();
      if (['COMPLIANT', 'COMPLETED', 'FINALIZED'].contains(f)) {
        _filter = 'COMPLIANT';
      } else if (['VIOLATION', 'VIOLATIONS', 'POTENTIAL_VIOLATION'].contains(f)) {
        _filter = 'VIOLATIONS';
      } else if (['REVIEW', 'NEEDS_REVIEW', 'IN_REVIEW', 'REVIEW_REQUIRED'].contains(f)) {
        _filter = 'REVIEW';
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inspectionsProvider.notifier).fetchInspections();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isWebDesktop(context)) {
      return InspectionsListWebLayout(initialStatusFilter: widget.initialStatusFilter);
    }

    final state = ref.watch(inspectionsProvider);

    List<InspectionModel> filtered = state.inspections.where((ins) {
      if (_filter == 'COMPLIANT' && !['COMPLETED', 'COMPLIANT'].contains(ins.status.toUpperCase())) {
        return false;
      }
      if (_filter == 'VIOLATIONS' && !['POTENTIAL_VIOLATION', 'VIOLATION'].contains(ins.status.toUpperCase())) {
        return false;
      }
      if (_filter == 'REVIEW' && !['REVIEW_REQUIRED', 'IN_REVIEW', 'DRAFT'].contains(ins.status.toUpperCase())) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesCode = ins.inspectionCode.toLowerCase().contains(q);
        final matchesLoc = ins.location.toLowerCase().contains(q);
        final matchesSeller = (ins.sellerName ?? ins.businessName ?? '').toLowerCase().contains(q);
        return matchesCode || matchesLoc || matchesSeller;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Inspections Registry'),
            SizedBox(width: 8),
            ContextHelpButton(pageId: 'inspections', color: Colors.white, size: 15),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(inspectionsProvider.notifier).fetchInspections(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by case ID, establishment, or location...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ALL', 'All Cases (${state.inspections.length})'),
                      const SizedBox(width: 8),
                      _buildFilterChip('VIOLATIONS', 'Violations Flagged', color: AppColors.violation),
                      const SizedBox(width: 8),
                      _buildFilterChip('REVIEW', 'Pending Review', color: AppColors.review),
                      const SizedBox(width: 8),
                      _buildFilterChip('COMPLIANT', 'Compliant', color: AppColors.compliant),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.neutral200),

          // List View
          Expanded(
            child: state.isLoading && state.inspections.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: _searchQuery.isNotEmpty
                            ? 'No cases match "$_searchQuery"'
                            : 'No inspections found',
                        description: 'Try adjusting your search terms or filter selection to see other inspection records.',
                        actionLabel: _searchQuery.isNotEmpty ? 'Clear Search' : 'New Inspection',
                        onActionPressed: () {
                          if (_searchQuery.isNotEmpty) {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          } else {
                            context.push('/new-inspection');
                          }
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final ins = filtered[index];
                          return _buildInspectionTile(context, ins);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryNavy,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Inspection',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        onPressed: () => context.push('/new-inspection'),
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, {Color? color}) {
    final isSelected = _filter == filterKey;
    final chipColor = color ?? AppColors.primaryNavy;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _filter = filterKey),
          borderRadius: AppRadii.full,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? chipColor : Colors.white,
              borderRadius: AppRadii.full,
              border: Border.all(
                color: isSelected ? chipColor : AppColors.borderLight,
                width: 1.1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.neutral700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInspectionTile(BuildContext context, InspectionModel ins) {
    return AppCard(
      onTap: () => context.push('/inspections/${ins.id}'),
      padding: const EdgeInsets.all(14),
      borderRadius: AppRadii.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    ins.inspectionCode,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppStatusBadge(
                    status: ins.status,
                    size: BadgeSize.sm,
                  ),
                ],
              ),
              Text(
                ins.inspectionDate.split('T').first,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ins.businessName ?? ins.sellerName ?? 'Retail Goods Inspection',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.neutral500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  ins.location,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  _buildBadge(ins.inspectionType, Icons.category_outlined),
                  if (ins.packageConstructionType != null)
                    _buildBadge(
                      ins.packageConstructionType == 'BLOWN_FORMED_MOLDED' ? 'Molded/Blown' : 'Standard Pack',
                      Icons.inventory_2_outlined,
                    ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Audit Details',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.accentBlue),
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
  }

  Widget _buildBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.neutral600),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(fontSize: 10, color: AppColors.neutral700, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
