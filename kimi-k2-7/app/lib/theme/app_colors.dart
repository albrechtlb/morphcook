import 'package:flutter/material.dart';

class AppColors {
  static const paper = Color(0xFFF7F5F0);
  static const paperDark = Color(0xFFEBE7DF);
  static const paperShadow = Color(0xFFDCD6CB);
  static const ink = Color(0xFF2E2825);
  static const inkMuted = Color(0xFF8C8078);
  static const inkLight = Color(0xFFBFB5AC);
  static const rule = Color(0xFF2E2825);
  static const coral = Color(0xFFE26D5A);
  static const teal = Color(0xFF2A9D8F);
  static const mustard = Color(0xFFE9C46A);
  static const charcoal = Color(0xFF264653);
}

extension ColorParsing on String {
  Color toColor() {
    final hex = replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return const Color(0xFF000000);
  }
}
