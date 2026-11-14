import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/enterprise_dialog_chrome.dart';
import '../../../analytics/presentation/analytics_dashboard_screen.dart';
import '../../../audit/providers/audit_provider.dart';
import '../../../disputes/providers/dispute_provider.dart';
import '../../models/audit_record.dart';
import '../../providers/audit_history_provider.dart';

/// Enterprise modal vault showing persisted SQLite audit runs searchable by
/// vendor name, with actions to reload past audits or directly export PDFs.
class AuditVaultDialog extends ConsumerStatefulWidget {
  final bool isFullScreen;
  final VoidCallback? onReload;

  const AuditVaultDialog({
    super.key,
    this.isFullScreen = false,
    this.onReload,
  });

  @override
  ConsumerState<AuditVaultDialog> createState() => _AuditVaultDialogState();
}

class _AuditVaultDialogState extends ConsumerState<AuditVaultDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _exportingRecordId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AuditRecord> _filterRecords(List<AuditRecord> records) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return records;
    return records.where((record) {
      return record.vendorName.toLowerCase().contains(q) ||
          record.contractName.toLowerCase().contains(q) ||
          record.invoiceName.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  Future<void> _handleExportPdf(AuditRecord record) async {
    setState(() => _exportingRecordId = record.id);
    try {
      final exporter = ref.read(disputePdfExporterProvider);
      final savedUri = await exporter.exportAndSavePdf(
        disputeState: record.toDisputeState(),
      );
      if (!mounted) return;
      if (savedUri != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emerald,
            content: Text(
              'PDF notice exported for ${record.vendorName}.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.crimson,
          content: Text('Failed to export PDF: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _exportingRecordId = null);
      }
    }
  }

  void _handleReloadAudit(AuditRecord record) {
    final restoredResult =
        ref.read(auditProvider.notifier).loadHistoricalAudit(record);
    ref
        .read(disputeProvider.notifier)
        .loadHistoricalDispute(record, restoredResult);
    if (!widget.isFullScreen) {
      Navigator.of(context).pop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevate,
        content: Text(
          'Reloaded audit for ${record.vendorName} from Audit Vault.',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
    widget.onReload?.call();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(auditHistoryProvider);
    final totalCount = historyAsync.asData?.value.length ?? 0;

    final isCompactViewport =
        MediaQuery.sizeOf(context).width < AppBreakpoints.compactPhone;
    final isDark = AppColors.isDark(context);

    if (widget.isFullScreen) {
      return Container(
        color: AppColors.surfaceBackgroundOf(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 52,
              padding: EdgeInsets.symmetric(
                horizontal: Navigator.of(context).canPop()
                    ? AppSpacing.xs
                    : (AppSpacing.sm + 4),
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceCardOf(context),
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSubtleOf(context)),
                ),
              ),
              child: Row(
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      tooltip: 'Back to Workbench',
                      color: AppColors.textPrimaryOf(context),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
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
                      Icons.inventory_2_outlined,
                      color: AppColors.sky,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Audit Vault & History',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimaryOf(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevateOf(context),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.borderSubtleOf(context)),
                    ),
                    child: Text(
                      '$totalCount SAVED',
                      style: AppTypography.monoBadge.copyWith(
                        color: isDark ? AppColors.sky : AppColors.brandAccentDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    onPressed: () =>
                        ref.read(auditHistoryProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    tooltip: 'Refresh Vault',
                    color: AppColors.textPrimaryOf(context),
                    splashRadius: 16,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: _buildSearchTextField(),
            ),
            Expanded(
              child: _buildVaultRecordsBody(historyAsync),
            ),
          ],
        ),
      );
    }

    return Dialog(
      backgroundColor: AppColors.surfaceCardOf(context),
      insetPadding: responsiveDialogInsetPadding(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppColors.borderSubtleOf(context)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 780,
          maxHeight: 680,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompactViewport ? AppSpacing.md : AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevateOf(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSubtleOf(context)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.skyBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: AppColors.sky.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.sky,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Audit Vault & History',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.textPrimaryOf(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (isCompactViewport)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCardOf(context),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                  border:
                                      Border.all(color: AppColors.borderSubtleOf(context)),
                                ),
                                child: Text(
                                  '$totalCount SAVED',
                                  style: AppTypography.monoBadge.copyWith(
                                    color: isDark ? AppColors.sky : AppColors.brandAccentDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Local SQLite persistence • Reload past discrepancies or export formal notices',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryOf(context),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isCompactViewport) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCardOf(context),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.borderSubtleOf(context)),
                      ),
                      child: Text(
                        '$totalCount SAVED',
                        style: AppTypography.monoBadge.copyWith(
                          color: AppColors.sky,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AnalyticsDashboardScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.insights_rounded, size: 14),
                      label: const Text('Analytics & Savings'),
                    ),
                  ] else
                    IconButton(
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AnalyticsDashboardScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.insights_rounded,
                        size: 18,
                        color: AppColors.emerald,
                      ),
                      tooltip: 'Analytics & Savings',
                      splashRadius: 16,
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    onPressed: () =>
                        ref.read(auditHistoryProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    tooltip: 'Refresh Vault',
                    splashRadius: 16,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: 'Close Vault',
                    splashRadius: 16,
                  ),
                ],
              ),
            ),

            // Search Field
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: _buildSearchTextField(),
            ),

            // Records List Body
            Expanded(
              child: _buildVaultRecordsBody(historyAsync),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTextField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        hintText:
            'Search saved audits by vendor name, contract, or invoice...',
        hintStyle: AppTypography.bodySmall,
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 18,
          color: AppColors.textMuted,
        ),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 16),
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceElevateOf(context),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.borderSubtleOf(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: AppColors.borderSubtleOf(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.sky),
        ),
      ),
    );
  }

  Widget _buildVaultRecordsBody(AsyncValue<List<AuditRecord>> historyAsync) {
    return historyAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.storage_rounded,
                color: AppColors.crimson,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Unable to load Audit Vault: $err',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      data: (records) {
        final filtered = _filterRecords(records);
        if (records.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Audit Vault is Empty',
            subtitle:
                'Completed AI audits with calculated discrepancies are automatically persisted to local SQLite storage.',
          );
        }
        if (filtered.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No Matching Audits',
            subtitle: 'No saved records match "$_query".',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final record = filtered[index];
            return _AuditVaultCard(
              record: record,
              isExporting: _exportingRecordId == record.id,
              onReload: () => _handleReloadAudit(record),
              onExportPdf: () => _handleExportPdf(record),
              onDelete: () =>
                  ref.read(auditHistoryProvider.notifier).deleteRecord(record.id),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevateOf(context),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSubtleOf(context)),
                ),
                child: Icon(icon, size: 28, color: AppColors.textMutedOf(context)),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditVaultCard extends StatelessWidget {
  final AuditRecord record;
  final bool isExporting;
  final VoidCallback onReload;
  final VoidCallback onExportPdf;
  final VoidCallback onDelete;

  const _AuditVaultCard({
    required this.record,
    required this.isExporting,
    required this.onReload,
    required this.onExportPdf,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final findings = record.decodeFindings();
    final parsedDate = record.parsedTimestamp;
    final dateStr = parsedDate != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(parsedDate.toLocal())
        : record.timestamp;

    final hasVariance = record.totalVariance > 0;
    final varianceStr = CurrencyFormatter.formatVariance(record.totalVariance);
    final invoicedStr = CurrencyFormatter.formatUsd(record.invoicedTotal);
    final baseStr = CurrencyFormatter.formatUsd(record.contractBase);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevateOf(context),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtleOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.vendorName,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimaryOf(context),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: hasVariance ? AppColors.crimsonBg : AppColors.emeraldBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  varianceStr,
                  style: AppTypography.monoBadge.copyWith(
                    color: hasVariance
                        ? AppColors.crimson
                        : (isDark ? AppColors.emerald : const Color(0xFF047857)),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                color: AppColors.textMutedOf(context),
                splashRadius: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                tooltip: 'Delete audit record',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                dateStr,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              Text('•', style: TextStyle(color: AppColors.textMutedOf(context))),
              Text(
                '${findings.length} ${findings.length == 1 ? 'finding' : 'findings'}',
                style: AppTypography.monoCitation.copyWith(
                  color: isDark ? AppColors.sky : AppColors.brandAccentDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text('•', style: TextStyle(color: AppColors.textMutedOf(context))),
              Text(
                '${record.contractName}  |  ${record.invoiceName}',
                style: AppTypography.monoCitation.copyWith(
                  color: isDark ? AppColors.sky : AppColors.brandAccentDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, cardConstraints) {
              final metrics = Wrap(
                spacing: AppSpacing.md,
                runSpacing: 4,
                children: [
                  Text(
                    'Invoiced: $invoicedStr',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  Text(
                    'Contract Base: $baseStr',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.emerald : const Color(0xFF047857),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );

              final actions = Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  OutlinedButton.icon(
                    onPressed: onReload,
                    icon: const Icon(Icons.restore_rounded, size: 14),
                    label: const Text('Reload Past Audit'),
                  ),
                  ElevatedButton.icon(
                    onPressed: isExporting ? null : onExportPdf,
                    icon: isExporting
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined, size: 14),
                    label: const Text('Export PDF'),
                  ),
                ],
              );

              if (cardConstraints.maxWidth < 480) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    metrics,
                    const SizedBox(height: AppSpacing.sm),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: metrics),
                  actions,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
