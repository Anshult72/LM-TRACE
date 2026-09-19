import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/responsive/responsive_layout.dart';

/// "How LM-TRACE Works" Section for the public landing page.
///
/// Features a 7-step structured pipeline illustrating:
/// Ingestion → Extraction → Normalization → CV Geometry → Statutory Rules → Deterministic Evaluation → Evidence Dossier.
///
/// Strictly demarcates AI understanding from deterministic statutory rule evaluation.
class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

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
                  color: AppColors.passGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.passGreen.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'THE 7-STEP COMPLIANCE PIPELINE',
                  style: TextStyle(
                    color: Color(0xFF047857),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                'How LM-TRACE Evaluates Packaging Compliance',
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
                  'A disciplined, multi-stage architecture separating intelligent data comprehension from deterministic statutory rule evaluation, ensuring complete legal defensibility.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Architectural Callout Note
              Container(
                constraints: const BoxConstraints(maxWidth: 860),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_outlined, color: Color(0xFF15803D), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Architectural Separation of Concerns: AI assists in understanding, parsing, and normalizing label data from noisy physical surfaces. The statutory Rule Engine executes deterministic evaluation against enacted law.',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 52),

              // Process Cards Sequence
              _buildPipelineGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPipelineGrid(BuildContext context) {
    final steps = [
      _StepData(
        number: '01',
        title: 'Capture & Ingestion',
        role: 'DATA INGESTION',
        roleColor: const Color(0xFF64748B),
        description:
            'High-resolution multi-surface package image capture (Front, Back, Sides, Top, Bottom) or digital e-commerce marketplace PDP viewport retrieval.',
        icon: Icons.camera_enhance_outlined,
      ),
      _StepData(
        number: '02',
        title: 'Multi-Surface OCR',
        role: 'GEOMETRIC EXTRACTION',
        roleColor: AppColors.accentBlue,
        description:
            'Optical Character Recognition extracts text clusters while preserving precise 2D pixel coordinate bounding boxes and label orientation across every package face.',
        icon: Icons.document_scanner_outlined,
      ),
      _StepData(
        number: '03',
        title: 'AI Understanding & Structuring',
        role: 'INTELLIGENT NORMALIZATION',
        roleColor: AppColors.aiPurple,
        description:
            'AI semantic models categorize raw OCR blocks into statutory declaration entities (Net Qty, MRP, Unit Sale Price, Packer Details, Month/Year, Consumer Care). AI structures—it does NOT decide the law.',
        icon: Icons.psychology_outlined,
      ),
      _StepData(
        number: '04',
        title: 'Computer Vision Geometry',
        role: 'PDP AREA & FONT MEASUREMENT',
        roleColor: const Color(0xFF0284C7),
        description:
            'Algorithmic measurement of the Principal Display Panel (PDP) surface area in cm² and precise pixel-to-millimeter calculation of numeral and letter heights.',
        icon: Icons.straighten_outlined,
      ),
      _StepData(
        number: '05',
        title: 'Applicable Statutory Rules',
        role: 'RULE CONTEXT IDENTIFICATION',
        roleColor: const Color(0xFFD97706),
        description:
            'The platform resolves the governing statutory mandate based on packaging geometry, commodity nature, and manufacture date (LMPC Rules, 2011, GSR 629(E), GSR 779(E)).',
        icon: Icons.rule_folder_outlined,
      ),
      _StepData(
        number: '06',
        title: 'Deterministic Evaluation',
        role: 'STATUTORY RULE ENGINE',
        roleColor: AppColors.passGreen,
        description:
            'Deterministic rule logic verifies compliance thresholds: presence of all mandatory declarations, Table-I font sizes, 1/3 numeral width ratios, and single MRP constraints.',
        icon: Icons.gavel_rounded,
      ),
      _StepData(
        number: '07',
        title: 'Evidence Dossier & Report',
        role: 'STATUTORY AUDIT ARTIFACT',
        roleColor: AppColors.primaryNavy,
        description:
            'Generates non-repudiable inspection reports linking every finding to photographic proof, bounding coordinates, statutory citations, and cryptographic hashes.',
        icon: Icons.assignment_turned_in_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1100
            ? 3
            : (constraints.maxWidth >= 720 ? 2 : 1);
        final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount;

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: steps.map((step) => _buildStepCard(step, itemWidth)).toList(),
        );
      },
    );
  }

  Widget _buildStepCard(_StepData step, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  step.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: step.roleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  step.role,
                  style: TextStyle(
                    color: step.roleColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(step.icon, color: AppColors.primaryNavy, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            step.description,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepData {
  final String number;
  final String title;
  final String role;
  final Color roleColor;
  final String description;
  final IconData icon;

  _StepData({
    required this.number,
    required this.title,
    required this.role,
    required this.roleColor,
    required this.description,
    required this.icon,
  });
}
