import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/responsive/responsive_layout.dart';

/// Problem Section for the LM-TRACE public landing page.
///
/// Clearly articulates the statutory enforcement bottlenecks faced by
/// legal metrology inspectors, contrasting manual workflows with structured
/// digital intelligence.
class ProblemSection extends StatelessWidget {
  const ProblemSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      width: double.infinity,
      color: AppColors.surfaceIvory,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: isMobile ? 56 : 88,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Section Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.mintMist,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.sage),
                ),
                child: const Text(
                  'REGULATORY ENFORCEMENT CHALLENGES',
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
                'The Complexity of Modern Packaging Compliance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primaryNavy,
                  fontSize: isMobile ? 26 : 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),

              const SizedBox(height: 14),

              // Description
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: const Text(
                  'Enforcing statutory consumer protection across millions of physical packaged goods and sprawling online marketplaces presents substantial operational bottlenecks under traditional manual inspection regimes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.steelBlue,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Problem Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 1080
                      ? 3
                      : (constraints.maxWidth >= 680 ? 2 : 1);

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildProblemCard(
                        width: (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount,
                        icon: Icons.straighten_outlined,
                        title: 'Manual PDP & Font Verification',
                        description:
                            'Calculating Principal Display Panel (PDP) surface area and physically verifying microscopic numeral and letter heights against Table-I thresholds is time-consuming and error-prone.',
                      ),
                      _buildProblemCard(
                        width: (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount,
                        icon: Icons.visibility_off_outlined,
                        title: 'Omitted & Deceptive Declarations',
                        description:
                            'Detecting subtle packaging omissions, such as absent Unit Sale Price (USP), hidden consumer care lines, or conflicting dual MRPs, requires rigorous, multi-surface cross-examination.',
                      ),
                      _buildProblemCard(
                        width: (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount,
                        icon: Icons.storefront_outlined,
                        title: 'E-Commerce Marketplace Volume',
                        description:
                            'Digital commerce listings under Rule 6(10) frequently lack mandatory manufacturer or country-of-origin declarations, overwhelming manual officer monitoring capacities.',
                      ),
                      _buildProblemCard(
                        width: (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount,
                        icon: Icons.history_edu_outlined,
                        title: 'Versioned Statutory Amendments',
                        description:
                            'Statutory rules evolve across Gazette notifications (e.g. GSR 629(E), GSR 779(E)). Maintaining consistency between active statutory law and packaging manufacture dates is difficult.',
                      ),
                      _buildProblemCard(
                        width: (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount,
                        icon: Icons.link_off_rounded,
                        title: 'Broken Chains of Custody',
                        description:
                            'Paper seizure records and untracked photos risk evidentiary challenges. Without coordinate bounding-box audit links, findings are vulnerable in statutory proceedings.',
                      ),
                      _buildProblemCard(
                        width: (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount,
                        icon: Icons.trending_down_rounded,
                        title: 'Undetected Shrinkflation Drift',
                        description:
                            'Subtle net weight reductions with identical packaging dimensions often escape manual spot checks without systematic product fingerprinting and historical packaging tracking.',
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

  Widget _buildProblemCard({
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
            color: Color(0x050F172A),
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
