import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/selectable_audit_card.dart';
import '../../models/audit_models.dart';

enum DiscrepancyCardSeverity {
  breach,
  warning,
  info,
}

class DiscrepancyItemCard extends StatelessWidget {
  final String title;
  final String category;
  final String clauseCitation;
  final String lineReference;
  final String varianceAmount;
  final String explanation;
  final String? rateComparisonText;
  final DiscrepancyCardSeverity severity;
  final bool isSelected;
  final VoidCallback? onTap;

  const DiscrepancyItemCard({
    super.key,
    required this.title,
    this.category = 'discrepancy',
    required this.clauseCitation,
    required this.lineReference,
    required this.varianceAmount,
    required this.explanation,
    this.rateComparisonText,
    this.severity = DiscrepancyCardSeverity.breach,
    this.isSelected = false,
    this.onTap,
  });

  factory DiscrepancyItemCard.fromFinding({
    Key? key,
    required AuditFinding finding,
    String currency = 'USD',
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    final mappedSeverity = switch (finding.severity.toLowerCase()) {
      'high' => DiscrepancyCardSeverity.breach,
      'medium' => DiscrepancyCardSeverity.warning,
      _ => DiscrepancyCardSeverity.info,
    };

    String? rateText;
    if (finding.agreedRate != null && finding.billedRate != null) {
      final agreed = CurrencyFormatter.formatAmount(
        finding.agreedRate!,
        currency: currency,
      );
      final billed = CurrencyFormatter.formatAmount(
        finding.billedRate!,
        currency: currency,
      );
      rateText = 'Agreed: $agreed  →  Billed: $billed';
    }

    return DiscrepancyItemCard(
      key: key,
      title: finding.title,
      category: finding.category,
      clauseCitation: finding.clauseReference,
      lineReference: finding.invoiceLineReference,
      varianceAmount: CurrencyFormatter.formatVariance(
        finding.varianceAmount,
        currency: currency,
      ),
      explanation: finding.description,
      rateComparisonText: rateText,
      severity: mappedSeverity,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  Color get _severityColor {
    switch (severity) {
      case DiscrepancyCardSeverity.breach:
        return AppColors.crimson;
      case DiscrepancyCardSeverity.warning:
        return AppColors.amber;
      case DiscrepancyCardSeverity.info:
        return AppColors.sky;
    }
  }

  Color get _severityBg {
    switch (severity) {
      case DiscrepancyCardSeverity.breach:
        return AppColors.crimsonBg;
      case DiscrepancyCardSeverity.warning:
        return AppColors.amberBg;
      case DiscrepancyCardSeverity.info:
        return AppColors.skyBg;
    }
  }

  String get _severityLabel {
    switch (severity) {
      case DiscrepancyCardSeverity.breach:
        return 'HIGH';
      case DiscrepancyCardSeverity.warning:
        return 'MEDIUM';
      case DiscrepancyCardSeverity.info:
        return 'LOW';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SelectableAuditCard(
      isSelected: isSelected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _severityBg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    _severityLabel,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamilySans,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _severityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.article_outlined,
                  size: 13,
                  color: AppColors.sky,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    clauseCitation,
                    style: AppTypography.monoCitation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text('•', style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    lineReference,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (rateComparisonText != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  rateComparisonText!,
                  style: AppTypography.monoCitation.copyWith(
                    fontSize: 10,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              explanation,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      category.toUpperCase().replaceAll('_', ' '),
                      style: AppTypography.labelMicro.copyWith(fontSize: 9),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  varianceAmount,
                  style: AppTypography.monoValue.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _severityColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
