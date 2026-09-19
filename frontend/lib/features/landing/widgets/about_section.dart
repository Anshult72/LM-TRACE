import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_brand.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/responsive/responsive_layout.dart';

/// About Section for the LM-TRACE public landing page.
///
/// Explains platform purpose and statutory authority under:
/// - The Legal Metrology Act, 2009 (Act No. 1 of 2010)
/// - The Legal Metrology (Packaged Commodities) Rules, 2011
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      width: double.infinity,
      color: Colors.white,
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
                  'STATUTORY PURPOSE & MANDATE',
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
                'About the LM-TRACE Platform',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: isMobile ? 26 : 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),

              const SizedBox(height: 14),

              // Purpose Card
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 18 : 32),
                  decoration: BoxDecoration(
                    color: AppColors.neutral50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight, width: 1.2),
                  ),
                  child: Column(
                    children: [
                      const AppLogo(
                        size: 72,
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${AppBrand.name} — ${AppBrand.platformSubtitle}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'LM-TRACE is designed as an advanced regulatory compliance and inspection platform that combines digital inspection workflows with multi-surface Optical Character Recognition (OCR), Computer Vision geometry, AI-assisted information normalization, deterministic statutory rule evaluation, and end-to-end evidence traceability.\n\nThe platform automates the verification of pre-packaged commodities and e-commerce marketplace viewports to safeguard consumers against deceptive packaging, missing statutory declarations, illegal multiple pricing, and unnotified weight reductions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          height: 1.65,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: AppColors.borderLight, height: 1),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildMandateTag('The Legal Metrology Act, 2009 (Act No. 1 of 2010)'),
                          _buildMandateTag('The Legal Metrology (Packaged Commodities) Rules, 2011'),
                          _buildMandateTag('E-Commerce Amendments (GSR 629(E))'),
                          _buildMandateTag('Unit Sale Price Mandate (GSR 779(E))'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMandateTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.neutral300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.accentBlue),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.neutral800,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
