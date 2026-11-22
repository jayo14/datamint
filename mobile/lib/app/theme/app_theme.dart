import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Signature Landing Page & Auth Page Mint Palette
  static const Color mint = Color(0xFF74E3B6); // --m: Primary glowing mint
  static const Color mintBg = Color(0xFFEAFBF3); // --bg: Light mint background
  static const Color mintDark = Color(0xFF0F2A21); // --dk: Deep forest dark base
  static const Color ink = Color(0xFF0D1F18); // --ink: Deep forest dark text
  static const Color textMuted = Color(0xFF3F5F52); // --tx: Secondary muted text
  static const Color mintBorder = Color(0xFFBFE3D2); // Soft mint border
  static const Color mintActive = Color(0xFF0B9E6B); // Active emerald green
  static const Color yellowAccent = Color(0xFFFFE08A); // Gold/Yellow coin accent
  static const Color blueAccent = Color(0xFF5FD6E8); // Cyan accent
  static const Color white = Colors.white;

  // Compatibility Tokens
  static const Color mintPrimary = Color(0xFF74E3B6);
  static const Color mintLight = Color(0xFFBFE3D2);
  static const Color mintAccent = Color(0xFF0B9E6B);
  static const Color celoGold = Color(0xFFF59E0B);
  static const Color celoGoldLight = Color(0xFFFFE08A);
  static const Color darkBackground = Color(0xFF0A1C16);
  static const Color cardBgLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFBFE3D2);

  // Dark Palette (Harmonized to DataMint's #0F2A21 Forest Dark)
  static const Color darkBg = Color(0xFF0A1C16);
  static const Color darkSurface = Color(0xFF0F2A21);
  static const Color darkCard = Color(0xFF14382C);
  static const Color darkBorder = Color(0xFF225241);
  static const Color darkTextPrimary = Color(0xFFF2FBF7);
  static const Color darkTextSecondary = Color(0xFF9EC5B6);
  static const Color darkTextMuted = Color(0xFF5D8877);

  // Light Palette (DataMint Default Mint Theme)
  static const Color lightBg = Color(0xFFEAFBF3);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFBFE3D2);
  static const Color lightTextPrimary = Color(0xFF0D1F18);
  static const Color lightTextSecondary = Color(0xFF3F5F52);
  static const Color lightTextMuted = Color(0xFF6B8B7E);

  // Status Colors
  static const Color success = Color(0xFF0B9E6B);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.mintPrimary,
        onPrimary: AppColors.ink,
        secondary: AppColors.mintActive,
        onSecondary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.lightBorder, width: 1.2),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.mintActive, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        hintStyle: const TextStyle(color: AppColors.lightTextMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mintPrimary,
          foregroundColor: AppColors.ink,
          elevation: 0,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.lightBorder, width: 1.4),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.mintPrimary,
        onPrimary: AppColors.ink,
        secondary: AppColors.mintActive,
        onSecondary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.error,
        onError: Colors.white,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.darkBorder, width: 1.2),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.bricolageGrotesque(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.mintPrimary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(color: AppColors.darkTextMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mintPrimary,
          foregroundColor: AppColors.ink,
          elevation: 0,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          side: const BorderSide(color: AppColors.darkBorder, width: 1.4),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
      ),
    );
  }
}
