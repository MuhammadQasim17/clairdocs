import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../models/audit_models.dart';

class KpiSummaryCard extends StatelessWidget {
  final AuditResult result;

  const KpiSummaryCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final hasVariance = result.totalVarianceAmount > 0;
    final varianceColor = hasVariance ? AppColors.crimson : AppColors.emerald;
    final varianceBg = hasVariance ? AppColors.crimsonBg : AppColors.emeraldBg;

    final formattedVariance = CurrencyFormatter.formatVariance(
      result.totalVarianceAmount,
      currency: result.currency,
    );
    final formattedBilled = CurrencyFormatter.formatAmount(
      result.invoicedTotal,
      currency: result.currency,
    );
    final formattedBase = CurrencyFormatter.formatAmount(
      result.verifiedContractBase,
      currency: result.currency,
    );
    final pctLabel =
        '${result.variancePercentage >= 0 ? '+' : ''}${result.variancePercentage.toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevate,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'TOTAL DISPUTED VARIANCE',
                  style: AppTypography.labelMicro,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: varianceBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: varianceColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  pctLabel,
                  style: AppTypography.monoBadge.copyWith(
                    color: varianceColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formattedVariance,
            style: AppTypography.monoMetricLarge.copyWith(
              color: varianceColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Invoiced Total', style: AppTypography.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      formattedBilled,
                      style: AppTypography.monoValue,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                height: 24,
                width: 1,
                color: AppColors.borderSubtle,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Contract Base', style: AppTypography.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      formattedBase,
                      style: AppTypography.monoValue.copyWith(
                        color: AppColors.emerald,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
