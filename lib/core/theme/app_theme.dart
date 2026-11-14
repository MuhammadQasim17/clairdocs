import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surfaceCard,
      cardColor: AppColors.surfaceCard,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.emerald,
        surface: AppColors.surfaceCard,
        surfaceContainerHighest: AppColors.surfaceElevate,
        error: AppColors.crimson,
        outline: AppColors.borderSubtle,
        onSurface: AppColors.textPrimary,
        onPrimary: Colors.white,
      ),
      fontFamily: AppTypography.fontFamilySans,
      dividerColor: AppColors.borderSubtle,
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 18,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
          textStyle: AppTypography.titleSmall,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderSubtle),
          textStyle: AppTypography.titleSmall,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.surfaceBackgroundLight,
      canvasColor: AppColors.surfacePrimaryLight,
      cardColor: AppColors.surfacePrimaryLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandAccent,
        surface: AppColors.surfacePrimaryLight,
        surfaceContainerHighest: AppColors.surfaceElevatedLight,
        surfaceContainer: AppColors.surfaceSecondaryLight,
        error: AppColors.crimson,
        outline: AppColors.borderSubtleLight,
        onSurface: AppColors.textPrimaryLight,
        onPrimary: Colors.white,
      ),
      fontFamily: AppTypography.fontFamilySans,
      dividerColor: AppColors.borderSubtleLight,
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtleLight,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryLight,
        size: 18,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
          textStyle: AppTypography.titleSmall,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryLight,
          side: const BorderSide(color: AppColors.borderSubtleLight),
          textStyle: AppTypography.titleSmall,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfacePrimaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
