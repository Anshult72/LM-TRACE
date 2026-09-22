import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum BadgeSize { sm, md }

/// Statutory status pill badge for LM-TRACE.
class AppStatusBadge extends StatelessWidget {
  final String status;
  final BadgeSize size;
  final bool showDot;
  final Color? customColor;
  final Color? customBgColor;

  const AppStatusBadge({
    super.key,
    required this.status,
    this.size = BadgeSize.md,
    this.showDot = true,
    this.customColor,
    this.customBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase().trim();

    Color textColor;
    Color bgColor;
    Color borderColor;

    if (normalized == 'COMPLIANT' ||
        normalized == 'PASS' ||
        normalized == 'VERIFIED' ||
        normalized == 'APPROVED' ||
        normalized == 'FINALIZED' ||
        normalized == 'ACTIVE') {
      textColor = AppColors.successGreen;
      bgColor = AppColors.mintMist.withValues(alpha: 0.4);
      borderColor = AppColors.sage;
    } else if (normalized == 'VIOLATION' ||
        normalized == 'NON_COMPLIANT' ||
        normalized == 'FAILED' ||
        normalized == 'REJECTED' ||
        normalized == 'CRITICAL') {
      textColor = AppColors.alertRed;
      bgColor = AppColors.alertRed.withValues(alpha: 0.08);
      borderColor = AppColors.alertRed.withValues(alpha: 0.3);
    } else if (normalized == 'REVIEW_REQUIRED' ||
        normalized == 'REVIEW' ||
        normalized == 'WARNING' ||
        normalized == 'PENDING' ||
        normalized == 'FLAGGED') {
      textColor = AppColors.warningAmber;
      bgColor = AppColors.warningAmber.withValues(alpha: 0.1);
      borderColor = AppColors.warningAmber.withValues(alpha: 0.3);
    } else if (normalized == 'AI_ANALYZED' ||
        normalized == 'PROCESSING' ||
        normalized == 'SCANNING' ||
        normalized == 'INFO') {
      textColor = AppColors.steelBlue;
      bgColor = AppColors.skyGrey.withValues(alpha: 0.35);
      borderColor = AppColors.skyGrey;
    } else {
      // Neutral/Draft
      textColor = AppColors.steelBlue;
      bgColor = AppColors.skyGrey.withValues(alpha: 0.25);
      borderColor = AppColors.skyGrey;
    }

    if (customColor != null) textColor = customColor!;
    if (customBgColor != null) bgColor = customBgColor!;

    final isSmall = size == BadgeSize.sm;
    final padding = isSmall
        ? const EdgeInsets.symmetric(horizontal: 7, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5);
    final fontSize = isSmall ? 10.5 : 11.5;
    final dotSize = isSmall ? 5.5 : 6.5;

    // Human readable text label (e.g. REVIEW_REQUIRED -> REVIEW REQUIRED)
    final displayLabel = normalized.replaceAll('_', ' ');

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.full,
        border: Border.all(color: borderColor, width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5.5),
          ],
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
