import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/responsive/web_page_container.dart';
import '../../core/widgets/widgets.dart';
import '../inspections/inspections_controller.dart';
import 'models/calibration_models.dart';
import 'widgets/calibration_canvas.dart';
import 'widgets/declaration_measurements_table.dart';
import 'widgets/calibration_history_card.dart';

class CalibrationScreen extends ConsumerStatefulWidget {
  final String? inspectionId;
  final String? initialImageId;

  const CalibrationScreen({
    super.key,
    this.inspectionId,
    this.initialImageId,
  });

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  String? _selectedInspectionId;
  String? _selectedImageId;
  Map<String, dynamic>? _selectedImage;

  Offset? _pointA;
  Offset? _pointB;
  String _activeTarget = 'A'; // 'A' or 'B'

  final _distanceController = TextEditingController(text: "100.0");
  final _refDescController = TextEditingController();
  final _pdpAreaController = TextEditingController();

  String _referenceType = "RULER"; // RULER, PACKAGE_DIMENSION, REFERENCE_MARKER, OTHER
  String _packageConstruction = "NORMAL"; // NORMAL or BLOWN_FORMED_MOLDED
  bool _planeVerified = true;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingHistory = false;

  List<CalibrationItemModel> _history = [];
  CalibrationPreviewModel? _preview;

  @override
  void initState() {
    super.initState();
    _selectedInspectionId = widget.inspectionId;
    _selectedImageId = widget.initialImageId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initScreen();
    });
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _refDescController.dispose();
    _pdpAreaController.dispose();
    super.dispose();
  }

  Future<void> _initScreen() async {
    setState(() => _isLoading = true);

    // 1. Ensure inspections list is loaded
    final inspNotifier = ref.read(inspectionsProvider.notifier);
    final inspState = ref.read(inspectionsProvider);
    if (inspState.inspections.isEmpty) {
      await inspNotifier.fetchInspections();
    }

    final allInspections = ref.read(inspectionsProvider).inspections;

    // Resolve target inspection ID
    if (_selectedInspectionId == null || _selectedInspectionId!.isEmpty) {
      if (allInspections.isNotEmpty) {
        _selectedInspectionId = allInspections.first.id;
      }
    }

    if (_selectedInspectionId != null) {
      await _loadInspectionData(_selectedInspectionId!);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadInspectionData(String inspectionId) async {
    final inspNotifier = ref.read(inspectionsProvider.notifier);
    final inspection = await inspNotifier.fetchInspectionDetail(inspectionId);

    if (inspection != null) {
      _resolveSelectedImage(inspection);

      // Pre-fill package construction and PDP area if already recorded
      if (inspection.packageConstructionType != null && inspection.packageConstructionType!.isNotEmpty) {
        _packageConstruction = inspection.packageConstructionType!;
      }

      final rawPdpArea = (inspection.pdpData?['areaCm2'] as num?)?.toDouble() ??
          (inspection.applicabilityContext['pdp_area_cm2'] as num?)?.toDouble();
      if (rawPdpArea != null && rawPdpArea > 0) {
        _pdpAreaController.text = rawPdpArea.toStringAsFixed(1);
      }

      // Fetch existing calibrations history and active calibration
      await _fetchCalibrationHistory(inspectionId);
      await _fetchActiveCalibration(inspectionId);
    }
  }

  void _resolveSelectedImage(InspectionModel inspection) {
    final images = inspection.images.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    if (images.isEmpty) {
      _selectedImage = null;
      _selectedImageId = null;
      return;
    }

    // Try initial requested image
    if (_selectedImageId != null) {
      final found = images.where((img) => img['id']?.toString() == _selectedImageId).firstOrNull;
      if (found != null) {
        _selectedImage = found;
        return;
      }
    }

    // Try FRONT (PDP) image
    final front = images.where((img) => img['surface_type']?.toString().toUpperCase() == 'FRONT').firstOrNull;
    if (front != null) {
      _selectedImage = front;
      _selectedImageId = front['id']?.toString();
      return;
    }

    // Fallback to first image
    _selectedImage = images.first;
    _selectedImageId = images.first['id']?.toString();
  }

  Future<void> _fetchCalibrationHistory(String inspectionId) async {
    setState(() => _isLoadingHistory = true);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get(ApiConstants.inspectionCalibrations(inspectionId));
      if (response.statusCode == 200 && response.data is List) {
        final list = (response.data as List)
            .whereType<Map>()
            .map((m) => CalibrationItemModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        setState(() {
          _history = list;
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _fetchActiveCalibration(String inspectionId) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get(ApiConstants.inspectionActiveCalibration(inspectionId));
      if (response.statusCode == 200 && response.data is Map) {
        final active = CalibrationItemModel.fromJson(Map<String, dynamic>.from(response.data));
        setState(() {
          _pointA = Offset(active.pointA.x, active.pointA.y);
          _pointB = Offset(active.pointB.x, active.pointB.y);
          _distanceController.text = active.knownDistance.toStringAsFixed(1);
          _referenceType = active.referenceType;
          if (active.referenceDescription != null) {
            _refDescController.text = active.referenceDescription!;
          }
        });
        // Trigger preview to get declaration measurements
        _updatePreview();
      }
    } catch (_) {}
  }

  double get _derivedPxPerMm {
    if (_pointA == null || _pointB == null) return 0.0;
    final dx = _pointB!.dx - _pointA!.dx;
    final dy = _pointB!.dy - _pointA!.dy;
    final distPx = sqrt(dx * dx + dy * dy);
    final knownMm = double.tryParse(_distanceController.text) ?? 0.0;
    if (knownMm <= 0) return 0.0;
    return distPx / knownMm;
  }

  double get _pixelDistance {
    if (_pointA == null || _pointB == null) return 0.0;
    final dx = _pointB!.dx - _pointA!.dx;
    final dy = _pointB!.dy - _pointA!.dy;
    return sqrt(dx * dx + dy * dy);
  }

  double get _resolvedMinHeight {
    final isBlown = _packageConstruction == "BLOWN_FORMED_MOLDED";
    final area = double.tryParse(_pdpAreaController.text) ?? 0.0;
    if (area <= 0) return isBlown ? 2.0 : 1.0;
    if (area <= 50) return isBlown ? 2.0 : 1.0;
    if (area <= 100) return isBlown ? 3.0 : 1.5;
    if (area <= 500) return isBlown ? 4.0 : 2.5;
    if (area <= 2500) return isBlown ? 6.0 : 4.0;
    return 6.0;
  }

  Future<void> _updatePreview() async {
    if (_selectedInspectionId == null || _pointA == null || _pointB == null) return;
    final knownMm = double.tryParse(_distanceController.text) ?? 0.0;
    if (knownMm <= 0) return;

    try {
      final client = ref.read(apiClientProvider);
      final customPdp = double.tryParse(_pdpAreaController.text);
      final response = await client.post(
        ApiConstants.inspectionCalibrationPreview(_selectedInspectionId!),
        data: {
          'image_id': _selectedImageId,
          'reference_type': _referenceType,
          'reference_description': _refDescController.text.trim(),
          'point_a': {'x': _pointA!.dx, 'y': _pointA!.dy},
          'point_b': {'x': _pointB!.dx, 'y': _pointB!.dy},
          'known_distance_mm': knownMm,
          'package_construction_type': _packageConstruction,
          'custom_pdp_area_cm2': customPdp != null && customPdp > 0 ? customPdp : null,
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        setState(() {
          _preview = CalibrationPreviewModel.fromJson(Map<String, dynamic>.from(response.data));
        });
      }
    } catch (e) {
      // Preview error silently handled, or set error
    }
  }

  Future<void> _saveCalibration() async {
    if (_selectedInspectionId == null) return;

    final knownMm = double.tryParse(_distanceController.text) ?? 0.0;
    final distPx = _pixelDistance;

    if (_pointA == null || _pointB == null) {
      _showError("Both calibration points (Point A and Point B) must be placed on the package image.");
      return;
    }

    if (distPx < 5.0) {
      _showError("Calibration points are too close together ($distPx px). Minimum separation is 5.0 px.");
      return;
    }

    if (knownMm <= 0) {
      _showError("Enter a valid known physical distance in millimetres (greater than 0 mm).");
      return;
    }

    if (!_planeVerified) {
      _showError("Please verify that reference and declarations share the same optical plane (Rule 5 requirement).");
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final client = ref.read(apiClientProvider);
      final customPdp = double.tryParse(_pdpAreaController.text);

      final response = await client.post(
        ApiConstants.inspectionCalibrations(_selectedInspectionId!),
        data: {
          'image_id': _selectedImageId,
          'reference_type': _referenceType,
          'reference_description': _refDescController.text.trim().isNotEmpty
              ? _refDescController.text.trim()
              : null,
          'point_a': {'x': _pointA!.dx, 'y': _pointA!.dy},
          'point_b': {'x': _pointB!.dx, 'y': _pointB!.dy},
          'known_distance_mm': knownMm,
          'package_construction_type': _packageConstruction,
          'custom_pdp_area_cm2': customPdp != null && customPdp > 0 ? customPdp : null,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text("✓ Calibration saved successfully (${_derivedPxPerMm.toStringAsFixed(2)} px/mm applied)."),
                ],
              ),
              backgroundColor: AppColors.passGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Refresh inspection detail and calibration history
        await ref.read(inspectionsProvider.notifier).fetchInspectionDetail(_selectedInspectionId!);
        await _fetchCalibrationHistory(_selectedInspectionId!);
        await _updatePreview();
      }
    } catch (e) {
      _showError("Failed to save calibration: $e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.violationRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onInspectionChanged(String newId) {
    if (newId == _selectedInspectionId) return;
    setState(() {
      _selectedInspectionId = newId;
      _selectedImageId = null;
      _selectedImage = null;
      _pointA = null;
      _pointB = null;
      _preview = null;
      _history = [];
    });
    _loadInspectionData(newId);
  }

  void _onSurfaceChanged(Map<String, dynamic> img) {
    setState(() {
      _selectedImage = img;
      _selectedImageId = img['id']?.toString();
      _pointA = null;
      _pointB = null;
      _preview = null;
    });
    if (_selectedInspectionId != null) {
      _fetchActiveCalibration(_selectedInspectionId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inspState = ref.watch(inspectionsProvider);
    final inspection = inspState.selectedInspection;
    final allInspections = inspState.inspections;

    final imgId = _selectedImageId ?? '';
    final primaryImgUrl = _selectedInspectionId != null && imgId.isNotEmpty
        ? ApiConstants.inspectionImage(_selectedInspectionId!, imgId)
        : '';
    final origPath = _selectedImage?['original_path']?.toString().replaceAll(RegExp(r'^[/\\]*'), '') ?? '';
    final cleanRel = origPath.replaceFirst(RegExp(r'^storage[/\\\\]?'), '');
    final fallbackImgUrl = cleanRel.isNotEmpty ? "${ApiConstants.baseUrl}/storage/$cleanRel" : null;

    final imgWidth = (_selectedImage?['width'] as num?)?.toDouble() ?? 0.0;
    final imgHeight = (_selectedImage?['height'] as num?)?.toDouble() ?? 0.0;

    final pxPerMm = _derivedPxPerMm;
    final isCalibrated = pxPerMm > 0;

    return Scaffold(
      backgroundColor: AppColors.surfaceIvory, // Official LM-TRACE institutional surface
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.inspectionGreen),
            )
          : SingleChildScrollView(
              child: WebPageContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Navigation Breadcrumb & Header Bar
                    _buildHeader(allInspections, inspection),
                    const SizedBox(height: 16),

                    // 2. Regulatory & Optical Depth Advisory Notice (Rule 5 requirement)
                    _buildAdvisoryBanner(),
                    const SizedBox(height: 16),

                    // 3. Package Surface Tabs / Thumbnails Selector
                    if (inspection != null && inspection.images.isNotEmpty) ...[
                      _buildSurfaceTabs(inspection),
                      const SizedBox(height: 16),
                    ],

                    // 4. Main Two-Column Split Layout
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Interactive Canvas & Rule 7 Verification Table
                        Expanded(
                          flex: 62,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Interactive Calibration Canvas
                              if (_selectedImage == null || primaryImgUrl.isEmpty)
                                _buildNoImageCard()
                              else
                                SizedBox(
                                  height: 480,
                                  child: CalibrationCanvas(
                                    imageUrl: primaryImgUrl,
                                    fallbackUrl: fallbackImgUrl,
                                    imageWidth: imgWidth > 0 ? imgWidth : 1920,
                                    imageHeight: imgHeight > 0 ? imgHeight : 1080,
                                    pointA: _pointA,
                                    pointB: _pointB,
                                    activeTarget: _activeTarget,
                                    onPointAChanged: (pt) {
                                      setState(() => _pointA = pt);
                                      _updatePreview();
                                    },
                                    onPointBChanged: (pt) {
                                      setState(() => _pointB = pt);
                                      _updatePreview();
                                    },
                                    onActiveTargetChanged: (t) => setState(() => _activeTarget = t),
                                  ),
                                ),
                              const SizedBox(height: 20),

                              // Rule 7 Table-I Character Height Verification Table
                              DeclarationMeasurementsTable(
                                measurements: _preview?.declarationMeasurements ?? [],
                                requiredMinHeightMm: _preview?.requiredMinHeightMm ?? _resolvedMinHeight,
                                pixelsPerMm: pxPerMm,
                                isCalibrated: isCalibrated,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Right Column: Controls, Metrics, PDP Context, & History
                        Expanded(
                          flex: 38,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Reference Standard Configuration Card
                              _buildReferenceConfigCard(pxPerMm),
                              const SizedBox(height: 16),

                              // Principal Display Panel (PDP) Context Card
                              _buildPdpContextCard(),
                              const SizedBox(height: 16),

                              // Save Button Action
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.passGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _isSaving ? null : _saveCalibration,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check_circle_outline, size: 18),
                                label: Text(
                                  _isSaving ? "Applying Calibration..." : "Save & Apply Calibration",
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Calibration Audit Trail & History Card
                              CalibrationHistoryCard(
                                history: _history,
                                isLoading: _isLoadingHistory,
                                onRefresh: () {
                                  if (_selectedInspectionId != null) {
                                    _fetchCalibrationHistory(_selectedInspectionId!);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(List<InspectionModel> allInspections, InspectionModel? currentInspection) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
              tooltip: "Back",
              onPressed: () {
                if (_selectedInspectionId != null) {
                  context.go('/inspections/$_selectedInspectionId');
                } else {
                  context.go('/inspections');
                }
              },
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "Scale & Metric Calibration",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(width: 8),
                    ContextHelpButton(pageId: 'calibration', size: 15),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  "Establish physical pixel-to-millimetre traceability under Legal Metrology Rule 5 & Rule 7",
                  style: TextStyle(fontSize: 12.5, color: AppColors.neutral600),
                ),
              ],
            ),
          ],
        ),

        // Inspection Selector Dropdown
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Active Case: ",
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.neutral600),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.neutral300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedInspectionId,
                  hint: const Text("Select Inspection", style: TextStyle(fontSize: 12)),
                  items: allInspections.map((insp) {
                    final code = insp.inspectionCode;
                    final name = insp.businessName ?? insp.sellerName ?? insp.productCategory;
                    return DropdownMenuItem<String>(
                      value: insp.id,
                      child: Text(
                        "$code ($name)",
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.neutral800),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) _onInspectionChanged(val);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvisoryBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintMist,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.inspectionGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.gavel_rounded, color: AppColors.inspectionGreen, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "STATUTORY MEASUREMENT DIRECTIVE: Physical dimensions cannot be inferred reliably from raw pixels alone. "
              "Place calibration handles on a known reference edge located on the same package surface and depth plane as the declaration. "
              "This eliminates perspective distortion and ensures verifiable character height evaluation under Rule 7 Table-I.",
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.primaryNavy,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurfaceTabs(InspectionModel inspection) {
    final images = inspection.images.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          const Text(
            "Package Surface: ",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neutral700),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: images.map((img) {
                  final isSelected = _selectedImageId == img['id']?.toString();
                  final surface = img['surface_type']?.toString().toUpperCase() ?? 'SURFACE';
                  final w = img['width']?.toString() ?? '—';
                  final h = img['height']?.toString() ?? '—';

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      onSelected: (_) => _onSurfaceChanged(img),
                      selectedColor: AppColors.primaryNavy,
                      backgroundColor: AppColors.surfaceIvory,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            surface == 'FRONT' ? Icons.crop_free : Icons.image_outlined,
                            size: 14,
                            color: isSelected ? Colors.white : AppColors.neutral700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            surface == 'FRONT' ? 'FRONT (PDP)' : surface,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.neutral800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "($w×$h px)",
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white70 : AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryNavy : AppColors.neutral300,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceConfigCard(double pxPerMm) {
    final distPx = _pixelDistance;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.straighten_outlined, size: 18, color: AppColors.primaryNavy),
              SizedBox(width: 8),
              Text(
                "Traceable Reference Standard",
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Reference Type Dropdown
          DropdownButtonFormField<String>(
            initialValue: _referenceType,
            decoration: const InputDecoration(
              labelText: "Reference Standard Type",
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: const [
              DropdownMenuItem(value: "RULER", child: Text("Standard Measuring Scale / Steel Ruler")),
              DropdownMenuItem(value: "PACKAGE_DIMENSION", child: Text("Verified Package Dimension / Edge")),
              DropdownMenuItem(value: "REFERENCE_MARKER", child: Text("Calibrated Fiducial Target Marker")),
              DropdownMenuItem(value: "OTHER", child: Text("Other Verified Physical Reference")),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _referenceType = val);
                _updatePreview();
              }
            },
          ),
          const SizedBox(height: 10),

          // Reference Description
          TextField(
            controller: _refDescController,
            decoration: const InputDecoration(
              labelText: "Reference Description / Note (Optional)",
              hintText: "e.g. 150mm steel ruler placed on front packaging edge",
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (_) => _updatePreview(),
          ),
          const SizedBox(height: 12),

          // Known Physical Distance Input
          TextField(
            controller: _distanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "Known Physical Distance (mm)",
              suffixText: "mm",
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (_) {
              setState(() {});
              _updatePreview();
            },
          ),
          const SizedBox(height: 8),

          // Preset Chips (50mm, 100mm, 150mm, 300mm)
          Wrap(
            spacing: 6,
            children: [50.0, 100.0, 150.0, 300.0].map((presetMm) {
              return ActionChip(
                label: Text("${presetMm.toInt()} mm", style: const TextStyle(fontSize: 11)),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                onPressed: () {
                  setState(() => _distanceController.text = presetMm.toStringAsFixed(1));
                  _updatePreview();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Derived Metrics Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceIvory,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.skyGrey),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Pixel Vector", style: TextStyle(fontSize: 10.5, color: AppColors.neutral500)),
                    Text(
                      "${distPx.toStringAsFixed(1)} px",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neutral800),
                    ),
                  ],
                ),
                Container(width: 1, height: 24, color: AppColors.neutral300),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Known Distance", style: TextStyle(fontSize: 10.5, color: AppColors.neutral500)),
                    Text(
                      "${_distanceController.text} mm",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neutral800),
                    ),
                  ],
                ),
                Container(width: 1, height: 24, color: AppColors.neutral300),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Derived Scale", style: TextStyle(fontSize: 10.5, color: AppColors.neutral500)),
                    Text(
                      "${pxPerMm.toStringAsFixed(2)} px/mm",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: pxPerMm > 0 ? AppColors.primaryNavy : AppColors.neutral400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdpContextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.aspect_ratio_outlined, size: 18, color: AppColors.primaryNavy),
              SizedBox(width: 8),
              Text(
                "Principal Display Panel (PDP) Context",
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Package Construction Dropdown
          DropdownButtonFormField<String>(
            initialValue: _packageConstruction,
            decoration: const InputDecoration(
              labelText: "Package Construction",
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: const [
              DropdownMenuItem(value: "NORMAL", child: Text("Normal Packaging (Carton, Pouch, Box)")),
              DropdownMenuItem(value: "BLOWN_FORMED_MOLDED", child: Text("Blown / Formed / Molded (Bottle, Can)")),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _packageConstruction = val);
                _updatePreview();
              }
            },
          ),
          const SizedBox(height: 10),

          // PDP Area Input
          TextField(
            controller: _pdpAreaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: "PDP Surface Area (cm²)",
              suffixText: "cm²",
              hintText: "Enter calculated area or leave for auto-detection",
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (_) {
              setState(() {});
              _updatePreview();
            },
          ),
          const SizedBox(height: 10),

          // Same-Plane Verification Checkbox
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: _planeVerified,
            activeColor: AppColors.primaryNavy,
            onChanged: (v) => setState(() => _planeVerified = v ?? false),
            title: const Text(
              "Same-Plane Reference Confirmed",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.neutral800),
            ),
            subtitle: const Text(
              "Scale reference and declarations exist on identical depth plane to avoid optical parallax.",
              style: TextStyle(fontSize: 10.5, color: AppColors.neutral500),
            ),
          ),
          const SizedBox(height: 8),

          // Rule 7 Minimum Threshold Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.passGreenLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.passGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gavel, size: 16, color: AppColors.passGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Rule 7 Table-I Standard: Minimum ${_resolvedMinHeight.toStringAsFixed(1)} mm character height required.",
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.passGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoImageCard() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_camera_back_outlined, size: 48, color: AppColors.neutral400),
            const SizedBox(height: 12),
            const Text(
              "No package images found for this inspection",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.neutral800),
            ),
            const SizedBox(height: 6),
            const Text(
              "Capture or upload package surface images before performing scale calibration.",
              style: TextStyle(fontSize: 12, color: AppColors.neutral500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (_selectedInspectionId != null) {
                  context.go('/scanner?inspectionId=$_selectedInspectionId');
                } else {
                  context.go('/scanner');
                }
              },
              icon: const Icon(Icons.qr_code_scanner, size: 16),
              label: const Text("Open Scanner & Ingestion"),
            ),
          ],
        ),
      ),
    );
  }
}
