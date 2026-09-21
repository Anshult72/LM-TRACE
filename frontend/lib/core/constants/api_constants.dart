class ApiConstants {
  // ---------------------------------------------------------------------------
  // Production API (Railway).
  // Override at build-time for local development:
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
  //   flutter build apk --release --dart-define=API_BASE_URL=https://maanak-production.up.railway.app
  // ---------------------------------------------------------------------------
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://maanak-production.up.railway.app',
  );

  static const String login = "/api/auth/login";
  static const String me = "/api/auth/me";
  
  static const String inspections = "/api/inspections";
  static const String rules = "/api/rules";
  static const String products = "/api/products";
  static const String reports = "/api/reports";
  static const String dashboard = "/api/dashboard";
  static const String auditLogs = "/api/audit-logs";
  static const String onlineListings = "/api/listings";
  static const String referenceLibrarySearch = "/api/reference-library/search";
  static String referenceLibraryDetail(String id, [String? version]) {
    if (version != null && version.isNotEmpty) {
      return "/api/reference-library/$id?version=$version";
    }
    return "/api/reference-library/$id";
  }

  static String inspectionCalibrations(String inspectionId) => "/api/inspections/$inspectionId/calibrations";
  static String inspectionActiveCalibration(String inspectionId) => "/api/inspections/$inspectionId/calibrations/active";
  static String inspectionCalibrationPreview(String inspectionId) => "/api/inspections/$inspectionId/calibrations/preview";
  static String inspectionImage(String inspectionId, String imageId) => "$baseUrl/api/inspections/$inspectionId/images/$imageId";

  static const String statutorySummary = "/api/statutory/summary";
  static const String statutoryDocuments = "/api/statutory/documents";
  static String statutoryDocument(String id) => "/api/statutory/documents/$id";
  static const String statutoryRules = "/api/statutory/rules";
  static String statutoryRule(String id) => "/api/statutory/rules/$id";
  static const String statutoryFamilies = "/api/statutory/families";
  static String statutoryTraceability(String code) => "/api/statutory/traceability/$code";
}
