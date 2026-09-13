import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_controller.dart';
import '../inspections/inspections_controller.dart';
import '../../core/widgets/widgets.dart';
import '../../core/responsive/responsive_layout.dart';
import 'widgets/maanak_navigation_drawer.dart';
import 'widgets/dashboard_web_layout.dart';

final dashboardSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get('/api/dashboard/summary');
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
  } catch (e) {
    // Re-throw so UI can display proper retry state rather than fake data
    rethrow;
  }
  throw Exception('Failed to load dashboard summary');
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inspectionsProvider.notifier).fetchInspections();
    });
  }

  Future<void> _refreshData() async {
    ref.invalidate(dashboardSummaryProvider);
    await ref.read(inspectionsProvider.notifier).fetchInspections();
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isWebDesktop(context)) {
      return const DashboardWebLayout();
    }

    final authState = ref.watch(authProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final inspectionsState = ref.watch(inspectionsProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      drawer: const MaanakNavigationDrawer(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 24),
            tooltip: 'Open navigation menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo.compact(
              size: 32,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'Legal Metrology',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Officer Context / Greeting Bar
              _buildGreetingHeader(authState.user),
              const SizedBox(height: 14),

              // 2. Prominent Primary Action (Clear single CTA, no overlapping FAB)
              _buildPrimaryActionButton(context),
              const SizedBox(height: 20),

              // 3. Inspection Intelligence (Real Database Metrics)
              _buildSectionTitle('INSPECTION INTELLIGENCE'),
              const SizedBox(height: 10),
              summaryAsync.when(
                data: (summary) => _buildKpiGrid(summary),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => _buildErrorCard(
                  title: 'Unable to load intelligence metrics',
                  onRetry: () => ref.invalidate(dashboardSummaryProvider),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Action Required (Real Pending Operational Work)
              summaryAsync.maybeWhen(
                data: (summary) => _buildActionRequiredSection(context, summary),
                orElse: () => const SizedBox.shrink(),
              ),

              // 5. Quick Actions (Physical Scan, E-Commerce Scan, Calibration, Product History)
              _buildQuickActions(context),
              const SizedBox(height: 20),

              // 6. Product Change Alert (Real Packaging Version Changes)
              summaryAsync.maybeWhen(
                data: (summary) => _buildProductAlertCard(context, summary['product_change_alert']),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // 7. Recent Inspections Section (Latest Real Records from Database)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Inspections',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/inspections'),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bind recent inspections consistently
              _buildRecentInspectionsContent(context, summaryAsync, inspectionsState),
              const SizedBox(height: 20),

              // 8. Legal Metrology / Rule Updates Card
              summaryAsync.maybeWhen(
                data: (summary) {
                  final update = summary['latest_rule_update'] as Map<String, dynamic>?;
                  if (update != null) {
                    return _buildRuleUpdateCard(context, update);
                  }
                  return const SizedBox.shrink();
                },
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.badge_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user?.fullName ?? 'Officer'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user?.role ?? 'INSPECTOR',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        (user?.zone != null && user!.zone.isNotEmpty)
                            ? user.zone
                            : 'Central Zone',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.add_a_photo_outlined, size: 20, color: Colors.white),
        label: const Text(
          '+ NEW INSPECTION',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.8,
          ),
        ),
        onPressed: () async {
          await context.push('/new-inspection');
          _refreshData();
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.neutral600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildKpiGrid(Map<String, dynamic> summary) {
    final total = summary['total_inspections'] ?? 0;
    final rate = (summary['compliance_rate'] as num?)?.toDouble();
    final rateSubtitle = summary['compliance_rate_subtitle'] as String? ?? 'Finalized Inspections';
    final violations = summary['potential_violations'] ?? 0;
    final violationsSubtitle = summary['violations_subtitle'] as String? ?? 'Compliance Violations';
    final pending = summary['pending_reviews'] ?? 0;
    final pendingSubtitle = summary['pending_subtitle'] as String? ?? 'Human Verification';

    final String displayRate = (rate != null) ? '${rate.toStringAsFixed(1)}%' : '—';

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.38,
      children: [
        StatMetricCard(
          title: 'Total Audited',
          value: total.toString(),
          icon: Icons.assignment_turned_in_outlined,
          accentColor: AppColors.secondaryBlue,
          subtitle: 'Packaged Commodities',
          onTap: () => context.go('/inspections'),
        ),
        StatMetricCard(
          title: 'Compliance Rate',
          value: displayRate,
          icon: Icons.verified_outlined,
          accentColor: AppColors.passGreen,
          subtitle: rateSubtitle,
          trendText: rate != null && rate >= 70 ? 'Optimal' : null,
          isPositiveTrend: rate != null && rate >= 70,
        ),
        StatMetricCard(
          title: 'Violations Flagged',
          value: violations.toString(),
          icon: Icons.gavel_outlined,
          accentColor: AppColors.violationRed,
          subtitle: violationsSubtitle,
          trendText: violations > 0 ? '$violations Alerts' : null,
          isPositiveTrend: violations == 0,
          onTap: () => context.go('/inspections'),
        ),
        StatMetricCard(
          title: 'Pending Review',
          value: pending.toString(),
          icon: Icons.pending_actions_outlined,
          accentColor: AppColors.reviewAmber,
          subtitle: pendingSubtitle,
          onTap: () => context.go('/inspections'),
        ),
      ],
    );
  }

  Widget _buildActionRequiredSection(BuildContext context, Map<String, dynamic> summary) {
    final actionData = summary['action_required'] as Map<String, dynamic>?;
    if (actionData == null) return const SizedBox.shrink();

    final pending = (actionData['pending_reviews'] as num?)?.toInt() ?? 0;
    final violations = (actionData['compliance_violations'] as num?)?.toInt() ?? 0;
    final labelChanges = (actionData['label_changes_to_review'] as num?)?.toInt() ?? 0;
    final lowConfidence = (actionData['low_confidence_cases'] as num?)?.toInt() ?? 0;

    final hasActions = pending > 0 || violations > 0 || labelChanges > 0 || lowConfidence > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ACTION REQUIRED'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.neutral200),
          ),
          child: !hasActions
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.compliant, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'No actions requiring attention',
                        style: TextStyle(
                          color: AppColors.neutral700,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (pending > 0)
                      _buildActionItemRow(
                        count: pending,
                        label: 'Pending Reviews',
                        color: AppColors.review,
                        onTap: () => context.go('/inspections'),
                      ),
                    if (violations > 0)
                      _buildActionItemRow(
                        count: violations,
                        label: 'Compliance Violations Flagged',
                        color: AppColors.violation,
                        onTap: () => context.go('/inspections'),
                      ),
                    if (labelChanges > 0)
                      _buildActionItemRow(
                        count: labelChanges,
                        label: 'Label Changes to Review',
                        color: Colors.teal.shade700,
                        onTap: () => context.go('/products'),
                      ),
                    if (lowConfidence > 0)
                      _buildActionItemRow(
                        count: lowConfidence,
                        label: 'Low Confidence Cases',
                        color: Colors.orange.shade800,
                        onTap: () => context.go('/inspections'),
                        isLast: true,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActionItemRow({
    required int count,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.neutral100)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral800,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.neutral400),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Physical\nScan',
                  color: AppColors.secondary,
                  onTap: () => context.go('/scanner'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.language,
                  label: 'E-Commerce\nScan',
                  color: Colors.teal.shade700,
                  onTap: () => context.push('/online-listing'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.straighten,
                  label: 'Calibration',
                  color: Colors.indigo.shade700,
                  onTap: () => context.push('/calibration'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.fingerprint,
                  label: 'Product\nHistory',
                  color: Colors.purple.shade700,
                  onTap: () => context.go('/products'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductAlertCard(BuildContext context, dynamic alert) {
    if (alert == null || alert is! Map<String, dynamic>) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.compliant, size: 22),
            SizedBox(width: 10),
            Text(
              'No product changes requiring attention',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
      );
    }

    final title = alert['title'] ?? 'Product Change Alert';
    final desc = alert['description'] ?? 'Specification change detected.';
    final detectedRule = alert['detected_rule'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, color: AppColors.warning, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detectedRule != null ? '$desc ($detectedRule)' : desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.neutral600),
            onPressed: () => context.go('/products'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInspectionsContent(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> summaryAsync,
    InspectionState inspectionsState,
  ) {
    if (inspectionsState.isLoading && inspectionsState.inspections.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (inspectionsState.errorMessage != null && inspectionsState.inspections.isEmpty) {
      return _buildErrorCard(
        title: 'Unable to load recent inspections',
        onRetry: () => ref.read(inspectionsProvider.notifier).fetchInspections(),
      );
    }

    // Prefer live inspections from state, fallback to summary recent inspections if fetched
    List<InspectionModel> displayList = [];
    if (inspectionsState.inspections.isNotEmpty) {
      displayList = inspectionsState.inspections.take(5).toList();
    } else {
      summaryAsync.whenData((summary) {
        final recentRaw = summary['recent_inspections'] as List?;
        if (recentRaw != null && recentRaw.isNotEmpty) {
          displayList = recentRaw
              .map((e) => InspectionModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      });
    }

    if (displayList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 40, color: AppColors.neutral400),
            const SizedBox(height: 8),
            const Text(
              'No inspections on record yet',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.neutral600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Start a physical or e-commerce inspection to audit packaged goods.',
              style: TextStyle(fontSize: 12, color: AppColors.neutral400),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await context.push('/new-inspection');
                _refreshData();
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Start First Inspection'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayList.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final ins = displayList[index];
        return _buildInspectionCard(context, ins);
      },
    );
  }

  Widget _buildInspectionCard(BuildContext context, InspectionModel ins) {
    final hasScore = ins.score != null;
    final scoreVal = hasScore ? (ins.score! > 1 ? ins.score!.toInt() : (ins.score! * 100).toInt()) : null;
    final isHigh = scoreVal != null && scoreVal >= 80;

    return AppCard(
      onTap: () => context.push('/inspections/${ins.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: AppRadii.md,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withValues(alpha: 0.07),
              borderRadius: AppRadii.sm,
              border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.12)),
            ),
            child: Icon(
              ins.inspectionType == 'ONLINE_LISTING' ? Icons.language_rounded : Icons.inventory_2_outlined,
              color: AppColors.primaryNavy,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ins.inspectionCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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
                const SizedBox(height: 4),
                Text(
                  ins.businessName ?? ins.sellerName ?? 'Packaged Goods Commodity',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${ins.inspectionDate.isNotEmpty ? ins.inspectionDate.split('T').first : 'Recent'} • ${ins.inspectionType == 'ONLINE_LISTING' ? 'E-Commerce Scan' : 'Physical Ingestion'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (scoreVal != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isHigh ? AppColors.passGreenLight : AppColors.violationRedLight,
                    borderRadius: AppRadii.xs,
                    border: Border.all(
                      color: isHigh ? AppColors.passGreenBorder : AppColors.violationRedBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '$scoreVal%',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      color: isHigh ? AppColors.passGreen : AppColors.violationRed,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.neutral400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleUpdateCard(BuildContext context, Map<String, dynamic> update) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel_outlined, color: AppColors.secondary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATUTORY RULE REGISTRY • ${update['code'] ?? 'RULE-007'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  update['title'] ?? 'Mandatory Declarations and Tolerances',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral900,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go('/rules'),
            child: const Text('View Rules →', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard({required String title, required VoidCallback onRetry}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
