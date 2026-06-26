import 'package:flutter/material.dart';

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
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
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
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
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
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
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
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
        color: surface,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: textPrimary,
        centerTitle: false,
        titleTextStyle: TextStyle(
            color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: rose),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: surfaceVariant,
        selectedColor: primary,
        labelStyle: const TextStyle(color: textSecondary),
      ),
      dividerTheme: const DividerThemeData(
          color: border, thickness: 1, space: 1),
      listTileTheme: const ListTileThemeData(
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle:
            const TextStyle(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
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

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
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
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lBorder),
        ),
        color: lSurface,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: lBackground,
        foregroundColor: lText,
        centerTitle: false,
        titleTextStyle: TextStyle(
            color: lText, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: lText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lPrimary, width: 2),
        ),
        labelStyle: const TextStyle(color: lTextSec),
        hintStyle: const TextStyle(color: lTextSec),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lPrimary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lPrimary,
          side: const BorderSide(color: lPrimary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lBorder),
        ),
      ),
    );
  }
}
