import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../contracts/providers/contract_providers.dart';
import '../../../disputes/presentation/widgets/dispute_studio_modal.dart';
import '../../../disputes/providers/dispute_provider.dart';
import '../../../invoices/providers/invoice_providers.dart';
import '../../models/audit_models.dart';
import '../../providers/audit_provider.dart';
import 'api_key_dialog.dart';
import 'audit_skeleton_loader.dart';
import 'kpi_summary_card.dart';
import 'rate_comparison_card.dart';
import 'discrepancy_item_card.dart';

class ActionStudioPanel extends ConsumerWidget {
  const ActionStudioPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractState = ref.watch(contractDocumentProvider);
    final invoiceState = ref.watch(invoiceDocumentProvider);
    final auditAsync = ref.watch(auditProvider);
    final selectedFinding = ref.watch(activeSelectedFindingProvider);
    final cooldownSeconds = ref.watch(auditCooldownProvider);
    final activeResult = auditAsync.asData?.value;
    final canDraftDispute =
        activeResult != null && activeResult.findings.isNotEmpty;
    final hasAnyDocument = contractState.document != null ||
        invoiceState.document != null ||
        contractState.isDemoMode ||
        invoiceState.isDemoMode;

    final rawEngineLabel = activeResult?.auditEngine ?? '';
    final compactEngineLabel = rawEngineLabel.contains('Groq')
        ? rawEngineLabel.replaceAll(' (Groq)', '')
        : rawEngineLabel.toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          left: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 12,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  size: 15,
                  color: AppColors.sky,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Discrepancy & Action Studio',
                    style: AppTypography.titleSmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 132),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevate,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      auditAsync.isLoading
                          ? 'AUDITING'
                          : (activeResult != null
                              ? compactEngineLabel
                              : ApiConstants.defaultGeminiModelShortBadge),
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamilySans,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: auditAsync.isLoading
                            ? AppColors.sky
                            : (rawEngineLabel.contains('Groq')
                                ? AppColors.sky
                                : AppColors.emerald),
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Reactive Studio Body
          Expanded(
            child: auditAsync.when(
              loading: () => const AuditSkeletonLoader(),
              error: (error, _) =>
                  _buildErrorState(context, ref, error, cooldownSeconds),
              data: (result) {
                if (result == null) {
                  return _buildIdleState(
                    ref,
                    cooldownSeconds,
                    hasAnyDocument: hasAnyDocument,
                  );
                }
                return _buildResultList(
                  ref,
                  result,
                  selectedFinding: selectedFinding,
                );
              },
            ),
          ),

          // Bottom CTA (hidden when idle or when no variances exist)
          if (canDraftDispute)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevate,
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(disputeProvider.notifier).generateDraft();
                      showDialog<void>(
                        context: context,
                        builder: (_) => const DisputeStudioModal(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.crimson,
                      disabledBackgroundColor: AppColors.borderSubtle,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    icon: const Icon(Icons.gavel_rounded, size: 16),
                    label: const Text(
                      'Draft Dispute Notice',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamilySans,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Generates formal notice citing ${activeResult.findings.length} flagged items.',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamilySans,
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIdleState(
    WidgetRef ref,
    int cooldownSeconds, {
    required bool hasAnyDocument,
  }) {
    final isDisabled = cooldownSeconds > 0 || !hasAnyDocument;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.skyBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.sky.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
                size: 28,
                color: AppColors.sky,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Ready for Autonomous Audit',
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload both a Governing Contract and Vendor Invoice (PDF, Word, or Spreadsheet), or switch both panels to Demo Sample, then click Run AI Audit.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: isDisabled
                  ? null
                  : () => ref.read(auditProvider.notifier).runAudit(),
              icon: Icon(
                cooldownSeconds > 0
                    ? Icons.hourglass_bottom_rounded
                    : Icons.auto_awesome_rounded,
                size: 15,
              ),
              label: Text(
                cooldownSeconds > 0 ? 'Wait ${cooldownSeconds}s' : 'Run AI Audit',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    Object error,
    int cooldownSeconds,
  ) {
    final isApiKeyError = error is ApiKeyMissingException;
    final isRateLimitError = error is GeminiRateLimitException;
    final isServerBusyError = error is GeminiServerBusyException;
    final isDualEngineError = error is DualEngineAuditException;
    final isWarningState =
        isRateLimitError || isServerBusyError || isDualEngineError;
    final isRetryDisabled = cooldownSeconds > 0;

    final accentColor = isWarningState ? AppColors.amber : AppColors.crimson;
    final bgColor = isWarningState ? AppColors.amberBg : AppColors.crimsonBg;
    final titleText = isRateLimitError
        ? 'Free Tier Rate Limit Reached'
        : (isServerBusyError
            ? 'Google AI Servers Busy (503)'
            : (isDualEngineError
                ? 'All AI Engines Unavailable'
                : 'Audit Could Not Complete'));
    final message = (isRateLimitError || isServerBusyError)
        ? (error as GeminiApiException).message
        : (error is StateError
            ? error.message
            : (error is ClairException ? error.message : error.toString()));

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                isRateLimitError
                    ? Icons.speed_rounded
                    : (isServerBusyError
                        ? Icons.cloud_off_rounded
                        : Icons.error_outline_rounded),
                size: 28,
                color: accentColor,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              titleText,
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isApiKeyError) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  final saved = await showDialog<bool>(
                    context: context,
                    builder: (_) => const ApiKeyDialog(),
                  );
                  if (saved == true && context.mounted) {
                    ref.read(auditProvider.notifier).runAudit();
                  }
                },
                icon: const Icon(Icons.key_rounded, size: 15),
                label: const Text('Configure Gemini API Key'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            OutlinedButton.icon(
              onPressed: isRetryDisabled
                  ? null
                  : () => ref.read(auditProvider.notifier).runAudit(),
              icon: Icon(
                isRetryDisabled
                    ? Icons.hourglass_bottom_rounded
                    : Icons.refresh_rounded,
                size: 15,
              ),
              label: Text(
                isRetryDisabled ? 'Wait ${cooldownSeconds}s to Retry' : 'Retry Audit',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultList(
    WidgetRef ref,
    AuditResult result, {
    AuditFinding? selectedFinding,
  }) {
    final rateFindings = result.findings
        .where((f) => f.agreedRate != null && f.billedRate != null)
        .toList();
    final primaryRateFinding = rateFindings.isNotEmpty ? rateFindings.first : null;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        KpiSummaryCard(result: result),
        if (primaryRateFinding != null) ...[
          const SizedBox(height: AppSpacing.md),
          RateComparisonCard(
            finding: primaryRateFinding,
            currency: result.currency,
            isSelected: selectedFinding?.id == primaryRateFinding.id,
            onTap: () => ref
                .read(activeSelectedFindingProvider.notifier)
                .selectFinding(
                  selectedFinding?.id == primaryRateFinding.id
                      ? null
                      : primaryRateFinding,
                ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'FLAGGED FINDINGS (${result.findings.length})',
                style: AppTypography.labelMicro,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              result.currency,
              style: AppTypography.monoCitation,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (result.findings.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.emeraldBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: AppColors.emerald,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '100% Contract Compliant. No billing breaches or discrepancies detected.',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamilySans,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emerald,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          for (final finding in result.findings) ...[
            DiscrepancyItemCard.fromFinding(
              finding: finding,
              currency: result.currency,
              isSelected: selectedFinding?.id == finding.id,
              onTap: () => ref
                  .read(activeSelectedFindingProvider.notifier)
                  .selectFinding(
                    selectedFinding?.id == finding.id ? null : finding,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}
