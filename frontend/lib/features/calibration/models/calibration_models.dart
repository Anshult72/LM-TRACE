
class CalibrationPointModel {
  final double x;
  final double y;

  const CalibrationPointModel({required this.x, required this.y});

  factory CalibrationPointModel.fromJson(Map<String, dynamic> json) {
    return CalibrationPointModel(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

class CalibrationItemModel {
  final String id;
  final String inspectionId;
  final String? imageId;
  final String userId;
  final String referenceType;
  final String? referenceDescription;
  final CalibrationPointModel pointA;
  final CalibrationPointModel pointB;
  final double pixelDistance;
  final double knownDistance;
  final String unit;
  final double pixelsPerUnit;
  final int? imageWidth;
  final int? imageHeight;
  final String? imageHash;
  final String calibrationStatus;
  final bool perspectiveWarning;
  final String createdAt;
  final String? updatedAt;

  CalibrationItemModel({
    required this.id,
    required this.inspectionId,
    this.imageId,
    required this.userId,
    required this.referenceType,
    this.referenceDescription,
    required this.pointA,
    required this.pointB,
    required this.pixelDistance,
    required this.knownDistance,
    this.unit = 'mm',
    required this.pixelsPerUnit,
    this.imageWidth,
    this.imageHeight,
    this.imageHash,
    this.calibrationStatus = 'VALID',
    this.perspectiveWarning = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory CalibrationItemModel.fromJson(Map<String, dynamic> json) {
    final ptA = json['point_a'] is Map
        ? CalibrationPointModel.fromJson(Map<String, dynamic>.from(json['point_a']))
        : const CalibrationPointModel(x: 0, y: 0);
    final ptB = json['point_b'] is Map
        ? CalibrationPointModel.fromJson(Map<String, dynamic>.from(json['point_b']))
        : const CalibrationPointModel(x: 0, y: 0);

    return CalibrationItemModel(
      id: json['id']?.toString() ?? '',
      inspectionId: json['inspection_id']?.toString() ?? '',
      imageId: json['image_id']?.toString(),
      userId: json['user_id']?.toString() ?? 'officer',
      referenceType: json['reference_type']?.toString() ?? 'RULER',
      referenceDescription: json['reference_description']?.toString(),
      pointA: ptA,
      pointB: ptB,
      pixelDistance: (json['pixel_distance'] as num?)?.toDouble() ?? 0.0,
      knownDistance: (json['known_distance'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString() ?? 'mm',
      pixelsPerUnit: (json['pixels_per_unit'] as num?)?.toDouble() ?? 0.0,
      imageWidth: (json['image_width'] as num?)?.toInt(),
      imageHeight: (json['image_height'] as num?)?.toInt(),
      imageHash: json['image_hash']?.toString(),
      calibrationStatus: json['calibration_status']?.toString() ?? 'VALID',
      perspectiveWarning: json['perspective_warning'] == true,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class DeclarationMeasurementItem {
  final String declarationId;
  final String fieldName;
  final String verifiedValue;
  final double pixelHeight;
  final double physicalHeightMm;
  final double? requiredMinHeightMm;
  final String status; // PASS, VIOLATION, UNVERIFIED
  final double differenceMm;

  DeclarationMeasurementItem({
    required this.declarationId,
    required this.fieldName,
    required this.verifiedValue,
    required this.pixelHeight,
    required this.physicalHeightMm,
    this.requiredMinHeightMm,
    required this.status,
    required this.differenceMm,
  });

  factory DeclarationMeasurementItem.fromJson(Map<String, dynamic> json) {
    return DeclarationMeasurementItem(
      declarationId: json['declaration_id']?.toString() ?? '',
      fieldName: json['field_name']?.toString() ?? '',
      verifiedValue: json['verified_value']?.toString() ?? '',
      pixelHeight: (json['pixel_height'] as num?)?.toDouble() ?? 0.0,
      physicalHeightMm: (json['physical_height_mm'] as num?)?.toDouble() ?? 0.0,
      requiredMinHeightMm: (json['required_min_height_mm'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'UNVERIFIED',
      differenceMm: (json['difference_mm'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CalibrationPreviewModel {
  final double pixelDistance;
  final double knownDistanceMm;
  final double pixelsPerMm;
  final String status;
  final double? pdpAreaCm2;
  final String? pdpThresholdLabel;
  final double? requiredMinHeightMm;
  final List<DeclarationMeasurementItem> declarationMeasurements;

  CalibrationPreviewModel({
    required this.pixelDistance,
    required this.knownDistanceMm,
    required this.pixelsPerMm,
    required this.status,
    this.pdpAreaCm2,
    this.pdpThresholdLabel,
    this.requiredMinHeightMm,
    this.declarationMeasurements = const [],
  });

  factory CalibrationPreviewModel.fromJson(Map<String, dynamic> json) {
    final list = (json['declaration_measurements'] as List? ?? [])
        .whereType<Map>()
        .map((m) => DeclarationMeasurementItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    return CalibrationPreviewModel(
      pixelDistance: (json['pixel_distance'] as num?)?.toDouble() ?? 0.0,
      knownDistanceMm: (json['known_distance_mm'] as num?)?.toDouble() ?? 0.0,
      pixelsPerMm: (json['pixels_per_mm'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'VALID',
      pdpAreaCm2: (json['pdp_area_cm2'] as num?)?.toDouble(),
      pdpThresholdLabel: json['pdp_threshold_label']?.toString(),
      requiredMinHeightMm: (json['required_min_height_mm'] as num?)?.toDouble(),
      declarationMeasurements: list,
    );
  }
}
