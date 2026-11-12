import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Mode Surfaces (Enterprise Palette)
  static const Color background = Color(0xFF0B0F19);
  static const Color surfaceCard = Color(0xFF111827);
  static const Color surfaceElevate = Color(0xFF1E293B);
  static const Color borderSubtle = Color(0xFF1F2937);
  static const Color borderSubtleDark = Color(0xFF1F2937);

  // Surface aliases for backward compatibility
  static const Color surfaceBackgroundDark = background;
  static const Color surfacePrimaryDark = surfaceCard;
  static const Color surfaceSecondaryDark = Color(0xFF1F2937);
  static const Color surfaceElevatedDark = surfaceElevate;

  // Light Mode Surfaces
  static const Color surfaceBackgroundLight = Color(0xFFF8FAFC);
  static const Color surfacePrimaryLight = Color(0xFFFFFFFF);
  static const Color surfaceSecondaryLight = Color(0xFFF1F5F9);
  static const Color surfaceElevatedLight = Color(0xFFE2E8F0);
  static const Color borderSubtleLight = Color(0xFFCBD5E1);

  // Text
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Backward compatibility text aliases
  static const Color textPrimaryDark = textPrimary;
  static const Color textSecondaryDark = textSecondary;
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);

  // Semantic Accents
  static const Color emerald = Color(0xFF10B981); // Audited / Run Action
  static const Color emeraldBg = Color(0x1F10B981);
  static const Color crimson = Color(0xFFEF4444); // Variance / Breach
  static const Color crimsonBg = Color(0x26EF4444);
  static const Color amber = Color(0xFFF59E0B);   // Warning / Cap Exceeded
  static const Color amberBg = Color(0x26F59E0B);
  static const Color sky = Color(0xFF38BDF8);     // Info / Selection
  static const Color skyBg = Color(0x1F38BDF8);

  // Status Aliases
  static const Color statusMatch = emerald;
  static const Color statusMatchBg = emeraldBg;
  static const Color statusWarning = amber;
  static const Color statusWarningBg = amberBg;
  static const Color statusDispute = crimson;
  static const Color statusDisputeBg = crimsonBg;

  // Brand Accent
  static const Color brandAccent = Color(0xFF6366F1);
  static const Color brandAccentDark = Color(0xFF4F46E5);
}
