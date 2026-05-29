// lib/utils/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette – rose poudré & doré chaud pour un salon chic et accessible
  static const Color rose = Color(0xFFE8A4B0);
  static const Color roseFonce = Color(0xFFD4748A);
  static const Color rosePale = Color(0xFFFDF0F3);
  static const Color dore = Color(0xFFCCA96E);
  static const Color dorePale = Color(0xFFFAF4E8);
  static const Color texte = Color(0xFF3D2B2B);
  static const Color texteClair = Color(0xFF8A6A6A);
  static const Color blanc = Color(0xFFFFFFFF);
  static const Color rouge = Color(0xFFE05555);
  static const Color vert = Color(0xFF6BAF8D);
  static const Color fond = Color(0xFFFAF6F7);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: rose,
          primary: roseFonce,
          secondary: dore,
          surface: blanc,
          background: fond,
          error: rouge,
        ),
        textTheme: GoogleFonts.nunitoTextTheme().copyWith(
          displayLarge: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: texte,
          ),
          titleLarge: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: texte,
          ),
          titleMedium: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: texte,
          ),
          bodyLarge: GoogleFonts.nunito(
            fontSize: 16,
            color: texte,
          ),
          bodyMedium: GoogleFonts.nunito(
            fontSize: 14,
            color: texteClair,
          ),
          labelLarge: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: blanc,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: blanc,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: texte,
          ),
          iconTheme: const IconThemeData(color: texte),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: roseFonce,
            foregroundColor: blanc,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            textStyle: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: roseFonce,
          foregroundColor: blanc,
          elevation: 4,
        ),
        cardTheme: CardThemeData(
          color: blanc,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: rosePale,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: roseFonce, width: 2),
          ),
          labelStyle: GoogleFonts.nunito(color: texteClair),
          hintStyle: GoogleFonts.nunito(color: texteClair),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        scaffoldBackgroundColor: fond,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: blanc,
          selectedItemColor: roseFonce,
          unselectedItemColor: texteClair,
          type: BottomNavigationBarType.fixed,
          elevation: 12,
        ),
      );
}
