import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/responsive/responsive_layout.dart';

/// Product Fingerprinting & Report Generation Section for the LM-TRACE public landing page.
///
/// Combines:
/// 1. Packaging fingerprinting & label revision monitoring (change detection triggering officer review)
/// 2. Structured, tamper-evident inspection reports & dossiers
class FingerprintChangeSection extends StatelessWidget {
  const FingerprintChangeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
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
                  color: AppColors.primaryNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.2)),
                ),
                child: const Text(
                  'PACKAGING INTELLIGENCE & DOSSIERS',
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
                'Product Fingerprinting & Structured Reporting',
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
                  'Continuous tracking of packaging iterations to flag shrinkflation or declaration modifications, paired with automated generation of structured, court-ready inspection dossiers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Fingerprinting & Change Detection (50%)
                        Expanded(child: _buildFingerprintCard(context, isMobile)),
                        const SizedBox(width: 28),
                        // Right: Structured Inspection Report Preview (50%)
                        Expanded(child: _buildReportCard(context, isMobile)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildFingerprintCard(context, isMobile),
                        const SizedBox(height: 28),
                        _buildReportCard(context, isMobile),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFingerprintCard(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.skyGrey, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F2D3A),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.mintMist,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fingerprint_rounded, color: AppColors.inspectionGreen, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Packaging Fingerprinting',
                      style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Label Evolution & Change Tracking',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'LM-TRACE builds historical visual fingerprints for commodities across inspection cycles. When packaging is updated, the platform detects changes and cues officer review.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.55),
          ),
          const SizedBox(height: 20),
          // Comparison Flow Preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceIvory,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.skyGrey),
            ),
            child: Column(
              children: [
                _buildComparisonRow('Historical Baseline', 'Net Qty: 500 g | MRP: ₹ 140 | Pkg: Box', isMobile: isMobile),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.inspectionGreen),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Algorithmic Comparison',
                          style: TextStyle(fontSize: 10, color: AppColors.inspectionGreen, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildComparisonRow('Current Package Scan', 'Net Qty: 450 g | MRP: ₹ 140 | Pkg: Box', isAlert: true, isMobile: isMobile),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.warningAmber, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A detected packaging change triggers officer review to assess statutory net content compliance. It is not an automatic legal violation.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, String detail, {bool isAlert = false, bool isMobile = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.warningAmber.withValues(alpha: 0.1) : AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAlert ? AppColors.warningAmber.withValues(alpha: 0.3) : AppColors.skyGrey,
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isAlert ? AppColors.warningAmber : AppColors.textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    color: isAlert ? AppColors.warningAmber : AppColors.textMuted,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(color: isAlert ? AppColors.warningAmber : AppColors.textDark, fontSize: 11.5, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    detail,
                    style: TextStyle(color: isAlert ? AppColors.warningAmber : AppColors.textMuted, fontSize: 11, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildReportCard(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.skyGrey, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F2D3A),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.mintMist,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_outlined, color: AppColors.inspectionGreen, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Structured Inspection Dossiers',
                      style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Standardized Statutory Findings Export',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Inspection dossiers compile comprehensive establishment metadata, photographic proof, millimeter measurements, and applicable rule evaluations into structured PDF/DOCX formats.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.55),
          ),
          const SizedBox(height: 20),
          // Report Sections Included
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceIvory,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.skyGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportFeature(Icons.check_rounded, 'Statutory Establishment & Inspector Details'),
                _buildReportFeature(Icons.check_rounded, 'Multi-Surface Photographic Proof Annexures'),
                _buildReportFeature(Icons.check_rounded, 'Table-I PDP Bounding Area & Font Calculations'),
                _buildReportFeature(Icons.check_rounded, 'Statutory Rule References & Gazette Citations'),
                _buildReportFeature(Icons.check_rounded, 'Cryptographic Verification Hash & Timestamp'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primaryNavy, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Generated reports provide structured evidentiary documentation for statutory proceedings under the Legal Metrology Act, 2009.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Icon(icon, color: AppColors.inspectionGreen, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
