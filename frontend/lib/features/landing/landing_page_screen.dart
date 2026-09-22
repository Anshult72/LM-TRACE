import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/public_navbar.dart';
import 'widgets/hero_section.dart';
import 'widgets/problem_section.dart';
import 'widgets/how_it_works_section.dart';
import 'widgets/capabilities_section.dart';
import 'widgets/inspection_workflow_section.dart';
import 'widgets/rule_engine_section.dart';
import 'widgets/evidence_traceability_section.dart';
import 'widgets/fingerprint_change_section.dart';
import 'widgets/technology_architecture_section.dart';
import 'widgets/why_lmtrace_section.dart';
import 'widgets/about_section.dart';
import 'widgets/final_cta_section.dart';
import 'widgets/public_footer.dart';

/// Public Landing Page for LM-TRACE.
///
/// Serves as the public front door of the LM-TRACE Web Application.
/// Fully responsive across Mobile, Tablet, and Desktop tiers.
class LandingPageScreen extends StatefulWidget {
  const LandingPageScreen({super.key});

  @override
  State<LandingPageScreen> createState() => _LandingPageScreenState();
}

class _LandingPageScreenState extends State<LandingPageScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  // Anchor Keys for smooth section navigation
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _capabilitiesKey = GlobalKey();
  final GlobalKey _ruleEngineKey = GlobalKey();
  final GlobalKey _evidenceKey = GlobalKey();
  final GlobalKey _architectureKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 40;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  void _scrollToKey(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      Scrollable.ensureVisible(
        context,
        duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceIvory,
      body: Stack(
        children: [
          // Scrollable Content Body
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Top spacing spacer equal to navbar height so hero content is not obscured
                const SizedBox(height: 68),

                // 1. Hero Section
                HeroSection(
                  onExploreTap: () => _scrollToKey(_howItWorksKey),
                ),

                // 2. Regulatory Enforcement Challenges Section
                const ProblemSection(),

                // 3. 7-Step Compliance Pipeline Section
                Container(
                  key: _howItWorksKey,
                  child: const HowItWorksSection(),
                ),

                // 4. Comprehensive Capabilities Grid Section
                Container(
                  key: _capabilitiesKey,
                  child: const CapabilitiesSection(),
                ),

                // 5. Dual Workflow Walkthrough (Physical & E-Commerce)
                const InspectionWorkflowSection(),

                // 6. Deterministic Statutory Rule Engine Section
                Container(
                  key: _ruleEngineKey,
                  child: const RuleEngineSection(),
                ),

                // 7. Evidence Traceability Chain of Custody Section
                Container(
                  key: _evidenceKey,
                  child: const EvidenceTraceabilitySection(),
                ),

                // 8. Packaging Fingerprinting & Dossier Reporting
                const FingerprintChangeSection(),

                // 9. Production Technology Stack Architecture Section
                Container(
                  key: _architectureKey,
                  child: const TechnologyArchitectureSection(),
                ),

                // 10. Institutional Value Pillars Section
                const WhyLmTraceSection(),

                // 11. Statutory Purpose & Mandate Section
                Container(
                  key: _aboutKey,
                  child: const AboutSection(),
                ),

                // 12. Final High-Impact Access CTA
                const FinalCtaSection(),

                // 13. Public Regulatory Footer
                PublicFooter(
                  onHowItWorksTap: () => _scrollToKey(_howItWorksKey),
                  onCapabilitiesTap: () => _scrollToKey(_capabilitiesKey),
                  onRuleEngineTap: () => _scrollToKey(_ruleEngineKey),
                  onEvidenceTap: () => _scrollToKey(_evidenceKey),
                  onArchitectureTap: () => _scrollToKey(_architectureKey),
                  onAboutTap: () => _scrollToKey(_aboutKey),
                ),
              ],
            ),
          ),

          // Sticky Top Navigation Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: PublicNavbar(
              isScrolled: _isScrolled,
              onHowItWorksTap: () => _scrollToKey(_howItWorksKey),
              onCapabilitiesTap: () => _scrollToKey(_capabilitiesKey),
              onRuleEngineTap: () => _scrollToKey(_ruleEngineKey),
              onEvidenceTap: () => _scrollToKey(_evidenceKey),
              onArchitectureTap: () => _scrollToKey(_architectureKey),
              onAboutTap: () => _scrollToKey(_aboutKey),
            ),
          ),
        ],
      ),
    );
  }
}
