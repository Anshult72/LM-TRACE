import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/calibration_models.dart';

class CalibrationHistoryCard extends StatelessWidget {
  final List<CalibrationItemModel> history;
  final bool isLoading;
  final VoidCallback onRefresh;

  const CalibrationHistoryCard({
    super.key,
    required this.history,
    this.isLoading = false,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_edu_outlined, size: 18, color: AppColors.primaryNavy),
                    const SizedBox(width: 8),
                    const Text(
                      "Calibration Audit Trail & History",
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
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${history.length}",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neutral600),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16, color: AppColors.neutral600),
                  tooltip: "Refresh Calibration History",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onRefresh,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.neutral200),

          // History List
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondaryBlue),
                ),
              ),
            )
          else if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Center(
                child: Text(
                  "No previous calibrations recorded for this inspection yet.",
                  style: TextStyle(fontSize: 12.5, color: AppColors.neutral500),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.neutral200),
              itemBuilder: (context, index) {
                final item = history[index];
                final isValid = item.calibrationStatus == 'VALID';
                final isSuperseded = item.calibrationStatus == 'SUPERSEDED';

                Color statusColor = isValid
                    ? AppColors.passGreen
                    : (isSuperseded ? AppColors.neutral500 : AppColors.violationRed);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Dot Indicator
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 5, right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),

                      // Main Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "${item.pixelsPerUnit.toStringAsFixed(2)} px/mm",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.neutral900,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                                  ),
                                  child: Text(
                                    item.calibrationStatus,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                                if (item.perspectiveWarning) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.reviewAmberLight,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.reviewAmber.withValues(alpha: 0.4)),
                                    ),
                                    child: const Text(
                                      "Perspective Warning",
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.reviewAmber,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Method: ${_formatReferenceType(item.referenceType)}"
                              "${item.referenceDescription != null && item.referenceDescription!.isNotEmpty ? ' (${item.referenceDescription})' : ''}"
                              " • Measured: ${item.knownDistance.toStringAsFixed(1)} mm (${item.pixelDistance.toStringAsFixed(1)} px)",
                              style: const TextStyle(fontSize: 11.5, color: AppColors.neutral600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Officer: ${item.userId} • Recorded: ${_formatDate(item.createdAt)}",
                              style: const TextStyle(fontSize: 11, color: AppColors.neutral400),
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

  String _formatReferenceType(String type) {
    switch (type.toUpperCase()) {
      case 'RULER':
        return 'Standard Measuring Scale / Ruler';
      case 'PACKAGE_DIMENSION':
        return 'Package Known Dimension';
      case 'REFERENCE_MARKER':
        return 'Calibrated Fiducial Marker';
      default:
        return type;
    }
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return isoString;
    }
  }
}
