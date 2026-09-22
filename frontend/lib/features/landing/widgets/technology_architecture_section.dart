import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/responsive/responsive_layout.dart';

/// Technology Architecture Section for the LM-TRACE public landing page.
///
/// Accurately reflects the production tech stack used in LM-TRACE:
/// - Frontend: Flutter (Web & Mobile)
/// - Backend API: FastAPI (Python asynchronous REST service on Railway)
/// - Ingestion & CV: Multi-surface OCR & Geometric Computer Vision
/// - Semantic Understanding: Google Gemini & Groq LLM assistance
/// - Rule Engine: Deterministic Statutory Compliance Engine
/// - Data & Media: Neon PostgreSQL & Cloudinary Evidence Storage
class TechnologyArchitectureSection extends StatelessWidget {
  const TechnologyArchitectureSection({super.key});

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
                  color: AppColors.mintMist,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.sage),
                ),
                child: const Text(
                  'SYSTEM ARCHITECTURE',
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
                'Production Technology Stack',
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
                  'Engineered with modern, high-performance, and verifiable technologies designed for scalability, low-latency processing, and robust cryptographic auditability.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.steelBlue,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Architecture Flow Diagram Strip
              _buildArchitectureFlow(context),

              const SizedBox(height: 40),

              // Detailed Layer Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final colCount = constraints.maxWidth >= 1100
                      ? 3
                      : (constraints.maxWidth >= 720 ? 2 : 1);
                  final colWidth = (constraints.maxWidth - (colCount - 1) * 20) / colCount;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildTechCard(
                        width: colWidth,
                        layer: 'CLIENT APPLICATIONS',
                        tech: 'Flutter Web & Mobile',
                        role: 'Cross-platform operational UI running unified code on desktop browsers and mobile field devices.',
                        icon: Icons.devices_rounded,
                        color: AppColors.inspectionGreen,
                      ),
                      _buildTechCard(
                        width: colWidth,
                        layer: 'API GATEWAY & ENGINE',
                        tech: 'FastAPI (Python 3.11)',
                        role: 'High-throughput asynchronous REST microservices hosting inspection logic, auth, and reporting pipelines.',
                        icon: Icons.api_rounded,
                        color: AppColors.successGreen,
                      ),
                      _buildTechCard(
                        width: colWidth,
                        layer: 'COMPUTER VISION & OCR',
                        tech: 'Multi-Surface OCR & Geometry',
                        role: '2D bounding coordinate extraction, Table-I PDP area calculation, and millimeter numeral height measurement.',
                        icon: Icons.remove_red_eye_outlined,
                        color: AppColors.steelBlue,
                      ),
                      _buildTechCard(
                        width: colWidth,
                        layer: 'STATUTORY RULE ENGINE',
                        tech: 'Deterministic Compliance Logic',
                        role: 'Zero-hallucination statutory evaluator validating LMPC Rules, 2011 parameters and Gazette amendments.',
                        icon: Icons.gavel_rounded,
                        color: AppColors.primaryNavy,
                      ),
                      _buildTechCard(
                        width: colWidth,
                        layer: 'PRIMARY RELATIONAL DATABASE',
                        tech: 'Neon Serverless PostgreSQL',
                        role: 'ACID-compliant storage for versioned rule registries, inspection records, user profiles, and audit trails.',
                        icon: Icons.storage_rounded,
                        color: AppColors.primaryNavy,
                      ),
                      _buildTechCard(
                        width: colWidth,
                        layer: 'EVIDENCE & ASSET CDN',
                        tech: 'Cloudinary Media Storage',
                        role: 'High-resolution photographic evidence storage with cryptographic SHA-256 hash preservation.',
                        icon: Icons.cloud_done_outlined,
                        color: AppColors.accentGold,
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

  Widget _buildArchitectureFlow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF163E50), width: 1.2),
      ),
      child: const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FlowPill('Flutter Client'),
            _FlowConnector(),
            _FlowPill('FastAPI Gateway'),
            _FlowConnector(),
            _FlowPill('OCR & CV Extraction'),
            _FlowConnector(),
            _FlowPill('AI Normalization'),
            _FlowConnector(),
            _FlowPill('Deterministic Rule Engine'),
            _FlowConnector(),
            _FlowPill('Postgres & Cloudinary'),
          ],
        ),
      ),
    );
  }

  Widget _buildTechCard({
    required double width,
    required String layer,
    required String tech,
    required String role,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.skyGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.skyGrey),
                  ),
                  child: Text(
                    layer,
                    style: TextStyle(
                      color: color,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            tech,
            style: const TextStyle(
              color: AppColors.primaryNavy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            role,
            style: const TextStyle(
              color: AppColors.steelBlue,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowPill extends StatelessWidget {
  final String text;
  const _FlowPill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF163E50),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.inspectionGreen, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _FlowConnector extends StatelessWidget {
  const _FlowConnector();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Icon(Icons.arrow_forward_rounded, color: AppColors.accentGold, size: 14),
    );
  }
}
