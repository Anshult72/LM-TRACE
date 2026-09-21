import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maanak_app/features/inspections/widgets/inspection_details_form.dart';
import 'package:maanak_app/features/inspections/inspections_controller.dart';

void main() {
  group('E-Commerce Listing Inspection Tests', () {
    test('InspectionFormData serializes e-commerce fields correctly', () {
      const data = InspectionFormData(
        location: 'Online Listing (Amazon India)',
        sellerName: 'Cloudtail India',
        businessName: 'Amazon India Listing',
        productCategory: 'FOOD',
        inspectionType: 'ONLINE_LISTING',
        packageType: 'STANDARD',
        packageConstructionType: 'RIGID',
        applicabilityContext: {'marketplace': 'Amazon India'},
        listingUrl: 'https://www.amazon.in/dp/B08XYZ1234',
        canonicalUrl: 'https://www.amazon.in/dp/B08XYZ1234',
        marketplace: 'Amazon India',
        listingMetadata: {
          'brand': 'Tata Sampann',
          'mrp': '₹120',
          'snapshot_hash': 'abcdef1234567890',
        },
      );

      final map = data.toMap();
      expect(map['inspection_type'], 'ONLINE_LISTING');
      expect(map['listing_url'], 'https://www.amazon.in/dp/B08XYZ1234');
      expect(map['canonical_url'], 'https://www.amazon.in/dp/B08XYZ1234');
      expect(map['marketplace'], 'Amazon India');
      expect(map['listing_metadata']['brand'], 'Tata Sampann');
      expect(map['listing_metadata']['snapshot_hash'], 'abcdef1234567890');
    });

    test('InspectionModel parses and stores e-commerce listing attributes', () {
      final model = InspectionModel(
        id: 'ecom-ins-01',
        inspectionCode: 'INS-ECOM-2026-001',
        inspectionDate: '2026-09-22T00:00:00Z',
        location: 'Online Listing (Flipkart)',
        status: 'IN_PROGRESS',
        listingUrl: 'https://www.flipkart.com/item/p/itm123',
        canonicalUrl: 'https://www.flipkart.com/item/p/itm123',
        marketplace: 'Flipkart',
        listingMetadata: {'title': 'Prestige Pressure Cooker'},
      );

      expect(model.listingUrl, 'https://www.flipkart.com/item/p/itm123');
      expect(model.canonicalUrl, 'https://www.flipkart.com/item/p/itm123');
      expect(model.marketplace, 'Flipkart');
      expect(model.listingMetadata?['title'], 'Prestige Pressure Cooker');

      final json = model.toJson();
      expect(json['listing_url'], 'https://www.flipkart.com/item/p/itm123');
      expect(json['marketplace'], 'Flipkart');

      final revived = InspectionModel.fromJson(json);
      expect(revived.listingUrl, 'https://www.flipkart.com/item/p/itm123');
      expect(revived.marketplace, 'Flipkart');
    });

    testWidgets('Switching to E-Commerce Listing displays listing URL and hides physical fields', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      InspectionFormData? capturedData;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
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
        ),
      );
      await tester.pumpAndSettle();

      // Initially Physical Commodity is selected
      expect(find.text('Physical Commodity'), findsOneWidget);
      expect(find.text('Inspection Location / Address *'), findsOneWidget);

      // Select E-Commerce Listing
      final ecomButton = find.text('E-Commerce Listing');
      expect(ecomButton, findsOneWidget);
      await tester.tap(ecomButton);
      await tester.pumpAndSettle();

      // Physical location field should be hidden
      expect(find.text('Inspection Location / Address *'), findsNothing);

      // E-commerce listing controls should appear
      expect(find.text('Marketplace / Platform'), findsOneWidget);
      expect(find.text('Product Listing URL *'), findsOneWidget);
      expect(find.text('Fetch Listing'), findsOneWidget);

      // Try to submit with empty URL
      final submitButton = find.text('Create & Open E-Commerce Inspection');
      expect(submitButton, findsOneWidget);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter the Product Listing URL to initiate an e-commerce inspection.'), findsOneWidget);
      expect(capturedData, isNull);

      // Enter valid product URL
      final urlField = find.widgetWithText(TextFormField, 'Product Listing URL *');
      await tester.enterText(urlField, 'https://www.amazon.in/dp/B09ABC1234');
      await tester.pumpAndSettle();

      // Submit form
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify captured data has e-commerce attributes
      expect(capturedData, isNotNull);
      expect(capturedData!.inspectionType, 'ONLINE_LISTING');
      expect(capturedData!.listingUrl, 'https://www.amazon.in/dp/B09ABC1234');
      expect(capturedData!.packageType, 'DIGITAL_LISTING');
      expect(capturedData!.location, contains('Online Listing'));
    });
  });
}
