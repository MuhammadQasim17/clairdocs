import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../disputes/presentation/widgets/dispute_studio_modal.dart';
import '../../../disputes/providers/dispute_provider.dart';
import '../../models/audit_models.dart';
import '../../providers/audit_provider.dart';
import '../widgets/api_key_dialog.dart';
import '../widgets/audit_skeleton_loader.dart';
import '../widgets/discrepancy_item_card.dart';
import '../widgets/kpi_summary_card.dart';
import '../widgets/rate_comparison_card.dart';

/// Dedicated full-screen audit results & findings view for mobile.
///
/// Replaces the cramped card container at the bottom of the document setup screen
/// with a spacious, professional screen dedicated to KPI recovery analysis,
/// discrepancy inspection, and dispute notice drafting.
class MobileAuditResultsScreen extends ConsumerWidget {
  const MobileAuditResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditAsync = ref.watch(auditProvider);
    final selectedFinding = ref.watch(activeSelectedFindingProvider);
    final cooldownSeconds = ref.watch(auditCooldownProvider);
    final activeResult = auditAsync.asData?.value;
    final isAuditing = auditAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.surfaceBackgroundOf(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Status Strip
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.surfaceCardOf(context),
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSubtleOf(context)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    tooltip: 'Back to Setup',
                    color: AppColors.textPrimaryOf(context),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                  padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.skyBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: AppColors.sky.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      size: 16,
                      color: AppColors.sky,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Audit Findings',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimaryOf(context),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Main Results Viewport
            Expanded(
              child: Builder(
                builder: (context) {
                  if (isAuditing) {
                    return const AuditSkeletonLoader();
                  }

                  if (auditAsync.hasError) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _buildErrorCard(
                        context,
                        ref,
                        auditAsync.error!,
                        cooldownSeconds,
                      ),
                    );
                  }

                  if (activeResult != null) {
                    return _buildResultsBody(
                      context,
                      ref,
                      activeResult,
                      selectedFinding,
                    );
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 44,
                            color: AppColors.textMutedOf(context),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No Audit Findings Yet',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimaryOf(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Return to the Home tab and run an AI audit across your governing contract and vendor invoice.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded, size: 16),
                            label: const Text('Back to Document Setup'),
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
      ),
    );
  }

  Widget _buildResultsBody(
    BuildContext context,
    WidgetRef ref,
    AuditResult result,
    AuditFinding? selectedFinding,
  ) {
    final count = result.findings.length;
    final statusText = count == 0
        ? '• 100% Compliant'
        : '• $count Discrepanc${count == 1 ? 'y' : 'ies'} Detected';

    final rateFindings = result.findings
        .where((f) => f.agreedRate != null && f.billedRate != null)
        .toList();
    final primaryRateFinding =
        rateFindings.isNotEmpty ? rateFindings.first : null;
    final isDark = AppColors.isDark(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: count == 0 ? AppColors.emeraldBg : AppColors.crimsonBg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: (count == 0 ? AppColors.emerald : AppColors.crimson)
                  .withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                count == 0
                    ? Icons.verified_rounded
                    : Icons.report_problem_rounded,
                size: 16,
                color: count == 0 ? AppColors.emerald : AppColors.crimson,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamilySans,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: count == 0 ? AppColors.emerald : AppColors.crimson,
                  ),
                ),
              ),
            ],
          ),
        ),
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
                style: AppTypography.labelMicro.copyWith(
                  color: AppColors.textMutedOf(context),
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              result.currency,
              style: AppTypography.monoCitation.copyWith(
                color: isDark ? AppColors.sky : AppColors.brandAccentDark,
              ),
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
        else ...[
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
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(disputeProvider.notifier).generateDraft();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DisputeStudioModal(isFullScreen: true),
                ),
              );
            },
            icon: const Icon(Icons.gavel_rounded, size: 16),
            label: const Text('Draft Dispute Notice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    ),
  );
}

  Widget _buildErrorCard(
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isWarningState
                    ? Icons.warning_amber_rounded
                    : Icons.error_outline_rounded,
                size: 18,
                color: accentColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titleText,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamilySans,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
                  icon: const Icon(Icons.key_rounded, size: 14),
                  label: const Text('Configure Key'),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              OutlinedButton.icon(
                onPressed: isRetryDisabled
                    ? null
                    : () => ref.read(auditProvider.notifier).runAudit(),
                icon: Icon(
                  isRetryDisabled
                      ? Icons.hourglass_bottom_rounded
                      : Icons.refresh_rounded,
                  size: 14,
                ),
                label: Text(
                  isRetryDisabled
                      ? 'Wait ${cooldownSeconds}s'
                      : 'Retry Audit',
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
