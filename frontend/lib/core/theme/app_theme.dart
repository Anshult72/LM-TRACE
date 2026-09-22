import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ===========================================================================
  // OFFICIAL LM-TRACE PRIMARY PALETTE
  // ===========================================================================
  /// Primary Navy (#0F2D3A): Primary brand color, sidebar, major headers, dark sections.
  static const Color primaryNavy = Color(0xFF0F2D3A);

  /// Inspection Green (#2E7D6B): Primary secondary accent, operational states, active items.
  static const Color inspectionGreen = Color(0xFF2E7D6B);

  /// Mint Mist (#CFE8D9): Soft green background, subtle success highlights, gentle emphasis.
  static const Color mintMist = Color(0xFFCFE8D9);

  /// Surface Ivory (#FAF9F5): Primary application warm surface/background (not cold pure white).
  static const Color surfaceIvory = Color(0xFFFAF9F5);

  /// Sand Beige (#E7DCC8): Warm supporting sections, neutral highlights, contextual balance.
  static const Color sandBeige = Color(0xFFE7DCC8);

  /// Accent Gold (#C9A227): Important CTA emphasis, highlights, selected/high-priority metrics.
  static const Color accentGold = Color(0xFFC9A227);

  /// Text Charcoal (#1F2933): Primary text, headings, labels, readable dark text on light surfaces.
  static const Color textCharcoal = Color(0xFF1F2933);

  // ===========================================================================
  // OFFICIAL LM-TRACE SECONDARY PALETTE
  // ===========================================================================
  /// Sage (#A7C4B0): Soft borders, gentle green supporting surface.
  static const Color sage = Color(0xFFA7C4B0);

  /// Sky Grey (#D9E2EA): Borders, dividers, subtle neutral boundaries.
  static const Color skyGrey = Color(0xFFD9E2EA);

  /// Steel Blue (#5B7C93): Informational metadata, secondary labels, neutral indicators.
  static const Color steelBlue = Color(0xFF5B7C93);

  /// Blush Neutral (#F3E9E1): Subtle warm secondary surface.
  static const Color blushNeutral = Color(0xFFF3E9E1);

  /// Alert Red (#D64545): Statutory violations, critical alerts, errors.
  static const Color alertRed = Color(0xFFD64545);

  /// Success Green (#2FA672): Statutory compliance, verified status, successes.
  static const Color successGreen = Color(0xFF2FA672);

  /// Warning Amber (#F59E0B): Needs review, pending supervisor sign-off, cautions.
  static const Color warningAmber = Color(0xFFF59E0B);

  // ===========================================================================
  // SEMANTIC DESIGN TOKENS
  // ===========================================================================
  static const Color bgPrimary = surfaceIvory;
  static const Color bgSecondary = sandBeige;
  static const Color surface = surfaceIvory;
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = blushNeutral;

  static const Color textPrimary = textCharcoal;
  static const Color textSecondary = steelBlue;
  static const Color textMuted = steelBlue;
  static const Color textDark = textCharcoal;
  static const Color textLight = steelBlue;

  static const Color border = skyGrey;
  static const Color borderLight = skyGrey;
  static const Color cardBorder = skyGrey;
  static const Color borderMuted = skyGrey;
  static const Color borderFocus = inspectionGreen;

  static const Color actionPrimary = primaryNavy;
  static const Color actionSecondary = inspectionGreen;
  static const Color actionMuted = mintMist;

  static const Color highlight = accentGold;
  static const Color success = successGreen;
  static const Color warning = warningAmber;
  static const Color danger = alertRed;
  static const Color info = steelBlue;

  // ===========================================================================
  // BACKWARD COMPATIBLE SYSTEM ALIASES
  // ===========================================================================
  static const Color primary = primaryNavy;
  static const Color primaryLight = Color(0xFF163E50);
  static const Color secondary = inspectionGreen;
  static const Color secondaryBlue = inspectionGreen;
  static const Color accentBlue = inspectionGreen;
  static const Color lightNeutral = surfaceIvory;

  // Status Pairs (Compliant / Review / Violation / Processing)
  static const Color passGreen = successGreen;
  static const Color passGreenLight = Color(0xFFEAF5EE);
  static const Color passGreenBorder = sage;

  static const Color compliant = successGreen;
  static const Color compliantBg = mintMist;
  static const Color compliantBorder = sage;

  static const Color reviewAmber = warningAmber;
  static const Color reviewAmberLight = Color(0xFFFEF9EE);
  static const Color reviewAmberBorder = Color(0xFFFDE68A);

  static const Color review = warningAmber;
  static const Color reviewBg = Color(0xFFFEF9EE);
  static const Color reviewBorder = Color(0xFFFDE68A);

  static const Color warningBg = Color(0xFFFEF9EE);

  static const Color violationRed = alertRed;
  static const Color violationRedLight = Color(0xFFFDF2F2);
  static const Color violationRedBorder = Color(0xFFF9C4C4);

  static const Color violation = alertRed;
  static const Color violationBg = Color(0xFFFDF2F2);
  static const Color violationBorder = Color(0xFFF9C4C4);

  // Eliminating purple-heavy UI in favor of Steel Blue / Sky Grey
  static const Color aiPurple = steelBlue;
  static const Color aiPurpleLight = Color(0xFFEBF1F5);
  static const Color aiPurpleBorder = skyGrey;

  static const Color infoBg = Color(0xFFEFF4F8);
  static const Color infoBorder = skyGrey;

  // Neutral scale (Slate to warm sky/charcoal scale)
  static const Color neutral50 = surfaceIvory;
  static const Color neutral100 = Color(0xFFF4F6F8);
  static const Color neutral200 = skyGrey;
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = steelBlue;
  static const Color neutral600 = steelBlue;
  static const Color neutral700 = textCharcoal;
  static const Color neutral800 = textCharcoal;
  static const Color neutral900 = primaryNavy;

  // ===========================================================================
  // OFFICIAL BRAND GRADIENTS
  // ===========================================================================
  /// Official Brand Gradient: #0F2D3A -> #2E7D6B -> #CFE8D9
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F2D3A),
      Color(0xFF2E7D6B),
      Color(0xFFCFE8D9),
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2D3A), Color(0xFF163E50)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D6B), Color(0xFF236354)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2D3A), Color(0xFF163E50)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2D3A), Color(0xFF2E7D6B)],
  );
}

class AppShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A0F2D3A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x060F2D3A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x080F2D3A),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x0A0F2D3A),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0F0F2D3A),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];

  static List<BoxShadow> glow(Color color, {double opacity = 0.25}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }
}

class AppRadii {
  static const BorderRadius xs = BorderRadius.all(Radius.circular(6));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius md = BorderRadius.all(Radius.circular(12));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(20));
  static const BorderRadius full = BorderRadius.all(Radius.circular(999));
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surfaceIvory,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryNavy,
        secondary: AppColors.inspectionGreen,
        surface: AppColors.cardSurface,
        error: AppColors.alertRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textCharcoal,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryNavy,
          letterSpacing: -0.8,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryNavy,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryNavy,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textCharcoal,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textCharcoal,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textCharcoal,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
          height: 1.45,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: AppColors.textCharcoal,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppColors.textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          side: const BorderSide(color: AppColors.borderLight, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.skyGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.skyGrey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: AppColors.inspectionGreen, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: AppColors.alertRed, width: 1.2),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: AppColors.alertRed, width: 1.6),
        ),
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: AppColors.neutral400, fontSize: 13),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.skyGrey,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
