class ReferenceProductSummary {
  final String productId;
  final String name;
  final String brand;
  final String category;
  final String packSize;
  final String declaredMrp;
  final String barcode;
  final String referenceStatus;
  final String referenceStatusLabel;
  final String eligibility;
  final List<String> eligibilityReasons;
  final String activeVersion;
  final String? lastInspectionDate;
  final String? sourceInspectionCode;
  final String? sourceInspectionId;
  final String? primaryImageUrl;
  final String? thumbnailUrl;
  final List<String> applicableRequirements;
  final List<String> matchReasons;
  final int relevanceScore;
  final int inspectionCount;

  ReferenceProductSummary({
    required this.productId,
    required this.name,
    required this.brand,
    required this.category,
    required this.packSize,
    required this.declaredMrp,
    required this.barcode,
    required this.referenceStatus,
    required this.referenceStatusLabel,
    required this.eligibility,
    required this.eligibilityReasons,
    required this.activeVersion,
    this.lastInspectionDate,
    this.sourceInspectionCode,
    this.sourceInspectionId,
    this.primaryImageUrl,
    this.thumbnailUrl,
    required this.applicableRequirements,
    required this.matchReasons,
    required this.relevanceScore,
    required this.inspectionCount,
  });

  factory ReferenceProductSummary.fromJson(Map<String, dynamic> json) {
    return ReferenceProductSummary(
      productId: json['product_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Packaged Commodity',
      brand: json['brand']?.toString() ?? 'Packaged Commodity',
      category: json['category']?.toString() ?? 'Packaged Commodity',
      packSize: json['pack_size']?.toString() ?? 'Standard Pack',
      declaredMrp: json['declared_mrp']?.toString() ?? 'Not captured',
      barcode: json['barcode']?.toString() ?? 'Not available',
      referenceStatus: json['reference_status']?.toString() ?? 'LIMITED',
      referenceStatusLabel: json['reference_status_label']?.toString() ?? 'Limited Statutory Data',
      eligibility: json['eligibility']?.toString() ?? 'LIMITED_DATA',
      eligibilityReasons: (json['eligibility_reasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      activeVersion: json['active_version']?.toString() ?? 'v1.0',
      lastInspectionDate: json['last_inspection_date']?.toString(),
      sourceInspectionCode: json['source_inspection_code']?.toString(),
      sourceInspectionId: json['source_inspection_id']?.toString(),
      primaryImageUrl: json['primary_image_url']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      applicableRequirements: (json['applicable_requirements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      matchReasons: (json['match_reasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      relevanceScore: (json['relevance_score'] as num?)?.toInt() ?? 0,
      inspectionCount: (json['inspection_count'] as num?)?.toInt() ?? 1,
    );
  }
}
