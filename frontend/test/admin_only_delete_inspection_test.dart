import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maanak_app/features/auth/auth_controller.dart';
import 'package:maanak_app/features/inspections/inspections_controller.dart';
import 'package:maanak_app/features/inspections/inspection_detail_screen.dart';
import 'package:maanak_app/features/inspections/widgets/inspection_detail_web_layout.dart';
import 'package:maanak_app/features/inspections/widgets/inspections_list_web_layout.dart';

class TestAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  TestAuthNotifier(super.initialState);

  @override
  Future<void> checkAuthStatus() async {}

  @override
  Future<bool> login(String email, String password) async => true;

  @override
  Future<void> logout() async {}
}

class TestInspectionsNotifier extends StateNotifier<InspectionState> implements InspectionsNotifier {
  TestInspectionsNotifier(super.initialState);

  @override
  String? get activeDraftId => null;

  @override
  Future<InspectionModel?> createFreshDraft() async => null;

  @override
  Future<InspectionModel?> fetchInspectionDetail(String id) async => state.selectedInspection;

  @override
  Future<void> fetchInspections() async {}

  @override
  Future<bool> deleteInspection(String inspectionId) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final sampleInspection = InspectionModel(
    id: 'ins-test-001',
    inspectionCode: 'INS-2026-TEST',
    inspectionDate: '2026-09-25T12:00:00Z',
    location: 'Test Location',
    status: 'DRAFT',
    productCategory: 'Packaged Food',
    sellerName: 'Sample Merchant',
  );

  Widget createDetailWebLayout({
    required String? role,
    required InspectionModel inspection,
  }) {
    final user = role != null
        ? AuthUser(
            id: 'u-1',
            email: 'user@demo.gov.in',
            fullName: 'Test User',
            officerId: 'LM-001',
            department: 'Metrology',
            role: role,
          )
        : null;

    return ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(
          AuthState(isAuthenticated: user != null, user: user),
        )),
        inspectionsProvider.overrideWith((ref) => TestInspectionsNotifier(
          InspectionState(selectedInspection: inspection, inspections: [inspection]),
        )),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: InspectionDetailWebLayout(
            inspection: inspection,
            onEditDeclaration: (_) {},
            onRefresh: () {},
          ),
        ),
      ),
    );
  }

  Widget createDetailMobileLayout({
    required String? role,
    required InspectionModel inspection,
  }) {
    final user = role != null
        ? AuthUser(
            id: 'u-1',
            email: 'user@demo.gov.in',
            fullName: 'Test User',
            officerId: 'LM-001',
            department: 'Metrology',
            role: role,
          )
        : null;

    return ProviderScope(
      key: UniqueKey(),
      overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(
          AuthState(isAuthenticated: user != null, user: user),
        )),
        inspectionsProvider.overrideWith((ref) => TestInspectionsNotifier(
          InspectionState(selectedInspection: inspection, inspections: [inspection]),
        )),
      ],
      child: MaterialApp(
        home: InspectionDetailScreen(
          key: UniqueKey(),
          inspectionId: inspection.id,
        ),
      ),
    );
  }

  Widget createListWebLayout({
    required String? role,
    required InspectionModel inspection,
  }) {
    final user = role != null
        ? AuthUser(
            id: 'u-1',
            email: 'user@demo.gov.in',
            fullName: 'Test User',
            officerId: 'LM-001',
            department: 'Metrology',
            role: role,
          )
        : null;

    return ProviderScope(
      key: UniqueKey(),
      overrides: [
        authProvider.overrideWith((ref) => TestAuthNotifier(
          AuthState(isAuthenticated: user != null, user: user),
        )),
        inspectionsProvider.overrideWith((ref) => TestInspectionsNotifier(
          InspectionState(selectedInspection: inspection, inspections: [inspection]),
        )),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: InspectionsListWebLayout(
            key: UniqueKey(),
          ),
        ),
      ),
    );
  }

  group('Admin-Only Delete Inspection RBAC UI Tests', () {
    testWidgets('ADMIN user CAN see and render the Delete Inspection action on Web Desktop Details', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createDetailWebLayout(
        role: 'ADMIN',
        inspection: sampleInspection,
      ));
      await tester.pumpAndSettle();

      final deleteBtnFinder = find.widgetWithText(OutlinedButton, 'Delete Inspection');
      expect(deleteBtnFinder, findsOneWidget);

      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      expect(find.text('Delete Inspection?'), findsOneWidget);
      expect(find.textContaining('This will permanently delete this inspection'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Delete Inspection'), findsOneWidget);
    });

    testWidgets('INSPECTOR user CANNOT see or render Delete Inspection on Web Desktop Details', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createDetailWebLayout(
        role: 'INSPECTOR',
        inspection: sampleInspection,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Delete Inspection'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Delete Inspection'), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.byIcon(Icons.delete_forever), findsNothing);
    });

    testWidgets('SUPERVISOR user CANNOT see or render Delete Inspection on Web Desktop Details', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createDetailWebLayout(
        role: 'SUPERVISOR',
        inspection: sampleInspection,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Delete Inspection'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Delete Inspection'), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      expect(find.byIcon(Icons.delete_forever), findsNothing);
    });

    testWidgets('UNAUTHENTICATED user CANNOT see or render Delete Inspection anywhere', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createDetailWebLayout(
        role: null,
        inspection: sampleInspection,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Delete Inspection'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Delete Inspection'), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('ADMIN user sees Delete Inspection on Mobile Details, non-admin does not', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. Admin
      await tester.pumpWidget(createDetailMobileLayout(
        role: 'ADMIN',
        inspection: sampleInspection,
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Delete Inspection'), findsOneWidget);

      // 2. Inspector
      await tester.pumpWidget(createDetailMobileLayout(
        role: 'INSPECTOR',
        inspection: sampleInspection,
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Delete Inspection'), findsNothing);
      expect(find.text('Delete Inspection'), findsNothing);
    });

    testWidgets('ADMIN user sees Delete action in Web Registry Table, Inspector does not', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. Admin in Table
      await tester.pumpWidget(createListWebLayout(
        role: 'ADMIN',
        inspection: sampleInspection,
      ));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Delete Inspection (Admin Only)'), findsOneWidget);

      // 2. Inspector in Table
      await tester.pumpWidget(createListWebLayout(
        role: 'INSPECTOR',
        inspection: sampleInspection,
      ));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Delete Inspection (Admin Only)'), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });
  });
}
