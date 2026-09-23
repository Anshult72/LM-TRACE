import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maanak_app/core/responsive/responsive_layout.dart';
import 'package:maanak_app/core/responsive/web_app_shell.dart';
import 'package:maanak_app/core/responsive/web_sidebar.dart';

void main() {
  testWidgets('Sidebar expansion must NOT move or resize main page content', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      // Set a desktop viewport size (1400x900)
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;

    const testPageKey = Key('test_main_page_content');

    final router = GoRouter(
      initialLocation: '/products',
      routes: [
        GoRoute(
          path: '/products',
          builder: (context, state) => WebAppShell(
            location: '/products',
            mobileChild: const SizedBox(),
            child: Container(
              key: testPageKey,
              color: Colors.white,
              child: const Text('Product Intelligence Page Content'),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial State: Sidebar is collapsed (72px)
    final initialContentFinder = find.byKey(testPageKey);
    expect(initialContentFinder, findsOneWidget);

    final initialContentOffset = tester.getTopLeft(initialContentFinder);
    final initialContentSize = tester.getSize(initialContentFinder);

    // Main content must start after compact rail (72px)
    expect(initialContentOffset.dx, equals(Breakpoints.collapsedSidebarWidth));

    // Verify initial sidebar width
    final sidebarFinder = find.byType(WebSidebar);
    expect(sidebarFinder, findsOneWidget);
    final initialSidebarSize = tester.getSize(sidebarFinder);
    expect(initialSidebarSize.width, equals(Breakpoints.collapsedSidebarWidth));

    // 2. Hover over the sidebar rail to expand it
    final mouseRegionFinder = find.byType(MouseRegion).first;
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(30, 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify sidebar has expanded to full width
    final expandedSidebarSize = tester.getSize(sidebarFinder);
    expect(expandedSidebarSize.width, equals(Breakpoints.sidebarWidth));

    // 3. CRITICAL NON-NEGOTIABLE CHECK:
    // Main page content position and size MUST NOT CHANGE AT ALL!
    final expandedContentOffset = tester.getTopLeft(initialContentFinder);
    final expandedContentSize = tester.getSize(initialContentFinder);

    expect(expandedContentOffset.dx, equals(initialContentOffset.dx));
    expect(expandedContentOffset.dy, equals(initialContentOffset.dy));
    expect(expandedContentSize.width, equals(initialContentSize.width));
    expect(expandedContentSize.height, equals(initialContentSize.height));

    // 4. Move mouse away to collapse the sidebar back
    await gesture.moveTo(const Offset(500, 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify sidebar is collapsed back to 72px
    final collapsedAgainSidebarSize = tester.getSize(sidebarFinder);
    expect(collapsedAgainSidebarSize.width, equals(Breakpoints.collapsedSidebarWidth));

    // Main page content remains at exact same coordinates
    final finalContentOffset = tester.getTopLeft(initialContentFinder);
    final finalContentSize = tester.getSize(initialContentFinder);
    expect(finalContentOffset.dx, equals(initialContentOffset.dx));
    await gesture.removePointer();
    } finally {
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });
}
