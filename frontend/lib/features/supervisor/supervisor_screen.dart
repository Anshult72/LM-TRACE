import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/responsive/web_page_container.dart';
import '../../core/widgets/stat_metric_card.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/app_status_badge.dart';

final supervisorDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get("${ApiConstants.dashboard}/supervisor");
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    }
  } catch (e) {
    // Fallback data
  }
  return {
    'team_metrics': {
      'total_inspections': 48,
      'passed': 38,
      'review_pending': 6,
      'confirmed_violations': 4,
      'repeat_offenders': 2
    },
    'escalations': [
      {
        'inspection_code': 'INS-2026-00103',
        'trader': 'Metro Cash & Carry Wholesale',
        'reason': 'Multi-pack unit sale price omitted across 12 SKUs (Rule 6(1)(k))',
        'severity': 'HIGH',
        'assigned_inspector': 'Inspector Sharma',
      },
      {
        'inspection_code': 'INS-2026-00089',
        'trader': 'Heritage Fresh Supermarket',
        'reason': 'Shrinkflation & Font reduction below 2.5mm Table-I threshold',
        'severity': 'CRITICAL',
        'assigned_inspector': 'Inspector Verma',
      }
    ],
    'repeat_offenders': [
      {'name': 'Apex Packaged Foods Ltd', 'infractions': 3, 'last_incident': '2026-02-14'},
      {'name': 'Sunrise Oils & Grains', 'infractions': 2, 'last_incident': '2026-01-28'},
    ]
  };
});

class SupervisorScreen extends ConsumerWidget {
  const SupervisorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supAsync = ref.watch(supervisorDashboardProvider);
    final isDesktop = ResponsiveLayout.isWebDesktop(context);

    Widget content = supAsync.when(
      data: (data) {
        final metrics = data['team_metrics'] as Map<String, dynamic>? ?? {};
        final escalations = (data['escalations'] as List?) ?? [];
        final repeats = (data['repeat_offenders'] as List?) ?? [];

        final total = (metrics['total_inspections'] as num?)?.toInt() ?? 0;
        final passed = (metrics['passed'] as num?)?.toInt() ?? 0;
        final pending = (metrics['review_pending'] as num?)?.toInt() ?? 0;
        final violations = (metrics['confirmed_violations'] as num?)?.toInt() ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Supervisor Command Banner
            _buildSupervisorBanner(context, ref),
            const SizedBox(height: 20),

            // 2. Team Performance KPIs (Unified StatMetricCard Grid)
            _buildTeamMetrics(context, total, passed, pending, violations),
            const SizedBox(height: 24),

            // 3. Operational Sections (2-column layout on Desktop >= 1200px, stacked on tablet/mobile)
            if (ResponsiveLayout.isDesktop(context))
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Escalations & Review Dockets (~62%)
                  Expanded(
                    flex: 62,
                    child: _buildEscalationsSection(context, escalations),
                  ),
                  const SizedBox(width: 20),

                  // Right Column: Repeat Offenders & Compliance Summary (~38%)
                  Expanded(
                    flex: 38,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRepeatOffendersSection(repeats),
                        const SizedBox(height: 20),
                        _buildComplianceSummaryCard(total, passed, violations, pending),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEscalationsSection(context, escalations),
                  const SizedBox(height: 24),
                  _buildRepeatOffendersSection(repeats),
                  const SizedBox(height: 20),
                  _buildComplianceSummaryCard(total, passed, violations, pending),
                ],
              ),
            const SizedBox(height: 32),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.secondaryBlue),
              SizedBox(height: 16),
              Text('Loading supervisory enforcement data...', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.violationRed),
              const SizedBox(height: 12),
              Text('Unable to load supervisor oversight: $e', style: const TextStyle(color: AppColors.textDark)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(supervisorDashboardProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );

    if (isDesktop) {
      return WebPageContainer(
        maxWidth: Breakpoints.maxContentWidth,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Supervisor & Enforcement Oversight'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(supervisorDashboardProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }

  Widget _buildSupervisorBanner(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: AppRadii.md,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: AppRadii.sm,
            ),
            child: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Legal Metrology Enforcement Command',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 3),
                Text(
                  'Jurisdiction: Northern Regional Zone (NCT of Delhi & Haryana) • Supervisory Console',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.passGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.passGreen.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.circle, color: AppColors.passGreen, size: 8),
                SizedBox(width: 6),
                Text(
                  'ACTIVE OVERSIGHT',
                  style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
            tooltip: 'Refresh Oversight Data',
            onPressed: () => ref.refresh(supervisorDashboardProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMetrics(BuildContext context, int total, int passed, int pending, int violations) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);

    final cardTotal = StatMetricCard(
      title: 'Zone Total Audits',
      value: '$total',
      icon: Icons.fact_check_outlined,
      accentColor: AppColors.primaryNavy,
      subtitle: 'All recorded audit cases',
    );

    final cardCompliant = StatMetricCard(
      title: 'Compliant Filings',
      value: '$passed',
      icon: Icons.verified_outlined,
      accentColor: AppColors.passGreen,
      subtitle: total > 0 ? '${((passed / total) * 100).toStringAsFixed(1)}% compliance rate' : 'No filings recorded',
    );

    final cardReviews = StatMetricCard(
      title: 'Supervisor Reviews',
      value: '$pending',
      icon: Icons.pending_actions_outlined,
      accentColor: AppColors.reviewAmber,
      subtitle: 'Awaiting supervisory sign-off',
    );

    final cardViolations = StatMetricCard(
      title: 'Enforcement Notices',
      value: '$violations',
      icon: Icons.gavel_outlined,
      accentColor: AppColors.violationRed,
      subtitle: 'Seizure & compounding memos',
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: cardTotal),
          const SizedBox(width: 14),
          Expanded(child: cardCompliant),
          const SizedBox(width: 14),
          Expanded(child: cardReviews),
          const SizedBox(width: 14),
          Expanded(child: cardViolations),
        ],
      );
    }

    if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cardTotal),
              const SizedBox(width: 12),
              Expanded(child: cardCompliant),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cardReviews),
              const SizedBox(width: 12),
              Expanded(child: cardViolations),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        cardTotal,
        const SizedBox(height: 10),
        cardCompliant,
        const SizedBox(height: 10),
        cardReviews,
        const SizedBox(height: 10),
        cardViolations,
      ],
    );
  }

  Widget _buildEscalationsSection(BuildContext context, List<dynamic> escalations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Critical Escalations & Review Dockets',
          subtitle: 'Pending legal notices and compounding recommendations requiring supervisory approval',
          icon: Icons.warning_amber_rounded,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.violationRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${escalations.length} Pending Action',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.violationRed),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (escalations.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(28),
            child: Center(
              child: Column(
                children: const [
                  Icon(Icons.check_circle_outline, size: 40, color: AppColors.passGreen),
                  SizedBox(height: 8),
                  Text('No Critical Escalations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 4),
                  Text('All pending statutory dockets in your jurisdiction have been addressed.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          ...escalations.map((esc) => _buildEscalationCard(context, esc)),
      ],
    );
  }

  Widget _buildEscalationCard(BuildContext context, dynamic esc) {
    final e = esc as Map<String, dynamic>;
    final severity = (e['severity'] ?? e['status'] ?? 'HIGH').toString().toUpperCase();
    final isCritical = severity.contains('CRITICAL') || severity.contains('VIOLATION');
    final code = e['inspection_code'] ?? e['id'] ?? 'INS-CASE';
    final trader = e['trader'] ?? e['product'] ?? e['business_name'] ?? 'Packaged Commodity Retailer';
    final reason = e['reason'] ?? e['issue'] ?? 'Statutory packaging non-compliance detected';
    final inspector = e['assigned_inspector'] ?? 'Enforcement Inspector';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isCritical ? AppColors.violationRed : AppColors.reviewAmber).withValues(alpha: 0.12),
                  borderRadius: AppRadii.sm,
                ),
                child: Icon(
                  isCritical ? Icons.gavel_rounded : Icons.report_problem_outlined,
                  size: 18,
                  color: isCritical ? AppColors.violationRed : AppColors.reviewAmber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryNavy),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      trader,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.neutral700),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isCritical ? AppColors.violationRed : AppColors.reviewAmber).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: (isCritical ? AppColors.violationRed : AppColors.reviewAmber).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  isCritical ? 'CRITICAL SEIZURE' : 'HIGH SCRUTINY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCritical ? AppColors.violationRed : AppColors.reviewAmber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              borderRadius: AppRadii.sm,
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 15, color: AppColors.neutral500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reason,
                    style: const TextStyle(fontSize: 12, color: AppColors.neutral700, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 15, color: AppColors.neutral500),
                  const SizedBox(width: 5),
                  Text(
                    'Investigator: $inspector',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.neutral600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.open_in_new, size: 14, color: Colors.white),
                label: const Text('Review Docket', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => context.go('/inspections'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildRepeatOffendersSection(List<dynamic> repeats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Repeat Offenders Registry',
          subtitle: 'Entities flagged for recurring statutory infractions',
          icon: Icons.history_edu_outlined,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.violationRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${repeats.length} Flagged',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.violationRed),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: repeats.asMap().entries.map((entry) {
              final idx = entry.key;
              final r = entry.value as Map<String, dynamic>;
              final isLast = idx == repeats.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.violationRed.withValues(alpha: 0.1),
                            borderRadius: AppRadii.sm,
                          ),
                          child: const Icon(Icons.flag_outlined, size: 16, color: AppColors.violationRed),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['name'] ?? '',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Last Incident: ${r['last_incident'] ?? 'Recent'}',
                                style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.violationRed.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.violationRed.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${r['infractions']} Violations',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.violationRed),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, color: AppColors.neutral200),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildComplianceSummaryCard(int total, int passed, int violations, int pending) {
    final passRate = total > 0 ? (passed / total) : 0.0;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.pie_chart_outline_rounded, size: 18, color: AppColors.primaryNavy),
              SizedBox(width: 8),
              Text(
                'Zone Compliance Health',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Aggregate status ratio under Legal Metrology Act, 2009',
            style: TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: passRate,
              minHeight: 10,
              backgroundColor: AppColors.neutral200,
              color: AppColors.passGreen,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryPill('Compliant', '$passed', AppColors.passGreen),
              _buildSummaryPill('Violations', '$violations', AppColors.violationRed),
              _buildSummaryPill('Pending', '$pending', AppColors.reviewAmber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
        ),
      ],
    );
  }
}
