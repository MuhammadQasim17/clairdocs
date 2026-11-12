import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Shared high-contrast slate border color used across modal cards, fields,
/// headers, and footers on dark enterprise surfaces.
const Color enterpriseModalBorderColor = Color(0xFF475569);

/// Shared enterprise modal header with elevated background, icon badge, title,
/// subtitle, and optional close button.
class EnterpriseDialogHeader extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final VoidCallback? onClose;
  final String closeTooltip;

  const EnterpriseDialogHeader({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    this.onClose,
    this.closeTooltip = 'Close dialog',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevate,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        border: Border(
          bottom: BorderSide(color: enterpriseModalBorderColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: accentColor.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.94),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: closeTooltip,
            splashRadius: 16,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

/// Shared structured card section used inside ClairDocs configuration and
/// dispatch modals.
class EnterpriseSectionCard extends StatelessWidget {
  final String sectionTitle;
  final Widget? trailing;
  final Widget child;

  const EnterpriseSectionCard({
    super.key,
    required this.sectionTitle,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevate.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: enterpriseModalBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sectionTitle,
                  style: AppTypography.labelMicro.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.85,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          child,
        ],
      ),
    );
  }
}

/// Shared inline status/error banner for modal feedback messages.
class EnterpriseFeedbackBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const EnterpriseFeedbackBanner({
    super.key,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isError ? AppColors.crimson : AppColors.emerald;
    final bg = isError ? AppColors.crimsonBg : AppColors.emeraldBg;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 4,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 15,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// Consistent input field decoration used across enterprise configuration and
/// dispatch modals.
InputDecoration buildEnterpriseFieldDecoration(
  String label, {
  String? hint,
  IconData? prefixIcon,
  Widget? suffixIcon,
  BoxConstraints? suffixIconConstraints,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 15, color: Colors.white),
    prefixIconConstraints: prefixIcon == null
        ? null
        : const BoxConstraints(minWidth: 34, minHeight: 34),
    suffixIcon: suffixIcon,
    suffixIconConstraints: suffixIconConstraints,
    labelStyle: AppTypography.bodySmall.copyWith(
      fontSize: 12,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    floatingLabelStyle: AppTypography.bodySmall.copyWith(
      fontSize: 12,
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: AppTypography.bodySmall.copyWith(
      fontSize: 12,
      color: AppColors.textPrimary.withValues(alpha: 0.78),
    ),
    filled: true,
    fillColor: AppColors.background,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm + 4,
      vertical: 11,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: const BorderSide(color: enterpriseModalBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: const BorderSide(color: enterpriseModalBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: const BorderSide(color: AppColors.brandAccent, width: 1.3),
    ),
  );
}
