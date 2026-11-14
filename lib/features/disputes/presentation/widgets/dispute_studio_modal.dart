import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../models/dispute_models.dart';
import '../../providers/dispute_provider.dart';
import '../../services/dispute_dispatch_service.dart';
import 'dispatch_notice_dialog.dart';

class DisputeStudioModal extends ConsumerStatefulWidget {
  final bool isFullScreen;

  const DisputeStudioModal({
    super.key,
    this.isFullScreen = false,
  });

  @override
  ConsumerState<DisputeStudioModal> createState() => _DisputeStudioModalState();
}

class _DisputeStudioModalState extends ConsumerState<DisputeStudioModal> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  String _lastSyncedDraftText = '';
  bool _isEditorFocused = false;

  @override
  void initState() {
    super.initState();
    _lastSyncedDraftText = ref.read(disputeProvider).draftText;
    _textController.value = TextEditingValue(
      text: _lastSyncedDraftText,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _editorFocusNode.addListener(_handleEditorFocusChange);

    // Automatically generate the initial dispute draft upon opening if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentDraft = ref.read(disputeProvider).draftText;
        if (currentDraft.trim().isEmpty) {
          ref.read(disputeProvider.notifier).generateDraft();
        }
      }
    });
  }

  void _handleEditorFocusChange() {
    if (!mounted) return;
    if (_isEditorFocused != _editorFocusNode.hasFocus) {
      setState(() => _isEditorFocused = _editorFocusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _editorFocusNode.removeListener(_handleEditorFocusChange);
    _editorFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _showStudioSnackBar(Widget content) {
    _messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevate,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            side: const BorderSide(color: AppColors.emerald),
          ),
          content: content,
        ),
      );
  }

  Future<void> _copyToClipboard() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      // Ignore platform channel errors in restricted test sandboxes
    }
    if (!mounted) return;

    _showStudioSnackBar(
      const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 16),
          SizedBox(width: 8),
          Text(
            'Dispute notice copied to clipboard.',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    final notifier = ref.read(disputeProvider.notifier);
    if (ref.read(disputeProvider).draftText != _textController.text) {
      notifier.updateDraftText(_textController.text);
    }

    final savedUri = await notifier.exportPdf();
    if (!mounted) return;

    if (savedUri != null) {
      _showStudioSnackBar(
        Row(
          children: [
            const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.emerald,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Formal PDF saved to: ${savedUri.toFilePath()}',
                style: AppTypography.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openDispatchDialog() async {
    final notifier = ref.read(disputeProvider.notifier);
    if (ref.read(disputeProvider).draftText != _textController.text) {
      notifier.updateDraftText(_textController.text);
    }

    final currentState = ref.read(disputeProvider);
    final isCompact =
        MediaQuery.sizeOf(context).width < AppBreakpoints.desktop;
    final DispatchResult? dispatchResult;
    if (widget.isFullScreen || isCompact) {
      dispatchResult = await Navigator.of(context).push<DispatchResult>(
        MaterialPageRoute(
          builder: (_) => DispatchNoticeDialog(
            disputeState: currentState,
            noticeText: _textController.text,
            isFullScreen: true,
          ),
        ),
      );
    } else {
      dispatchResult = await showDialog<DispatchResult>(
        context: context,
        builder: (_) => DispatchNoticeDialog(
          disputeState: currentState,
          noticeText: _textController.text,
        ),
      );
    }
    if (!mounted || dispatchResult == null) return;

    _showStudioSnackBar(
      const Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppColors.emerald,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            'Dispute Notice Dispatched to Vendor',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  void _syncControllerIfNeeded(String draftText) {
    if (_lastSyncedDraftText == draftText &&
        _textController.text == draftText) {
      return;
    }
    _lastSyncedDraftText = draftText;
    if (_textController.text != draftText) {
      _textController.value = TextEditingValue(
        text: draftText,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final disputeState = ref.watch(disputeProvider);
    final notifier = ref.read(disputeProvider.notifier);

    ref.listen<DisputeState>(disputeProvider, (previous, next) {
      _syncControllerIfNeeded(next.draftText);
    });
    _syncControllerIfNeeded(disputeState.draftText);

    final hasDraftText = disputeState.draftText.trim().isNotEmpty;
    final isGenerating =
        disputeState.status == DisputeGenerationStatus.generating &&
            !hasDraftText;
    final isAiBusy = isGenerating || disputeState.isRefiningWithAi;
    final withheldStr = CurrencyFormatter.formatVariance(
      disputeState.totalWithheld,
      currency: disputeState.currency,
    );
    final invoicedStr = CurrencyFormatter.formatAmount(
      disputeState.totalInvoiced,
      currency: disputeState.currency,
    );
    final approvedStr = CurrencyFormatter.formatAmount(
      disputeState.approvedPayment,
      currency: disputeState.currency,
    );

    final isCompactViewport =
        MediaQuery.sizeOf(context).width < AppBreakpoints.compactPhone;
    final isDark = AppColors.isDark(context);
    final borderColor =
        isDark ? AppColors.borderSubtle : AppColors.borderSubtleLight;

    final headerWidget = Container(
      height: widget.isFullScreen ? 52 : null,
      padding: EdgeInsets.symmetric(
        horizontal: widget.isFullScreen
            ? AppSpacing.xs
            : (isCompactViewport ? AppSpacing.md : AppSpacing.lg),
        vertical: widget.isFullScreen
            ? 0
            : (isCompactViewport ? AppSpacing.sm + 2 : AppSpacing.md),
      ),
      decoration: BoxDecoration(
        color: widget.isFullScreen
            ? AppColors.surfaceCardOf(context)
            : (isDark ? AppColors.surfaceElevate : AppColors.surfaceSecondaryLight),
        borderRadius: widget.isFullScreen
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          if (widget.isFullScreen) ...[
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              tooltip: 'Close Studio',
              color: AppColors.textPrimaryOf(context),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Container(
            padding: EdgeInsets.all(widget.isFullScreen ? 7 : 8),
            decoration: BoxDecoration(
              color: AppColors.crimsonBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.crimson.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              Icons.gavel_rounded,
              color: AppColors.crimson,
              size: widget.isFullScreen ? 16 : 18,
            ),
          ),
          SizedBox(width: widget.isFullScreen ? AppSpacing.sm : AppSpacing.sm + 4),
          Expanded(
            child: widget.isFullScreen
                ? Text(
                    'Interactive Dispute Studio',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimaryOf(context),
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Interactive Dispute Studio',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimaryOf(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: disputeState.usedFallback
                                  ? AppColors.amberBg
                                  : AppColors.skyBg,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (disputeState.isRefiningWithAi) ...[
                                  const SizedBox(
                                    width: 9,
                                    height: 9,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.amber,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                Flexible(
                                  child: Text(
                                    disputeState.isRefiningWithAi
                                        ? 'TEMPLATE READY • AI REFINING'
                                        : disputeState.draftEngine,
                                    style: TextStyle(
                                      fontFamily:
                                          AppTypography.fontFamilySans,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: disputeState.usedFallback
                                          ? AppColors.amber
                                          : (isDark
                                              ? AppColors.sky
                                              : AppColors.brandAccentDark),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 12,
                            color: isDark
                                ? Colors.white
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Vendor: ${disputeState.vendorName}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textPrimaryOf(context),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '•',
                            style: TextStyle(
                                color: AppColors.textPrimaryOf(context)),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              'Invoice: ${disputeState.invoiceReference}',
                              style: AppTypography.monoCitation.copyWith(
                                color: isDark
                                    ? AppColors.sky
                                    : AppColors.brandAccentDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          if (!widget.isFullScreen && !isCompactViewport) ...[
            const SizedBox(width: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.crimsonBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: AppColors.crimson.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'TOTAL WITHHELD',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamilySans,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.crimson,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    withheldStr,
                    style: AppTypography.monoMetric.copyWith(
                      fontSize: 16,
                      color: AppColors.crimson,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!widget.isFullScreen) ...[
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 20),
              tooltip: 'Close Studio',
              color: isDark ? Colors.white : AppColors.textSecondaryLight,
            ),
          ],
        ],
      ),
    );

    final bodyContent = Column(
      children: [
        headerWidget,

            // Tone Selector Ribbon (Flexible Wrapping Layout)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceElevate
                    : AppColors.surfaceSecondaryLight,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppColors.borderSubtle
                        : AppColors.borderSubtleLight,
                  ),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'TONE:',
                    style: AppTypography.labelMicro.copyWith(
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  for (final tone in DisputeTone.values)
                    ChoiceChip(
                      label: Text(tone.label),
                      selected: disputeState.tone == tone,
                      showCheckmark: false,
                      onSelected: isGenerating
                          ? null
                          : (_) => notifier.switchTone(tone),
                      selectedColor: isDark
                          ? AppColors.skyBg
                          : AppColors.brandAccent.withValues(alpha: 0.15),
                      backgroundColor: isDark
                          ? AppColors.background
                          : AppColors.surfacePrimaryLight,
                      side: BorderSide(
                        color: disputeState.tone == tone
                            ? (isDark ? AppColors.sky : AppColors.brandAccent)
                            : (isDark
                                ? AppColors.borderSubtle
                                : AppColors.borderSubtleLight),
                      ),
                      labelStyle: TextStyle(
                        fontFamily: AppTypography.fontFamilySans,
                        fontSize: 11.5,
                        fontWeight: disputeState.tone == tone
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: disputeState.tone == tone
                            ? (isDark ? AppColors.sky : AppColors.brandAccentDark)
                            : (isDark
                                ? AppColors.textPrimary
                                : AppColors.textPrimaryLight),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),

            // Action Buttons Toolbar (Responsive Multi-Row Grid for Mobile)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceCard
                    : AppColors.surfacePrimaryLight,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppColors.borderSubtle
                        : AppColors.borderSubtleLight,
                  ),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 620;

                  final regenerateBtn = OutlinedButton.icon(
                    onPressed: isAiBusy ? null : notifier.regenerateWithAi,
                    icon: isAiBusy
                        ? const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_outlined, size: 14),
                    label: Text(isAiBusy ? 'AI Refining...' : 'Regenerate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                      side: BorderSide(
                        color: isDark
                            ? AppColors.borderSubtle
                            : AppColors.borderSubtleLight,
                      ),
                      minimumSize: const Size(120, 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  );

                  final copyBtn = OutlinedButton.icon(
                    onPressed:
                        hasDraftText && !isAiBusy ? _copyToClipboard : null,
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: const Text('Copy to Clipboard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                      side: BorderSide(
                        color: isDark
                            ? AppColors.borderSubtle
                            : AppColors.borderSubtleLight,
                      ),
                      minimumSize: const Size(120, 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  );

                  final exportBtn = ElevatedButton.icon(
                    onPressed: (!hasDraftText ||
                            isAiBusy ||
                            disputeState.isExportingPdf)
                        ? null
                        : _exportPdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: disputeState.isExportingPdf
                        ? const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 14,
                          ),
                    label: Text(
                      disputeState.isExportingPdf
                          ? 'Exporting...'
                          : 'Export PDF',
                    ),
                  );

                  final dispatchBtn = ElevatedButton.icon(
                    onPressed:
                        hasDraftText && !isAiBusy ? _openDispatchDialog : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 14),
                    label: const Text('Dispatch Notice'),
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: regenerateBtn),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: copyBtn),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        Row(
                          children: [
                            Expanded(child: exportBtn),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: dispatchBtn),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      regenerateBtn,
                      const SizedBox(width: AppSpacing.sm),
                      copyBtn,
                      const Spacer(),
                      exportBtn,
                      const SizedBox(width: AppSpacing.sm),
                      dispatchBtn,
                    ],
                  );
                },
              ),
            ),

            // Financial Summary Ribbon
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isCompactViewport ? AppSpacing.md : AppSpacing.lg,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceElevate
                    : AppColors.surfaceSecondaryLight,
                border: Border(
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              child: Wrap(
                spacing: AppSpacing.lg,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: isCompactViewport ? AppSpacing.md : AppSpacing.lg,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (isCompactViewport)
                        Text.rich(
                          TextSpan(
                            text: 'Withheld: ',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryOf(context),
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: withheldStr,
                                style: AppTypography.monoValue.copyWith(
                                  color: AppColors.crimson,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text.rich(
                        TextSpan(
                          text: 'Stated Invoiced: ',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryOf(context),
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: invoicedStr,
                              style: AppTypography.monoValue.copyWith(
                                color: AppColors.textPrimaryOf(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          text: 'Approved Release: ',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryOf(context),
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: approvedStr,
                              style: AppTypography.monoValue.copyWith(
                                color: isDark
                                    ? AppColors.emerald
                                    : const Color(0xFF047857),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 13,
                        color: isDark ? AppColors.amber : const Color(0xFFB45309),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Rectification Deadline: 14 Business Days',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamilySans,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.amber : const Color(0xFFB45309),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Editable Monospace Draft Canvas with Inline AI Overlay
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(
                  isCompactViewport ? AppSpacing.md : AppSpacing.lg,
                ),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.background
                            : AppColors.surfacePrimaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: _isEditorFocused
                              ? (isDark
                                  ? AppColors.sky.withValues(alpha: 0.65)
                                  : AppColors.brandAccent)
                              : borderColor,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        focusNode: _editorFocusNode,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        onChanged: (value) {
                          _lastSyncedDraftText = value;
                          notifier.updateDraftText(value);
                        },
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamilyMono,
                          fontSize: 12.5,
                          height: 1.55,
                          color: AppColors.textPrimaryOf(context),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(AppSpacing.md),
                          hintText:
                              'Dispute notice draft will appear here...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ),
                    ),
                    if (isAiBusy)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? AppColors.surfaceCard
                                    : AppColors.surfacePrimaryLight)
                                .withValues(alpha: 0.97),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: AppColors.sky.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    color: AppColors.sky,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Refining ${disputeState.tone.label} notice with AI...',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: AppColors.textPrimaryOf(context),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Attempting ${ApiConstants.defaultGeminiModelDisplayName} / Groq fast engine (8s timeout).',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondaryOf(context),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextButton.icon(
                                    onPressed: notifier.cancelAiRefine,
                                    icon: const Icon(
                                      Icons.flash_on_rounded,
                                      size: 15,
                                    ),
                                    label:
                                        const Text('Use Instant Local Draft'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      );

    if (widget.isFullScreen) {
      return ScaffoldMessenger(
        key: _messengerKey,
        child: Scaffold(
          backgroundColor: AppColors.surfaceBackgroundOf(context),
          body: SafeArea(
            child: bodyContent,
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: AppColors.surfaceCardOf(context),
      insetPadding: isCompactViewport
          ? const EdgeInsets.all(AppSpacing.sm + 4)
          : const EdgeInsets.all(AppSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1020,
          maxHeight: 740,
        ),
        child: ScaffoldMessenger(
          key: _messengerKey,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: bodyContent,
          ),
        ),
      ),
    );
  }
}
