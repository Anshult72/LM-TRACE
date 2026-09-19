import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/responsive/responsive_layout.dart';

/// Statutory Rule Engine Section for the LM-TRACE public landing page.
///
/// Features:
/// - Clear positioning of deterministic rule engine vs AI
/// - Visual timeline of Gazette amendments and versioned rule registry
/// - Live rule condition tree preview with parameters, effective dates, and statutory references
class RuleEngineSection extends StatelessWidget {
  const RuleEngineSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      width: double.infinity,
      color: AppColors.neutral50,
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
                  color: AppColors.primaryNavy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.25)),
                ),
                child: const Text(
                  'STATUTORY RULE REGISTRY & ENGINE',
                  style: TextStyle(
                    color: AppColors.primaryNavy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                'Deterministic Statutory Compliance Engine',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDark,
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
                  'Statutory compliance in LM-TRACE is never delegated to probabilistic AI outputs. Compliance decisions are executed by a deterministic, auditable Rule Engine referencing versioned statutory Gazette notifications.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Main Architecture Block
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Versioning Timeline (45%)
                        Expanded(
                          flex: 45,
                          child: _buildVersioningTimeline(context, isMobile),
                        ),
                        const SizedBox(width: 32),
                        // Right: Rule Condition Card Preview (55%)
                        Expanded(
                          flex: 55,
                          child: _buildRuleInspectionCard(context, isMobile),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildVersioningTimeline(context, isMobile),
                        const SizedBox(height: 32),
                        _buildRuleInspectionCard(context, isMobile),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersioningTimeline(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history_toggle_off_rounded, color: AppColors.accentBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Versioned Legal Rules',
                    style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Gazette Amendment Lineage & Traceability',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Statutory requirements change over time via Ministry notifications. LM-TRACE maps inspections to the exact statutory version effective on the commodity\'s manufacture date, preventing retroactive penalties.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.55),
          ),
          const SizedBox(height: 24),
          // Timeline Steps
          _buildTimelineItem(
            version: 'PCR 2011 Baseline',
            notification: 'G.S.R. 202(E) • March 2011',
            desc: 'Enactment of The Legal Metrology (Packaged Commodities) Rules, 2011. Core declarations & Table-I PDP area standards established.',
            isActive: false,
          ),
          _buildTimelineItem(
            version: 'Amendment GSR 629(E)',
            notification: 'June 2017 Gazette',
            desc: 'Addition of Rule 6(10) mandating e-commerce marketplace seller declarations on digital product viewports.',
            isActive: false,
          ),
          _buildTimelineItem(
            version: 'Amendment GSR 779(E)',
            notification: 'November 2021 Gazette',
            desc: 'Mandatory Unit Sale Price (USP) declaration on all packaged commodities to empower price comparison.',
            isActive: false,
          ),
          _buildTimelineItem(
            version: 'Active Registry v2024.1',
            notification: 'Current Enacted Standard',
            desc: 'Integrated statutory baseline governing active field and marketplace inspections in LM-TRACE.',
            isActive: true,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String version,
    required String notification,
    required String desc,
    required bool isActive,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppColors.passGreen : const Color(0xFFCBD5E1),
                border: Border.all(
                  color: isActive ? const Color(0xFFA7F3D0) : Colors.white,
                  width: 2.5,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 54,
                color: const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      version,
                      style: TextStyle(
                        color: isActive ? AppColors.primaryNavy : AppColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.passGreenLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.passGreenBorder, width: 0.8),
                        ),
                        child: const Text(
                          'ACTIVE LAW',
                          style: TextStyle(color: AppColors.passGreen, fontSize: 9, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
                Text(
                  notification,
                  style: const TextStyle(color: AppColors.accentBlue, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleInspectionCard(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2537),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E3A5F), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.terminal_rounded, color: Color(0xFF60A5FA), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'RULE EXECUTION DEFINITION',
                    style: TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'RULE-007-PDP // ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Principal Display Panel (PDP) Font Size & Area Calibration',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Statutory Basis: Rule 7 & Table-I, Legal Metrology (Packaged Commodities) Rules, 2011',
            style: TextStyle(color: Color(0xFF8DA4C4), fontSize: 12),
          ),
          const SizedBox(height: 20),
          // Parameters Matrix
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF091624),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF162D47), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DETERMINISTIC EVALUATION PARAMETERS (TABLE-I)',
                  style: TextStyle(color: Color(0xFF60A5FA), fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                _buildParamRow('Area ≤ 50 cm²', 'Min Numeral: 1.0 mm', 'Min Letter: 1.0 mm', isMobile: isMobile),
                _buildParamRow('50 < Area ≤ 100 cm²', 'Min Numeral: 1.5 mm', 'Min Letter: 1.0 mm', isMobile: isMobile),
                _buildParamRow('100 < Area ≤ 500 cm²', 'Min Numeral: 2.5 mm', 'Min Letter: 1.5 mm (Match)', isMobile: isMobile),
                _buildParamRow('500 < Area ≤ 2500 cm²', 'Min Numeral: 4.0 mm', 'Min Letter: 2.5 mm', isMobile: isMobile),
                _buildParamRow('Area > 2500 cm²', 'Min Numeral: 6.0 mm', 'Min Letter: 4.0 mm', isMobile: isMobile),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.passGreen, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Deterministic condition trees ensure identical packaging always produces identical compliance findings, eliminating officer subjectivity.',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParamRow(String area, String numH, String letH, {bool isMobile = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(area, style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    Text(numH, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 10.5, fontWeight: FontWeight.w600)),
                    Text(letH, style: const TextStyle(color: Color(0xFF8DA4C4), fontSize: 10)),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(area, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontFamily: 'monospace')),
                Text(numH, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11, fontWeight: FontWeight.w600)),
                Text(letH, style: const TextStyle(color: Color(0xFF8DA4C4), fontSize: 10.5)),
              ],
            ),
    );
  }
}
