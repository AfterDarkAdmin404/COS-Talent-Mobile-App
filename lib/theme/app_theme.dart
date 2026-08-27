import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand tokens lifted directly from the web app's `app/globals.css`
/// (`@theme` block): Deep Navy / Bright Teal / Clean White, the 2026
/// repositioning palette. Keep these in sync with that file — it is
/// the source of truth, this mirrors it for Flutter.
class AppColors {
  AppColors._();

  // Navy ramp — structure, headers, primary surfaces.
  static const navy = Color(0xFF0B2545);
  static const navyDark = Color(0xFF06182E);
  static const navyLight = Color(0xFF2A5A8C);

  // Teal ramp — accent, CTAs.
  static const teal = Color(0xFF14B8A6);
  static const tealDark = Color(0xFF0E7C8E);
  static const tealLight = Color(0xFF5FD3DD);

  // Neutrals.
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF8FAFC); // page background
  static const ink = Color(0xFF0F172A); // body text
  static const muted = Color(0xFF475569); // secondary text

  // Status colors — not in the web palette (marketing site has no
  // status states), chosen to sit quietly alongside navy/teal for the
  // talent_profiles.status lifecycle (draft/pending_review/approved/rejected).
  static const statusDraft = Color(0xFF94A3B8);
  static const statusPending = Color(0xFFCA8A04);
  static const statusApproved = teal;
  static const statusRejected = Color(0xFFDC2626);

  static const border = Color(0xFFE2E8F0);
}

/// Corner/elevation values observed in the web app's Tailwind usage —
/// `rounded-2xl` (16) dominates cards, `rounded-full` for buttons/pills,
/// `shadow-sm`/`shadow-lg` for elevation.
class AppRadius {
  AppRadius._();
  static const card = 20.0; // rounded-2xl-ish, slightly opened up for touch
  static const control = 14.0; // rounded-xl for inputs
  static const pill = 999.0; // rounded-full
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.offWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        brightness: Brightness.light,
        primary: AppColors.navy,
        secondary: AppColors.teal,
        surface: AppColors.white,
        error: AppColors.statusRejected,
      ),
    );

    final sans = GoogleFonts.manropeTextTheme(base.textTheme);
    final display = GoogleFonts.frauncesTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: sans.copyWith(
        // Fraunces (serif/display) mirrors the web app's use of a serif
        // display face for hero-style headlines, sans for everything else.
        displayLarge: display.displayLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          height: 1.08,
        ),
        displayMedium: display.displayMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
        headlineLarge: display.headlineLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: sans.headlineSmall?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: sans.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: sans.titleMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: sans.bodyLarge?.copyWith(color: AppColors.ink, height: 1.5),
        bodyMedium: sans.bodyMedium?.copyWith(
          color: AppColors.muted,
          height: 1.5,
        ),
        labelLarge: sans.labelLarge?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.offWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.navy),
        titleTextStyle: GoogleFonts.manrope(
          color: AppColors.navy,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.tealDark,
          textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.6),
        ),
        labelStyle: GoogleFonts.manrope(color: AppColors.muted),
        hintStyle: GoogleFonts.manrope(color: AppColors.muted),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.teal
              : AppColors.white,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.teal
              : AppColors.border,
        ),
        thumbColor: const WidgetStatePropertyAll(AppColors.white),
      ),
    );
  }
}

/// Soft brand shadow matching the web app's `shadow-sm` / `shadow-lg`
/// card elevation — layered, low-opacity, navy-tinted rather than pure black.
List<BoxShadow> brandShadow({double strength = 1}) => [
  BoxShadow(
    color: AppColors.navy.withValues(alpha: 0.06 * strength),
    blurRadius: 24 * strength,
    offset: Offset(0, 10 * strength),
  ),
  BoxShadow(
    color: AppColors.navy.withValues(alpha: 0.03 * strength),
    blurRadius: 4 * strength,
    offset: Offset(0, 1 * strength),
  ),
];
