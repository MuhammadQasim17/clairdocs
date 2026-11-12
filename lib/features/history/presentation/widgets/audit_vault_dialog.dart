import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../analytics/presentation/analytics_dashboard_screen.dart';
import '../../../audit/providers/audit_provider.dart';
import '../../../disputes/providers/dispute_provider.dart';
import '../../models/audit_record.dart';
import '../../providers/audit_history_provider.dart';

/// Enterprise modal vault showing persisted SQLite audit runs searchable by
/// vendor name, with actions to reload past audits or directly export PDFs.
class AuditVaultDialog extends ConsumerStatefulWidget {
  const AuditVaultDialog({super.key});

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
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevate,
        content: Text(
          'Reloaded audit for ${record.vendorName} from Audit Vault.',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(auditHistoryProvider);
    final totalCount = historyAsync.asData?.value.length ?? 0;

    return Dialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.borderSubtle),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audit Vault & History',
                          style: AppTypography.titleMedium,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Local SQLite persistence • Reload past discrepancies or export formal notices',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.borderSubtle),
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
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search saved audits by vendor name, contract, or invoice...',
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
                  fillColor: AppColors.background,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    borderSide: const BorderSide(color: AppColors.sky),
                  ),
                ),
              ),
            ),

            // Records List Body
            Expanded(
              child: historyAsync.when(
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
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final record = filtered[index];
                      return _AuditVaultCard(
                        record: record,
                        isExporting: _exportingRecordId == record.id,
                        onReload: () => _handleReloadAudit(record),
                        onExportPdf: () => _handleExportPdf(record),
                        onDelete: () => ref
                            .read(auditHistoryProvider.notifier)
                            .deleteRecord(record.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
                  color: AppColors.surfaceElevate,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Icon(icon, size: 28, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: AppTypography.titleSmall),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: AppTypography.bodySmall,
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.vendorName,
                  style: AppTypography.titleSmall,
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
                    color: hasVariance ? AppColors.crimson : AppColors.emerald,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                color: AppColors.textMuted,
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
              Text(dateStr, style: AppTypography.bodySmall),
              const Text('•', style: TextStyle(color: AppColors.textMuted)),
              Text(
                '${findings.length} ${findings.length == 1 ? 'finding' : 'findings'}',
                style: AppTypography.monoCitation.copyWith(color: AppColors.sky),
              ),
              const Text('•', style: TextStyle(color: AppColors.textMuted)),
              Text(
                '${record.contractName}  |  ${record.invoiceName}',
                style: AppTypography.monoCitation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Invoiced: $invoicedStr',
                      style: AppTypography.bodySmall,
                    ),
                    Text(
                      'Contract Base: $baseStr',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onReload,
                icon: const Icon(Icons.restore_rounded, size: 14),
                label: const Text('Reload Past Audit'),
              ),
              const SizedBox(width: AppSpacing.xs),
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
          ),
        ],
      ),
    );
  }
}
