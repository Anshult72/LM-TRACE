import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CalibrationCanvas extends StatefulWidget {
  final String imageUrl;
  final String? fallbackUrl;
  final double imageWidth;
  final double imageHeight;
  final Offset? pointA;
  final Offset? pointB;
  final ValueChanged<Offset?> onPointAChanged;
  final ValueChanged<Offset?> onPointBChanged;
  final String activeTarget; // 'A', 'B', or 'AUTO'
  final ValueChanged<String> onActiveTargetChanged;

  const CalibrationCanvas({
    super.key,
    required this.imageUrl,
    this.fallbackUrl,
    required this.imageWidth,
    required this.imageHeight,
    required this.pointA,
    required this.pointB,
    required this.onPointAChanged,
    required this.onPointBChanged,
    required this.activeTarget,
    required this.onActiveTargetChanged,
  });

  @override
  State<CalibrationCanvas> createState() => _CalibrationCanvasState();
}

class _CalibrationCanvasState extends State<CalibrationCanvas> {
  final TransformationController _transformController = TransformationController();
  double _currentScale = 1.0;
  String? _draggingPoint; // 'A' or 'B'

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if (scale != _currentScale) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  void _zoomIn() {
    final newScale = (_currentScale * 1.3).clamp(0.5, 8.0);
    _setZoom(newScale);
  }

  void _zoomOut() {
    final newScale = (_currentScale / 1.3).clamp(0.5, 8.0);
    _setZoom(newScale);
  }

  void _resetZoom() {
    setState(() {
      _transformController.value = Matrix4.identity();
      _currentScale = 1.0;
    });
  }

  void _setZoom(double targetScale) {
    final matrix = Matrix4.diagonal3Values(targetScale, targetScale, 1.0);
    setState(() {
      _transformController.value = matrix;
      _currentScale = targetScale;
    });
  }

  void _nudgePoint(String pointLabel, double dx, double dy) {
    if (pointLabel == 'A' && widget.pointA != null) {
      final newX = (widget.pointA!.dx + dx).clamp(0.0, widget.imageWidth);
      final newY = (widget.pointA!.dy + dy).clamp(0.0, widget.imageHeight);
      widget.onPointAChanged(Offset(newX, newY));
    } else if (pointLabel == 'B' && widget.pointB != null) {
      final newX = (widget.pointB!.dx + dx).clamp(0.0, widget.imageWidth);
      final newY = (widget.pointB!.dy + dy).clamp(0.0, widget.imageHeight);
      widget.onPointBChanged(Offset(newX, newY));
    }
  }

  double _getPixelDistance() {
    if (widget.pointA == null || widget.pointB == null) return 0.0;
    final dx = widget.pointB!.dx - widget.pointA!.dx;
    final dy = widget.pointB!.dy - widget.pointA!.dy;
    return sqrt(dx * dx + dy * dy);
  }

  @override
  Widget build(BuildContext context) {
    final hasValidDimensions = widget.imageWidth > 0 && widget.imageHeight > 0;
    final aspectRatio = hasValidDimensions ? (widget.imageWidth / widget.imageHeight) : 16 / 9;
    final pixelDist = _getPixelDistance();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryNavy, // Brand dark canvas
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF163E50), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Main Interactive Zoomable Canvas Area
          LayoutBuilder(
            builder: (context, constraints) {
              final maxCanvasW = constraints.maxWidth;
              final maxCanvasH = constraints.maxHeight.isFinite ? constraints.maxHeight : 440.0;

              // Compute bounding box that preserves aspect ratio within available container
              double renderW = maxCanvasW;
              double renderH = renderW / aspectRatio;
              if (renderH > maxCanvasH) {
                renderH = maxCanvasH;
                renderW = renderH * aspectRatio;
              }

              return Center(
                child: SizedBox(
                  width: renderW,
                  height: renderH,
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.5,
                    maxScale: 8.0,
                    boundaryMargin: const EdgeInsets.all(120),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        if (!hasValidDimensions) return;
                        final localPos = details.localPosition;
                        final imgX = (localPos.dx / renderW) * widget.imageWidth;
                        final imgY = (localPos.dy / renderH) * widget.imageHeight;
                        final clampedPoint = Offset(
                          imgX.clamp(0.0, widget.imageWidth),
                          imgY.clamp(0.0, widget.imageHeight),
                        );

                        if (widget.activeTarget == 'A') {
                          widget.onPointAChanged(clampedPoint);
                          widget.onActiveTargetChanged('B');
                        } else if (widget.activeTarget == 'B') {
                          widget.onPointBChanged(clampedPoint);
                        } else {
                          // AUTO mode: place A if null, then B; or toggle
                          if (widget.pointA == null || widget.pointB != null) {
                            widget.onPointAChanged(clampedPoint);
                            widget.onPointBChanged(null);
                            widget.onActiveTargetChanged('B');
                          } else {
                            widget.onPointBChanged(clampedPoint);
                            widget.onActiveTargetChanged('A');
                          }
                        }
                      },
                      onPanStart: (details) {
                        if (!hasValidDimensions) return;
                        final localPos = details.localPosition;
                        final imgX = (localPos.dx / renderW) * widget.imageWidth;
                        final imgY = (localPos.dy / renderH) * widget.imageHeight;

                        // Check hit radius in image coords (e.g. 35px scaled by current zoom)
                        final hitRadiusImg = (28.0 / _currentScale) * (widget.imageWidth / renderW);

                        if (widget.pointA != null &&
                            (widget.pointA! - Offset(imgX, imgY)).distance <= hitRadiusImg) {
                          _draggingPoint = 'A';
                          widget.onActiveTargetChanged('A');
                        } else if (widget.pointB != null &&
                            (widget.pointB! - Offset(imgX, imgY)).distance <= hitRadiusImg) {
                          _draggingPoint = 'B';
                          widget.onActiveTargetChanged('B');
                        } else {
                          _draggingPoint = null;
                        }
                      },
                      onPanUpdate: (details) {
                        if (_draggingPoint == null || !hasValidDimensions) return;
                        final localPos = details.localPosition;
                        final imgX = ((localPos.dx / renderW) * widget.imageWidth)
                            .clamp(0.0, widget.imageWidth);
                        final imgY = ((localPos.dy / renderH) * widget.imageHeight)
                            .clamp(0.0, widget.imageHeight);
                        final newPt = Offset(imgX, imgY);

                        if (_draggingPoint == 'A') {
                          widget.onPointAChanged(newPt);
                        } else if (_draggingPoint == 'B') {
                          widget.onPointBChanged(newPt);
                        }
                      },
                      onPanEnd: (_) {
                        _draggingPoint = null;
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Underlying Image
                          Image.network(
                            widget.imageUrl,
                            fit: BoxFit.fill,
                            errorBuilder: (ctx, err, stack) {
                              if (widget.fallbackUrl != null && widget.fallbackUrl!.isNotEmpty) {
                                return Image.network(
                                  widget.fallbackUrl!,
                                  fit: BoxFit.fill,
                                  errorBuilder: (c, e, s) => _buildPlaceholder(),
                                );
                              }
                              return _buildPlaceholder();
                            },
                            loadingBuilder: (ctx, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.secondaryBlue,
                                  strokeWidth: 2.5,
                                ),
                              );
                            },
                          ),

                          // Custom Vector Calibration Overlay
                          if (hasValidDimensions)
                            CustomPaint(
                              painter: _InteractiveCalibrationPainter(
                                pointA: widget.pointA,
                                pointB: widget.pointB,
                                imageWidth: widget.imageWidth,
                                imageHeight: widget.imageHeight,
                                currentScale: _currentScale,
                                activeTarget: widget.activeTarget,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. Top Banner Overlay: Target Point Indicator & Helper Guidance
          Positioned(
            top: 12,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xDD0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.activeTarget == 'A'
                          ? AppColors.mintMist // Point A
                          : AppColors.accentGold, // Point B
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.activeTarget == 'A'
                        ? "Active: Place or drag Point A on first calibration edge"
                        : "Active: Place or drag Point B on opposite calibration edge",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Top-Right Floating Zoom & Viewport Controls
          Positioned(
            top: 12,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xDD0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                    tooltip: "Zoom In (Up to 8x)",
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: _zoomIn,
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.zoom_out, color: Colors.white, size: 18),
                    tooltip: "Zoom Out",
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: _zoomOut,
                  ),
                  const SizedBox(width: 4),
                  Container(width: 1, height: 16, color: Colors.white24),
                  const SizedBox(width: 4),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _resetZoom,
                    child: Text(
                      "${(_currentScale * 100).toInt()}%",
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Coordinate Readout & Fine-Tuning Bar
          Positioned(
            bottom: 12,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xEE0A1F29),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF163E50)),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
              ),
              child: Row(
                children: [
                  // Point A Coordinates Pill
                  InkWell(
                    onTap: () => widget.onActiveTargetChanged('A'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.activeTarget == 'A'
                            ? AppColors.mintMist.withValues(alpha: 0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.activeTarget == 'A'
                              ? AppColors.mintMist
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Pt A: ",
                            style: TextStyle(
                              color: AppColors.mintMist,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            widget.pointA == null
                                ? "Not Set"
                                : "${widget.pointA!.dx.toStringAsFixed(1)}, ${widget.pointA!.dy.toStringAsFixed(1)} px",
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Point B Coordinates Pill
                  InkWell(
                    onTap: () => widget.onActiveTargetChanged('B'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.activeTarget == 'B'
                            ? AppColors.accentGold.withValues(alpha: 0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.activeTarget == 'B'
                              ? AppColors.accentGold
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Pt B: ",
                            style: TextStyle(
                              color: AppColors.accentGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            widget.pointB == null
                                ? "Not Set"
                                : "${widget.pointB!.dx.toStringAsFixed(1)}, ${widget.pointB!.dy.toStringAsFixed(1)} px",
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Measured Distance in Pixels
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.straighten, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          "Native Vector: ${pixelDist.toStringAsFixed(1)} px",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Precise Nudge Tool (Arrows for currently active point)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNudgeButton(Icons.arrow_left, () => _nudgePoint(widget.activeTarget, -1, 0)),
                      _buildNudgeButton(Icons.arrow_drop_up, () => _nudgePoint(widget.activeTarget, 0, -1)),
                      _buildNudgeButton(Icons.arrow_drop_down, () => _nudgePoint(widget.activeTarget, 0, 1)),
                      _buildNudgeButton(Icons.arrow_right, () => _nudgePoint(widget.activeTarget, 1, 0)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNudgeButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: Colors.white70, size: 16),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.broken_image_outlined, size: 48, color: Colors.white38),
            SizedBox(height: 10),
            Text(
              "Package image could not be loaded",
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveCalibrationPainter extends CustomPainter {
  final Offset? pointA;
  final Offset? pointB;
  final double imageWidth;
  final double imageHeight;
  final double currentScale;
  final String activeTarget;

  _InteractiveCalibrationPainter({
    required this.pointA,
    required this.pointB,
    required this.imageWidth,
    required this.imageHeight,
    required this.currentScale,
    required this.activeTarget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth <= 0 || imageHeight <= 0) return;

    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    Offset? dispA = pointA != null ? Offset(pointA!.dx * scaleX, pointA!.dy * scaleY) : null;
    Offset? dispB = pointB != null ? Offset(pointB!.dx * scaleX, pointB!.dy * scaleY) : null;

    // Draw reference connector line if both points exist
    if (dispA != null && dispB != null) {
      // Glow under line
      final glowPaint = Paint()
        ..color = const Color(0x55F59E0B)
        ..strokeWidth = 6.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(dispA, dispB, glowPaint);

      // Primary calibration line
      final linePaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(dispA, dispB, linePaint);

      // Center distance badge
      final mid = Offset((dispA.dx + dispB.dx) / 2, (dispA.dy + dispB.dy) / 2);
      final distPx = sqrt(pow(pointB!.dx - pointA!.dx, 2) + pow(pointB!.dy - pointA!.dy, 2));

      final textSpan = TextSpan(
        text: "${distPx.toStringAsFixed(1)} px",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

      final badgeRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: mid, width: tp.width + 12, height: tp.height + 6),
        const Radius.circular(4),
      );
      final badgePaint = Paint()..color = const Color(0xEE0F172A);
      final borderPaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawRRect(badgeRect, badgePaint);
      canvas.drawRRect(badgeRect, borderPaint);
      tp.paint(canvas, Offset(mid.dx - tp.width / 2, mid.dy - tp.height / 2));
    }

    // Draw Point A handle (Mint Mist / Inspection Green)
    if (dispA != null) {
      _drawHandle(
        canvas: canvas,
        center: dispA,
        color: AppColors.mintMist,
        label: "A",
        isActive: activeTarget == 'A',
      );
    }

    // Draw Point B handle (Accent Gold)
    if (dispB != null) {
      _drawHandle(
        canvas: canvas,
        center: dispB,
        color: AppColors.accentGold,
        label: "B",
        isActive: activeTarget == 'B',
      );
    }
  }

  void _drawHandle({
    required Canvas canvas,
    required Offset center,
    required Color color,
    required String label,
    required bool isActive,
  }) {
    // Halo glow
    final haloPaint = Paint()
      ..color = color.withValues(alpha: isActive ? 0.40 : 0.20)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, isActive ? 18.0 : 14.0, haloPaint);

    // Crosshairs
    final crossHairPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(center.dx - 14, center.dy), Offset(center.dx + 14, center.dy), crossHairPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 14), Offset(center.dx, center.dy + 14), crossHairPaint);

    // Pin circle
    final outerPinPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 7.0, outerPinPaint);

    final innerPinPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5.0, innerPinPaint);

    // Label tag pill
    final tagOffset = Offset(center.dx, center.dy - 22);
    final textSpan = TextSpan(
      text: "Point $label",
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: tagOffset, width: tp.width + 10, height: tp.height + 4),
      const Radius.circular(4),
    );
    final bgPaint = Paint()..color = const Color(0xEE0F172A);
    final tagBorderPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(pillRect, bgPaint);
    canvas.drawRRect(pillRect, tagBorderPaint);
    tp.paint(canvas, Offset(tagOffset.dx - tp.width / 2, tagOffset.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _InteractiveCalibrationPainter oldDelegate) {
    return oldDelegate.pointA != pointA ||
        oldDelegate.pointB != pointB ||
        oldDelegate.currentScale != currentScale ||
        oldDelegate.activeTarget != activeTarget;
  }
}
