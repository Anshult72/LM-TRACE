import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_brand.dart';
import '../../core/widgets/widgets.dart';
import '../../core/responsive/web_page_container.dart';
import 'models/statutory_models.dart';
import 'statutory_offline_registry.dart';

// State Providers for Statutory Reference
final statutorySummaryProvider = FutureProvider<StatutorySummaryModel?>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get(ApiConstants.statutorySummary);
    if (response.statusCode == 200 && response.data is Map) {
      return StatutorySummaryModel.fromJson(response.data as Map<String, dynamic>);
    }
  } catch (e) {
    debugPrint('Error loading statutory summary: $e');
  }
  return kStatutorySummaryBaseline;
});

final statutoryFilterProvider = StateProvider<Map<String, String>>((ref) {
  return {
    'q': '',
    'doc_type': 'ALL',
    'status': 'ALL',
    'family': 'ALL',
  };
});

final statutoryDocumentsProvider = FutureProvider<List<StatutoryDocumentModel>>((ref) async {
  final filters = ref.watch(statutoryFilterProvider);
  final client = ref.watch(apiClientProvider);
  try {
    final queryParams = <String, dynamic>{};
    if (filters['q']!.isNotEmpty) queryParams['q'] = filters['q'];
    if (filters['doc_type'] != 'ALL') queryParams['doc_type'] = filters['doc_type'];
    if (filters['status'] != 'ALL') queryParams['status'] = filters['status'];
    if (filters['family'] != 'ALL') queryParams['family'] = filters['family'];

    final response = await client.get(
      ApiConstants.statutoryDocuments,
      queryParameters: queryParams,
    );
    if (response.statusCode == 200 && response.data is List && (response.data as List).isNotEmpty) {
      return (response.data as List).map((e) => StatutoryDocumentModel.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (e) {
    debugPrint('Error loading statutory documents: $e');
  }

  // Verified baseline registry fallback
  var list = List<StatutoryDocumentModel>.from(kStatutoryDocumentsBaseline);
  final q = filters['q']!.toLowerCase().trim();
  if (q.isNotEmpty) {
    list = list.where((d) =>
      d.title.toLowerCase().contains(q) ||
      d.shortTitle.toLowerCase().contains(q) ||
      (d.notificationNumber ?? '').toLowerCase().contains(q) ||
      (d.gazetteReference ?? '').toLowerCase().contains(q) ||
      d.summary.toLowerCase().contains(q)
    ).toList();
  }
  if (filters['doc_type'] != 'ALL') {
    list = list.where((d) => d.documentType.toUpperCase() == filters['doc_type']!.toUpperCase()).toList();
  }
  if (filters['status'] != 'ALL') {
    list = list.where((d) => d.status.toUpperCase() == filters['status']!.toUpperCase()).toList();
  }
  return list;
});

final statutoryRulesProvider = FutureProvider<List<StatutoryRuleModel>>((ref) async {
  final filters = ref.watch(statutoryFilterProvider);
  final client = ref.watch(apiClientProvider);
  try {
    final queryParams = <String, dynamic>{};
    if (filters['q']!.isNotEmpty) queryParams['q'] = filters['q'];
    if (filters['doc_type'] != 'ALL') queryParams['doc_type'] = filters['doc_type'];
    if (filters['status'] != 'ALL') queryParams['status'] = filters['status'];
    if (filters['family'] != 'ALL') queryParams['family'] = filters['family'];

    final response = await client.get(
      ApiConstants.statutoryRules,
      queryParameters: queryParams,
    );
    if (response.statusCode == 200 && response.data is List && (response.data as List).isNotEmpty) {
      return (response.data as List).map((e) => StatutoryRuleModel.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (e) {
    debugPrint('Error loading statutory rules: $e');
  }

  // Verified baseline registry fallback
  var list = List<StatutoryRuleModel>.from(kStatutoryRulesBaseline);
  final q = filters['q']!.toLowerCase().trim();
  if (q.isNotEmpty) {
    list = list.where((r) =>
      r.title.toLowerCase().contains(q) ||
      r.ruleNumber.toLowerCase().contains(q) ||
      r.ruleCode.toLowerCase().contains(q) ||
      (r.mappedRuleEngineCode ?? '').toLowerCase().contains(q) ||
      r.requirementSummary.toLowerCase().contains(q) ||
      r.subject.toLowerCase().contains(q) ||
      r.sourceReference.toLowerCase().contains(q)
    ).toList();
  }
  if (filters['status'] != 'ALL') {
    list = list.where((r) => r.status.toUpperCase() == filters['status']!.toUpperCase()).toList();
  }
  return list;
});

final statutoryFamiliesProvider = FutureProvider<List<StatutoryFamilyModel>>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get(ApiConstants.statutoryFamilies);
    if (response.statusCode == 200 && response.data is List) {
      return (response.data as List).map((e) => StatutoryFamilyModel.fromJson(e as Map<String, dynamic>)).toList();
    }
  } catch (e) {
    debugPrint('Error loading statutory families: $e');
  }
  return [];
});

class StatutoryReferenceScreen extends ConsumerStatefulWidget {
  const StatutoryReferenceScreen({super.key});

  @override
  ConsumerState<StatutoryReferenceScreen> createState() => _StatutoryReferenceScreenState();
}

class _StatutoryReferenceScreenState extends ConsumerState<StatutoryReferenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter(String key, String value) {
    final current = Map<String, String>.from(ref.read(statutoryFilterProvider));
    current[key] = value;
    ref.read(statutoryFilterProvider.notifier).state = current;
  }

  void _resetFilters() {
    _searchController.clear();
    ref.read(statutoryFilterProvider.notifier).state = {
      'q': '',
      'doc_type': 'ALL',
      'status': 'ALL',
      'family': 'ALL',
    };
  }

  Future<void> _openExternalUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        debugPrint('Could not open external URL: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(statutorySummaryProvider);
    final filters = ref.watch(statutoryFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceIvory,
      body: WebPageContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Breadcrumb & Header
              _buildHeader(context),
              const SizedBox(height: 20),

              // 2. Summary KPI Metrics Bar
              summaryAsync.when(
                data: (summary) => _buildSummaryKpis(summary),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => _buildSummaryKpis(kStatutorySummaryBaseline),
              ),
              const SizedBox(height: 24),

              // 3. Search & Filter Bar
              _buildSearchAndFilters(filters),
              const SizedBox(height: 20),

              // 4. Tab Navigation
              _buildTabs(),
              const SizedBox(height: 20),

              // 5. Tab Content
              SizedBox(
                height: 850,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRulesTab(),
                    _buildDocumentsTab(),
                    _buildTimelineTab(),
                    _buildAboutFrameworkTab(summaryAsync.value),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
              child: const Text(
                'Platform',
                style: TextStyle(fontSize: 12, color: AppColors.steelBlue),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.steelBlue),
            const SizedBox(width: 6),
            const Text(
              'Statutory Reference & Law Library',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.inspectionGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Main Title
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Statutory Reference',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      ContextHelpButton(pageId: 'statutory_reference', size: 18),
                    ],
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Official statutory sources, gazette notifications, and legal provisions governing LM-TRACE automated compliance rules.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(statutorySummaryProvider);
                ref.invalidate(statutoryDocumentsProvider);
                ref.invalidate(statutoryRulesProvider);
                ref.invalidate(statutoryFamiliesProvider);
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryNavy,
                side: const BorderSide(color: AppColors.skyGrey),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => _openExternalUrl('https://consumeraffairs.gov.in/pages/legal-metrology-act'),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('DCA Official Portal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryKpis(StatutorySummaryModel? summary) {
    if (summary == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildKpiCard(
              title: 'OFFICIAL DOCUMENTS',
              mainValue: '${summary.totalDocuments}',
              subText: '${summary.amendmentDocuments} Amendments & Advisories',
              icon: Icons.source_rounded,
              color: AppColors.inspectionGreen,
              badgeText: 'DCA Verified',
              badgeColor: AppColors.mintMist,
              badgeTextColor: AppColors.primaryNavy,
              width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
            ),
            _buildKpiCard(
              title: 'ACTIVE STATUTORY PROVISIONS',
              mainValue: '${summary.activeStatutoryRules}',
              subText: '${summary.automatedRulesCount} Automated Engine Mappings',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.successGreen,
              badgeText: 'Legally Enforced',
              badgeColor: AppColors.mintMist,
              badgeTextColor: AppColors.inspectionGreen,
              width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
            ),
            _buildKpiCard(
              title: 'SCHEDULED PROVISIONS',
              mainValue: '${summary.scheduledRules}',
              subText: 'Scheduled Effective: 1 July 2027',
              icon: Icons.schedule_rounded,
              color: AppColors.warningAmber,
              badgeText: 'NOT YET EFFECTIVE',
              badgeColor: AppColors.warningAmber.withValues(alpha: 0.1),
              badgeTextColor: AppColors.warningAmber,
              width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
            ),
            _buildKpiCard(
              title: 'ENFORCEMENT JURISDICTION',
              mainValue: 'Union of India',
              subText: 'Dept of Consumer Affairs, MoCA',
              icon: Icons.account_balance_rounded,
              color: AppColors.steelBlue,
              badgeText: 'National Scope',
              badgeColor: AppColors.surfaceIvory,
              badgeTextColor: AppColors.primaryNavy,
              width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String mainValue,
    required String subText,
    required IconData icon,
    required Color color,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                mainValue,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(Map<String, String> filters) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Search Input
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => _applyFilter('q', val.trim()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilter('q', '');
                            },
                          )
                        : null,
                    hintText: 'Search provisions, rule numbers, G.S.R. numbers, keywords (e.g., Rule 6, G.S.R. 779(E), MRP, Table-I)...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF0F2942), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Document Type Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filters['doc_type'] ?? 'ALL',
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All Document Types', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'ACT', child: Text('Principal Act (2009)', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'RULES', child: Text('Principal Rules (2011)', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'GAZETTE_AMENDMENT', child: Text('Gazette Amendments', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'OFFICIAL_ADVISORY', child: Text('Official Advisories', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'PROPOSED_AMENDMENT', child: Text('Proposed Standards', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (val) {
                      if (val != null) _applyFilter('doc_type', val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Status Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filters['status'] ?? 'ALL',
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All Statuses', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'ACTIVE', child: Text('Enforced / Active Only', style: TextStyle(fontSize: 13))),
                      DropdownMenuItem(value: 'NOT_YET_EFFECTIVE', child: Text('Scheduled (Future)', style: TextStyle(fontSize: 13))),
                    ],
                    onChanged: (val) {
                      if (val != null) _applyFilter('status', val);
                    },
                  ),
                ),
              ),

              // Reset Filters Button
              if (filters['q']!.isNotEmpty || filters['doc_type'] != 'ALL' || filters['status'] != 'ALL') ...[
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                  label: const Text('Reset', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF0F2942),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        indicatorColor: const Color(0xFF0F2942),
        indicatorWeight: 3,
        tabs: const [
          Tab(
            icon: Icon(Icons.rule_folder_outlined, size: 18),
            text: 'Statutory Rules & Provisions',
          ),
          Tab(
            icon: Icon(Icons.article_outlined, size: 18),
            text: 'Official Statutory Documents',
          ),
          Tab(
            icon: Icon(Icons.timeline_rounded, size: 18),
            text: 'Amendment History & Timeline',
          ),
          Tab(
            icon: Icon(Icons.account_tree_outlined, size: 18),
            text: 'Statutory Framework & About',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: STATUTORY RULES & PROVISIONS
  // ==========================================
  Widget _buildRulesTab() {
    final rulesAsync = ref.watch(statutoryRulesProvider);

    return rulesAsync.when(
      data: (rules) {
        if (rules.isEmpty) {
          return _buildEmptyState('No statutory rules matching the filter criteria.');
        }

        return ListView.separated(
          itemCount: rules.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final rule = rules[index];
            return _buildRuleCard(rule);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading rules: $e')),
    );
  }

  Widget _buildRuleCard(StatutoryRuleModel rule) {
    final isScheduled = rule.isScheduled;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isScheduled ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rule Code Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Text(
                  rule.ruleCodeDisplay(rule.ruleCode),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Rule Number
              Text(
                rule.ruleNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 12),

              // Status Badge
              _buildStatusBadge(rule.status, rule.effectiveFrom),
              const Spacer(),

              // Automated Rule Engine Mapping Badge
              if (rule.mappedRuleEngineCode != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.memory_rounded, size: 13, color: Color(0xFF4338CA)),
                      const SizedBox(width: 5),
                      Text(
                        'Automated: ${rule.mappedRuleEngineCode}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4338CA),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Traceability Button
              OutlinedButton.icon(
                onPressed: () => _showRuleDetailDialog(rule),
                icon: const Icon(Icons.account_tree_outlined, size: 14),
                label: const Text('Traceability & Details', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F2942),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            rule.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),

          // Requirement Summary
          Text(
            rule.requirementSummary,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Metadata row: Document, Publication Date vs Effective Date
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 13, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  rule.documentTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              _buildDatePill('Published', _formatIsoDate(rule.publicationDate)),
              const SizedBox(width: 12),
              _buildDatePill(
                isScheduled ? 'Effective (Future)' : 'Effective',
                _formatIsoDate(rule.effectiveFrom),
                isHighlight: isScheduled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: OFFICIAL STATUTORY DOCUMENTS
  // ==========================================
  Widget _buildDocumentsTab() {
    final docsAsync = ref.watch(statutoryDocumentsProvider);

    return docsAsync.when(
      data: (docs) {
        if (docs.isEmpty) {
          return _buildEmptyState('No official statutory documents matching the filter criteria.');
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _buildDocumentCard(doc);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading documents: $e')),
    );
  }

  Widget _buildDocumentCard(StatutoryDocumentModel doc) {
    final isScheduled = doc.isScheduled;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isScheduled ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Badge
              _buildDocTypeBadge(doc.documentType),
              const SizedBox(width: 10),

              // Title & Notification Number
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (doc.notificationNumber != null)
                      Text(
                        'Notification / G.S.R.: ${doc.notificationNumber!}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F2942),
                        ),
                      ),
                    if (doc.gazetteReference != null)
                      Text(
                        doc.gazetteReference!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Status
              _buildStatusBadge(doc.status, doc.effectiveDate),
              const SizedBox(width: 10),

              // Official Document URL
              if (doc.officialDocumentUrl != null || doc.sourceUrl != null)
                OutlinedButton.icon(
                  onPressed: () => _openExternalUrl(doc.officialDocumentUrl ?? doc.sourceUrl),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                  label: const Text('Official Gazette PDF', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F2942),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            doc.summary,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Metadata row
          Row(
            children: [
              const Icon(Icons.account_balance_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  doc.authority,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              _buildDatePill('Published', _formatIsoDate(doc.publicationDate)),
              const SizedBox(width: 10),
              _buildDatePill(
                isScheduled ? 'Effective (Future)' : 'Effective',
                _formatIsoDate(doc.effectiveDate),
                isHighlight: isScheduled,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: AMENDMENT HISTORY & TIMELINE
  // ==========================================
  Widget _buildTimelineTab() {
    final timelineEvents = [
      {
        'year': '2009',
        'effective': '1 April 2011',
        'title': 'The Legal Metrology Act, 2009 (Act No. 1 of 2010)',
        'notification': 'Act No. 1 of 2010 • Published 14 Jan 2010',
        'type': 'PRINCIPAL_ACT',
        'status': 'ACTIVE',
        'description':
            'Enacted by Parliament to establish and enforce standards of weights and measures, regulate trade and commerce in pre-packaged commodities, and establish Section 18 statutory packaging mandates.',
      },
      {
        'year': '2011',
        'effective': '1 April 2011',
        'title': 'Legal Metrology (Packaged Commodities) Rules, 2011',
        'notification': 'G.S.R. 202(E) • Published 7 Mar 2011',
        'type': 'PRINCIPAL_RULES',
        'status': 'ACTIVE',
        'description':
            'Framed mandatory label declarations under Rule 6(1), minimum numeral/letter font height ratio Table-I under Rule 7, and legibility contrast requirements under Rule 9.',
      },
      {
        'year': '2017',
        'effective': '1 January 2018',
        'title': 'E-Commerce Platform Mandatory Declarations Amendment',
        'notification': 'G.S.R. 629(E) • Published 23 Jun 2017',
        'type': 'AMENDMENT',
        'status': 'ACTIVE',
        'description':
            'Inserted Rule 6(10) mandating e-commerce marketplaces to display all statutory declarations (MRP, manufacturer, origin, net quantity) on digital product listing viewports prior to purchase.',
      },
      {
        'year': '2021',
        'effective': '1 December 2022',
        'title': 'Unit Sale Price (USP) Mandatory Declaration Amendment',
        'notification': 'G.S.R. 779(E) • Published 2 Nov 2021',
        'type': 'AMENDMENT',
        'status': 'ACTIVE',
        'description':
            'Introduced Rule 6(11) mandating clear Unit Sale Price (₹ per g / ₹ per ml / ₹ per kg / ₹ per L) alongside retail MRP on every packaged retail commodity exceeding unit size.',
      },
      {
        'year': '2022',
        'effective': '6 July 2022',
        'title': 'Electronic Products QR Code Label Declarations Amendment',
        'notification': 'G.S.R. 520(E) • Published 6 Jul 2022',
        'type': 'AMENDMENT',
        'status': 'ACTIVE',
        'description':
            'Permitted electronic goods manufacturers to declare non-critical declarations via interactive QR Code, while requiring physical label presence for core parameters (MRP, net quantity, commodity name).',
      },
      {
        'year': '2023-24',
        'effective': '1 January 2024',
        'title': 'Jan Vishwas Act Alignment & Decriminalization Amendment',
        'notification': 'G.S.R. 721(E) • Published 6 Oct 2023',
        'type': 'AMENDMENT',
        'status': 'ACTIVE',
        'description':
            'Substituted penal provisions under Rule 32 in alignment with Jan Vishwas Act, 2023, modernizing first-time technical labeling infractions to statutory civil compounding.',
      },
      {
        'year': '2024',
        'effective': '1 May 2024',
        'title': 'DCA Operational Advisory: Above-The-Fold E-Commerce Declarations',
        'notification': 'DCA-ADVISORY-2024-ECOM • Published 15 Apr 2024',
        'type': 'ADVISORY',
        'status': 'ACTIVE',
        'description':
            'Department of Consumer Affairs operational directive mandating all e-commerce platforms to present statutory declarations prominently above the digital fold without requiring user scroll/clicks.',
      },
      {
        'year': '2027',
        'effective': '1 July 2027 (SCHEDULED)',
        'title': 'Strategic Digital Viewport Standard: Machine-Readable QR Synchronization',
        'notification': 'DCA-PROPOSED-2026/GSR-889 • Advance Published 10 Sep 2026',
        'type': 'PROPOSED_STANDARD',
        'status': 'NOT_YET_EFFECTIVE',
        'description':
            'Future scheduled standard mandating dynamic machine-readable QR verification and real-time backend declaration synchronization on all marketplace listings. Published early for industry preparedness.',
      },
    ];

    return ListView.builder(
      itemCount: timelineEvents.length,
      itemBuilder: (context, index) {
        final ev = timelineEvents[index];
        final isLast = index == timelineEvents.length - 1;
        final isFuture = ev['status'] == 'NOT_YET_EFFECTIVE';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Date Column
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ev['year']!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isFuture ? const Color(0xFFD97706) : const Color(0xFF0F2942),
                    ),
                  ),
                  Text(
                    ev['effective']!,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Timeline Spine
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isFuture ? const Color(0xFFD97706) : const Color(0xFF0F2942),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 4),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 130,
                    color: const Color(0xFFCBD5E1),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Right Content Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isFuture ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ev['title']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isFuture)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFCD34D)),
                            ),
                            child: const Text(
                              'SCHEDULED / 2027',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ev['notification']!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F2942),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ev['description']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // TAB 4: STATUTORY FRAMEWORK & ABOUT
  // ==========================================
  Widget _buildAboutFrameworkTab(StatutorySummaryModel? summary) {
    return ListView(
      children: [
        // Statutory Authority Hierarchy Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STATUTORY AUTHORITY & ENFORCEMENT HIERARCHY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Legal Metrology enforcement in India operates under a structured statutory hierarchy. LM-TRACE maps every automated digital inspection rule directly back to its enabling Act section and Gazette notification:',
                style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildHierarchyStep(
                step: '1',
                title: 'Parliament of India',
                subtitle: 'The Legal Metrology Act, 2009 (Act No. 1 of 2010)',
                detail: 'Section 18 mandates compulsory declarations on all pre-packaged goods.',
              ),
              _buildHierarchyStep(
                step: '2',
                title: 'Ministry of Consumer Affairs, Food & Public Distribution',
                subtitle: 'The Legal Metrology (Packaged Commodities) Rules, 2011',
                detail: 'Rules 6, 7, 8, 9, 10, 11, 12 define mandatory specifications & font size ratios.',
              ),
              _buildHierarchyStep(
                step: '3',
                title: 'Gazette Amendments & Statutory Notifications',
                subtitle: 'G.S.R. 629(E), 779(E), 520(E), 721(E)',
                detail: 'Enacted E-Commerce declarations, Unit Sale Price (USP), and Jan Vishwas compounding.',
              ),
              _buildHierarchyStep(
                step: '4',
                title: 'LM-TRACE Automated Compliance Engine',
                subtitle: 'Rule Engine Mappings (RULE-006, RULE-007, RULE-009, RULE-ECOM-2026)',
                detail: 'Executes pixel-level OCR grounding, character height ratio verification, and automated evidence bundling.',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // About LM-TRACE Card (Preserving existing Help & About info cleanly)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AppLogo.document(
                size: 60,
              ),
              const SizedBox(height: 12),
              const Text(
                'Legal Metrology Inspection Platform (LM-TRACE)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Department of Consumer Affairs\nMinistry of Consumer Affairs, Food and Public Distribution • Government of India',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Production System • Release v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 20),

              // Capabilities List
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'INTEGRATED ENFORCEMENT CAPABILITIES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.neutral500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildCapabilityItem(
                Icons.document_scanner_outlined,
                'Multi-Surface AI OCR',
                'Extracts and grounds declaration text across all 6 packaging surfaces with bounding box coordinates.',
              ),
              _buildCapabilityItem(
                Icons.straighten_outlined,
                'Table-I PDP Measurement & Calibration',
                'Evaluates minimum numeral/letter height against packaging area thresholds using optical calibration.',
              ),
              _buildCapabilityItem(
                Icons.currency_rupee_outlined,
                'Dual MRP & Unit Sale Price (USP) Verification',
                'Detects predatory pricing, multiple MRP sticker overlays, and unit sale price omissions.',
              ),
              _buildCapabilityItem(
                Icons.shopping_cart_outlined,
                'Marketplace Listing Scan (Rule 6(10))',
                'Monitors e-commerce PDP viewports for mandatory digital disclosures prior to consumer purchase.',
              ),
              _buildCapabilityItem(
                Icons.fingerprint_outlined,
                'Product Fingerprinting & Version History',
                'Tracks packaging revisions over time and alerts inspectors to unauthorized size/weight shrinkflation.',
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),

              // Enforcement Contact
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Icon(Icons.support_agent_rounded, size: 18, color: Color(0xFF0F2942)),
                    const SizedBox(width: 8),
                    const Text(
                      'Central Legal Metrology Enforcement Desk:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppBrand.supportEmail,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHierarchyStep({
    required String step,
    required String title,
    required String subtitle,
    required String detail,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF0F2942),
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0F2942)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DETAIL MODAL: RULE & TRACEABILITY
  // ==========================================
  void _showRuleDetailDialog(StatutoryRuleModel rule) async {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Container(
            width: 760,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_tree_outlined, color: Color(0xFF2563EB), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${rule.ruleNumber} — ${rule.title}',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Statutory Code: ${rule.ruleCode} • ${rule.ruleFamily}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),

                  // Dates & Status
                  Row(
                    children: [
                      _buildDetailBadge('Status', rule.status, isStatus: true, effectiveDate: rule.effectiveFrom),
                      const SizedBox(width: 16),
                      _buildDetailBadge('Publication Date', _formatIsoDate(rule.publicationDate)),
                      const SizedBox(width: 16),
                      _buildDetailBadge(
                        rule.isScheduled ? 'Effective Date (Future)' : 'Effective Date',
                        _formatIsoDate(rule.effectiveFrom),
                        highlight: rule.isScheduled,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Legal Source & Document
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OFFICIAL ENABLING INSTRUMENT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rule.documentTitle,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Statutory Reference: ${rule.sourceReference}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Applicability
                  const Text(
                    'APPLICABILITY',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rule.applicability,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 16),

                  // Full Requirement
                  const Text(
                    'FULL STATUTORY REQUIREMENT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      rule.requirementSummary,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF78350F), height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Traceability Chain Box
                  const Text(
                    'RULE ENGINE TRACEABILITY CHAIN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChainItem(
                          step: 'Finding / Check',
                          value: rule.mappedRuleEngineCode != null ? 'Active Inspection Check' : 'Manual Statutory Finding',
                          icon: Icons.search_rounded,
                        ),
                        _buildChainItem(
                          step: 'Rule Engine Code',
                          value: rule.mappedRuleEngineCode ?? 'Manual Assessment / Legal Compounding',
                          icon: Icons.memory_rounded,
                          isHighlight: rule.mappedRuleEngineCode != null,
                        ),
                        _buildChainItem(
                          step: 'Statutory Rule',
                          value: '${rule.ruleNumber} (${rule.title})',
                          icon: Icons.rule_rounded,
                        ),
                        _buildChainItem(
                          step: 'Gazette Source',
                          value: '${rule.documentTitle} (Published: ${_formatIsoDate(rule.publicationDate)})',
                          icon: Icons.description_rounded,
                        ),
                        _buildChainItem(
                          step: 'Authority',
                          value: 'Ministry of Consumer Affairs, Government of India',
                          icon: Icons.account_balance_rounded,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Dialog Footer Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (rule.officialUrl != null)
                        OutlinedButton.icon(
                          onPressed: () => _openExternalUrl(rule.officialUrl),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: const Text('View Official DCA Gazette'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F2942),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2942),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChainItem({
    required String step,
    required String value,
    required IconData icon,
    bool isHighlight = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: isHighlight ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(
              step,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
                color: isHighlight ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBadge(String label, String value, {bool isStatus = false, bool highlight = false, String? effectiveDate}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 3),
        if (isStatus)
          _buildStatusBadge(value, effectiveDate)
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: highlight ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: highlight ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: highlight ? const Color(0xFFB45309) : const Color(0xFF1E293B),
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // HELPER BADGES & UTILITIES
  // ==========================================
  Widget _buildStatusBadge(String status, String? effectiveDate) {
    final s = status.toUpperCase();
    if (s == 'NOT_YET_EFFECTIVE' || s == 'SCHEDULED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.schedule_rounded, size: 12, color: Color(0xFFB45309)),
            SizedBox(width: 4),
            Text(
              'NOT YET EFFECTIVE / SCHEDULED',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF047857)),
          SizedBox(width: 4),
          Text(
            'ACTIVE & ENFORCED',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF047857)),
          ),
        ],
      ),
    );
  }

  Widget _buildDocTypeBadge(String docType) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    String label = docType.replaceAll('_', ' ');

    switch (docType.toUpperCase()) {
      case 'ACT':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        label = 'PARLIAMENTARY ACT';
        break;
      case 'RULES':
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF15803D);
        label = 'PRINCIPAL RULES';
        break;
      case 'GAZETTE_AMENDMENT':
        bg = const Color(0xFFFAF5FF);
        fg = const Color(0xFF7E22CE);
        label = 'GAZETTE AMENDMENT';
        break;
      case 'OFFICIAL_ADVISORY':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFC2410C);
        label = 'OFFICIAL ADVISORY';
        break;
      case 'PROPOSED_AMENDMENT':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFB45309);
        label = 'PROPOSED STANDARD';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }

  Widget _buildDatePill(String label, String dateStr, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isHighlight ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isHighlight ? const Color(0xFFB45309) : const Color(0xFF64748B),
            ),
          ),
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isHighlight ? const Color(0xFFB45309) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _resetFilters,
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  String _formatIsoDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(iso);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso.length >= 10 ? iso.substring(0, 10) : iso;
    }
  }
}

extension RuleDisplayExt on StatutoryRuleModel {
  String ruleCodeDisplay(String code) {
    return code;
  }
}
