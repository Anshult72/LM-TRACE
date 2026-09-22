import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/calibration_models.dart';

class DeclarationMeasurementsTable extends StatelessWidget {
  final List<DeclarationMeasurementItem> measurements;
  final double? requiredMinHeightMm;
  final double pixelsPerMm;
  final bool isCalibrated;

  const DeclarationMeasurementsTable({
    super.key,
    required this.measurements,
    this.requiredMinHeightMm,
    required this.pixelsPerMm,
    required this.isCalibrated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceIvory,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.skyGrey),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.sandBeige.withValues(alpha: 0.25),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              border: const Border(bottom: BorderSide(color: AppColors.skyGrey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, size: 18, color: AppColors.primaryNavy),
                    const SizedBox(width: 8),
                    const Text(
                      "Rule 7 Table-I Character Height Verification",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCalibrated ? AppColors.passGreen.withValues(alpha: 0.12) : AppColors.neutral200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCalibrated ? "Calibrated Live" : "Pending Scale",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCalibrated ? AppColors.passGreen : AppColors.neutral600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (requiredMinHeightMm != null)
                  Text(
                    "Rule 7 Min Threshold: ${requiredMinHeightMm!.toStringAsFixed(1)} mm",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryBlue,
                    ),
                  ),
              ],
            ),
          ),

          // Content Area
          if (measurements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.font_download_outlined,
                      size: 36,
                      color: AppColors.neutral400,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "No declaration character heights detected yet",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Run AI Vision Analysis on the package inspection to extract OCR bounding boxes and compute character heights.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 38,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 52,
                horizontalMargin: 16,
                columnSpacing: 24,
                headingTextStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral600,
                  letterSpacing: 0.3,
                ),
                columns: const [
                  DataColumn(label: Text("DECLARATION FIELD")),
                  DataColumn(label: Text("EXTRACTED VALUE")),
                  DataColumn(label: Text("DETECTED PX")),
                  DataColumn(label: Text("PHYSICAL HEIGHT (MM)")),
                  DataColumn(label: Text("RULE 7 REQ")),
                  DataColumn(label: Text("STATUTORY STATUS")),
                ],
                rows: measurements.map((item) {
                  final status = item.status.toUpperCase();
                  Color badgeBg = AppColors.neutral100;
                  Color badgeColor = AppColors.neutral700;
                  IconData statusIcon = Icons.help_outline;

                  if (status == 'PASS') {
                    badgeBg = AppColors.passGreen.withValues(alpha: 0.12);
                    badgeColor = AppColors.passGreen;
                    statusIcon = Icons.check_circle_outline;
                  } else if (status == 'VIOLATION') {
                    badgeBg = AppColors.violationRed.withValues(alpha: 0.12);
                    badgeColor = AppColors.violationRed;
                    statusIcon = Icons.error_outline;
                  } else {
                    badgeBg = AppColors.reviewAmber.withValues(alpha: 0.12);
                    badgeColor = AppColors.reviewAmber;
                    statusIcon = Icons.info_outline;
                  }

                  final diff = item.differenceMm;
                  final diffStr = diff >= 0
                      ? "+${diff.toStringAsFixed(2)} mm margin"
                      : "${diff.toStringAsFixed(2)} mm shortfall";

                  return DataRow(
                    cells: [
                      // Field Name
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: badgeColor,
                              ),
                            ),
                            Text(
                              _formatFieldName(item.fieldName),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Extracted Value
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            item.verifiedValue.isEmpty ? "—" : item.verifiedValue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.neutral700),
                          ),
                        ),
                      ),

                      // Detected PX Height
                      DataCell(
                        Text(
                          item.pixelHeight > 0 ? "${item.pixelHeight.toStringAsFixed(1)} px" : "—",
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: AppColors.neutral600,
                          ),
                        ),
                      ),

                      // Converted MM Height
                      DataCell(
                        item.physicalHeightMm > 0
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${item.physicalHeightMm.toStringAsFixed(2)} mm",
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: status == 'PASS'
                                          ? AppColors.passGreen
                                          : (status == 'VIOLATION' ? AppColors.violationRed : AppColors.neutral800),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "($diffStr)",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: diff >= 0 ? AppColors.passGreen : AppColors.violationRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : const Text("—", style: TextStyle(fontSize: 12, color: AppColors.neutral400)),
                      ),

                      // Required Minimum Height
                      DataCell(
                        Text(
                          item.requiredMinHeightMm != null
                              ? "≥ ${item.requiredMinHeightMm!.toStringAsFixed(1)} mm"
                              : (requiredMinHeightMm != null ? "≥ ${requiredMinHeightMm!.toStringAsFixed(1)} mm" : "—"),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral600,
                          ),
                        ),
                      ),

                      // Statutory Status Badge
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 13, color: badgeColor),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _formatFieldName(String name) {
    if (name.isEmpty) return 'Declaration';
    final s = name.replaceAll('_', ' ');
    return s.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }
}
