import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Polished rounded logo badge rendering `assets/logo.png` cleanly across
/// both the startup splash screen and the top workbench command bar.
class ClairLogoBadge extends StatelessWidget {
  final double size;
  final double borderRadius;
  final List<BoxShadow>? shadows;
  final Color? borderColor;

  const ClairLogoBadge({
    super.key,
    required this.size,
    this.borderRadius = 8,
    this.shadows,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.brandAccent.withValues(alpha: 0.4),
          width: size >= 48 ? 1.5 : 1,
        ),
        boxShadow: shadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => Container(
          color: AppColors.brandAccentDark,
          alignment: Alignment.center,
          child: Icon(
            Icons.verified_user_rounded,
            color: Colors.white,
            size: size * 0.56,
          ),
        ),
      ),
    );
  }
}
