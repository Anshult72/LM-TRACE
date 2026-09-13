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
      textColor = AppColors.passGreen;
      bgColor = AppColors.passGreenLight;
      borderColor = AppColors.passGreenBorder;
    } else if (normalized == 'VIOLATION' ||
        normalized == 'NON_COMPLIANT' ||
        normalized == 'FAILED' ||
        normalized == 'REJECTED' ||
        normalized == 'CRITICAL') {
      textColor = AppColors.violationRed;
      bgColor = AppColors.violationRedLight;
      borderColor = AppColors.violationRedBorder;
    } else if (normalized == 'REVIEW_REQUIRED' ||
        normalized == 'REVIEW' ||
        normalized == 'WARNING' ||
        normalized == 'PENDING' ||
        normalized == 'FLAGGED') {
      textColor = AppColors.reviewAmber;
      bgColor = AppColors.reviewAmberLight;
      borderColor = AppColors.reviewAmberBorder;
    } else if (normalized == 'AI_ANALYZED' ||
        normalized == 'PROCESSING' ||
        normalized == 'SCANNING') {
      textColor = AppColors.aiPurple;
      bgColor = AppColors.aiPurpleLight;
      borderColor = AppColors.aiPurpleBorder;
    } else {
      // Neutral/Draft
      textColor = AppColors.neutral600;
      bgColor = AppColors.neutral100;
      borderColor = AppColors.neutral200;
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
