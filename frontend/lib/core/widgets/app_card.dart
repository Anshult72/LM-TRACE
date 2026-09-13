import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Premium, production-grade card widget for LM-TRACE.
///
/// Features:
/// - Crisp borders, rounded corners, soft ambient shadows.
/// - Optional interactive hover elevation effect on web / desktop.
/// - Built-in optional header (with icon, title, subtitle, trailing action).
/// - Consistent padding and background color.
class AppCard extends StatefulWidget {
  final Widget? child;
  final Widget? header;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final BorderRadius? borderRadius;
  final bool enableHover;
  final bool isSelected;
  final Color? selectedBorderColor;

  const AppCard({
    super.key,
    this.child,
    this.header,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.enableHover = true,
    this.isSelected = false,
    this.selectedBorderColor,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveRadius = widget.borderRadius ?? AppRadii.lg;
    final isInteractive = widget.onTap != null;

    final effectiveBorder = widget.border ??
        Border.all(
          color: widget.isSelected
              ? (widget.selectedBorderColor ?? AppColors.accentBlue)
              : (_isHovered && isInteractive
                  ? AppColors.neutral300
                  : AppColors.borderLight),
          width: widget.isSelected ? 1.5 : 1.0,
        );

    final effectiveShadow = _isHovered && isInteractive
        ? AppShadows.lg
        : (widget.isSelected ? AppShadows.md : AppShadows.sm);

    Widget content = Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.cardSurface,
        borderRadius: effectiveRadius,
        border: effectiveBorder,
        boxShadow: effectiveShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: effectiveRadius,
          hoverColor: isInteractive ? AppColors.neutral50.withValues(alpha: 0.5) : Colors.transparent,
          splashColor: AppColors.accentBlue.withValues(alpha: 0.06),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: widget.padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.header != null) widget.header!,
                if (widget.header == null && (widget.title != null || widget.icon != null)) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (widget.iconColor ?? AppColors.primaryNavy).withValues(alpha: 0.08),
                            borderRadius: AppRadii.sm,
                          ),
                          child: Icon(
                            widget.icon,
                            size: 18,
                            color: widget.iconColor ?? AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.title != null)
                              Text(
                                widget.title!,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.trailing != null) widget.trailing!,
                    ],
                  ),
                  if (widget.child != null) const SizedBox(height: AppSpacing.md),
                ],
                if (widget.child != null) widget.child!,
              ],
            ),
          ),
        ),
      ),
    );

    if (isInteractive && widget.enableHover) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: _isHovered ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
          child: content,
        ),
      );
    }

    return content;
  }
}
