import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maanak_app/features/landing/landing_page_screen.dart';
import 'package:maanak_app/features/landing/widgets/public_navbar.dart';
import 'package:maanak_app/features/landing/widgets/hero_section.dart';
import 'package:maanak_app/features/landing/widgets/problem_section.dart';
import 'package:maanak_app/features/landing/widgets/how_it_works_section.dart';
import 'package:maanak_app/features/landing/widgets/capabilities_section.dart';
import 'package:maanak_app/features/landing/widgets/rule_engine_section.dart';
import 'package:maanak_app/features/landing/widgets/evidence_traceability_section.dart';
import 'package:maanak_app/features/landing/widgets/technology_architecture_section.dart';
import 'package:maanak_app/features/landing/widgets/why_lmtrace_section.dart';
import 'package:maanak_app/features/landing/widgets/about_section.dart';
import 'package:maanak_app/features/landing/widgets/final_cta_section.dart';
import 'package:maanak_app/features/landing/widgets/public_footer.dart';

void main() {
  testWidgets('LandingPageScreen renders all core sections on desktop', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LandingPageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify presence of structural components
    expect(find.byType(PublicNavbar), findsOneWidget);
    expect(find.byType(HeroSection), findsOneWidget);
    expect(find.byType(ProblemSection), findsOneWidget);
    expect(find.byType(HowItWorksSection), findsOneWidget);
    expect(find.byType(CapabilitiesSection), findsOneWidget);
    expect(find.byType(RuleEngineSection), findsOneWidget);
    expect(find.byType(EvidenceTraceabilitySection), findsOneWidget);
    expect(find.byType(TechnologyArchitectureSection), findsOneWidget);
    expect(find.byType(WhyLmTraceSection), findsOneWidget);
    expect(find.byType(AboutSection), findsOneWidget);
    expect(find.byType(FinalCtaSection), findsOneWidget);
    expect(find.byType(PublicFooter), findsOneWidget);

    // Verify key statutory terms
    expect(find.textContaining('LM-TRACE'), findsWidgets);
    expect(find.textContaining('Legal Metrology'), findsWidgets);
  });

  testWidgets('LandingPageScreen renders cleanly on mobile viewport without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LandingPageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LandingPageScreen), findsOneWidget);
    expect(find.byType(PublicNavbar), findsOneWidget);
    expect(find.byType(HeroSection), findsOneWidget);
    // On mobile, the hamburger menu icon is displayed
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
  });
}
