import 'package:flutter/material.dart';
import '../constants/app_brand.dart';

/// Reusable branding widget for the official LM-TRACE logo asset.
///
/// Features:
/// - Preserves strict 1:1 aspect ratio without stretching, squashing, distortion or blur.
/// - Context-aware sizing: sidebar, header, login, mobile, hero, and document presets.
/// - Configurable dimensions, rounded corners, tooltips, and accessibility semantics.
/// - Single master brand asset as visual source of truth (`assets/images/logo/lm_trace_logo.png`).
class AppLogo extends StatelessWidget {
  /// Custom width constraint.
  final double? width;

  /// Custom height constraint.
  final double? height;

  /// Square size shortcut (sets both width and height to this value).
  final double? size;

  /// Whether to render in compact mode (appropriate for toolbars, collapsed sidebars, and badges).
  final bool compact;

  /// Optional custom tooltip or accessibility label.
  final String? tooltip;

  /// How the image should be inscribed into the box (defaults to BoxFit.contain).
  final BoxFit fit;

  /// Corner radius for the logo boundary.
  final BorderRadius? borderRadius;

  /// Optional hero tag for smooth transitions (e.g. between splash/login and dashboard).
  final String? heroTag;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.size,
    this.compact = false,
    this.tooltip,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.heroTag,
  });

  /// Factory for a compact 32px-40px icon brand mark.
  const AppLogo.compact({
    super.key,
    double? size,
    this.tooltip,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.heroTag,
  })  : compact = true,
        size = size ?? 34.0,
        width = null,
        height = null;

  /// Factory for desktop sidebar (compact: 34px when collapsed, 48px when expanded).
  const AppLogo.sidebar({
    super.key,
    bool collapsed = false,
    this.tooltip,
    this.fit = BoxFit.contain,
    this.heroTag,
  })  : compact = collapsed,
        size = collapsed ? 34.0 : 48.0,
        borderRadius = const BorderRadius.all(Radius.circular(10)),
        width = null,
        height = null;

  /// Factory for application top header bar (very compact 28px).
  const AppLogo.header({
    super.key,
    this.size = 28.0,
    this.tooltip,
    this.fit = BoxFit.contain,
    this.heroTag,
  })  : compact = true,
        borderRadius = const BorderRadius.all(Radius.circular(6)),
        width = null,
        height = null;

  /// Factory for mobile app bars and mobile navigation drawer (32px).
  const AppLogo.mobile({
    super.key,
    this.size = 32.0,
    this.tooltip,
    this.fit = BoxFit.contain,
    this.heroTag,
  })  : compact = true,
        borderRadius = const BorderRadius.all(Radius.circular(6)),
        width = null,
        height = null;

  /// Factory for authentication / login screen card (balanced 68px).
  const AppLogo.login({
    super.key,
    this.size = 68.0,
    this.tooltip,
    this.fit = BoxFit.contain,
    this.heroTag,
  })  : compact = false,
        borderRadius = const BorderRadius.all(Radius.circular(16)),
        width = null,
        height = null;

  /// Factory for landing page hero or prominent about cards (72px).
  const AppLogo.hero({
    super.key,
    this.size = 72.0,
    this.tooltip,
    this.fit = BoxFit.contain,
    this.heroTag,
  })  : compact = false,
        borderRadius = const BorderRadius.all(Radius.circular(14)),
        width = null,
        height = null;

  /// Factory for formal PDF reports, certificates, and print documents (40px).
  const AppLogo.document({
    super.key,
    this.size = 40.0,
    this.tooltip,
    this.fit = BoxFit.contain,
    this.heroTag,
  })  : compact = true,
        borderRadius = const BorderRadius.all(Radius.circular(8)),
        width = null,
        height = null;

  /// Factory for a full brand mark with specified width/height.
  const AppLogo.full({
    super.key,
    this.width,
    this.height,
    this.size,
    this.tooltip,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.heroTag,
  }) : compact = false;

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? (compact ? 34.0 : 48.0);
    final effectiveWidth = width ?? effectiveSize;
    final effectiveHeight = height ?? effectiveSize;
    final effectiveTooltip = tooltip ?? AppBranding.semanticLabel;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(compact ? 8.0 : 12.0);

    Widget imageWidget = ClipRRect(
      borderRadius: effectiveRadius,
      child: Image.asset(
        AppBranding.logoAsset,
        width: effectiveWidth,
        height: effectiveHeight,
        fit: fit,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        semanticLabel: effectiveTooltip,
        errorBuilder: (context, error, stackTrace) {
          // Graceful fallback to alternate logo key if one is not yet indexed in asset bundle
          return Image.asset(
            'assets/images/logo/lm_trace_logo.png',
            width: effectiveWidth,
            height: effectiveHeight,
            fit: fit,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (context2, error2, stackTrace2) {
              return Image.asset(
                'assets/images/logo/lm_trace_brand_master.png',
                width: effectiveWidth,
                height: effectiveHeight,
                fit: fit,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                errorBuilder: (context3, error3, stackTrace3) {
                  return Container(
                    width: effectiveWidth,
                    height: effectiveHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2537),
                      borderRadius: effectiveRadius,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.cyanAccent, size: 24),
                  );
                },
              );
            },
          );
        },
      ),
    );

    if (heroTag != null) {
      imageWidget = Hero(
        tag: heroTag!,
        child: imageWidget,
      );
    }

    return Semantics(
      label: effectiveTooltip,
      image: true,
      child: Tooltip(
        message: effectiveTooltip,
        waitDuration: const Duration(milliseconds: 750),
        child: imageWidget,
      ),
    );
  }
}

/// Alias for [AppLogo] adhering to the specification.
typedef LMTraceLogo = AppLogo;
