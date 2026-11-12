import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Shared neutral card container that remains unhighlighted by default and
/// transitions cleanly only on explicit pointer hover or active selection.
class SelectableAuditCard extends StatefulWidget {
  final bool isSelected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool highlightOnHover;
  final double pulseStrength;
  final Color defaultColor;
  final Color? selectedColor;
  final Widget child;

  const SelectableAuditCard({
    super.key,
    required this.isSelected,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.highlightOnHover = true,
    this.pulseStrength = 0.0,
    this.defaultColor = AppColors.surfaceCard,
    this.selectedColor,
    required this.child,
  });

  @override
  State<SelectableAuditCard> createState() => _SelectableAuditCardState();
}

class _SelectableAuditCardState extends State<SelectableAuditCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final canTap = widget.onTap != null;
    final canHover = widget.highlightOnHover;
    final showHover = canHover && _isHovered && !isSelected;

    final Color bgColor;
    final Color borderColor;
    final double borderWidth;

    if (isSelected) {
      bgColor = widget.selectedColor ??
          (widget.pulseStrength > 0
              ? AppColors.amber.withValues(
                  alpha: 0.14 + (0.08 * widget.pulseStrength),
                )
              : AppColors.surfaceElevate);
      borderColor = AppColors.amber;
      borderWidth = 1.5;
    } else if (showHover) {
      bgColor = AppColors.surfaceElevate.withValues(alpha: 0.65);
      borderColor = AppColors.sky.withValues(alpha: 0.55);
      borderWidth = 1.0;
    } else {
      bgColor = widget.defaultColor;
      borderColor = AppColors.borderSubtle;
      borderWidth = 1.0;
    }

    final cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.amber.withValues(
                    alpha: 0.16 + (0.20 * widget.pulseStrength),
                  ),
                  blurRadius: 10 + (6 * widget.pulseStrength),
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: widget.child,
    );

    return MouseRegion(
      cursor: canTap ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: canHover ? (_) => setState(() => _isHovered = true) : null,
      onExit: canHover ? (_) => setState(() => _isHovered = false) : null,
      child: canTap
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: cardContent,
            )
          : cardContent,
    );
  }
}
