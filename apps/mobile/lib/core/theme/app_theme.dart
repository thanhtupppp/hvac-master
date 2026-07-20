import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_colors.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData _light = _build(Brightness.light);
  static final ThemeData _dark = _build(Brightness.dark);

  static ThemeData get lightTheme => _light;
  static ThemeData get darkTheme => _dark;

  static ThemeData _build(Brightness brightness) {
    final base = brightness == Brightness.light
        ? ThemeData.light()
        : ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentPrimary,
        brightness: brightness,
      ),
      textTheme: GoogleFonts.loraTextTheme(base.textTheme),
    );
  }
}
