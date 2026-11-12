import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Shared symmetrical two-tier header bar for the Contract and Invoice panes.
///
/// Enforces consistent header geometry and height parity across both panes so
/// the side-by-side document viewports stay horizontally and vertically aligned
/// across empty, demo, Word, and PDF states without clipping controls.
class DocumentPaneHeader extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final bool isDemo;
  final bool hasFile;
  final bool isPdf;
  final String? sha256Hash;
  final String? formattedSize;
  final String? demoStatusLabel;
  final int zoomPercent;
  final int currentPage;
  final int totalPages;
  final VoidCallback onSelectLiveDoc;
  final VoidCallback onSelectDemoSample;
  final VoidCallback onClearFile;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onResetZoom;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  const DocumentPaneHeader({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.isDemo,
    required this.hasFile,
    required this.isPdf,
    required this.zoomPercent,
    required this.currentPage,
    required this.totalPages,
    required this.onSelectLiveDoc,
    required this.onSelectDemoSample,
    required this.onClearFile,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onResetZoom,
    this.sha256Hash,
    this.formattedSize,
    this.demoStatusLabel,
    this.onPreviousPage,
    this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    final Widget statusBadge;
    if (!isDemo && hasFile && sha256Hash != null) {
      statusBadge = Tooltip(
        message: 'SHA-256: $sha256Hash\nSize: ${formattedSize ?? ''}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.emeraldBg,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.35),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_outlined,
                size: 11,
                color: AppColors.emerald,
              ),
              SizedBox(width: 4),
              Text(
                'SHA-256 Verified',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamilySans,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (isDemo && demoStatusLabel != null) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.crimsonBg,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          demoStatusLabel!,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamilySans,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.crimson,
          ),
        ),
      );
    } else {
      statusBadge = Text(
        isDemo ? 'SAMPLE PREVIEW' : 'AWAITING DOCUMENT',
        style: AppTypography.labelMicro,
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1 (fixed 28px height): Clean Document Title + Far-Right Close (X)
          SizedBox(
            height: 28,
            child: Row(
              children: [
                Icon(icon, size: 15, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Tooltip(
                    message: title,
                    child: Text(
                      title,
                      style: AppTypography.titleSmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                if (hasFile || isDemo) ...[
                  const SizedBox(width: 4),
                  _CompactHeaderButton(
                    icon: Icons.close,
                    size: 14,
                    tooltip: 'Remove file',
                    onPressed: onClearFile,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Row 2 (symmetric 28px minHeight): Mode Switcher, Verification Badge & Zoom/Page Controls
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 28),
            child: LayoutBuilder(
              builder: (context, row2Constraints) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: 4,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: row2Constraints.maxWidth,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  border:
                                      Border.all(color: AppColors.borderSubtle),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _ModeChip(
                                      label: 'Live Doc',
                                      isActive: !isDemo,
                                      accentColor: accentColor,
                                      onTap: onSelectLiveDoc,
                                    ),
                                    _ModeChip(
                                      label: 'Demo Sample',
                                      isActive: isDemo,
                                      accentColor: accentColor,
                                      onTap: onSelectDemoSample,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs + 2),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: statusBadge,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isDemo && hasFile)
                          Wrap(
                        spacing: 2,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _CompactHeaderButton(
                            icon: Icons.remove,
                            size: 14,
                            tooltip: 'Zoom Out',
                            onPressed: onZoomOut,
                          ),
                          InkWell(
                            onTap: onResetZoom,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                '$zoomPercent%',
                                style: AppTypography.monoCitation,
                              ),
                            ),
                          ),
                          _CompactHeaderButton(
                            icon: Icons.add,
                            size: 14,
                            tooltip: 'Zoom In',
                            onPressed: onZoomIn,
                          ),
                          _CompactHeaderButton(
                            icon: Icons.restart_alt,
                            size: 14,
                            tooltip: 'Reset Zoom (100%)',
                            onPressed: onResetZoom,
                          ),
                          if (isPdf)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 4),
                                _CompactHeaderButton(
                                  icon: Icons.chevron_left,
                                  size: 16,
                                  tooltip: 'Previous Page',
                                  onPressed: onPreviousPage,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: Text(
                                    '$currentPage / ${totalPages > 0 ? totalPages : "-"}',
                                    style: AppTypography.monoCitation,
                                  ),
                                ),
                                _CompactHeaderButton(
                                  icon: Icons.chevron_right,
                                  size: 16,
                                  tooltip: 'Next Page',
                                  onPressed: onNextPage,
                                ),
                              ],
                            ),
                        ],
                      ),
                  ],
                ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactHeaderButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final String tooltip;
  final VoidCallback? onPressed;

  const _CompactHeaderButton({
    required this.icon,
    required this.size,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 24, height: 24),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(24, 24),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: size),
      splashRadius: 12,
      tooltip: tooltip,
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceElevate : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamilySans,
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? accentColor : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
