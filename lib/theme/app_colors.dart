import 'package:flutter/material.dart';

/// CineTrack renk paleti.
/// Light ve dark tema icin ayri renk setleri.
class AppColors {
  AppColors._();

  // ---- Light tema ----
  static const lightBackground = Color(0xFFF8F9FB);
  static const lightCard = Color(0xFFFFFFFF);
  static const primary = Color(0xFF7C8CF8); // Soft Indigo
  static const secondary = Color(0xFFA7B4FF);
  static const accent = Color(0xFFFFD166);
  static const lightTextPrimary = Color(0xFF1F2937);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightDivider = Color(0xFFEAEAEA);

  // ---- Dark tema ----
  static const darkBackground = Color(0xFF121212);
  static const darkCard = Color(0xFF1E1E1E);
  static const primaryDark = Color(0xFF8EA2FF);
  static const darkTextPrimary = Color(0xFFF5F5F5);
  static const darkTextSecondary = Color(0xFFB0B0B0);
  static const darkDivider = Color(0xFF2A2A2A);

  // Durum renkleri (her iki temada da kullanilir, dusuk doygunluk)
  static const statusWatchlist = Color(0xFF9CA3AF);
  static const statusWatching = Color(0xFF7C8CF8);
  static const statusCompleted = Color(0xFF34D399);
  static const statusRewatch = Color(0xFFFFD166);
  static const statusDropped = Color(0xFFF87171);
}
