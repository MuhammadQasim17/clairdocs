import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Responsive modal inset padding that preserves desktop breathing room while
/// avoiding cramped horizontal space on compact mobile screens.
EdgeInsets responsiveDialogInsetPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < AppBreakpoints.compactPhone) {
    return const EdgeInsets.symmetric(horizontal: 12, vertical: 16);
  }
  return const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
}

/// Shared high-contrast slate border color used across modal cards, fields,
/// headers, and footers on dark enterprise surfaces.
const Color enterpriseModalBorderColor = Color(0xFF475569);

Color enterpriseBorderColor(BuildContext context) =>
    AppColors.isDark(context) ? enterpriseModalBorderColor : AppColors.borderSubtleLight;

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
    final isDark = AppColors.isDark(context);
    final borderColor =
        isDark ? enterpriseModalBorderColor : AppColors.borderSubtleLight;
    final bgColor =
        isDark ? AppColors.surfaceElevate : AppColors.surfaceSecondaryLight;
    final titleColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.94)
        : AppColors.textSecondaryLight;
    final closeBtnColor =
        isDark ? Colors.white : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        border: Border(
          bottom: BorderSide(color: borderColor),
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
                    color: titleColor,
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
                    color: subtitleColor,
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
            color: closeBtnColor,
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
    final isDark = AppColors.isDark(context);
    final borderColor =
        isDark ? enterpriseModalBorderColor : AppColors.borderSubtleLight;
    final bgColor = isDark
        ? AppColors.surfaceElevate.withValues(alpha: 0.48)
        : AppColors.surfacePrimaryLight;
    final titleColor = isDark ? Colors.white : AppColors.textPrimaryLight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor),
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
                    color: titleColor,
                    letterSpacing: 0.85,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  flex: 0,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: trailing!,
                  ),
                ),
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
  BuildContext? context,
  String? hint,
  IconData? prefixIcon,
  Widget? suffixIcon,
  BoxConstraints? suffixIconConstraints,
}) {
  final isLight =
      context != null && !AppColors.isDark(context);
  final borderColor =
      isLight ? AppColors.borderSubtleLight : enterpriseModalBorderColor;
  final fillColor =
      isLight ? AppColors.surfacePrimaryLight : AppColors.background;
  final labelColor =
      isLight ? AppColors.textSecondaryLight : AppColors.textPrimary;
  final floatingLabelColor =
      isLight ? AppColors.brandAccentDark : Colors.white;
  final hintColor = isLight
      ? AppColors.textMuted
      : AppColors.textPrimary.withValues(alpha: 0.78);
  final iconColor = isLight ? AppColors.textSecondaryLight : Colors.white;

  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 15, color: iconColor),
    prefixIconConstraints: prefixIcon == null
        ? null
        : const BoxConstraints(minWidth: 34, minHeight: 34),
    suffixIcon: suffixIcon,
    suffixIconConstraints: suffixIconConstraints,
    labelStyle: AppTypography.bodySmall.copyWith(
      fontSize: 12,
      color: labelColor,
      fontWeight: FontWeight.w600,
    ),
    floatingLabelStyle: AppTypography.bodySmall.copyWith(
      fontSize: 12,
      color: floatingLabelColor,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: AppTypography.bodySmall.copyWith(
      fontSize: 12,
      color: hintColor,
    ),
    filled: true,
    fillColor: fillColor,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm + 4,
      vertical: 11,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: const BorderSide(color: AppColors.brandAccent, width: 1.3),
    ),
  );
}
