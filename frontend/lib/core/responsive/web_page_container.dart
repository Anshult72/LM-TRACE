import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'responsive_layout.dart';

/// Standard container for desktop and tablet web pages.
/// Enforces maximum width constraint (1440px), centers content on ultra-wide screens,
/// and applies consistent institutional spacing and background.
class WebPageContainer extends StatefulWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final ScrollController? scrollController;
  final bool scrollable;

  const WebPageContainer({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.padding,
    this.scrollController,
    this.scrollable = true,
  });

  @override
  State<WebPageContainer> createState() => _WebPageContainerState();
}

class _WebPageContainerState extends State<WebPageContainer> {
  ScrollController? _internalController;

  ScrollController get _effectiveController =>
      widget.scrollController ?? (_internalController ??= ScrollController());

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopTier = ResponsiveLayout.isDesktop(context);
    final effectivePadding = widget.padding ??
        EdgeInsets.symmetric(
          horizontal: isDesktopTier ? 28.0 : 20.0,
          vertical: isDesktopTier ? 24.0 : 16.0,
        );

    final constrainedContent = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: Padding(
          padding: effectivePadding,
          child: widget.child,
        ),
      ),
    );

    if (!widget.scrollable) {
      return Container(
        color: AppColors.neutral50,
        width: double.infinity,
        height: double.infinity,
        child: constrainedContent,
      );
    }

    final controller = _effectiveController;

    return Container(
      color: AppColors.neutral50,
      width: double.infinity,
      height: double.infinity,
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          child: constrainedContent,
        ),
      ),
    );
  }
}
