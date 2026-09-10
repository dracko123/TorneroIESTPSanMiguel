import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de Colores "Dark Stadium"
  static const Color stadiumDarkBg = Color(0xFF090D16);
  static const Color stadiumCardBg = Color(0xFF131B2E);
  static const Color stadiumElevatedBg = Color(0xFF1B253D);
  static const Color turfGreen = Color(0xFF10B981);
  static const Color turfGreenLight = Color(0xFF34D399);
  static const Color trophyGold = Color(0xFFF59E0B);
  static const Color liveRed = Color(0xFFEF4444);
  static const Color liveRedGlow = Color(0xFFF87171);
  static const Color slateTextSecondary = Color(0xFF94A3B8);
  static const Color pureWhite = Color(0xFFF8FAFC);

  static ThemeData get darkStadiumTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: stadiumDarkBg,
      primaryColor: turfGreen,
      colorScheme: const ColorScheme.dark(
        primary: turfGreen,
        secondary: trophyGold,
        surface: stadiumCardBg,
        error: liveRed,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: pureWhite,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: pureWhite),
        titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: pureWhite),
        titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: pureWhite),
        bodyLarge: GoogleFonts.outfit(fontSize: 15, color: pureWhite),
        bodyMedium: GoogleFonts.outfit(fontSize: 13, color: slateTextSecondary),
      ),
      cardTheme: CardThemeData(
        color: stadiumCardBg,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withAlpha(25), width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: stadiumDarkBg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: pureWhite,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: pureWhite),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: turfGreen,
          foregroundColor: Colors.black,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: stadiumElevatedBg,
        hintStyle: const TextStyle(color: slateTextSecondary),
        labelStyle: const TextStyle(color: turfGreenLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(30)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(30)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: turfGreen, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withAlpha(20),
        thickness: 1,
      ),
    );
  }
}
