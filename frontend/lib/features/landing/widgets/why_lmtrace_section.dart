import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/responsive/responsive_layout.dart';

/// "Why LM-TRACE" Section for the public landing page.
///
/// Details the institutional value proposition for legal metrology enforcement:
/// consistency, non-repudiation, turnaround speed, and statutory integrity.
class WhyLmTraceSection extends StatelessWidget {
  const WhyLmTraceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      width: double.infinity,
      color: AppColors.surfaceIvory,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: isMobile ? 56 : 96,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.mintMist,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.sage),
                ),
                child: const Text(
                  'INSTITUTIONAL VALUE',
                  style: TextStyle(
                    color: AppColors.inspectionGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                'Why Legal Metrology Enforcement Relies on LM-TRACE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryNavy,
                  fontSize: isMobile ? 26 : 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),

              const SizedBox(height: 14),

              // Subtitle
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: const Text(
                  'Bridging statutory legal standards with digital verification to protect consumer interests, prevent deceptive packaging, and ensure standardized regulatory fairness.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.steelBlue,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Value Pillars Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final colCount = constraints.maxWidth >= 1050
                      ? 3
                      : (constraints.maxWidth >= 680 ? 2 : 1);
                  final colWidth = (constraints.maxWidth - (colCount - 1) * 20) / colCount;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildPillarCard(
                        width: colWidth,
                        icon: Icons.balance_rounded,
                        title: 'Zero Subjectivity & Discretion',
                        description:
                            'Deterministic evaluation algorithms apply statutory rules uniformly across all inspections, ensuring consistent and defensible findings.',
                      ),
                      _buildPillarCard(
                        width: colWidth,
                        icon: Icons.speed_rounded,
                        title: 'Accelerated Inspection Turnaround',
                        description:
                            'Automating PDP surface area calculation and numeral height verification reduces multi-surface packaging review times significantly.',
                      ),
                      _buildPillarCard(
                        width: colWidth,
                        icon: Icons.shield_outlined,
                        title: 'Court-Ready Evidentiary Rigor',
                        description:
                            'Every finding is tethered to coordinate-grounded visual proof, raw OCR blocks, and non-repudiable audit logs.',
                      ),
                      _buildPillarCard(
                        width: colWidth,
                        icon: Icons.timeline_rounded,
                        title: 'Packaging Lineage & Anti-Shrinkflation',
                        description:
                            'Historical product fingerprinting detects deceptive volume reductions and packaging alterations across manufacturing batches.',
                      ),
                      _buildPillarCard(
                        width: colWidth,
                        icon: Icons.rule_folder_outlined,
                        title: 'Version-Aware Statutory Rules',
                        description:
                            'Preserves legal accuracy by matching commodities to the Gazette notifications active on their respective dates of manufacture.',
                      ),
                      _buildPillarCard(
                        width: colWidth,
                        icon: Icons.lock_outline_rounded,
                        title: 'Enterprise Role-Based Access',
                        description:
                            'Strict separation between Inspector field workflows, Supervisor review authorities, and Central Administrator rule configurations.',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillarCard({
    required double width,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.skyGrey, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceIvory,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.skyGrey.withValues(alpha: 0.6)),
            ),
            child: Icon(icon, color: AppColors.inspectionGreen, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryNavy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.steelBlue,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
