import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import 'models/audit_models.dart';

// --- State Providers ---

final auditQueryFilterProvider = StateProvider<String>((ref) => '');
final auditCategoryFilterProvider = StateProvider<String>((ref) => 'ALL');
final auditResultFilterProvider = StateProvider<String>((ref) => 'ALL');
final auditRoleFilterProvider = StateProvider<String>((ref) => 'ALL');
final auditDateFilterProvider = StateProvider<String>((ref) => 'ALL'); // 'ALL', 'TODAY', 'WEEK'

final auditSummaryProvider = FutureProvider<AuditSummary>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get('${ApiConstants.auditLogs}/summary');
    if (response.statusCode == 200 && response.data is Map) {
      return AuditSummary.fromJson(Map<String, dynamic>.from(response.data));
    }
  } catch (e) {
    debugPrint('Audit summary fetch error: $e');
  }
  return AuditSummary.empty();
});

final auditLogsProvider = FutureProvider<List<AuditEvent>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final q = ref.watch(auditQueryFilterProvider);
  final category = ref.watch(auditCategoryFilterProvider);
  final result = ref.watch(auditResultFilterProvider);
  final role = ref.watch(auditRoleFilterProvider);
  final dateFilter = ref.watch(auditDateFilterProvider);

  final queryParams = <String, dynamic>{
    'limit': 100,
    'offset': 0,
  };

  if (q.trim().isNotEmpty) queryParams['q'] = q.trim();
  if (category != 'ALL') queryParams['event_type'] = category;
  if (result != 'ALL') queryParams['result'] = result;
  if (role != 'ALL') queryParams['role'] = role;

  final now = DateTime.now().toUtc();
  if (dateFilter == 'TODAY') {
    final todayStart = DateTime.utc(now.year, now.month, now.day).toIso8601String();
    queryParams['date_from'] = todayStart;
  } else if (dateFilter == 'WEEK') {
    final weekAgo = now.subtract(const Duration(days: 7)).toIso8601String();
    queryParams['date_from'] = weekAgo;
  }

  try {
    final response = await client.get(
      ApiConstants.auditLogs,
      queryParameters: queryParams,
    );

    if (response.statusCode == 200) {
      List<dynamic> rawItems = [];
      if (response.data is Map && response.data['items'] is List) {
        rawItems = response.data['items'] as List<dynamic>;
      } else if (response.data is List) {
        rawItems = response.data as List<dynamic>;
      }
      return rawItems
          .map((item) => AuditEvent.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
  } catch (e) {
    debugPrint('Audit logs fetch error: $e');
    rethrow;
  }
  return [];
});

class AuditTrailScreen extends ConsumerStatefulWidget {
  const AuditTrailScreen({super.key});

  @override
  ConsumerState<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends ConsumerState<AuditTrailScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(auditSummaryProvider);
    ref.invalidate(auditLogsProvider);
  }

  void _resetFilters() {
    _searchController.clear();
    ref.read(auditQueryFilterProvider.notifier).state = '';
    ref.read(auditCategoryFilterProvider.notifier).state = 'ALL';
    ref.read(auditResultFilterProvider.notifier).state = 'ALL';
    ref.read(auditRoleFilterProvider.notifier).state = 'ALL';
    ref.read(auditDateFilterProvider.notifier).state = 'ALL';
  }

  void _showChainOfCustodyDialog(String inspectionId) async {
    showDialog(
      context: context,
      builder: (dialogCtx) => _ChainOfCustodyModal(inspectionId: inspectionId),
    );
  }

  void _showEventDetailDialog(AuditEvent event) {
    showDialog(
      context: context,
      builder: (dialogCtx) => _EventDetailModal(
        event: event,
        onViewChain: event.inspectionId != null
            ? () {
                Navigator.of(dialogCtx).pop();
                _showChainOfCustodyDialog(event.inspectionId!);
              }
            : null,
      ),
    );
  }

  void _showLookupChainDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.timeline_outlined, color: AppColors.secondaryBlue, size: 22),
            SizedBox(width: 8),
            Text('Lookup Chain of Custody', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter an Inspection ID or Case Code to trace its end-to-end statutory chain of custody:',
              style: TextStyle(fontSize: 12, color: AppColors.neutral700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'e.g. ins-demo-001 or INS-2026-DEL-001',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final id = textController.text.trim();
              if (id.isNotEmpty) {
                Navigator.of(ctx).pop();
                _showChainOfCustodyDialog(id);
              }
            },
            child: const Text('View Chain'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(auditSummaryProvider);
    final logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Sticky Top AppBar
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            titleSpacing: 24,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Legal Metrology / System Audit',
                  style: TextStyle(fontSize: 11, color: AppColors.neutral500, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 2),
                Text(
                  'Audit Trail',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: _showLookupChainDialog,
                icon: const Icon(Icons.timeline_outlined, size: 16),
                label: const Text('Trace Chain of Custody'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryNavy,
                  side: const BorderSide(color: AppColors.neutral300),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.neutral700),
                tooltip: 'Refresh Audit Log',
                onPressed: _refreshAll,
              ),
              const SizedBox(width: 16),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.neutral200),
            ),
          ),

          // Main Content Sliver
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statutory Header Banner
                  _buildStatutoryBanner(),
                  const SizedBox(height: 16),

                  // KPI Summary Cards
                  _buildSummarySection(summaryAsync),
                  const SizedBox(height: 20),

                  // Filter & Search Controls
                  _buildFilterBar(),
                  const SizedBox(height: 16),

                  // Event Records List
                  _buildEventList(logsAsync),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatutoryBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.gavel_outlined, size: 20, color: Color(0xFF15803D)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'IMMUTABLE STATUTORY CHAIN OF CUSTODY • LEGAL METROLOGY ACT, 2009',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Chronological, cryptographically sealed record of officer authentications, computer vision scale metrics, rule calibrations, supervisory confirmations, and statutory report generation.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF14532D), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(AsyncValue<AuditSummary> summaryAsync) {
    return summaryAsync.when(
      data: (summary) => Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              title: 'Total System Events',
              value: summary.totalEvents.toString(),
              icon: Icons.history_edu_outlined,
              iconColor: const Color(0xFF2563EB),
              subtitle: 'Append-only ledger entries',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              title: "Today's Events (IST)",
              value: summary.todayEvents.toString(),
              icon: Icons.today_outlined,
              iconColor: const Color(0xFF0D9488),
              subtitle: 'Current working shift',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              title: 'Inspection Operations',
              value: summary.inspectionEvents.toString(),
              icon: Icons.assignment_turned_in_outlined,
              iconColor: const Color(0xFF7C3AED),
              subtitle: 'OCR, CV, rules & compliance',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricCard(
              title: 'Access & Security',
              value: summary.securityEvents.toString(),
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFFDC2626),
              subtitle: 'Officer authentication & tokens',
            ),
          ),
        ],
      ),
      loading: () => const LinearProgressIndicator(minHeight: 3),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.neutral600),
              ),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.neutral900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final selectedCategory = ref.watch(auditCategoryFilterProvider);
    final selectedResult = ref.watch(auditResultFilterProvider);
    final selectedRole = ref.watch(auditRoleFilterProvider);
    final selectedDate = ref.watch(auditDateFilterProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          // Search Box
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Event ID (e.g. AUD-000101), officer, action, inspection code...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.neutral400),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.neutral500),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(auditQueryFilterProvider.notifier).state = '';
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (val) {
                    ref.read(auditQueryFilterProvider.notifier).state = val;
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Search'),
                onPressed: () {
                  ref.read(auditQueryFilterProvider.notifier).state = _searchController.text;
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.neutral700,
                  side: const BorderSide(color: AppColors.neutral300),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('Reset'),
                onPressed: _resetFilters,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dropdown Filters Row
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Category Filter
              _buildDropdownFilter(
                label: 'Category',
                value: selectedCategory,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Categories')),
                  DropdownMenuItem(value: 'INSPECTION', child: Text('Inspection')),
                  DropdownMenuItem(value: 'EVIDENCE', child: Text('Evidence')),
                  DropdownMenuItem(value: 'OCR', child: Text('OCR Extraction')),
                  DropdownMenuItem(value: 'CV', child: Text('Computer Vision')),
                  DropdownMenuItem(value: 'CALIBRATION', child: Text('Scale Calibration')),
                  DropdownMenuItem(value: 'RULE_ENGINE', child: Text('Rule Engine')),
                  DropdownMenuItem(value: 'COMPLIANCE', child: Text('Compliance')),
                  DropdownMenuItem(value: 'FINDING', child: Text('Findings & Violations')),
                  DropdownMenuItem(value: 'REPORT', child: Text('Reports')),
                  DropdownMenuItem(value: 'AUTH', child: Text('Security & Auth')),
                  DropdownMenuItem(value: 'SYSTEM', child: Text('System')),
                ],
                onChanged: (val) {
                  ref.read(auditCategoryFilterProvider.notifier).state = val ?? 'ALL';
                },
              ),

              // Role Filter
              _buildDropdownFilter(
                label: 'Role',
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Roles')),
                  DropdownMenuItem(value: 'INSPECTOR', child: Text('Inspector')),
                  DropdownMenuItem(value: 'SUPERVISOR', child: Text('Supervisor')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                  DropdownMenuItem(value: 'SYSTEM', child: Text('System')),
                ],
                onChanged: (val) {
                  ref.read(auditRoleFilterProvider.notifier).state = val ?? 'ALL';
                },
              ),

              // Result Filter
              _buildDropdownFilter(
                label: 'Result',
                value: selectedResult,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Results')),
                  DropdownMenuItem(value: 'SUCCESS', child: Text('SUCCESS')),
                  DropdownMenuItem(value: 'FAILURE', child: Text('FAILURE')),
                  DropdownMenuItem(value: 'WARNING', child: Text('WARNING')),
                ],
                onChanged: (val) {
                  ref.read(auditResultFilterProvider.notifier).state = val ?? 'ALL';
                },
              ),

              // Date Range Filter
              _buildDropdownFilter(
                label: 'Timeframe',
                value: selectedDate,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Time')),
                  DropdownMenuItem(value: 'TODAY', child: Text('Today Only')),
                  DropdownMenuItem(value: 'WEEK', child: Text('Past 7 Days')),
                ],
                onChanged: (val) {
                  ref.read(auditDateFilterProvider.notifier).state = val ?? 'ALL';
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.neutral500)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              style: const TextStyle(fontSize: 12, color: AppColors.neutral900, fontWeight: FontWeight.w500),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(AsyncValue<List<AuditEvent>> logsAsync) {
    return logsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off_outlined, size: 48, color: AppColors.neutral400),
                const SizedBox(height: 12),
                const Text(
                  'No audit events match current criteria',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.neutral700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Try modifying your keyword search or resetting category filters.',
                  style: TextStyle(fontSize: 12, color: AppColors.neutral500),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset All Filters'),
                  onPressed: _resetFilters,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventCard(event);
          },
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Column(
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading authenticated audit trail records...', style: TextStyle(fontSize: 12, color: AppColors.neutral600)),
          ],
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Failed to load audit records from backend',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                  ),
                  const SizedBox(height: 2),
                  Text('$e', style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C))),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: _refreshAll,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(AuditEvent event) {
    final catColor = event.categoryColor;
    final resColor = event.resultColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Icon Badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(event.categoryIcon, size: 20, color: catColor),
            ),
            const SizedBox(width: 14),

            // Middle: Event Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Event ID + Action + Result Badge
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      // Event ID Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.neutral300),
                        ),
                        child: Text(
                          event.eventId,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral800,
                          ),
                        ),
                      ),

                      // Action Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: catColor.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          event.actionTitle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: catColor,
                          ),
                        ),
                      ),

                      // Result Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: resColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: resColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.result,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: resColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Category Tag
                      Text(
                        '• ${event.eventType}',
                        style: const TextStyle(fontSize: 11, color: AppColors.neutral500, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Description Text
                  Text(
                    event.description,
                    style: const TextStyle(fontSize: 13, color: AppColors.neutral800, height: 1.3),
                  ),
                  const SizedBox(height: 8),

                  // Metadata line: Actor, Target, Inspection Link, Timestamp
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      // Actor
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.neutral500),
                          const SizedBox(width: 4),
                          Text(
                            '${event.actorName} (${event.role})',
                            style: const TextStyle(fontSize: 11, color: AppColors.neutral600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),

                      // Target
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.layers_outlined, size: 14, color: AppColors.neutral500),
                          const SizedBox(width: 4),
                          Text(
                            '${event.targetType}: ${event.targetId}',
                            style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
                          ),
                        ],
                      ),

                      // Inspection ID if present
                      if (event.inspectionId != null)
                        InkWell(
                          onTap: () => _showChainOfCustodyDialog(event.inspectionId!),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timeline, size: 12, color: Color(0xFF2563EB)),
                                const SizedBox(width: 3),
                                Text(
                                  'Case: ${event.inspectionId}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // IST Timestamp
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 13, color: AppColors.neutral400),
                          const SizedBox(width: 4),
                          Text(
                            event.formattedIST,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.neutral500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right: View Details Button
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _showEventDetailDialog(event),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Event Detail Modal ---

class _EventDetailModal extends StatelessWidget {
  final AuditEvent event;
  final VoidCallback? onViewChain;

  const _EventDetailModal({required this.event, this.onViewChain});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 680,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(event.categoryIcon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AUDIT EVENT: ${event.eventId}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          event.actionTitle,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF93C5FD)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Modal Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Authoritative Timestamp Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('RECORDED TIMESTAMP (IST)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neutral500)),
                                const SizedBox(height: 2),
                                Text(
                                  event.formattedIST,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: event.resultColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'RESULT: ${event.result}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: event.resultColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Key Details Grid
                    const Text('Audit Context', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neutral800)),
                    const SizedBox(height: 8),
                    _buildInfoGrid([
                      {'label': 'Action', 'value': event.action},
                      {'label': 'Category', 'value': event.eventType},
                      {'label': 'Officer / Actor', 'value': event.actorName},
                      {'label': 'Actor Role', 'value': event.role},
                      {'label': 'Actor ID', 'value': event.actorId},
                      {'label': 'Target Resource', 'value': '${event.targetType} (${event.targetId})'},
                      if (event.inspectionId != null) {'label': 'Inspection Case', 'value': event.inspectionId!},
                      if (event.correlationId != null) {'label': 'Correlation ID', 'value': event.correlationId!},
                      {'label': 'Source Channel', 'value': event.source},
                    ]),
                    const SizedBox(height: 16),

                    // Description
                    const Text('Operational Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neutral800)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: Text(event.description, style: const TextStyle(fontSize: 13, color: AppColors.neutral800, height: 1.4)),
                    ),
                    const SizedBox(height: 16),

                    // State Changes (Before vs After)
                    if (event.oldValue != null || event.newValue != null || event.beforeData != null || event.afterData != null) ...[
                      const Text('State Transition (Before / After)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neutral800)),
                      const SizedBox(height: 8),
                      _buildDiffView(
                        event.oldValue ?? event.beforeData,
                        event.newValue ?? event.afterData,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Metadata Payload
                    if (event.metadata != null && event.metadata!.isNotEmpty) ...[
                      const Text('Technical Payload & Metadata', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neutral800)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          const JsonEncoder.withIndent('  ').convert(event.metadata),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Immutability Seal
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.neutral300),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.verified, size: 16, color: Color(0xFF0284C7)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Certified Immutable Record • Tamper-Evident • Legal Metrology Act, 2009 Standards',
                              style: TextStyle(fontSize: 11, color: AppColors.neutral600, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Modal Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border(top: BorderSide(color: AppColors.neutral200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onViewChain != null)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.timeline, size: 16),
                      label: const Text('View Inspection Chain'),
                      onPressed: onViewChain,
                    ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(List<Map<String, String>> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: items.map((item) {
          return SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['label']!, style: const TextStyle(fontSize: 10, color: AppColors.neutral500, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(item['value']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.neutral800)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDiffView(Map<String, dynamic>? before, Map<String, dynamic>? after) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Before
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFFEF2F2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PREVIOUS STATE (OLD)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                  const SizedBox(height: 6),
                  Text(
                    before != null ? const JsonEncoder.withIndent('  ').convert(before) : 'None / Initial creation',
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF7F1D1D)),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.neutral200),
          // After
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFF0FDF4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('UPDATED STATE (NEW)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                  const SizedBox(height: 6),
                  Text(
                    after != null ? const JsonEncoder.withIndent('  ').convert(after) : 'None / Final state',
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF14532D)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Chain of Custody Modal ---

class _ChainOfCustodyModal extends ConsumerStatefulWidget {
  final String inspectionId;

  const _ChainOfCustodyModal({required this.inspectionId});

  @override
  ConsumerState<_ChainOfCustodyModal> createState() => _ChainOfCustodyModalState();
}

class _ChainOfCustodyModalState extends ConsumerState<_ChainOfCustodyModal> {
  ChainOfCustodyData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChain();
  }

  Future<void> _loadChain() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final res = await client.get('${ApiConstants.auditLogs}/chain/${widget.inspectionId}');
      if (res.statusCode == 200 && res.data is Map) {
        setState(() {
          _data = ChainOfCustodyData.fromJson(Map<String, dynamic>.from(res.data));
          _loading = false;
        });
        return;
      }
      throw Exception('Unexpected response');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 720,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timeline, color: Color(0xFF38BDF8), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STATUTORY CHAIN OF CUSTODY',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Inspection: ${_data?.inspectionCode ?? widget.inspectionId}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 40, color: AppColors.violationRed),
                                const SizedBox(height: 8),
                                Text('Error loading chain: $_error', style: const TextStyle(color: AppColors.violationRed)),
                                const SizedBox(height: 12),
                                ElevatedButton(onPressed: _loadChain, child: const Text('Retry')),
                              ],
                            ),
                          ),
                        )
                      : _data == null || _data!.stages.isEmpty
                          ? const Center(child: Text('No stages recorded for this inspection.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _data!.stages.length,
                              itemBuilder: (context, idx) {
                                final stage = _data!.stages[idx];
                                final isLast = idx == _data!.stages.length - 1;
                                return _buildTimelineItem(stage, idx + 1, isLast);
                              },
                            ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border(top: BorderSide(color: AppColors.neutral200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Events Linked: ${_data?.events.length ?? 0}',
                    style: const TextStyle(fontSize: 12, color: AppColors.neutral600, fontWeight: FontWeight.w500),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(ChainOfCustodyStage stage, int stepNumber, bool isLast) {
    final completed = stage.isCompleted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Node & Vertical Line
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: completed ? const Color(0xFF10B981) : AppColors.neutral200,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: completed
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '$stepNumber',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neutral600),
                      ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: completed ? const Color(0xFF86EFAC) : AppColors.neutral200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Stage Details Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: completed ? Colors.white : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: completed ? const Color(0xFFE2E8F0) : AppColors.neutral200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stage.stageName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: completed ? AppColors.neutral900 : AppColors.neutral500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: completed ? const Color(0xFFECFDF5) : AppColors.neutral100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          stage.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: completed ? const Color(0xFF059669) : AppColors.neutral500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (stage.details != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      stage.details!,
                      style: TextStyle(
                        fontSize: 12,
                        color: completed ? AppColors.neutral700 : AppColors.neutral400,
                      ),
                    ),
                  ],
                  if (completed && (stage.actor != null || stage.timestamp != null)) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (stage.actor != null)
                          Text(
                            'By: ${stage.actor} (${stage.role ?? "INSPECTOR"})',
                            style: const TextStyle(fontSize: 11, color: AppColors.neutral500, fontWeight: FontWeight.w500),
                          ),
                        const Spacer(),
                        if (stage.timestamp != null)
                          Text(
                            stage.timestamp!.replaceFirst('T', ' ').split('.').first,
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.neutral400),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
