import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maanak_app/core/widgets/context_help_drawer.dart';

void main() {
  group('PageHelpRegistry Configuration Tests', () {
    const requiredPages = [
      'dashboard',
      'inspections',
      'scanner',
      'products',
      'reference_library',
      'rules',
      'calibration',
      'supervisor',
      'audit_trail',
      'statutory_reference',
      'settings',
      'reports',
    ];

    test('All 12 required major pages exist in registry with valid sections', () {
      for (final pageId in requiredPages) {
        final content = PageHelpRegistry.get(pageId);
        expect(content, isNotNull, reason: 'PageHelpRegistry must have entry for $pageId');
        expect(content!.pageTitle.isNotEmpty, isTrue);
        expect(content.subtitle.isNotEmpty, isTrue);
        expect(content.whyExists.isNotEmpty, isTrue);
        expect(content.whatYouCanDo.isNotEmpty, isTrue);
        expect(content.howItWorks.isNotEmpty, isTrue);
        expect(content.resultsMeaning.isNotEmpty, isTrue);
        expect(content.dataSources.isNotEmpty, isTrue);
        expect(content.importantConsiderations.isNotEmpty, isTrue);
        expect(content.howItConnects.isNotEmpty, isTrue);
      }
    });

    test('Route to pageId resolution works correctly for all primary routes', () {
      expect(PageHelpRegistry.resolveFromRoute('/')?.pageId, 'dashboard');
      expect(PageHelpRegistry.resolveFromRoute('/dashboard')?.pageId, 'dashboard');
      expect(PageHelpRegistry.resolveFromRoute('/inspections')?.pageId, 'inspections');
      expect(PageHelpRegistry.resolveFromRoute('/scanner')?.pageId, 'scanner');
      expect(PageHelpRegistry.resolveFromRoute('/scan')?.pageId, 'scanner');
      expect(PageHelpRegistry.resolveFromRoute('/products')?.pageId, 'products');
      expect(PageHelpRegistry.resolveFromRoute('/reference-library')?.pageId, 'reference_library');
      expect(PageHelpRegistry.resolveFromRoute('/rules')?.pageId, 'rules');
      expect(PageHelpRegistry.resolveFromRoute('/calibration')?.pageId, 'calibration');
      expect(PageHelpRegistry.resolveFromRoute('/supervisor')?.pageId, 'supervisor');
      expect(PageHelpRegistry.resolveFromRoute('/audit-trail')?.pageId, 'audit_trail');
      expect(PageHelpRegistry.resolveFromRoute('/statutory-reference')?.pageId, 'statutory_reference');
      expect(PageHelpRegistry.resolveFromRoute('/about')?.pageId, 'statutory_reference');
      expect(PageHelpRegistry.resolveFromRoute('/settings')?.pageId, 'settings');
      expect(PageHelpRegistry.resolveFromRoute('/reports/INS-001')?.pageId, 'reports');
    });

    test('No false legal claims or guarantee terminology in help content', () {
      for (final pageId in requiredPages) {
        final content = PageHelpRegistry.get(pageId)!;
        final allText = '${content.whyExists} ${content.howItWorks} ${content.dataSources} ${content.importantConsiderations.join(" ")}';
        expect(allText.contains('100% accurate'), isFalse);
        expect(allText.contains('guaranteed compliant'), isFalse);
        expect(allText.contains('AI decides the law'), isFalse);
        expect(allText.contains('automatically certifies'), isFalse);
      }
    });
  });

  group('ContextHelpButton & ContextHelpDrawer Widget Tests', () {
    testWidgets('ContextHelpButton renders with accessible tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ContextHelpButton(pageId: 'dashboard'),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(ContextHelpButton);
      expect(buttonFinder, findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'About this page');
    });

    testWidgets('Clicking ContextHelpButton opens contextual help drawer with correct content', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ContextHelpButton(pageId: 'dashboard'),
            ),
          ),
        ),
      );

      // Tap the help button
      await tester.tap(find.byType(ContextHelpButton));
      await tester.pumpAndSettle();

      // Verify drawer opened
      expect(find.byType(ContextHelpDrawer), findsOneWidget);
      expect(find.text('ABOUT THIS PAGE'), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('WHY THIS PAGE EXISTS'), findsOneWidget);
      expect(find.text('WHAT YOU CAN DO HERE'), findsOneWidget);
      expect(find.text('HOW IT WORKS'), findsOneWidget);
      expect(find.text('WHAT THE RESULTS MEAN'), findsOneWidget);
      expect(find.text('DATA COMES FROM'), findsOneWidget);
      expect(find.text('IMPORTANT CONSIDERATIONS'), findsOneWidget);
      expect(find.text('HOW IT CONNECTS TO LM-TRACE'), findsOneWidget);

      // Verify Dashboard-specific content
      expect(find.textContaining('Compliance Rate'), findsWidgets);
    });

    testWidgets('Close button closes the drawer', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ContextHelpButton(pageId: 'inspections'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ContextHelpButton));
      await tester.pumpAndSettle();
      expect(find.byType(ContextHelpDrawer), findsOneWidget);

      // Tap the close button
      await tester.tap(find.byTooltip('Close Help Drawer (Esc)'));
      await tester.pumpAndSettle();

      // Drawer is dismissed
      expect(find.byType(ContextHelpDrawer), findsNothing);
    });

    testWidgets('ESC key closes the drawer', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ContextHelpButton(pageId: 'rules'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ContextHelpButton));
      await tester.pumpAndSettle();
      expect(find.byType(ContextHelpDrawer), findsOneWidget);

      // Send Escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(ContextHelpDrawer), findsNothing);
    });

    testWidgets('Opening drawer preserves page form text input and state', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = TextEditingController(text: 'Initial Test Value');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const ContextHelpButton(pageId: 'calibration'),
                TextField(controller: controller),
              ],
            ),
          ),
        ),
      );

      expect(controller.text, 'Initial Test Value');

      // Open drawer
      await tester.tap(find.byType(ContextHelpButton));
      await tester.pumpAndSettle();
      expect(find.byType(ContextHelpDrawer), findsOneWidget);

      // Close drawer
      await tester.tap(find.byTooltip('Close Help Drawer (Esc)'));
      await tester.pumpAndSettle();
      expect(find.byType(ContextHelpDrawer), findsNothing);

      // Verify controller text remained untouched
      expect(controller.text, 'Initial Test Value');
    });

    testWidgets('Mobile viewport renders responsive sheet without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ContextHelpButton(pageId: 'audit_trail'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ContextHelpButton));
      await tester.pumpAndSettle();

      expect(find.byType(ContextHelpDrawer), findsOneWidget);
      expect(find.text('Audit Trail'), findsWidgets);
      expect(find.text('WHY THIS PAGE EXISTS'), findsOneWidget);
    });
  });
}
