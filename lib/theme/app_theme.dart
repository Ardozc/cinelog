import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Uygulamanin light ve dark ThemeData tanimlari.
/// Basliklar: Poppins SemiBold | Govde metni: Inter
class AppTheme {
  AppTheme._();

  static const _radius = 20.0;

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: AppColors.lightCard,
      ),
      textTheme: _textTheme(
        titleColor: AppColors.lightTextPrimary,
        bodyColor: AppColors.lightTextSecondary,
      ),
      dividerColor: AppColors.lightDivider,
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.inter(
            color: AppColors.lightTextSecondary, fontSize: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      splashColor: AppColors.primary.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryDark,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: AppColors.darkCard,
      ),
      textTheme: _textTheme(
        titleColor: AppColors.darkTextPrimary,
        bodyColor: AppColors.darkTextSecondary,
      ),
      dividerColor: AppColors.darkDivider,
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        hintStyle:
            GoogleFonts.inter(color: AppColors.darkTextSecondary, fontSize: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: const Color(0xFF121212),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.poppins(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      splashColor: AppColors.primaryDark.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
    );
  }

  static TextTheme _textTheme(
      {required Color titleColor, required Color bodyColor}) {
    return TextTheme(
      displayLarge: GoogleFonts.poppins(
          fontSize: 30, fontWeight: FontWeight.w600, color: titleColor),
      headlineMedium: GoogleFonts.poppins(
          fontSize: 22, fontWeight: FontWeight.w600, color: titleColor),
      titleLarge: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: titleColor),
      titleMedium: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w600, color: titleColor),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: bodyColor, height: 1.5),
      bodyMedium:
          GoogleFonts.inter(fontSize: 13, color: bodyColor, height: 1.4),
      labelLarge: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w500, color: bodyColor),
    );
  }
}
