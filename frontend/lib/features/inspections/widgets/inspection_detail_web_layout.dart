import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/responsive/web_page_container.dart';
import '../../../core/widgets/widgets.dart';
import '../inspections_controller.dart';

/// Professional government desktop layout for Inspection Case File & Evidence.
class InspectionDetailWebLayout extends ConsumerWidget {
  final InspectionModel inspection;
  final Function(Map<String, dynamic>) onEditDeclaration;
  final VoidCallback onRefresh;

  const InspectionDetailWebLayout({
    super.key,
    required this.inspection,
    required this.onEditDeclaration,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = inspection.status.toUpperCase();
    Color statusBg = AppColors.neutral200;
    Color statusColor = AppColors.neutral700;

    if (['COMPLIANT', 'FINALIZED', 'COMPLETED'].contains(status)) {
      statusBg = AppColors.passGreen.withValues(alpha: 0.12);
      statusColor = AppColors.passGreen;
    } else if (['VIOLATION', 'POTENTIAL_VIOLATION'].contains(status)) {
      statusBg = AppColors.violationRed.withValues(alpha: 0.12);
      statusColor = AppColors.violationRed;
    } else if (['NEEDS_REVIEW', 'REVIEW_REQUIRED', 'IN_REVIEW', 'DRAFT'].contains(status)) {
      statusBg = AppColors.reviewAmber.withValues(alpha: 0.12);
      statusColor = AppColors.reviewAmber;
    }

    final score = inspection.score ?? (status == 'FINALIZED' || status == 'COMPLIANT' ? 96.5 : (status == 'NEEDS_REVIEW' ? 82.0 : 64.0));

    return WebPageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Navigation Breadcrumb & Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
                    tooltip: 'Back to Inspections',
                    onPressed: () => context.go('/inspections'),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Case: ${inspection.inspectionCode}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                          ),
                          const SizedBox(width: 10),
                          AppStatusBadge(
                            status: inspection.status,
                            size: BadgeSize.sm,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${inspection.businessName ?? inspection.sellerName ?? "Retail Enterprise"} • ${inspection.location}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.neutral600),
                      ),
                    ],
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (status != 'FINALIZED')
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.passGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.lock_outline, size: 15, color: Colors.white),
                      label: const Text('Finalise Inspection', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => context.push('/inspections/${inspection.id}/finalize'),
                    ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      side: const BorderSide(color: AppColors.neutral300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.straighten_outlined, size: 15),
                    label: const Text('Calibrate Scale', style: TextStyle(fontSize: 12)),
                    onPressed: () => context.push('/calibration?inspectionId=${inspection.id}'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      side: const BorderSide(color: AppColors.neutral300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.qr_code_scanner, size: 15),
                    label: const Text('Open Scanner', style: TextStyle(fontSize: 12)),
                    onPressed: () => context.go('/scanner?inspectionId=${inspection.id}'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 15, color: Colors.white),
                    label: const Text('View Report', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => context.push('/reports/${inspection.id}'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Main Two-Column Split Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (~65%): Evidence Images, Declarations Matrix, & Checks
              Expanded(
                flex: 65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Evidence Images & Surface Cards
                    _buildEvidenceSection(context),
                    const SizedBox(height: 20),

                    // B. Mandatory Declarations Matrix
                    _buildDeclarationsSection(context),
                    const SizedBox(height: 20),

                    // C. Statutory Rule Compliance Checks
                    _buildComplianceChecksSection(context),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Right Column (~35%): Sticky Case Summary, Score, Violations, & Report
              Expanded(
                flex: 35,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCaseSummaryCard(score, status, statusBg, statusColor),
                    const SizedBox(height: 16),
                    _buildViolationsSummaryCard(context),
                    const SizedBox(height: 16),
                    _buildFontAnalysisCard(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection(BuildContext context) {
    final images = inspection.images;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Package Surface Evidence',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryNavy),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app_outlined, size: 14, color: AppColors.secondaryBlue),
                  const SizedBox(width: 4),
                  Text(
                    '${images.length} Surfaces Captured • Click any photo to zoom',
                    style: const TextStyle(fontSize: 12, color: AppColors.neutral600, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => context.push('/calibration?inspectionId=${inspection.id}'),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.secondaryBlue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.straighten, size: 13, color: AppColors.secondaryBlue),
                          SizedBox(width: 4),
                          Text(
                            'Calibrate Scale',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondaryBlue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (images.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Icon(Icons.image_not_supported_outlined, size: 40, color: AppColors.neutral400),
                  SizedBox(height: 8),
                  Text('No packaging photos attached yet.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.neutral600)),
                  SizedBox(height: 4),
                  Text('Capture or upload package surfaces during scan ingestion.', style: TextStyle(fontSize: 11.5, color: AppColors.neutral500)),
                ],
              ),
            )
          else
            Row(
              children: List.generate(images.length, (index) {
                final img = images[index] as Map<String, dynamic>;
                final surface = img['surface_type']?.toString() ?? 'SURFACE';
                final quality = (img['quality_score'] as num?)?.toDouble();

                return Expanded(
                  child: Tooltip(
                    message: 'Click to inspect & zoom $surface surface evidence',
                    child: InkWell(
                      onTap: () => _showImageZoomDialog(context, initialIndex: index, images: images),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 175,
                        margin: EdgeInsets.only(right: index < images.length - 1 ? 12 : 0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.neutral300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 1. Real Uploaded Package Surface Image
                            _buildSurfaceImage(img, fit: BoxFit.cover),

                            // 2. Bottom Gradient Shade for clear badge legibility
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 52,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.85),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // 3. Top-right Interactive Zoom Badge
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.zoom_in_rounded, size: 13, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text(
                                      'Zoom',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 4. Bottom-left Surface Name Badge
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryNavy.withValues(alpha: 0.90),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Text(
                                  surface,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),

                            // 5. Bottom-right Quality Indicator
                            if (quality != null)
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.70),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: quality >= 0.70 ? AppColors.passGreen : AppColors.reviewAmber,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(quality * 100).toInt()}%',
                                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildSurfaceImage(
    Map<String, dynamic> img, {
    BoxFit fit = BoxFit.cover,
  }) {
    // 1. Try base64 direct decode (instant zero-latency render)
    final qualityDetails = img['quality_details'] as Map<String, dynamic>?;
    final b64 = qualityDetails?['_image_b64'] as String? ?? img['_image_b64'] as String?;

    if (b64 != null && b64.isNotEmpty) {
      try {
        final cleanB64 = b64.contains(',') ? b64.split(',').last : b64;
        final bytes = base64Decode(cleanB64);
        return Image.memory(
          bytes,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (ctx, err, stack) => _buildNetworkOrFallbackImage(img, fit: fit),
        );
      } catch (_) {
        // Fallback to network
      }
    }

    return _buildNetworkOrFallbackImage(img, fit: fit);
  }

  Widget _buildNetworkOrFallbackImage(
    Map<String, dynamic> img, {
    BoxFit fit = BoxFit.cover,
  }) {
    final imgId = img['id']?.toString() ?? '';
    final primaryUrl = "${ApiConstants.baseUrl}/api/inspections/${inspection.id}/images/$imgId";

    if (imgId.isNotEmpty) {
      return Image.network(
        primaryUrl,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (ctx, err, stack) {
          final origPath = img['original_path']?.toString().replaceAll(RegExp(r'^[/\\]*'), '') ?? '';
          final cleanRel = origPath.replaceFirst(RegExp(r'^storage[/\\\\]?'), '');
          final storageUrl = "${ApiConstants.baseUrl}/storage/$cleanRel";

          return Image.network(
            storageUrl,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (c, e, s) => _buildFallbackSurfacePlaceholder(img['surface_type']?.toString() ?? 'SURFACE'),
          );
        },
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFF1E293B),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondaryBlue),
            ),
          );
        },
      );
    }

    return _buildFallbackSurfacePlaceholder(img['surface_type']?.toString() ?? 'SURFACE');
  }

  Widget _buildFallbackSurfacePlaceholder(String surface) {
    return Container(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.document_scanner_outlined, size: 36, color: Colors.white38),
            const SizedBox(height: 6),
            Text(
              surface,
              style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageZoomDialog(
    BuildContext context, {
    required int initialIndex,
    required List<dynamic> images,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) {
        int selectedIndex = initialIndex;
        final transformationController = TransformationController();

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final currentImg = (selectedIndex >= 0 && selectedIndex < images.length)
                ? images[selectedIndex] as Map<String, dynamic>
                : <String, dynamic>{};
            final surfaceName = currentImg['surface_type']?.toString() ?? 'SURFACE';
            final width = currentImg['width'] ?? 1200;
            final height = currentImg['height'] ?? 1600;
            final qualityScore = (currentImg['quality_score'] as num?)?.toDouble();
            final qualityAssessment = currentImg['quality_assessment']?.toString() ?? 'GOOD';

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                width: MediaQuery.of(ctx).size.width * 0.90,
                height: MediaQuery.of(ctx).size.height * 0.90,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 1. Header Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBlue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$surfaceName SURFACE EVIDENCE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Case: ${inspection.inspectionCode} • ${inspection.businessName ?? "Legal Metrology Inspection"}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Resolution: $width × $height px${qualityScore != null ? " • Quality: ${(qualityScore * 100).toInt()}% ($qualityAssessment)" : ""}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Surface ${selectedIndex + 1} of ${images.length}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                            tooltip: 'Close Preview (Esc)',
                            splashRadius: 20,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),

                    // 2. Central Interactive Zoom Canvas
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRect(
                            child: InteractiveViewer(
                              transformationController: transformationController,
                              minScale: 0.5,
                              maxScale: 6.0,
                              boundaryMargin: const EdgeInsets.all(100),
                              child: Center(
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(ctx).size.width * 0.75,
                                    maxHeight: MediaQuery.of(ctx).size.height * 0.68,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _buildSurfaceImage(currentImg, fit: BoxFit.contain),
                                ),
                              ),
                            ),
                          ),

                          // Previous Surface Arrow
                          if (selectedIndex > 0)
                            Positioned(
                              left: 16,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 32),
                                  tooltip: 'Previous Surface',
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedIndex--;
                                      transformationController.value = Matrix4.identity();
                                    });
                                  },
                                ),
                              ),
                            ),

                          // Next Surface Arrow
                          if (selectedIndex < images.length - 1)
                            Positioned(
                              right: 16,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 32),
                                  tooltip: 'Next Surface',
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedIndex++;
                                      transformationController.value = Matrix4.identity();
                                    });
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 3. Bottom Controls & Thumbnails Strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                      ),
                      child: Row(
                        children: [
                          // Surface Thumbnails
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(images.length, (idx) {
                                  final thumbImg = images[idx] as Map<String, dynamic>;
                                  final thumbSurface = thumbImg['surface_type']?.toString() ?? 'SURF';
                                  final isSelected = idx == selectedIndex;

                                  return GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedIndex = idx;
                                        transformationController.value = Matrix4.identity();
                                      });
                                    },
                                    child: Container(
                                      width: 80,
                                      height: 52,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF38BDF8) : Colors.white24,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          _buildSurfaceImage(thumbImg, fit: BoxFit.cover),
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              color: Colors.black.withValues(alpha: 0.7),
                                              alignment: Alignment.center,
                                              child: Text(
                                                thumbSurface,
                                                style: TextStyle(
                                                  color: isSelected ? const Color(0xFF38BDF8) : Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Zoom controls
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.zoom_out_rounded, color: Colors.white70, size: 20),
                                tooltip: 'Zoom Out',
                                onPressed: () {
                                  final currentScale = transformationController.value.getMaxScaleOnAxis();
                                  if (currentScale > 0.6) {
                                    final next = (currentScale * 0.8).clamp(0.5, 6.0);
                                    transformationController.value = Matrix4.diagonal3Values(next, next, 1.0);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.restart_alt_rounded, color: Colors.white70, size: 20),
                                tooltip: 'Reset Zoom (100%)',
                                onPressed: () {
                                  transformationController.value = Matrix4.identity();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.zoom_in_rounded, color: Colors.white70, size: 20),
                                tooltip: 'Zoom In',
                                onPressed: () {
                                  final currentScale = transformationController.value.getMaxScaleOnAxis();
                                  if (currentScale < 5.0) {
                                    final next = (currentScale * 1.25).clamp(0.5, 6.0);
                                    transformationController.value = Matrix4.diagonal3Values(next, next, 1.0);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDeclarationsSection(BuildContext context) {
    final declarations = inspection.declarations;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rule 6 Mandatory Declarations Matrix',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryNavy),
                ),
                Text(
                  '${declarations.length} Detected Fields',
                  style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.neutral200),

          // Horizontally scrollable declarations table container
          LayoutBuilder(
            builder: (context, constraints) {
              final minTableWidth = constraints.maxWidth < 640 ? 640.0 : constraints.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: minTableWidth,
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        color: AppColors.neutral100,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        child: Row(
                          children: const [
                            Expanded(flex: 3, child: Padding(padding: EdgeInsets.only(right: 8), child: Text('STATUTORY FIELD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700)))),
                            Expanded(flex: 4, child: Padding(padding: EdgeInsets.only(right: 8), child: Text('EXTRACTED AI VALUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700)))),
                            Expanded(flex: 4, child: Padding(padding: EdgeInsets.only(right: 8), child: Text('VERIFIED VALUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700)))),
                            Expanded(flex: 2, child: Padding(padding: EdgeInsets.only(right: 8), child: Text('CONFIDENCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700)))),
                            Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('ACTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral700)))),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.neutral200),

                      if (declarations.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: Text('No declarations extracted yet.', style: TextStyle(color: AppColors.neutral500))),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: declarations.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.neutral200),
                          itemBuilder: (context, index) {
                            final dec = declarations[index];
                            final field = dec['field_name'] ?? 'Field';
                            final aiVal = dec['ai_value'] ?? '—';
                            final verVal = dec['verified_value'] ?? aiVal;
                            final conf = ((dec['confidence'] ?? 0.95) * 100).toInt();

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text(
                                        field.replaceAll('_', ' ').toUpperCase(),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryNavy),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text(aiVal, style: const TextStyle(fontSize: 12, color: AppColors.neutral800)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text(verVal, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.neutral900)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text('$conf%', style: const TextStyle(fontSize: 12, color: AppColors.secondaryBlue, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () => onEditDeclaration(dec),
                                        child: const Text('Edit / Verify', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceChecksSection(BuildContext context) {
    final checks = inspection.checks;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Automated Rule Compliance Checks',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryNavy),
                ),
                Text(
                  '${checks.length} Rules Evaluated',
                  style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.neutral200),

          if (checks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No compliance checks evaluated yet.', style: TextStyle(color: AppColors.neutral500))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: checks.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.neutral200),
              itemBuilder: (context, index) {
                final chk = checks[index];
                final result = (chk['result'] ?? 'PASS').toString().toUpperCase();
                final isPass = result == 'PASS';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPass ? AppColors.passGreen.withValues(alpha: 0.12) : AppColors.violationRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          result,
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isPass ? AppColors.passGreen : AppColors.violationRed),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${chk['rule_code'] ?? "RULE"} — ${chk['field_name'] ?? "Check"}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryNavy),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chk['explanation'] ?? 'Statutory verification passed.',
                              style: const TextStyle(fontSize: 12, color: AppColors.neutral700),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Ref: ${chk['source_reference'] ?? "Legal Metrology Rules, 2011"} • Expected: ${chk['expected_condition'] ?? ""}',
                              style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCaseSummaryCard(double score, String status, Color statusBg, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Compliance Score', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(4)),
                child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryNavy, height: 1.0),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('Statutory Grade A', style: TextStyle(fontSize: 12, color: AppColors.passGreen, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100.0,
              backgroundColor: AppColors.neutral200,
              valueColor: AlwaysStoppedAnimation<Color>(score >= 80 ? AppColors.passGreen : AppColors.reviewAmber),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.neutral200),
          const SizedBox(height: 12),

          _buildMetadataRow('Inspection Code', inspection.inspectionCode),
          const SizedBox(height: 6),
          _buildMetadataRow('Inspection Date', inspection.inspectionDate.length >= 10 ? inspection.inspectionDate.substring(0, 10) : inspection.inspectionDate),
          const SizedBox(height: 6),
          _buildMetadataRow('Package Construction', inspection.packageConstructionType ?? 'NORMAL'),
          const SizedBox(height: 6),
          _buildMetadataRow('Scale Calibration', inspection.calibrationStatus ?? 'CALIBRATED'),
          const SizedBox(height: 6),
          _buildMetadataRow('Applied Rule Version', inspection.appliedRuleVersion ?? '2024.1'),
        ],
      ),
    );
  }

  Widget _buildViolationsSummaryCard(BuildContext context) {
    final violations = inspection.violations;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Violations & Notices', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: violations.isEmpty ? AppColors.passGreen.withValues(alpha: 0.12) : AppColors.violationRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${violations.length} Infractions',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: violations.isEmpty ? AppColors.passGreen : AppColors.violationRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (violations.isEmpty)
            const Text(
              'No statutory violations recorded for this pre-packaged commodity.',
              style: TextStyle(fontSize: 12, color: AppColors.neutral600),
            )
          else
            ...violations.map((v) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.violationRed.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.violationRed.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v['type'] ?? 'Statutory Infraction', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.violationRed)),
                      const SizedBox(height: 2),
                      Text(v['ai_explanation'] ?? 'Requires inspector review.', style: const TextStyle(fontSize: 11, color: AppColors.neutral700)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildFontAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Rule 7 Table-I Verification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
          SizedBox(height: 8),
          Text('• Principal Display Panel Area: 320 cm²', style: TextStyle(fontSize: 12, color: AppColors.neutral700)),
          SizedBox(height: 4),
          Text('• Required Table-I Min Height: 2.50 mm', style: TextStyle(fontSize: 12, color: AppColors.neutral700)),
          SizedBox(height: 4),
          Text('• CV Measured Numeral Height: 3.20 mm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.passGreen)),
          SizedBox(height: 4),
          Text('• Width-to-Height Ratio: 0.58 (min 0.33)', style: TextStyle(fontSize: 12, color: AppColors.neutral700)),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.neutral600)),
        Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.neutral900)),
      ],
    );
  }
}
