import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/responsive/responsive_layout.dart';

/// Capabilities Section for the LM-TRACE public landing page.
///
/// Features an interactive category-filtered capability grid detailing
/// core features implemented in the LM-TRACE platform.
class CapabilitiesSection extends StatefulWidget {
  const CapabilitiesSection({super.key});

  @override
  State<CapabilitiesSection> createState() => _CapabilitiesSectionState();
}

class _CapabilitiesSectionState extends State<CapabilitiesSection> {
  String _selectedCategory = 'ALL';

  final List<_CapabilityItem> _allCapabilities = [
    _CapabilityItem(
      category: 'PHYSICAL',
      title: 'Physical Package Inspection',
      subtitle: 'Multi-Surface Package Capture',
      description:
          'Structured scanning of all physical packaging surfaces (Front, Back, Sides, Top, Bottom) with perspective correction and surface alignment.',
      icon: Icons.inventory_2_outlined,
      tag: 'CORE WORKFLOW',
    ),
    _CapabilityItem(
      category: 'PHYSICAL',
      title: 'Multi-Surface AI OCR',
      subtitle: 'Coordinate-Grounded Extraction',
      description:
          'Extracts declaration text blocks while preserving exact bounding box coordinates [x, y, w, h] to enable statutory geometric measurement.',
      icon: Icons.document_scanner_outlined,
      tag: 'EXTRACTION',
    ),
    _CapabilityItem(
      category: 'PHYSICAL',
      title: 'Table-I PDP Font Height Verification',
      subtitle: 'Packaging Area vs Numeral Height',
      description:
          'Computes Principal Display Panel area (cm²) and checks that minimum numeral/letter heights and 1:3 width ratios satisfy Rule 7 Table-I mandates.',
      icon: Icons.straighten_outlined,
      tag: 'STATUTORY CV',
    ),
    _CapabilityItem(
      category: 'RULES',
      title: 'Missing Declaration Detection',
      subtitle: 'Rule 6(1) Mandatory Check',
      description:
          'Automated audit of mandatory pre-packaged commodity declarations: commodity name, net quantity, MRP, packer name/address, mfg date, and consumer care.',
      icon: Icons.rule_rounded,
      tag: 'RULE 6(1)',
    ),
    _CapabilityItem(
      category: 'RULES',
      title: 'Dual MRP & Pricing Verification',
      subtitle: 'Predatory Pricing Restrictions',
      description:
          'Detects illegal multiple Maximum Retail Prices under Rule 18(2) and verifies statutory Unit Sale Price (USP) declarations under GSR 779(E).',
      icon: Icons.currency_rupee_rounded,
      tag: 'PRICING RULES',
    ),
    _CapabilityItem(
      category: 'ECOMMERCE',
      title: 'E-Commerce Marketplace Listing Scan',
      subtitle: 'Rule 6(10) Digital Declarations',
      description:
          'Inspects online marketplace product detail pages (PDPs) to verify mandatory digital declarations (country of origin, manufacturer, net qty, MRP).',
      icon: Icons.shopping_cart_outlined,
      tag: 'RULE 6(10)',
    ),
    _CapabilityItem(
      category: 'PHYSICAL',
      title: 'Product Packaging Fingerprinting',
      subtitle: 'Packaging History & Revisions',
      description:
          'Generates mathematical feature fingerprints of packaging labels to identify packaging modifications, revision cycles, and historical changes.',
      icon: Icons.fingerprint_rounded,
      tag: 'FINGERPRINT',
    ),
    _CapabilityItem(
      category: 'PHYSICAL',
      title: 'Label Change & Shrinkflation Detection',
      subtitle: 'Net Quantity Drift Alerts',
      description:
          'Compares new packaging against historical fingerprints to flag net weight reductions disguised in identical exterior packaging.',
      icon: Icons.compare_arrows_rounded,
      tag: 'CHANGE DETECTION',
    ),
    _CapabilityItem(
      category: 'RULES',
      title: 'Versioned Statutory Rule Registry',
      subtitle: 'Gazette Amendment Traceability',
      description:
          'Maintains active, historical, and amended statutory rules with effective dates (e.g. PCR 2011, 2017 GSR 629(E), 2021 GSR 779(E)).',
      icon: Icons.gavel_rounded,
      tag: 'RULE REGISTRY',
    ),
    _CapabilityItem(
      category: 'EVIDENCE',
      title: 'Evidence Traceability Chain',
      subtitle: 'Pixel to Finding Cryptographic Link',
      description:
          'Directly links every compliance finding to raw camera imagery, bounding box crops, extracted text, and governing statutory citation.',
      icon: Icons.verified_user_outlined,
      tag: 'AUDIT TRAIL',
    ),
    _CapabilityItem(
      category: 'EVIDENCE',
      title: 'Inspection History & Dossier Export',
      subtitle: 'PDF / DOCX Court-Ready Reports',
      description:
          'Generates standardized, signed inspection reports containing officer observations, evidence annexures, and statutory violation summaries.',
      icon: Icons.description_outlined,
      tag: 'DOSSIER GENERATION',
    ),
    _CapabilityItem(
      category: 'EVIDENCE',
      title: 'Statutory Legibility & Contrast',
      subtitle: 'Rule 9 Background Contrast',
      description:
          'Evaluates label legibility, text prominence, and background contrast ensuring declarations are distinct and unobstructed.',
      icon: Icons.contrast_rounded,
      tag: 'RULE 9',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    final filteredCapabilities = _selectedCategory == 'ALL'
        ? _allCapabilities
        : _allCapabilities.where((c) => c.category == _selectedCategory).toList();

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
                  color: AppColors.mintMist,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.sage),
                ),
                child: const Text(
                  'COMPREHENSIVE CAPABILITIES',
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
                'Built for Legal Metrology Enforcement Workflows',
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
                constraints: const BoxConstraints(maxWidth: 780),
                child: const Text(
                  'Every module is precision-engineered to address statutory requirements under the Legal Metrology Act, 2009 and Packaged Commodities Rules, 2011.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.steelBlue,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFilterTab('ALL', 'All Capabilities'),
                    const SizedBox(width: 8),
                    _buildFilterTab('PHYSICAL', 'Physical Package Scan'),
                    const SizedBox(width: 8),
                    _buildFilterTab('RULES', 'Statutory Rule Engine'),
                    const SizedBox(width: 8),
                    _buildFilterTab('ECOMMERCE', 'E-Commerce Marketplace'),
                    const SizedBox(width: 8),
                    _buildFilterTab('EVIDENCE', 'Evidence & Audit Trail'),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Capabilities Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 1100
                      ? 3
                      : (constraints.maxWidth >= 700 ? 2 : 1);
                  final itemWidth =
                      (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: filteredCapabilities
                        .map((item) => _buildCapabilityCard(item, itemWidth))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String categoryKey, String label) {
    final isSelected = _selectedCategory == categoryKey;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = categoryKey),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.skyGrey,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textCharcoal,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCapabilityCard(_CapabilityItem item, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.skyGrey, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceIvory,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.skyGrey.withValues(alpha: 0.6)),
                ),
                child: Icon(item.icon, color: AppColors.inspectionGreen, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.mintMist.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.tag,
                  style: const TextStyle(
                    color: AppColors.inspectionGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            style: const TextStyle(
              color: AppColors.primaryNavy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: const TextStyle(
              color: AppColors.inspectionGreen,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.description,
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

class _CapabilityItem {
  final String category;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String tag;

  _CapabilityItem({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.tag,
  });
}
