import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/responsive/responsive_layout.dart';

/// Evidence Traceability Section for the LM-TRACE public landing page.
///
/// Demonstrates the end-to-end chain of custody:
/// Product → Captured Evidence → OCR Output → Visual Observation → Applicable Rule → Evaluation → Finding → Report.
/// Answers the fundamental enforcement question: "Why was this finding produced?"
class EvidenceTraceabilitySection extends StatelessWidget {
  const EvidenceTraceabilitySection({super.key});

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
                  color: AppColors.primaryNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.2)),
                ),
                child: const Text(
                  'END-TO-END AUDIT INTEGRITY',
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
                'Complete Evidence Chain of Custody',
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
                constraints: const BoxConstraints(maxWidth: 800),
                child: const Text(
                  'Every compliance evaluation in LM-TRACE is grounded in indisputable photographic and spatial evidence. Officers can instantly trace findings backward from court-ready reports to the exact pixel coordinates on the packaging.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Evidence Trace Chain Visual Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 960;
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceIvory,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.skyGrey, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.link_rounded, color: AppColors.inspectionGreen, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Traceability Pathway: From Raw Photometric Evidence to Admissible Finding',
                                style: TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Trace Steps
                        isWide
                            ? Row(
                                children: [
                                  Expanded(child: _buildChainNode('01', 'High-Res Ingestion', 'Packaging surface photo with metadata timestamp', Icons.camera_alt_outlined)),
                                  _buildChainArrow(),
                                  Expanded(child: _buildChainNode('02', 'Spatial Bounding', '2D polygon coordinates [x, y, w, h] of declarations', Icons.crop_free_rounded)),
                                  _buildChainArrow(),
                                  Expanded(child: _buildChainNode('03', 'OCR Text Cluster', 'Normalized text characters with confidence score', Icons.text_snippet_outlined)),
                                  _buildChainArrow(),
                                  Expanded(child: _buildChainNode('04', 'Statutory Rule Match', 'Rule 6(1), Rule 7 Table-I condition check', Icons.gavel_rounded)),
                                  _buildChainArrow(),
                                  Expanded(child: _buildChainNode('05', 'Signed Dossier', 'Cryptographically sealed PDF inspection report', Icons.verified_user_rounded, isLast: true)),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildChainNode('01', 'High-Res Ingestion', 'Packaging surface photo with metadata timestamp', Icons.camera_alt_outlined),
                                  const SizedBox(height: 12),
                                  _buildChainNode('02', 'Spatial Bounding', '2D polygon coordinates [x, y, w, h] of declarations', Icons.crop_free_rounded),
                                  const SizedBox(height: 12),
                                  _buildChainNode('03', 'OCR Text Cluster', 'Normalized text characters with confidence score', Icons.text_snippet_outlined),
                                  const SizedBox(height: 12),
                                  _buildChainNode('04', 'Statutory Rule Match', 'Rule 6(1), Rule 7 Table-I condition check', Icons.gavel_rounded),
                                  const SizedBox(height: 12),
                                  _buildChainNode('05', 'Signed Dossier', 'Cryptographically sealed PDF inspection report', Icons.verified_user_rounded, isLast: true),
                                ],
                              ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Practical Finding Trace Example Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceIvory,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.skyGrey, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x060F2D3A),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.mintMist,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.verified_rounded, color: AppColors.inspectionGreen, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Why was this finding produced? (Statutory Transparency Principle)',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Every line item in the inspection report contains a direct hyperlink to the original image cropped at the declaration bounding box, the exact statutory clause enforced, and the mathematical formula evaluated. No black-box verdicts.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChainNode(String num, String title, String subtitle, IconData icon, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLast ? AppColors.inspectionGreen : AppColors.skyGrey,
          width: isLast ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                num,
                style: const TextStyle(
                  color: AppColors.inspectionGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
              Icon(icon, size: 18, color: isLast ? AppColors.inspectionGreen : AppColors.steelBlue),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChainArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Icon(Icons.arrow_forward_rounded, color: AppColors.steelBlue, size: 18),
    );
  }
}
