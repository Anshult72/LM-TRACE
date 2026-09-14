import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maanak_app/features/inspections/widgets/inspection_details_form.dart';
import 'package:maanak_app/features/inspections/inspections_controller.dart';

void main() {
  testWidgets('InspectionDetailsForm requires establishment name and valid location', (WidgetTester tester) async {
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
              initialInspection: InspectionModel(
                id: 'ins-test-01',
                inspectionCode: 'INS-2026-TEST',
                inspectionDate: '2026-09-13T00:00:00Z',
                location: 'Field Scan (Pending Finalisation)',
                status: 'DRAFT',
              ),
              isFinalizing: true,
              onSubmit: (data) async {
                submitted = true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify submit button is present
    final submitFinder = find.text('Confirm & Finalize Inspection');
    expect(submitFinder, findsOneWidget);

    await tester.ensureVisible(submitFinder);
    await tester.tap(submitFinder);
    await tester.pumpAndSettle();


    // Validation errors must be shown and form not submitted
    expect(find.text('Establishment name is required'), findsOneWidget);
    expect(submitted, isFalse);
  });

  testWidgets('InspectionDetailsForm submits valid data correctly', (WidgetTester tester) async {
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

    final bizField = find.byType(TextFormField).first;
    await tester.enterText(bizField, 'Heritage Fresh Supermarket');

    final locField = find.byType(TextFormField).at(1);
    await tester.enterText(locField, 'Khan Market, Shop 14, New Delhi');

    await tester.ensureVisible(submitFinder);
    await tester.tap(submitFinder);
    await tester.pumpAndSettle();

    expect(capturedData, isNotNull);
    expect(capturedData!.businessName, 'Heritage Fresh Supermarket');
    expect(capturedData!.location, 'Khan Market, Shop 14, New Delhi');
  });
}
