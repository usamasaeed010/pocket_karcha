import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';

/// Local font family registered in [pubspec.yaml] under `assets/fonts/`.
abstract final class AppFonts {
  static const String family = 'Poppins';

  /// System serif used for store names and section headings.
  /// Android resolves `serif` to Noto Serif; iOS falls back to Georgia.
  static const String serif = 'serif';
  static const List<String> serifFallback = [
    'Georgia',
    'Noto Serif',
    'Times New Roman',
  ];

  /// Display style for store names, totals and section headings.
  static TextStyle display({
    double size = 22,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w700,
    double? height,
  }) {
    return TextStyle(
      fontFamily: serif,
      fontFamilyFallback: serifFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: -0.2,
    );
  }
}
