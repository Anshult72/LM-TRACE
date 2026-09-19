import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/responsive/responsive_layout.dart';

/// Hero Section for the LM-TRACE public landing page.
///
/// Features:
/// - Authoritative institutional heading and value proposition
/// - Dual CTAs: Access Platform (/login) and Explore Workflow
/// - Interactive digital inspection & compliance terminal preview
/// - Visual evidence breakdown adhering to LMPC Rules, 2011
class HeroSection extends StatefulWidget {
  final VoidCallback onExploreTap;

  const HeroSection({super.key, required this.onExploreTap});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  int _activeTab = 0; // 0: Declarations, 1: PDP Table-I, 2: Statutory Rules

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryNavy,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F2537),
            Color(0xFF091624),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background ambient grid pattern and subtle radial glows
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentBlue.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.passGreen.withValues(alpha: 0.04),
              ),
            ),
          ),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 32,
                  vertical: isMobile ? 48 : 80,
                ),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left column: Headline & CTAs (52%)
                          Expanded(
                            flex: 52,
                            child: _buildHeroTextContent(context, isMobile),
                          ),
                          const SizedBox(width: 48),
                          // Right column: Digital Compliance Terminal (48%)
                          Expanded(
                            flex: 48,
                            child: _buildInteractiveTerminal(context),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildHeroTextContent(context, isMobile),
                          const SizedBox(height: 40),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: _buildInteractiveTerminal(context),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTextContent(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Statutory Authority Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2E5685), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.passGreen,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LEGAL METROLOGY COMPLIANCE & INSPECTION PLATFORM',
                style: TextStyle(
                  color: Color(0xFFBAE6FD),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Main Headline
        Text(
          'Intelligent Evidence,\nStatutory Rules, and\nTraceable Enforcement',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 32 : 46,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
        ),

        const SizedBox(height: 20),

        // Supporting Subtitle
        Text(
          'LM-TRACE modernizes regulatory inspection workflows for physical pre-packaged commodities and e-commerce marketplaces under the Legal Metrology Act, 2009 and Packaged Commodities Rules, 2011.',
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 16,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 32),

        // Call to Action Buttons
        Wrap(
          spacing: 16,
          runSpacing: 14,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            // Primary CTA: Access Platform
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                shadowColor: AppColors.accentBlue.withValues(alpha: 0.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Access Platform',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),

            // Secondary CTA: Explore How It Works
            OutlinedButton(
              onPressed: widget.onExploreTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE2E8F0),
                side: const BorderSide(color: Color(0xFF2E4E73), width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_outline_rounded, size: 18, color: Color(0xFF93C5FD)),
                  SizedBox(width: 8),
                  Text(
                    'Explore How It Works',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 36),

        // Trust & Regulatory Pillars Strip
        Wrap(
          spacing: 24,
          runSpacing: 12,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            _buildTrustBadge(Icons.gavel_rounded, 'Act No. 1 of 2010'),
            _buildTrustBadge(Icons.rule_rounded, 'LMPC Rules, 2011'),
            _buildTrustBadge(Icons.straighten_rounded, 'Table-I PDP Verified'),
            _buildTrustBadge(Icons.lock_clock_outlined, 'Traceable Audit Dossier'),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF60A5FA), size: 15),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8DA4C4),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Digital Inspection Terminal Preview
  Widget _buildInteractiveTerminal(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1928),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A5F), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D000000),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x1F2563EB),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Terminal Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F2537),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF4444)),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'LM-TRACE // COMPLIANCE EVALUATION ENGINE v1.0',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.passGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.passGreen.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: const Text(
                    'EVALUATED',
                    style: TextStyle(
                      color: AppColors.passGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Terminal Mode Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF091624),
              border: Border(bottom: BorderSide(color: Color(0xFF162D47), width: 1)),
            ),
            child: Row(
              children: [
                _buildTerminalTab(0, 'Declarations (6)', Icons.text_snippet_outlined),
                const SizedBox(width: 8),
                _buildTerminalTab(1, 'PDP Table-I', Icons.straighten_outlined),
                const SizedBox(width: 8),
                _buildTerminalTab(2, 'Rule Engine', Icons.gavel_outlined),
              ],
            ),
          ),

          // Terminal Body Content
          Padding(
            padding: const EdgeInsets.all(18),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildActiveTabContent(),
            ),
          ),

          // Terminal Footer: Evidence Trace Fingerprint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF091624),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              border: Border(top: BorderSide(color: Color(0xFF162D47), width: 1)),
            ),
            child: const Row(
              children: [
                Icon(Icons.fingerprint_rounded, color: Color(0xFF60A5FA), size: 14),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'SHA-256: 7f8a92b1...d40e',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Traceable Dossier',
                  style: TextStyle(
                    color: Color(0xFF8DA4C4),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalTab(int index, String label, IconData icon) {
    final isActive = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E3A5F) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? Colors.white : const Color(0xFF8DA4C4),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF8DA4C4),
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildDeclarationsContent();
      case 1:
        return _buildPdpContent();
      case 2:
        return _buildRuleEngineContent();
      default:
        return _buildDeclarationsContent();
    }
  }

  Widget _buildDeclarationsContent() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'EXTRACTED STATUTORY DECLARATIONS',
              style: TextStyle(
                color: Color(0xFF93C5FD),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.passGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '6/6 Present',
                style: TextStyle(color: AppColors.passGreen, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDeclRow('Net Quantity', '500 g', 'Rule 6(1)(e)', true),
        _buildDeclRow('Maximum Retail Price', '₹ 145.00 (Incl. of all taxes)', 'Rule 6(1)(c)', true),
        _buildDeclRow('Unit Sale Price (USP)', '₹ 0.29 / g', 'GSR 779(E)', true),
        _buildDeclRow('Manufacturer / Packer', 'Apex Consumer Products Ltd., Baddi (H.P.)', 'Rule 6(1)(a)', true),
        _buildDeclRow('Date of Manufacture', '10/2024', 'Rule 6(1)(d)', true),
        _buildDeclRow('Consumer Care Details', 'care@apex.in | 1800-200-XXXX', 'Rule 6(1)(g)', true),
      ],
    );
  }

  Widget _buildDeclRow(String label, String value, String rule, bool isPass) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isPass ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isPass ? AppColors.passGreen : AppColors.violationRed,
            size: 14,
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFF162D47),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              rule,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdpContent() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRINCIPAL DISPLAY PANEL (PDP) TABLE-I VERIFICATION',
          style: TextStyle(
            color: Color(0xFF93C5FD),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildMetricRow('Computed PDP Area', '142.6 cm²', 'Threshold: 100 < Area ≤ 500 cm²'),
        _buildMetricRow('Statutory Min. Numeral Height', '2.5 mm', 'Rule 7, Table-I Baseline'),
        _buildMetricRow('Statutory Min. Letter Height', '1.5 mm', 'Rule 7, Table-I Baseline'),
        _buildMetricRow('Measured Net Qty Numeral', '2.92 mm', 'PASS (+0.42 mm clearance)', isPass: true),
        _buildMetricRow('Measured MRP Numeral', '2.68 mm', 'PASS (+0.18 mm clearance)', isPass: true),
        _buildMetricRow('Numeral Width-to-Height Ratio', '0.41', 'PASS (Statutory minimum 0.33)', isPass: true),
      ],
    );
  }

  Widget _buildMetricRow(String title, String val, String sub, {bool? isPass}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11.5, fontWeight: FontWeight.w600)),
                Text(sub, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isPass == null
                  ? const Color(0xFF162D47)
                  : (isPass ? AppColors.passGreen.withValues(alpha: 0.15) : AppColors.violationRed.withValues(alpha: 0.15)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              val,
              style: TextStyle(
                color: isPass == null ? const Color(0xFF93C5FD) : (isPass ? AppColors.passGreen : AppColors.violationRed),
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleEngineContent() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DETERMINISTIC STATUTORY RULE EXECUTION',
          style: TextStyle(
            color: Color(0xFF93C5FD),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildRuleStatusRow('RULE-006-DECL', 'PCR 2011 Rule 6(1)', 'MANDATORY DECLARATIONS', 'COMPLIANT'),
        _buildRuleStatusRow('RULE-007-PDP', 'PCR 2011 Rule 7', 'PDP CHARACTER HEIGHT (TABLE-I)', 'COMPLIANT'),
        _buildRuleStatusRow('RULE-002-USP', 'GSR 779(E) 2021', 'UNIT SALE PRICE OBLIGATION', 'COMPLIANT'),
        _buildRuleStatusRow('RULE-009-LEG', 'PCR 2011 Rule 9(1)', 'LABEL CONTRAST & LEGIBILITY', 'COMPLIANT'),
        _buildRuleStatusRow('RULE-018-DMR', 'PCR 2011 Rule 18(2)', 'DUAL MRP RESTRICTION', 'COMPLIANT'),
      ],
    );
  }

  Widget _buildRuleStatusRow(String code, String citation, String name, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.passGreen),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$code // $name',
                  style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  citation,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.passGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.passGreen.withValues(alpha: 0.3), width: 0.8),
            ),
            child: Text(
              status,
              style: const TextStyle(color: AppColors.passGreen, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
