import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_brand.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/responsive/responsive_layout.dart';

/// Institutional Public Footer for the LM-TRACE public landing page.
class PublicFooter extends StatelessWidget {
  final VoidCallback? onHowItWorksTap;
  final VoidCallback? onCapabilitiesTap;
  final VoidCallback? onRuleEngineTap;
  final VoidCallback? onEvidenceTap;
  final VoidCallback? onArchitectureTap;
  final VoidCallback? onAboutTap;

  const PublicFooter({
    super.key,
    this.onHowItWorksTap,
    this.onCapabilitiesTap,
    this.onRuleEngineTap,
    this.onEvidenceTap,
    this.onArchitectureTap,
    this.onAboutTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      width: double.infinity,
      color: const Color(0xFF07121D),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: isMobile ? 48 : 64,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
          child: Column(
            children: [
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Branding (40%)
                        Expanded(
                          flex: 40,
                          child: _buildBrandCol(context),
                        ),
                        const Spacer(),
                        // Nav Links (20%)
                        Expanded(
                          flex: 20,
                          child: _buildNavigationCol(context),
                        ),
                        // Statutory Mandate (25%)
                        Expanded(
                          flex: 25,
                          child: _buildStatutoryCol(context),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBrandCol(context),
                        const SizedBox(height: 32),
                        _buildNavigationCol(context),
                        const SizedBox(height: 32),
                        _buildStatutoryCol(context),
                      ],
                    ),

              const SizedBox(height: 48),
              const Divider(color: Color(0xFF162D47), height: 1),
              const SizedBox(height: 24),

              // Bottom Attribution Bar
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '© ${DateTime.now().year} ${AppBrand.name} — ${AppBrand.platformSubtitle}. All rights reserved.',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2537),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF1E3A5F), width: 1),
                      ),
                      child: const Text(
                        'Production Release v1.0.0',
                        style: TextStyle(
                          color: Color(0xFF8DA4C4),
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '© ${DateTime.now().year} ${AppBrand.name} — ${AppBrand.platformSubtitle}. All rights reserved.',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2537),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF1E3A5F), width: 1),
                      ),
                      child: const Text(
                        'Production Release v1.0.0',
                        style: TextStyle(
                          color: Color(0xFF8DA4C4),
                          fontSize: 11,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandCol(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppLogo.compact(
              size: 34,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            const SizedBox(width: 10),
            Text(
              AppBrand.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Legal Metrology Compliance & Inspection Platform combining multi-surface OCR, computer vision geometry, deterministic statutory rule evaluation, and non-repudiable evidence dossiers.',
          style: TextStyle(
            color: Color(0xFF8DA4C4),
            fontSize: 13,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.email_outlined, color: Color(0xFF60A5FA), size: 15),
            const SizedBox(width: 8),
            Text(
              AppBrand.supportEmail,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationCol(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLATFORM NAVIGATION',
          style: TextStyle(
            color: Color(0xFF93C5FD),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 14),
        _buildFooterLink('How It Works', onHowItWorksTap),
        _buildFooterLink('Capabilities', onCapabilitiesTap),
        _buildFooterLink('Statutory Rule Engine', onRuleEngineTap),
        _buildFooterLink('Evidence Traceability', onEvidenceTap),
        _buildFooterLink('System Architecture', onArchitectureTap),
        _buildFooterLink('Statutory Mandate', onAboutTap),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => context.go('/login'),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.login_rounded, color: AppColors.accentBlue, size: 14),
                SizedBox(width: 6),
                Text(
                  'Login to Platform',
                  style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatutoryCol(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATUTORY GOVERNANCE',
          style: TextStyle(
            color: Color(0xFF93C5FD),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 14),
        Text(
          '• The Legal Metrology Act, 2009 (Act No. 1 of 2010)\n• The Legal Metrology (Packaged Commodities) Rules, 2011\n• E-Commerce Marketplace Amendment (GSR 629(E))\n• Unit Sale Price Mandate (GSR 779(E))\n• Electronics QR Provisions (GSR 529(E))',
          style: TextStyle(
            color: Color(0xFF8DA4C4),
            fontSize: 12,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLink(String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
