import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bgBase = Color(0xFF0D0F14);
  static const bgSurface = Color(0xFF13161E);
  static const bgElevated = Color(0xFF1A1E2A);
  static const bgHover = Color(0xFF20253A);

  static const accent = Color(0xFF4F7CFF);
  static const accentHover = Color(0xFF6B93FF);
  static const accentMuted = Color(0x264F7CFF);

  static const textPrimary = Color(0xFFE8EAF0);
  static const textSecondary = Color(0xFF8B90A0);
  static const textMuted = Color(0xFF555B72);

  static const border = Color(0xFF1E2235);
  static const borderActive = Color(0x554F7CFF);

  static const high = Color(0xFFFF5E6C);
  static const medium = Color(0xFFFFB84D);
  static const low = Color(0xFF4FC98D);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bgBase,
    colorScheme: ColorScheme.dark(
      surface: AppColors.bgSurface,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    cardColor: AppColors.bgSurface,
    dividerColor: AppColors.border,
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    iconTheme: const IconThemeData(color: AppColors.textSecondary),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgSurface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
