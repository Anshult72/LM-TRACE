import 'package:flutter_test/flutter_test.dart';
import 'package:maanak_app/features/scanner/models/scanner_surface_state.dart';

void main() {
  group('RequiredSurfaceValidator Tests', () {
    test('Initial states are all empty, isValid is false, 4 missing', () {
      final surfaces = RequiredSurfaceValidator.createInitialStates();
      final result = RequiredSurfaceValidator.validate(surfaces);

      expect(result.isValid, isFalse);
      expect(result.requiredCount, equals(4));
      expect(result.completedCount, equals(0));
      expect(result.missingSurfaceNames.length, equals(4));
    });

    test('1/4 complete: FRONT is success, other 3 missing -> invalid', () {
      final surfaces = RequiredSurfaceValidator.createInitialStates();
      surfaces['FRONT'] = surfaces['FRONT']!.copyWith(status: SurfaceUploadStatus.success);

      final result = RequiredSurfaceValidator.validate(surfaces);
      expect(result.isValid, isFalse);
      expect(result.completedCount, equals(1));
      expect(result.missingSurfaceNames, equals(['Back (Declarations)', 'Side (Consumer Care)', 'MRP & Date Stamp']));
    });

    test('2/4 complete: FRONT and BACK success -> invalid', () {
      final surfaces = RequiredSurfaceValidator.createInitialStates();
      surfaces['FRONT'] = surfaces['FRONT']!.copyWith(status: SurfaceUploadStatus.success);
      surfaces['BACK'] = surfaces['BACK']!.copyWith(status: SurfaceUploadStatus.success);

      final result = RequiredSurfaceValidator.validate(surfaces);
      expect(result.isValid, isFalse);
      expect(result.completedCount, equals(2));
      expect(result.missingSurfaceNames, equals(['Side (Consumer Care)', 'MRP & Date Stamp']));
    });

    test('3/4 complete: FRONT, BACK, SIDE success -> invalid, missing MRP', () {
      final surfaces = RequiredSurfaceValidator.createInitialStates();
      surfaces['FRONT'] = surfaces['FRONT']!.copyWith(status: SurfaceUploadStatus.success);
      surfaces['BACK'] = surfaces['BACK']!.copyWith(status: SurfaceUploadStatus.success);
      surfaces['SIDE'] = surfaces['SIDE']!.copyWith(status: SurfaceUploadStatus.success);

      final result = RequiredSurfaceValidator.validate(surfaces);
      expect(result.isValid, isFalse);
      expect(result.completedCount, equals(3));
      expect(result.missingSurfaceNames, equals(['MRP & Date Stamp']));
    });

    test('4/4 complete: all 4 success -> valid', () {
      final surfaces = RequiredSurfaceValidator.createInitialStates();
      surfaces['FRONT'] = surfaces['FRONT']!.copyWith(status: SurfaceUploadStatus.success);
      surfaces['BACK'] = surfaces['BACK']!.copyWith(status: SurfaceUploadStatus.success);
      surfaces['SIDE'] = surfaces['SIDE']!.copyWith(status: SurfaceUploadStatus.success);
      surfaces['MRP_AREA'] = surfaces['MRP_AREA']!.copyWith(status: SurfaceUploadStatus.success);

      final result = RequiredSurfaceValidator.validate(surfaces);
      expect(result.isValid, isTrue);
      expect(result.completedCount, equals(4));
      expect(result.missingSurfaceNames, isEmpty);
    });

    test('Uploading surface blocks analysis even if other 3 complete', () {
      final surfaces = RequiredSurfaceValidator.createInitialStates();
      surfaces['FRONT'] = surfaces['FRONT']!.copyWith(status: SurfaceUploadStatus.success);
      surfaces['BACK'] = surfaces['BACK']!.copyWith(status: SurfaceUploadStatus.success);
      surfaces['SIDE'] = surfaces['SIDE']!.copyWith(status: SurfaceUploadStatus.success);
      surfaces['MRP_AREA'] = surfaces['MRP_AREA']!.copyWith(status: SurfaceUploadStatus.uploading);

      final result = RequiredSurfaceValidator.validate(surfaces);
      expect(result.isValid, isFalse);
      expect(result.uploadingSurfaceNames, equals(['MRP & Date Stamp']));
    });

    test('Failed upload blocks analysis', () {
      final surfaces = RequiredSurfaceValidator.createInitialStates();
      surfaces['FRONT'] = surfaces['FRONT']!.copyWith(status: SurfaceUploadStatus.success);
      surfaces['BACK'] = surfaces['BACK']!.copyWith(status: SurfaceUploadStatus.failed);
      surfaces['SIDE'] = surfaces['SIDE']!.copyWith(status: SurfaceUploadStatus.success);
      surfaces['MRP_AREA'] = surfaces['MRP_AREA']!.copyWith(status: SurfaceUploadStatus.success);

      final result = RequiredSurfaceValidator.validate(surfaces);
      expect(result.isValid, isFalse);
      expect(result.failedSurfaceNames, equals(['Back (Declarations)']));
    });

    test('Clearing a surface re-blocks analysis', () {
      final surfaces = RequiredSurfaceValidator.createInitialStates();
      surfaces['FRONT'] = surfaces['FRONT']!.copyWith(status: SurfaceUploadStatus.success);
      surfaces['BACK'] = surfaces['BACK']!.copyWith(status: SurfaceUploadStatus.success);
      surfaces['SIDE'] = surfaces['SIDE']!.copyWith(status: SurfaceUploadStatus.success);
      surfaces['MRP_AREA'] = surfaces['MRP_AREA']!.copyWith(status: SurfaceUploadStatus.success);

      expect(RequiredSurfaceValidator.validate(surfaces).isValid, isTrue);

      // Remove SIDE
      surfaces['SIDE'] = surfaces['SIDE']!.copyWith(status: SurfaceUploadStatus.empty, clearImage: true);
      final resultAfterClear = RequiredSurfaceValidator.validate(surfaces);
      expect(resultAfterClear.isValid, isFalse);
      expect(resultAfterClear.missingSurfaceNames, equals(['Side (Consumer Care)']));
    });
  });
}
