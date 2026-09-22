import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost, danger, highlight }
enum AppButtonSize { sm, md, lg }

/// Standardized, modern button for LM-TRACE.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? trailingIcon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final Color? customColor;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customColor,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customColor,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.highlight({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customColor,
  }) : variant = AppButtonVariant.highlight;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customColor,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.isFullWidth = false,
    this.customColor,
  }) : variant = AppButtonVariant.danger;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    // Dimensions based on size
    final double height = switch (widget.size) {
      AppButtonSize.sm => 36.0,
      AppButtonSize.md => 44.0,
      AppButtonSize.lg => 50.0,
    };

    final double fontSize = switch (widget.size) {
      AppButtonSize.sm => 12.5,
      AppButtonSize.md => 14.0,
      AppButtonSize.lg => 15.0,
    };

    final double iconSize = switch (widget.size) {
      AppButtonSize.sm => 16.0,
      AppButtonSize.md => 18.0,
      AppButtonSize.lg => 20.0,
    };

    final EdgeInsetsGeometry padding = switch (widget.size) {
      AppButtonSize.sm => const EdgeInsets.symmetric(horizontal: 14),
      AppButtonSize.md => const EdgeInsets.symmetric(horizontal: 20),
      AppButtonSize.lg => const EdgeInsets.symmetric(horizontal: 26),
    };

    // Colors
    Color backgroundColor;
    Color foregroundColor;
    Border? border;
    List<BoxShadow> boxShadow = [];

    switch (widget.variant) {
      case AppButtonVariant.primary:
        backgroundColor = widget.customColor ??
            (isEnabled
                ? (_isHovered ? AppColors.inspectionGreen : AppColors.primaryNavy)
                : AppColors.skyGrey);
        foregroundColor = isEnabled ? Colors.white : AppColors.steelBlue;
        if (isEnabled && _isHovered) {
          boxShadow = AppShadows.glow(backgroundColor, opacity: 0.25);
        }
        break;

      case AppButtonVariant.secondary:
        backgroundColor = _isHovered
            ? AppColors.mintMist
            : (widget.customColor ?? AppColors.surfaceIvory);
        foregroundColor = isEnabled ? AppColors.primaryNavy : AppColors.steelBlue;
        border = Border.all(
          color: _isHovered ? AppColors.inspectionGreen : AppColors.skyGrey,
          width: 1.2,
        );
        break;

      case AppButtonVariant.highlight:
        backgroundColor = widget.customColor ??
            (isEnabled
                ? (_isHovered ? const Color(0xFFB5901F) : AppColors.accentGold)
                : AppColors.skyGrey);
        foregroundColor = Colors.white;
        if (isEnabled && _isHovered) {
          boxShadow = AppShadows.glow(AppColors.accentGold, opacity: 0.3);
        }
        break;

      case AppButtonVariant.ghost:
        backgroundColor = _isHovered ? AppColors.mintMist.withValues(alpha: 0.3) : Colors.transparent;
        foregroundColor = isEnabled ? (widget.customColor ?? AppColors.primaryNavy) : AppColors.steelBlue;
        break;

      case AppButtonVariant.danger:
        backgroundColor = isEnabled
            ? (_isHovered ? const Color(0xFFB93838) : AppColors.alertRed)
            : AppColors.skyGrey;
        foregroundColor = Colors.white;
        if (isEnabled && _isHovered) {
          boxShadow = AppShadows.glow(AppColors.alertRed, opacity: 0.25);
        }
        break;
    }

    Widget innerContent;
    if (widget.isLoading) {
      innerContent = Center(
        child: SizedBox(
          width: iconSize,
          height: iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
          ),
        ),
      );
    } else {
      innerContent = Row(
        mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: iconSize, color: foregroundColor),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: foregroundColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.trailingIcon != null) ...[
            const SizedBox(width: 8),
            widget.trailingIcon!,
          ],
        ],
      );
    }

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadii.sm,
          border: border,
          boxShadow: boxShadow,
        ),
        child: innerContent,
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? widget.onPressed : null,
        borderRadius: AppRadii.sm,
        child: widget.isFullWidth ? SizedBox(width: double.infinity, child: button) : button,
      ),
    );
  }
}
