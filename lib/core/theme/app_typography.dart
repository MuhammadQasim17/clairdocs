import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamilySans = 'Inter';
  static const String fontFamilyMono = 'JetBrains Mono';

  // Headings & Titles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
    color: AppColors.textPrimary,
  );

  // Body Text
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.36,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelMicro = TextStyle(
    fontFamily: fontFamilySans,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textMuted,
  );

  // Monospace (Financials, Line Items, Rates, Clauses)
  static const TextStyle monoMetric = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle monoMetricLarge = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.crimson,
  );

  static const TextStyle monoValue = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static const TextStyle monoCitation = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: AppColors.sky,
  );

  static const TextStyle monoBadge = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );
}
