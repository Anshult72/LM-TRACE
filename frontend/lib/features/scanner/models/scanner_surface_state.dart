import 'dart:typed_data';

enum SurfaceUploadStatus {
  empty,
  uploading,
  success,
  failed,
}

class RequiredSurfaceDef {
  final String code;
  final String name;
  final String description;

  const RequiredSurfaceDef({
    required this.code,
    required this.name,
    required this.description,
  });
}

class SurfaceState {
  final RequiredSurfaceDef definition;
  final SurfaceUploadStatus status;
  final Uint8List? imageBytes;
  final String? imageName;
  final String? serverImageId;
  final String? remoteImageUrl;
  final String? imageBase64;
  final String? errorMessage;

  const SurfaceState({
    required this.definition,
    this.status = SurfaceUploadStatus.empty,
    this.imageBytes,
    this.imageName,
    this.serverImageId,
    this.remoteImageUrl,
    this.imageBase64,
    this.errorMessage,
  });

  bool get isComplete => status == SurfaceUploadStatus.success;
  bool get isUploading => status == SurfaceUploadStatus.uploading;
  bool get isFailed => status == SurfaceUploadStatus.failed;
  bool get isEmpty => status == SurfaceUploadStatus.empty;
  bool get hasPreview =>
      (imageBytes != null && imageBytes!.isNotEmpty) ||
      (remoteImageUrl != null && remoteImageUrl!.isNotEmpty) ||
      (imageBase64 != null && imageBase64!.isNotEmpty);

  SurfaceState copyWith({
    SurfaceUploadStatus? status,
    Uint8List? imageBytes,
    String? imageName,
    String? serverImageId,
    String? remoteImageUrl,
    String? imageBase64,
    String? errorMessage,
    bool clearImage = false,
  }) {
    return SurfaceState(
      definition: definition,
      status: status ?? this.status,
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
      imageName: clearImage ? null : (imageName ?? this.imageName),
      serverImageId: clearImage ? null : (serverImageId ?? this.serverImageId),
      remoteImageUrl: clearImage ? null : (remoteImageUrl ?? this.remoteImageUrl),
      imageBase64: clearImage ? null : (imageBase64 ?? this.imageBase64),
      errorMessage: clearImage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class RequiredImagesValidationResult {
  final bool isValid;
  final int requiredCount;
  final int completedCount;
  final List<String> missingSurfaceNames;
  final List<String> completedSurfaceNames;
  final List<String> uploadingSurfaceNames;
  final List<String> failedSurfaceNames;

  const RequiredImagesValidationResult({
    required this.isValid,
    required this.requiredCount,
    required this.completedCount,
    required this.missingSurfaceNames,
    required this.completedSurfaceNames,
    required this.uploadingSurfaceNames,
    required this.failedSurfaceNames,
  });

  String get summaryText => '$completedCount of $requiredCount required images uploaded';

  String get missingText {
    if (missingSurfaceNames.isEmpty) return '';
    return 'Missing:\n• ${missingSurfaceNames.join('\n• ')}';
  }
}

class RequiredSurfaceValidator {
  static const List<RequiredSurfaceDef> canonicalSurfaces = [
    RequiredSurfaceDef(
      code: 'FRONT',
      name: 'Front (PDP)',
      description: 'Principal Display Panel',
    ),
    RequiredSurfaceDef(
      code: 'BACK',
      name: 'Back (Declarations)',
      description: 'Mandatory Declarations',
    ),
    RequiredSurfaceDef(
      code: 'SIDE',
      name: 'Side (Consumer Care)',
      description: 'Consumer Care & Contact Details',
    ),
    RequiredSurfaceDef(
      code: 'MRP_AREA',
      name: 'MRP & Date Stamp',
      description: 'MRP, Unit Sale Price & Date of Packaging',
    ),
  ];

  static Map<String, SurfaceState> createInitialStates() {
    return {
      for (final def in canonicalSurfaces)
        def.code: SurfaceState(definition: def),
    };
  }

  static RequiredImagesValidationResult validate(Map<String, SurfaceState> surfaces) {
    final missingNames = <String>[];
    final completedNames = <String>[];
    final uploadingNames = <String>[];
    final failedNames = <String>[];

    for (final def in canonicalSurfaces) {
      final state = surfaces[def.code];
      if (state == null || state.status == SurfaceUploadStatus.empty) {
        missingNames.add(def.name);
      } else if (state.status == SurfaceUploadStatus.uploading) {
        uploadingNames.add(def.name);
        missingNames.add(def.name);
      } else if (state.status == SurfaceUploadStatus.failed) {
        failedNames.add(def.name);
        missingNames.add(def.name);
      } else if (state.status == SurfaceUploadStatus.success) {
        completedNames.add(def.name);
      }
    }

    final isValid = completedNames.length == canonicalSurfaces.length &&
        uploadingNames.isEmpty &&
        failedNames.isEmpty;

    return RequiredImagesValidationResult(
      isValid: isValid,
      requiredCount: canonicalSurfaces.length,
      completedCount: completedNames.length,
      missingSurfaceNames: missingNames,
      completedSurfaceNames: completedNames,
      uploadingSurfaceNames: uploadingNames,
      failedSurfaceNames: failedNames,
    );
  }
}
