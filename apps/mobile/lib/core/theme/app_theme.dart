import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentPrimary,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.loraTextTheme(ThemeData.light().textTheme),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentPrimary,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.loraTextTheme(ThemeData.dark().textTheme),
    );
  }
}
