import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color paperCream = Color(0xFFFAF8F5);
  static const Color inkBlack = Color(0xFF2D2D2D);
  static const Color stripeCoral = Color(0xFFE8A87C);
  static const Color stripeTeal = Color(0xFF4ECDC4);
  static const Color stripeLavender = Color(0xFFB8A9C9);
  static const Color stripeGold = Color(0xFFFFD700);
  static const Color stripeRose = Color(0xFFFF6B6B);
  static const Color dashedBorder = Color(0xFFD4C5B2);
  static const Color paperGrain = Color(0xFFF5F0E8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: inkBlack,
        secondary: stripeCoral,
        surface: paperCream,
        background: paperCream,
        onPrimary: paperCream,
        onSecondary: inkBlack,
        onSurface: inkBlack,
        onBackground: inkBlack,
      ),
      scaffoldBackgroundColor: paperCream,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          color: inkBlack,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          color: inkBlack,
          height: 1.3,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          color: inkBlack,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
          color: inkBlack,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: inkBlack,
        ),
        titleMedium: GoogleFonts.caveat(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: inkBlack,
        ),
        bodyLarge: GoogleFonts.jetBrainsMono(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: inkBlack,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: inkBlack,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: inkBlack,
        ),
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: inkBlack,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paperCream,
        foregroundColor: inkBlack,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          color: inkBlack,
        ),
      ),
      cardTheme: CardThemeData(
        color: paperCream,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: BorderSide(color: dashedBorder, width: 0.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: paperCream,
        selectedColor: inkBlack,
        disabledColor: paperGrain,
        labelStyle: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          color: inkBlack,
        ),
        secondaryLabelStyle: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          color: paperCream,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: BorderSide(color: dashedBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: inkBlack,
          foregroundColor: paperCream,
          textStyle: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: inkBlack,
          textStyle: GoogleFonts.jetBrainsMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paperGrain,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(color: dashedBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(color: dashedBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(color: inkBlack, width: 2),
        ),
        labelStyle: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          color: inkBlack,
        ),
      ),
    );
  }

  static BoxDecoration get paperGrainDecoration {
    return BoxDecoration(
      color: paperCream,
    );
  }

  static BoxDecoration stripedPlaceholder(Color color) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.1),
          color.withOpacity(0.2),
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }

  static BoxDecoration get polaroidCard {
    return BoxDecoration(
      color: paperCream,
      border: Border.all(color: inkBlack, width: 1),
      boxShadow: [
        BoxShadow(
          color: inkBlack.withOpacity(0.1),
          offset: Offset(3, 3),
          blurRadius: 0,
        ),
      ],
    );
  }
}
