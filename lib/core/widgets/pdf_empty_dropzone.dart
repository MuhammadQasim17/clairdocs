import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class PdfEmptyDropzone extends StatefulWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final Color accentColor;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSelectFile;
  final VoidCallback onToggleDemoMode;

  const PdfEmptyDropzone({
    super.key,
    required this.title,
    required this.subtitle,
    this.buttonLabel = 'Select Document',
    required this.icon,
    required this.accentColor,
    required this.onSelectFile,
    required this.onToggleDemoMode,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<PdfEmptyDropzone> createState() => _PdfEmptyDropzoneState();
}

class _PdfEmptyDropzoneState extends State<PdfEmptyDropzone> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.isLoading ? null : widget.onSelectFile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppColors.surfaceElevate.withValues(alpha: 0.45)
                  : AppColors.surfaceCard.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: _isHovered
                    ? widget.accentColor.withValues(alpha: 0.7)
                    : AppColors.borderSubtle,
                width: _isHovered ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: widget.isLoading
                          ? SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: widget.accentColor,
                              ),
                            )
                          : Icon(
                              widget.icon,
                              size: 28,
                              color: widget.accentColor,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      widget.isLoading ? 'Ingesting Document...' : widget.title,
                      style: AppTypography.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    if (widget.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.crimsonBg,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: AppColors.crimson.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 14,
                              color: AppColors.crimson,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.errorMessage!,
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamilySans,
                                  fontSize: 11,
                                  color: AppColors.crimson,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: widget.isLoading ? null : widget.onSelectFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: widget.accentColor == AppColors.sky
                            ? AppColors.background
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.folder_open_outlined, size: 16),
                      label: Text(
                        widget.buttonLabel,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: widget.isLoading ? null : widget.onToggleDemoMode,
                      icon: const Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      label: const Text(
                        'Preview Sample Mockup',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamilySans,
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}

