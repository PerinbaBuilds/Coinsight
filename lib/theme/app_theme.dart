import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Growth Finance Color Palette ────────────────────────────────────────────
  // Concept: seed → sapling → tree. Green = growth/healthy, amber = caution,
  // red = alert/over-budget. Dark soil background with vibrant status colors.

  static const Color background     = Color(0xFF050E09); // deep dark soil
  static const Color surface        = Color(0xFF0C1910); // dark card surface
  static const Color surfaceVariant = Color(0xFF142816); // slightly lighter

  // Brand / positive
  static const Color primary        = Color(0xFF22C55E); // growth green
  static const Color primaryLight   = Color(0xFF4ADE80); // lighter green
  static const Color primaryDark    = Color(0xFF15803D); // deeper green

  // Status — mirrors traffic-light logic
  static const Color emerald        = Color(0xFF10B981); // savings / goals
  static const Color rose           = Color(0xFFEF4444); // over budget / danger
  static const Color amber          = Color(0xFFF59E0B); // warning (80-99% used)
  static const Color sky            = Color(0xFF38BDF8); // income

  // Text
  static const Color textPrimary    = Color(0xFFF0FDF4);
  static const Color textSecondary  = Color(0xFF6EE7B7);
  static const Color textMuted      = Color(0xFF374151);

  // Border
  static const Color border         = Color(0xFF1C3A26);

  // Legacy aliases (other screens reference these names)
  static const Color navy           = primary;
  static const Color navyDark       = background;
  static const Color navyLight      = primaryLight;

  // ── Spacing scale (4pt rhythm) ────────────────────────────────────────────────
  static const double space2  = 2;
  static const double space4  = 4;
  static const double space8  = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;

  // ── Radius scale ───────────────────────────────────────────────────────────
  static const double radiusSm  = 10;
  static const double radiusMd  = 16;
  static const double radiusLg  = 20;
  static const double radiusXl  = 28;

  // ── Motion tokens ────────────────────────────────────────────────────────────
  // Bezier(0.16,1,0.3,1) — fast-out, smooth settle. Feels premium, not bouncy.
  static const Curve motionCurve = Cubic(0.16, 1, 0.3, 1);
  static const Duration motionFast   = Duration(milliseconds: 150);
  static const Duration motionMedium = Duration(milliseconds: 250);
  static const Duration motionSlow   = Duration(milliseconds: 400);
  static const double pressScale = 0.97;

  // ── Typography ───────────────────────────────────────────────────────────────
  static TextTheme _textTheme(Color heading, Color body) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 36, fontWeight: FontWeight.w700, color: heading, height: 1.1, letterSpacing: -0.5),
      displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28, fontWeight: FontWeight.w700, color: heading, height: 1.15, letterSpacing: -0.3),
      headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w700, color: heading, letterSpacing: -0.2),
      headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w700, color: heading),
      headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: heading),
      titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: heading),
      titleMedium: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w600, color: heading),
      titleSmall: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, color: body),
      bodyLarge: GoogleFonts.inter(fontSize: 16, height: 1.5, color: body),
      bodyMedium: GoogleFonts.inter(fontSize: 14, height: 1.5, color: body),
      bodySmall: GoogleFonts.inter(fontSize: 12, height: 1.4, color: body),
      labelLarge: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, color: body, letterSpacing: 0.2),
      labelMedium: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600, color: body, letterSpacing: 0.4),
      labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500, color: body, letterSpacing: 0.4),
    );
  }

  // ── Gradients ────────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0C1910), Color(0xFF1A3020)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2A1A), Color(0xFF1A4229), Color(0xFF050E09)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient greenAccentGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF15803D)],
  );

  /// Subtle frosted-glass fill for elevated surfaces over the dark background.
  static Color glassSurface(Color base, {double alpha = 0.06}) =>
      base.withValues(alpha: alpha);

  // ── Shadows ──────────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get navShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 24,
          offset: const Offset(0, -4),
        ),
      ];

  static List<BoxShadow> glowShadow(Color color, {double opacity = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 18,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
      ];

  /// Soft ambient glow used behind primary CTAs/highlighted cards for a
  /// premium, slightly luminous feel without looking neon.
  static List<BoxShadow> ambientGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.22),
          blurRadius: 28,
          spreadRadius: -6,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Returns status color based on budget utilisation percentage.
  static Color budgetStatusColor(double pct, bool isOver) {
    if (isOver) return rose;
    if (pct >= 80) return amber;
    return primary;
  }

  // ── Route Transitions ────────────────────────────────────────────────────────
  static Route<T> slideRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: motionCurve);
        return SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0), end: Offset.zero)
              .animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Route<T> bottomSheetRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: motionCurve);
        return SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0), end: Offset.zero)
              .animate(curved),
          child: child,
        );
      },
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────────────────
  static ThemeData get dark {
    final textTheme = _textTheme(textPrimary, textSecondary);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: emerald,
        error: rose,
        surface: surface,
        onSurface: textPrimary,
        onPrimary: Colors.white,
        outline: border,
      ),
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: border, width: 1),
        ),
        color: surface,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: textPrimary,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: space16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: rose),
        ),
        labelStyle: TextStyle(color: textSecondary, fontFamily: GoogleFonts.inter().fontFamily),
        hintStyle: TextStyle(color: textMuted, fontFamily: GoogleFonts.inter().fontFamily),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          padding:
              const EdgeInsets.symmetric(horizontal: space24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(space8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSm)),
          padding:
              const EdgeInsets.symmetric(horizontal: space24, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(space8)),
        padding:
            const EdgeInsets.symmetric(horizontal: space12, vertical: space4 + 2),
        backgroundColor: surfaceVariant,
        selectedColor: primary,
        labelStyle: TextStyle(color: textSecondary, fontFamily: GoogleFonts.inter().fontFamily),
      ),
      dividerTheme: const DividerThemeData(
          color: border, thickness: 1, space: 1),
      listTileTheme: const ListTileThemeData(
        contentPadding:
            EdgeInsets.symmetric(horizontal: space16, vertical: space4),
        tileColor: surface,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: border),
        ),
      ),
      drawerTheme:
          const DrawerThemeData(backgroundColor: surface),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? primary
                : textMuted),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? primary.withValues(alpha: 0.4)
                : border),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusSm)),
          side: BorderSide(color: border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Light Theme ──────────────────────────────────────────────────────────────
  static ThemeData get light {
    const Color lPrimary = Color(0xFF16A34A);
    const Color lBackground = Color(0xFFF0FDF4);
    const Color lSurface = Color(0xFFFFFFFF);
    const Color lBorder = Color(0xFFD1FAE5);
    const Color lText = Color(0xFF052E16);
    const Color lTextSec = Color(0xFF166534);
    final textTheme = _textTheme(lText, lTextSec);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: lPrimary,
        secondary: Color(0xFF10B981),
        error: Color(0xFFEF4444),
        surface: lSurface,
        onSurface: lText,
        onPrimary: Colors.white,
        outline: lBorder,
      ),
      scaffoldBackgroundColor: lBackground,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: lBorder),
        ),
        color: lSurface,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: lBackground,
        foregroundColor: lText,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: const IconThemeData(color: lText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: space16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: lBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: lBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: lPrimary, width: 2),
        ),
        labelStyle: TextStyle(color: lTextSec, fontFamily: GoogleFonts.inter().fontFamily),
        hintStyle: TextStyle(color: lTextSec, fontFamily: GoogleFonts.inter().fontFamily),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSm)),
          padding:
              const EdgeInsets.symmetric(horizontal: space24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lPrimary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(space8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lPrimary,
          side: const BorderSide(color: lPrimary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSm)),
          padding:
              const EdgeInsets.symmetric(horizontal: space24, vertical: 14),
        ),
      ),
      dividerTheme: const DividerThemeData(
          color: lBorder, thickness: 1, space: 1),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: lPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: StadiumBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: lBorder),
        ),
      ),
    );
  }
}
