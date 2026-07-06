import 'package:flutter/material.dart';

/// Central palette for the neon / glassmorphic look.
class AppColors {
  static const bg0 = Color(0xFF0A0518);
  static const bg1 = Color(0xFF160B34);
  static const bg2 = Color(0xFF2A1259);

  static const cyan = Color(0xFF31E7FF);
  static const magenta = Color(0xFFFF3D9A);
  static const purple = Color(0xFF9B5CFF);
  static const gold = Color(0xFFFFC93C);
  static const green = Color(0xFF3AE374);
  static const danger = Color(0xFFFF5C7A);

  static Color glass(double a) => Colors.white.withValues(alpha: a);
}

class AppText {
  static const heading = TextStyle(
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    color: Colors.white,
  );
  static const label = TextStyle(
    fontWeight: FontWeight.w600,
    color: Colors.white70,
    letterSpacing: 0.3,
  );
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg0,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.cyan,
      secondary: AppColors.magenta,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
  );
}
