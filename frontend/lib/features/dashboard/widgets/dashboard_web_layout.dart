import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/responsive/web_page_container.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/auth_controller.dart';
import '../../inspections/inspections_controller.dart';
import '../dashboard_screen.dart';

/// Professional government enterprise desktop dashboard for LM-TRACE.
class DashboardWebLayout extends ConsumerStatefulWidget {
  const DashboardWebLayout({super.key});

  @override
  ConsumerState<DashboardWebLayout> createState() => _DashboardWebLayoutState();
}

class _DashboardWebLayoutState extends ConsumerState<DashboardWebLayout> {
  String _tableFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isSupervisor = user?.isSupervisor ?? false;
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final inspectionsState = ref.watch(inspectionsProvider);

    return WebPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Welcome & Primary Action Context Card
          _buildWelcomeHeader(context, user),
          const SizedBox(height: 20),

          // 2. 4 Stat Cards in a row
          summaryAsync.when(
            data: (summary) => _buildStatCards(summary, isSupervisor),
            loading: () => _buildStatCardsSkeleton(),
            error: (err, stack) => _buildStatCardsFallback(inspectionsState.inspections, isSupervisor),
          ),
          const SizedBox(height: 20),

          // 3. Operational Action Required Strip (Live DB work queue)
          summaryAsync.maybeWhen(
            data: (summary) => _buildActionRequiredBanner(context, summary, isSupervisor),
            orElse: () => const SizedBox.shrink(),
          ),

          // 4. Middle Section: 65% Activity Overview / 35% Compliance Breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Overview & Trend Analysis (~65%)
              Expanded(
                flex: 65,
                child: _buildActivityOverviewCard(summaryAsync, inspectionsState),
              ),
              const SizedBox(width: 20),

              // Right: Compliance Breakdown by Rule Family (~35%)
              Expanded(
                flex: 35,
                child: _buildComplianceBreakdownCard(summaryAsync, inspectionsState, user),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 5. Recent Inspections Desktop Table
          _buildRecentInspectionsTable(context, inspectionsState),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, UserModel? user) {
    final zoneText = (user?.zone != null && user!.zone.isNotEmpty)
        ? 'Zone: ${user.zone}'
        : 'Central Enforcement Directorate';

    final isSupervisor = user?.isSupervisor ?? false;
    final isAdmin = user?.isAdmin ?? false;

    final roleLabel = isAdmin
        ? 'Directorate Administration & System Audit'
        : (isSupervisor
            ? 'Supervisory Review & Case Oversight'
            : 'Field Enforcement & Inspection Workspace');

    final roleIcon = isAdmin
        ? Icons.admin_panel_settings_outlined
        : (isSupervisor ? Icons.verified_user_outlined : Icons.policy_outlined);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.skyGrey),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isSupervisor ? AppColors.inspectionGreen : AppColors.primaryNavy,
            child: Icon(roleIcon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Welcome back, ${user?.fullName ?? "Officer"}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSupervisor
                            ? AppColors.mintMist
                            : (isAdmin ? AppColors.sandBeige : AppColors.mintMist.withValues(alpha: 0.6)),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSupervisor
                              ? AppColors.sage
                              : (isAdmin ? AppColors.accentGold.withValues(alpha: 0.4) : AppColors.sage),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        user?.role ?? 'INSPECTOR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isSupervisor
                              ? AppColors.inspectionGreen
                              : (isAdmin ? AppColors.primaryNavy : AppColors.inspectionGreen),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${user?.department ?? "Legal Metrology Department"} • $zoneText • $roleLabel',
                  style: const TextStyle(fontSize: 12, color: AppColors.steelBlue),
                ),
              ],
            ),
          ),

          // Role-specific action shortcut button (Supervisors and Admins only; standard canonical New Inspection CTA resides in page header)
          if (isSupervisor)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.inspectionGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
              icon: const Icon(Icons.rate_review_outlined, size: 16, color: Colors.white),
              label: const Text('Supervisor Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => context.go('/supervisor'),
            )
          else if (isAdmin)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
              icon: const Icon(Icons.settings_outlined, size: 16, color: Colors.white),
              label: const Text('System Settings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              onPressed: () => context.go('/settings'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCards(Map<String, dynamic> summary, bool isSupervisor) {
    final audited = (summary['total_audited'] ?? summary['total_inspections'] ?? 0) as int;
    final compRate = (summary['compliance_rate'] as num?)?.toDouble();
    final violations = (summary['violations_flagged'] ?? summary['potential_violations'] ?? 0) as int;
    final pending = (summary['pending_review'] ?? summary['pending_reviews'] ?? 0) as int;

    return Row(
      children: [
        Expanded(
          child: StatMetricCard(
            title: 'Total Audited',
            value: '$audited',
            subtitle: audited == 0 ? 'No finalized audits yet' : 'Statutory Audits Finalized',
            icon: Icons.assignment_turned_in_outlined,
            accentColor: AppColors.inspectionGreen,
            onTap: () => context.go('/inspections?status=COMPLETED'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: StatMetricCard(
            title: 'Compliance Rate',
            value: compRate != null ? '${compRate.toStringAsFixed(1)}%' : '—',
            subtitle: compRate != null ? 'Rule 6 & 7 Compliant' : 'No audits completed',
            icon: Icons.verified_outlined,
            accentColor: AppColors.successGreen,
            trendText: compRate != null ? (compRate >= 70 ? 'Optimal' : 'Needs Review') : null,
            isPositiveTrend: compRate != null ? compRate >= 70 : true,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: StatMetricCard(
            title: 'Violations Flagged',
            value: '$violations',
            subtitle: violations == 0 ? 'Zero active violations' : 'Non-compliant Goods',
            icon: Icons.gavel_outlined,
            accentColor: AppColors.alertRed,
            trendText: violations > 0 ? '$violations Alerts' : '0 Alerts',
            isPositiveTrend: violations == 0,
            onTap: () => context.go('/inspections?status=VIOLATION'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: StatMetricCard(
            title: 'Pending Review',
            value: '$pending',
            subtitle: pending == 0 ? 'All reviews completed' : 'Awaiting Sign-off',
            icon: Icons.pending_actions_outlined,
            accentColor: AppColors.warningAmber,
            trendText: pending > 0 ? '$pending pending' : 'All clear',
            isPositiveTrend: pending == 0,
            onTap: () => isSupervisor ? context.go('/supervisor') : context.go('/inspections?status=REVIEW'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCardsSkeleton() {
    return Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Container(
            height: 130,
            margin: EdgeInsets.only(right: index < 3 ? 14 : 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCardsFallback(List<InspectionModel> list, bool isSupervisor) {
    final audited = list.where((i) => ['COMPLETED', 'COMPLIANT', 'FINALIZED', 'ARCHIVED'].contains(i.status.toUpperCase())).length;
    final violations = list.where((i) => ['VIOLATION', 'POTENTIAL_VIOLATION'].contains(i.status.toUpperCase())).length;
    final compliant = list.where((i) => ['COMPLIANT', 'FINALIZED'].contains(i.status.toUpperCase())).length;
    final rate = audited > 0 ? (compliant / audited) * 100 : null;
    final pending = list.where((i) => ['NEEDS_REVIEW', 'REVIEW_REQUIRED', 'IN_REVIEW'].contains(i.status.toUpperCase())).length;

    return _buildStatCards({
      'total_audited': audited,
      'compliance_rate': rate,
      'violations_flagged': violations,
      'pending_review': pending,
    }, isSupervisor);
  }

  Widget _buildActionRequiredBanner(BuildContext context, Map<String, dynamic> summary, bool isSupervisor) {
    final actionData = summary['action_required'] as Map<String, dynamic>?;
    if (actionData == null) return const SizedBox.shrink();

    final pending = (actionData['pending_reviews'] as num?)?.toInt() ?? 0;
    final violations = (actionData['compliance_violations'] as num?)?.toInt() ?? 0;
    final labelChanges = (actionData['label_changes_to_review'] as num?)?.toInt() ?? 0;
    final lowConfidence = (actionData['low_confidence_cases'] as num?)?.toInt() ?? 0;

    final hasActions = pending > 0 || violations > 0 || labelChanges > 0 || lowConfidence > 0;

    if (!hasActions) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.mintMist.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.sage),
        ),
        child: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 18),
            SizedBox(width: 10),
            Text(
              'All statutory compliance reviews are up to date. Zero items requiring urgent officer sign-off.',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sandBeige.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.sandBeige),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warningAmber, size: 20),
          const SizedBox(width: 10),
          const Text(
            'ACTION REQUIRED:',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primaryNavy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (pending > 0)
                  _buildActionPill(
                    '$pending Pending Reviews',
                    AppColors.warningAmber,
                    () => isSupervisor ? context.go('/supervisor') : context.go('/inspections?status=REVIEW'),
                  ),
                if (violations > 0)
                  _buildActionPill(
                    '$violations Violations Flagged',
                    AppColors.alertRed,
                    () => context.go('/inspections?status=VIOLATION'),
                  ),
                if (labelChanges > 0)
                  _buildActionPill(
                    '$labelChanges Packaging Changes',
                    AppColors.inspectionGreen,
                    () => context.go('/products'),
                  ),
                if (lowConfidence > 0)
                  _buildActionPill(
                    '$lowConfidence Low Confidence',
                    AppColors.accentGold,
                    () => context.go('/inspections?status=REVIEW'),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => isSupervisor ? context.go('/supervisor') : context.go('/inspections?status=REVIEW'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: const Text('Review Cases →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPill(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  Widget _buildActivityOverviewCard(
    AsyncValue<Map<String, dynamic>> summaryAsync,
    InspectionState inspectionsState,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.skyGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Text(
                'Inspection Activity & Commodity Spread',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildLegendIndicator('Compliant', AppColors.successGreen),
                  _buildLegendIndicator('Under Review', AppColors.warningAmber),
                  _buildLegendIndicator('Violation', AppColors.alertRed),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dynamic Commodity category spread bars from live DB summary
          summaryAsync.maybeWhen(
            data: (summary) {
              final rawList = summary['commodity_spread'] as List<dynamic>?;
              var list = rawList?.whereType<Map<String, dynamic>>().toList() ?? [];

              if (list.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.pie_chart_outline, size: 36, color: AppColors.neutral400),
                        const SizedBox(height: 8),
                        const Text(
                          'No commodity distribution data yet',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.neutral600),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Commodity spread analytics will populate as inspections are conducted and finalized.',
                          style: TextStyle(fontSize: 11.5, color: AppColors.neutral500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: list.map((item) {
                  final name = (item['name'] ?? item['category']) as String? ?? 'Packaged Commodity';
                  final count = (((item['count'] ?? item['total']) as num?)?.toInt() ?? 0);
                  final compRate = ((item['compliance_rate'] ?? item['rate']) as num?)?.toDouble();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildCategoryBar(name, count, compRate),
                  );
                }).toList(),
              );
            },
            orElse: () {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
          ),
          const SizedBox(height: 16),

          // Operational notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceIvory,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.skyGrey.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 16, color: AppColors.steelBlue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Physical font-height results are reported only when the captured image has an inspection-specific calibrated pixel-to-millimetre scale.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textCharcoal),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar(String label, int total, double? complianceRate) {
    final compPercent = complianceRate != null ? (complianceRate * 100).toInt() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textCharcoal)),
            Text('$total Audited • ${complianceRate == null ? '—' : '$compPercent%'} Compliant', style: const TextStyle(fontSize: 11, color: AppColors.steelBlue)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Expanded(
                flex: compPercent > 0 ? compPercent : (total == 0 ? 0 : 1),
                child: Container(
                  height: 7,
                  color: complianceRate == null ? AppColors.skyGrey : AppColors.successGreen,
                ),
              ),
              Expanded(
                flex: (100 - compPercent) > 0 ? (100 - compPercent) : 0,
                child: Container(
                  height: 7,
                  color: complianceRate == null ? AppColors.skyGrey : AppColors.alertRed.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendIndicator(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 11, color: AppColors.steelBlue)),
      ],
    );
  }

  Widget _buildComplianceBreakdownCard(
    AsyncValue<Map<String, dynamic>> summaryAsync, [
    InspectionState? inspectionsState,
    UserModel? user,
  ]) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.skyGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statutory Rule Health',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 4),
          const Text(
            'Live Legal Metrology rule enforcement compliance',
            style: TextStyle(fontSize: 11, color: AppColors.steelBlue),
          ),
          const SizedBox(height: 18),

          // Dynamic rule health from live DB summary
          summaryAsync.maybeWhen(
            data: (summary) {
              final rawRules = summary['rule_health'] as List<dynamic>?;
              var rules = rawRules?.whereType<Map<String, dynamic>>().toList() ?? [];

              if (rules.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No statutory rule health data available yet.',
                      style: TextStyle(fontSize: 12, color: AppColors.steelBlue),
                    ),
                  ),
                );
              }

              return Column(
                children: List.generate(rules.length, (index) {
                  final item = rules[index];
                  final ruleName = (item['rule'] ?? item['title'] ?? item['code']) as String? ?? 'Rule';
                  final rate = (item['rate'] ?? item['progress']) as num?;

                  String percentStr;
                  double progress;
                  Color color;

                  if (rate == null) {
                    percentStr = '—';
                    progress = 0.0;
                    color = AppColors.steelBlue;
                  } else {
                    final p = (rate.toDouble() * 100).toInt();
                    percentStr = '$p%';
                    progress = rate.toDouble();
                    color = rate >= 0.70 ? AppColors.successGreen : AppColors.warningAmber;
                  }

                  return Column(
                    children: [
                      _buildRuleHealthRow(ruleName, percentStr, progress, color),
                      if (index < rules.length - 1)
                        const Divider(height: 20, color: AppColors.skyGrey),
                    ],
                  );
                }),
              );
            },
            orElse: () {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
          ),
          if (user?.canAccessRoute('/rules') ?? false) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  side: const BorderSide(color: AppColors.skyGrey),
                ),
                onPressed: () => context.go('/rules'),
                child: const Text('View Rule Engine Registry →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleHealthRow(String title, String percent, double progress, Color color) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textCharcoal)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.skyGrey.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Text(
          percent,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildRecentInspectionsTable(BuildContext context, InspectionState state) {
    final inspections = state.inspections;

    final filtered = inspections.where((ins) {
      if (_tableFilter == 'COMPLIANT' && !['COMPLETED', 'COMPLIANT', 'FINALIZED'].contains(ins.status.toUpperCase())) {
        return false;
      }
      if (_tableFilter == 'VIOLATIONS' && !['POTENTIAL_VIOLATION', 'VIOLATION'].contains(ins.status.toUpperCase())) {
        return false;
      }
      if (_tableFilter == 'REVIEW' && !['REVIEW_REQUIRED', 'IN_REVIEW', 'NEEDS_REVIEW', 'DRAFT'].contains(ins.status.toUpperCase())) {
        return false;
      }
      return true;
    }).take(6).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.skyGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Recent Inspection Cases',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${inspections.length} total)',
                      style: const TextStyle(fontSize: 12, color: AppColors.steelBlue),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildTableFilterChip('ALL', 'All Cases'),
                    _buildTableFilterChip('COMPLIANT', 'Compliant'),
                    _buildTableFilterChip('REVIEW', 'Needs Review'),
                    _buildTableFilterChip('VIOLATIONS', 'Violations'),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => context.go('/inspections'),
                      child: const Text('View All Registry →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.skyGrey),

          // Horizontally scrollable table container for complete responsive safety
          LayoutBuilder(
            builder: (context, constraints) {
              final minTableWidth = constraints.maxWidth < 940 ? 940.0 : constraints.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: minTableWidth,
                  child: Column(
                    children: [
                      // Data Table Header
                      Container(
                        color: AppColors.surfaceIvory,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          children: const [
                            Expanded(flex: 2, child: Text('CASE ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.steelBlue))),
                            Expanded(flex: 4, child: Text('ESTABLISHMENT / TRADER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.steelBlue))),
                            Expanded(flex: 3, child: Text('LOCATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.steelBlue))),
                            Expanded(flex: 2, child: Text('INSPECTION TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.steelBlue))),
                            Expanded(flex: 3, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.steelBlue))),
                            Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.steelBlue))),
                            Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('ACTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.steelBlue)))),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.skyGrey),

                      // Data Rows or Clean Empty States
                      if (inspections.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceIvory,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.skyGrey),
                                  ),
                                  child: const Icon(Icons.assignment_outlined, size: 32, color: AppColors.steelBlue),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No Inspections Recorded Yet',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryNavy),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Create your first inspection or launch a physical scan to begin statutory audits.',
                                  style: TextStyle(fontSize: 12, color: AppColors.steelBlue),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: Text(
                              'No inspection cases match selected filter "$_tableFilter".',
                              style: const TextStyle(color: AppColors.steelBlue, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.skyGrey),
                          itemBuilder: (context, index) {
                            final ins = filtered[index];
                            return _buildTableRow(context, ins);
                          },
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
  }

  Widget _buildTableFilterChip(String key, String label) {
    final isSelected = _tableFilter == key;
    return InkWell(
      onTap: () => setState(() => _tableFilter = key),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.inspectionGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? AppColors.inspectionGreen : AppColors.skyGrey),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textCharcoal,
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, InspectionModel ins) {
    final dateStr = ins.inspectionDate.length >= 10 ? ins.inspectionDate.substring(0, 10) : ins.inspectionDate;

    return InkWell(
      onTap: () => context.push('/inspections/${ins.id}'),
      hoverColor: AppColors.mintMist.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                ins.inspectionCode,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.primaryNavy),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                ins.businessName ?? ins.sellerName ?? 'Retail Enterprise',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textCharcoal),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                ins.location,
                style: const TextStyle(fontSize: 12, color: AppColors.steelBlue),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                ins.inspectionType,
                style: const TextStyle(fontSize: 12, color: AppColors.textCharcoal),
              ),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppStatusBadge(
                  status: ins.status,
                  size: BadgeSize.sm,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                dateStr,
                style: const TextStyle(fontSize: 12, color: AppColors.steelBlue),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 12, color: AppColors.inspectionGreen),
                  label: const Text('View', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.inspectionGreen)),
                  onPressed: () => context.push('/inspections/${ins.id}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
