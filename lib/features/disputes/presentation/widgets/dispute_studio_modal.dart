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
  const DisputeStudioModal({super.key});

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
    final dispatchResult = await showDialog<DispatchResult>(
      context: context,
      builder: (_) => DispatchNoticeDialog(
        disputeState: currentState,
        noticeText: _textController.text,
      ),
    );
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

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.borderSubtle),
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
            body: Column(
              children: [
            // Dynamic Header Metadata
            Container(
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
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.crimsonBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: AppColors.crimson.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.gavel_rounded,
                      color: AppColors.crimson,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Interactive Dispute Studio',
                              style: AppTypography.titleMedium,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Container(
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
                                              : AppColors.sky,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.business_outlined,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Vendor: ${disputeState.vendorName}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Text(
                              '•',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                'Invoice: ${disputeState.invoiceReference}',
                                style: AppTypography.monoCitation,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Total Withheld Amount Badge
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
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Close Studio',
                  ),
                ],
              ),
            ),

            // Top Toolbar Actions (Tone Selector, Regenerate, Copy, Export PDF)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 10,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Text(
                          'TONE:',
                          style: AppTypography.labelMicro,
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
                          selectedColor: AppColors.skyBg,
                          backgroundColor: AppColors.background,
                          side: BorderSide(
                            color: disputeState.tone == tone
                                ? AppColors.sky
                                : AppColors.borderSubtle,
                          ),
                          labelStyle: TextStyle(
                            fontFamily: AppTypography.fontFamilySans,
                            fontSize: 11,
                            fontWeight: disputeState.tone == tone
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: disputeState.tone == tone
                                ? AppColors.sky
                                : AppColors.textPrimary,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: 6,
                    children: [
                      OutlinedButton.icon(
                        onPressed: isAiBusy ? null : notifier.regenerateWithAi,
                        icon: isAiBusy
                            ? const SizedBox(
                                width: 13,
                                height: 13,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome_outlined, size: 15),
                        label: Text(isAiBusy ? 'AI Refining...' : 'Regenerate'),
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            hasDraftText && !isAiBusy ? _copyToClipboard : null,
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: const Text('Copy to Clipboard'),
                      ),
                      ElevatedButton.icon(
                        onPressed: (!hasDraftText ||
                                isAiBusy ||
                                disputeState.isExportingPdf)
                            ? null
                            : _exportPdf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.white,
                        ),
                        icon: disputeState.isExportingPdf
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 15,
                              ),
                        label: Text(
                          disputeState.isExportingPdf
                              ? 'Exporting...'
                              : 'Export PDF',
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            hasDraftText && !isAiBusy ? _openDispatchDialog : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandAccent,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.send_rounded, size: 14),
                        label: const Text('Dispatch Notice'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Financial Summary Ribbon
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 8,
              ),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Stated Invoiced: ',
                    style: AppTypography.bodySmall,
                  ),
                  Text(invoicedStr, style: AppTypography.monoValue),
                  const SizedBox(width: AppSpacing.lg),
                  const Text(
                    'Approved Release: ',
                    style: AppTypography.bodySmall,
                  ),
                  Text(
                    approvedStr,
                    style: AppTypography.monoValue.copyWith(
                      color: AppColors.emerald,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.schedule_outlined,
                    size: 13,
                    color: AppColors.amber,
                  ),
                  const SizedBox(width: 4),
                  const Flexible(
                    child: Text(
                      'Rectification Deadline: 14 Business Days',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamilySans,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.amber,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Main Editable Monospace Draft Canvas with Inline AI Overlay
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: _isEditorFocused
                              ? AppColors.sky.withValues(alpha: 0.65)
                              : AppColors.borderSubtle,
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
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamilyMono,
                          fontSize: 12.5,
                          height: 1.55,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(AppSpacing.md),
                          hintText:
                              'Dispute notice draft will appear here...',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    if (isAiBusy)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard.withValues(alpha: 0.97),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: AppColors.sky.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color: AppColors.sky,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'Refining ${disputeState.tone.label} notice with AI...',
                                  style: AppTypography.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Attempting ${ApiConstants.defaultGeminiModelDisplayName} / Groq fast engine (8s timeout).',
                                  style: AppTypography.bodySmall,
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
                  ],
                ),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
