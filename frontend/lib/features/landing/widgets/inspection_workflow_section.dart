import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/responsive/responsive_layout.dart';

/// Inspection Workflow Section for the LM-TRACE public landing page.
///
/// Features side-by-side or tabbed walkthroughs for:
/// 1. Physical Package Inspection (Multi-surface capture, PDP area, Table-I font measurement)
/// 2. E-Commerce Marketplace Listing Inspection (Rule 6(10) online declarations)
class InspectionWorkflowSection extends StatefulWidget {
  const InspectionWorkflowSection({super.key});

  @override
  State<InspectionWorkflowSection> createState() => _InspectionWorkflowSectionState();
}

class _InspectionWorkflowSectionState extends State<InspectionWorkflowSection> {
  int _activeWorkflow = 0; // 0: Physical Packaging, 1: E-Commerce Marketplace

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
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
                  color: AppColors.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'DUAL WORKFLOW ARCHITECTURE',
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                'Physical Packaging & E-Commerce Workflows',
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
                  'Whether inspecting pre-packaged goods at retail points of sale or evaluating digital seller viewports across marketplace platforms, LM-TRACE provides specialized enforcement paths.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Workflow Toggle Buttons
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleBtn(0, 'Physical Package Inspection', Icons.inventory_2_outlined),
                    _buildToggleBtn(1, 'E-Commerce Listing Scan', Icons.shopping_bag_outlined),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Active Workflow Display
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _activeWorkflow == 0
                    ? _buildPhysicalWorkflow(context, isDesktop, isMobile)
                    : _buildEcommerceWorkflow(context, isDesktop, isMobile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleBtn(int index, String label, IconData icon) {
    final isActive = _activeWorkflow == index;
    return InkWell(
      onTap: () => setState(() => _activeWorkflow = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive ? AppShadows.sm : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.primaryNavy : AppColors.neutral500,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primaryNavy : AppColors.neutral600,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalWorkflow(BuildContext context, bool isDesktop, bool isMobile) {
    return Container(
      key: const ValueKey('physical'),
      padding: EdgeInsets.all(isMobile ? 20 : 36),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Physical Pre-Packaged Commodity Inspection Pipeline',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Governed by The Legal Metrology (Packaged Commodities) Rules, 2011 (LMPC Rules, 2011)',
                      style: TextStyle(color: AppColors.accentBlue, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final colCount = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 550 ? 2 : 1);
              final colWidth = (constraints.maxWidth - (colCount - 1) * 16) / colCount;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildWorkflowStepCard(
                    width: colWidth,
                    stepNum: '01',
                    title: 'Multi-Surface Ingestion',
                    desc: 'Captures front PDP, back, top, and sides with perspective correction and lighting normalization.',
                  ),
                  _buildWorkflowStepCard(
                    width: colWidth,
                    stepNum: '02',
                    title: 'PDP & Font Measurement',
                    desc: 'Computes PDP bounding area (cm²) and checks numeral/letter heights against Table-I thresholds.',
                  ),
                  _buildWorkflowStepCard(
                    width: colWidth,
                    stepNum: '03',
                    title: 'Declarations & Pricing',
                    desc: 'Verifies Rule 6(1) entities, unit sale price (USP), and flags multiple/altered MRPs.',
                  ),
                  _buildWorkflowStepCard(
                    width: colWidth,
                    stepNum: '04',
                    title: 'Dossier Generation',
                    desc: 'Generates non-repudiable inspection dossier with evidence crops and statutory violation citations.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEcommerceWorkflow(BuildContext context, bool isDesktop, bool isMobile) {
    return Container(
      key: const ValueKey('ecommerce'),
      padding: EdgeInsets.all(isMobile ? 20 : 36),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'E-Commerce Marketplace Listing Compliance Pipeline',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Governed by Rule 6(10), Legal Metrology (Packaged Commodities) Amendment Rules, 2017 (GSR 629(E))',
                      style: TextStyle(color: AppColors.accentBlue, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final colCount = constraints.maxWidth >= 900 ? 4 : (constraints.maxWidth >= 550 ? 2 : 1);
              final colWidth = (constraints.maxWidth - (colCount - 1) * 16) / colCount;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildWorkflowStepCard(
                    width: colWidth,
                    stepNum: '01',
                    title: 'Digital Listing Ingestion',
                    desc: 'Extracts online product detail page (PDP) metadata, seller attributes, and package image carousels.',
                  ),
                  _buildWorkflowStepCard(
                    width: colWidth,
                    stepNum: '02',
                    title: 'Rule 6(10) Mandatory Audit',
                    desc: 'Verifies mandatory digital display of MRP, Net Qty, Country of Origin, and Manufacturer identity.',
                  ),
                  _buildWorkflowStepCard(
                    width: colWidth,
                    stepNum: '03',
                    title: 'Image vs Text Reconciliation',
                    desc: 'Cross-checks declarations printed on carousel image packaging against listed text attributes for discrepancy.',
                  ),
                  _buildWorkflowStepCard(
                    width: colWidth,
                    stepNum: '04',
                    title: 'Marketplace Notice Filing',
                    desc: 'Structures statutory non-compliance notice citing Rule 6(10) with timestamped URL evidence snapshots.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStepCard({
    required double width,
    required String stepNum,
    required String title,
    required String desc,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              stepNum,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
