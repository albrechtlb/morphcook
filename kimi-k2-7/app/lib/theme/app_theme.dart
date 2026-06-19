import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static const String displayFont = 'PlayfairDisplay';
  static const String bodyFont = 'JetBrainsMono';
  static const String handFont = 'Caveat';

  static ThemeData get lightTheme {
    final base = ThemeData.light().copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.ink,
        onPrimary: AppColors.paper,
        secondary: AppColors.teal,
        onSecondary: AppColors.paper,
        surface: AppColors.paperDark,
        onSurface: AppColors.ink,
        background: AppColors.paper,
        onBackground: AppColors.ink,
        error: AppColors.coral,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: displayFont,
          fontStyle: FontStyle.italic,
          fontSize: 40,
          height: 1.1,
          color: AppColors.ink,
        ),
        displayMedium: TextStyle(
          fontFamily: displayFont,
          fontStyle: FontStyle.italic,
          fontSize: 32,
          height: 1.1,
          color: AppColors.ink,
        ),
        displaySmall: TextStyle(
          fontFamily: displayFont,
          fontStyle: FontStyle.italic,
          fontSize: 24,
          height: 1.2,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontFamily: displayFont,
          fontStyle: FontStyle.italic,
          fontSize: 22,
          height: 1.2,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontFamily: displayFont,
          fontStyle: FontStyle.italic,
          fontSize: 20,
          color: AppColors.ink,
        ),
        bodyLarge: TextStyle(
          fontFamily: bodyFont,
          fontSize: 16,
          height: 1.5,
          color: AppColors.ink,
        ),
        bodyMedium: TextStyle(
          fontFamily: bodyFont,
          fontSize: 14,
          height: 1.5,
          color: AppColors.ink,
        ),
        bodySmall: TextStyle(
          fontFamily: bodyFont,
          fontSize: 12,
          color: AppColors.inkMuted,
        ),
        labelLarge: TextStyle(
          fontFamily: bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppColors.ink,
        ),
      ).apply(
        displayColor: AppColors.ink,
        bodyColor: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: displayFont,
          fontStyle: FontStyle.italic,
          fontSize: 22,
          color: AppColors.ink,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          textStyle: const TextStyle(fontFamily: bodyFont, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink),
          textStyle: const TextStyle(fontFamily: bodyFont, fontSize: 14),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: const TextStyle(fontFamily: bodyFont, fontSize: 14),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.paperDark,
        selectedColor: AppColors.ink,
        disabledColor: AppColors.paperShadow,
        labelStyle: TextStyle(fontFamily: bodyFont, fontSize: 12, color: AppColors.ink),
        secondaryLabelStyle: TextStyle(fontFamily: bodyFont, fontSize: 12, color: AppColors.paper),
        shape: StadiumBorder(),
        side: BorderSide.none,
      ),
      cardTheme: CardThemeData(
        color: AppColors.paperDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        margin: const EdgeInsets.all(0),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.paper,
        selectedItemColor: AppColors.ink,
        unselectedItemColor: AppColors.inkMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontFamily: bodyFont, fontSize: 10),
        unselectedLabelStyle: TextStyle(fontFamily: bodyFont, fontSize: 10),
      ),
    );
    return base;
  }

  static final darkCookTheme = ThemeData.dark().copyWith(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.teal,
      onPrimary: Colors.white,
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFEAEAEA),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: displayFont, fontStyle: FontStyle.italic, fontSize: 32, color: Colors.white),
      bodyLarge: TextStyle(fontFamily: bodyFont, fontSize: 16, color: Colors.white),
      bodyMedium: TextStyle(fontFamily: bodyFont, fontSize: 14, color: Colors.white70),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
      ),
    ),
  );
}

class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const DashedDivider({
    super.key,
    this.height = 1,
    this.color = AppColors.rule,
    this.dashWidth = 6,
    this.dashSpace = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(dashCount, (index) {
          return Container(width: dashWidth, height: height, color: color);
        }),
      );
    });
  }
}
