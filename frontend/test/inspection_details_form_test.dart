import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maanak_app/features/inspections/widgets/inspection_details_form.dart';
import 'package:maanak_app/features/inspections/inspections_controller.dart';

void main() {
  group('InspectionDetailsForm — Progressive Disclosure & Simplification', () {
    testWidgets('New Inspection displays only minimal baseline fields (no upfront questionnaires)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InspectionDetailsForm(
                initialInspection: null,
                isFinalizing: false,
                onSubmit: (data) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Baseline case creation fields MUST be present
      expect(find.text('Inspection Channel'), findsOneWidget);
      expect(find.text('Physical Commodity'), findsOneWidget);
      expect(find.text('E-Commerce Listing'), findsOneWidget);
      expect(find.text('Basic Inspection Information'), findsOneWidget);
      expect(find.text('Establishment / Trader Name *'), findsOneWidget);
      expect(find.text('Inspection Location / Address *'), findsOneWidget);
      expect(find.text('Commodity Category *'), findsOneWidget);
      expect(find.text('Dealer / Seller Licensee (Optional)'), findsOneWidget);
      expect(find.text('Optional Field Notes'), findsOneWidget);
      expect(find.text('Inspection Field Notes (Optional)'), findsOneWidget);

      // Primary action button reflects physical next step
      expect(find.text('Create & Proceed to Capture'), findsOneWidget);

      // Technical & legal questionnaire fields MUST NOT be shown upfront
      expect(find.text('Package Construction'), findsNothing);
      expect(find.text('Package Geometry / Shape'), findsNothing);
      expect(find.text('Declaration Applicability (Rule 6)'), findsNothing);
      expect(find.text('Intended Consumer / Market Scope'), findsNothing);
      expect(find.text('Commodity Origin'), findsNothing);
      expect(find.text('Separate packer declaration'), findsNothing);
      expect(find.text('Best Before / Use By declaration'), findsNothing);
      expect(find.text('Commodity dimensions declaration'), findsNothing);
      expect(find.text('Unit sale price declaration'), findsNothing);
      expect(find.text('Multi-piece / group / gift package'), findsNothing);
      expect(find.text('Declarations provided through QR / electronic link'), findsNothing);
      expect(find.text('Package has an outside container / wrapper'), findsNothing);
    });

    testWidgets('New Inspection submits with only minimal mandatory fields (optional notes left empty)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      InspectionFormData? capturedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InspectionDetailsForm(
                initialInspection: null,
                isFinalizing: false,
                onSubmit: (data) async {
                  capturedData = data;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final submitFinder = find.text('Create & Proceed to Capture');
      expect(submitFinder, findsOneWidget);

      // Enter only mandatory establishment and location
      final bizField = find.widgetWithText(TextFormField, 'Establishment / Trader Name *');
      await tester.enterText(bizField, 'Heritage Fresh Supermarket');

      final locField = find.widgetWithText(TextFormField, 'Inspection Location / Address *');
      await tester.enterText(locField, 'Khan Market, Shop 14, New Delhi');

      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(capturedData, isNotNull);
      expect(capturedData!.businessName, 'Heritage Fresh Supermarket');
      expect(capturedData!.location, 'Khan Market, Shop 14, New Delhi');
      expect(capturedData!.inspectionType, 'PHYSICAL');
      expect(capturedData!.notes, isNull);
      // Backend defaults safely preserved
      expect(capturedData!.packageType, 'RECTANGULAR');
      expect(capturedData!.packageConstructionType, 'NORMAL');
    });

    testWidgets('New Inspection rejects submission when mandatory fields are missing', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InspectionDetailsForm(
                initialInspection: null,
                isFinalizing: false,
                onSubmit: (data) async {
                  submitted = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final submitFinder = find.text('Create & Proceed to Capture');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.text('Establishment name is required'), findsOneWidget);
      expect(find.text('Inspection location address is required'), findsOneWidget);
      expect(submitted, isFalse);
    });

    testWidgets('Finalize Inspection screen displays streamlined baseline fields matching new inspection', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InspectionDetailsForm(
                initialInspection: InspectionModel(
                  id: 'ins-test-01',
                  inspectionCode: 'INS-2026-TEST',
                  inspectionDate: '2026-09-13T00:00:00Z',
                  location: 'Connaught Place, New Delhi',
                  businessName: 'Metro Hypermarket',
                  status: 'DRAFT',
                ),
                isFinalizing: true,
                onSubmit: (data) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Finalization button
      expect(find.text('Confirm & Finalize Inspection'), findsOneWidget);

      // Baseline fields MUST be present and prefilled
      expect(find.text('Basic Inspection Information'), findsOneWidget);
      expect(find.text('Establishment / Trader Name *'), findsOneWidget);
      expect(find.text('Inspection Location / Address *'), findsOneWidget);
      expect(find.text('Commodity Category *'), findsOneWidget);
      expect(find.text('Dealer / Seller Licensee (Optional)'), findsOneWidget);
      expect(find.text('Optional Field Notes'), findsOneWidget);
      expect(find.text('Metro Hypermarket'), findsOneWidget);
      expect(find.text('Connaught Place, New Delhi'), findsOneWidget);

      // Technical & legal questionnaire fields MUST NOT be shown
      expect(find.text('Package Construction'), findsNothing);
      expect(find.text('Package Geometry / Shape'), findsNothing);
      expect(find.text('Declaration Applicability (Rule 6)'), findsNothing);
      expect(find.text('Intended Consumer / Market Scope'), findsNothing);
      expect(find.text('Commodity Origin'), findsNothing);
      expect(find.text('Separate packer declaration'), findsNothing);
      expect(find.text('Best Before / Use By declaration'), findsNothing);
      expect(find.text('Multi-piece / group / gift package'), findsNothing);
      expect(find.text('Package has an outside container / wrapper'), findsNothing);
    });
  });
}
