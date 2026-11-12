import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/selectable_audit_card.dart';
import '../../models/audit_models.dart';

class RateComparisonCard extends StatelessWidget {
  final AuditFinding finding;
  final String currency;
  final bool isSelected;
  final VoidCallback? onTap;

  const RateComparisonCard({
    super.key,
    required this.finding,
    this.currency = 'USD',
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final agreed = finding.agreedRate ?? 0.0;
    final billed = finding.billedRate ?? 0.0;
    final delta = billed - agreed;

    final agreedStr =
        '${CurrencyFormatter.formatAmount(agreed, currency: currency)}/unit';
    final billedStr =
        '${CurrencyFormatter.formatAmount(billed, currency: currency)}/unit';
    final deltaStr = CurrencyFormatter.formatVariance(delta, currency: currency);

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
                  finding.title,
                  style: AppTypography.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 118),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.crimsonBg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    finding.category.toUpperCase().replaceAll('_', ' '),
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamilySans,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.crimson,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.bookmark_outline_rounded,
                size: 13,
                color: AppColors.sky,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  finding.clauseReference,
                  style: AppTypography.monoCitation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  finding.invoiceLineReference,
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Agreed Cap', style: AppTypography.labelMicro),
                      const SizedBox(height: 2),
                      Text(
                        agreedStr,
                        style: AppTypography.monoValue.copyWith(
                          color: AppColors.emerald,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.textMuted,
                  size: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Billed Rate', style: AppTypography.labelMicro),
                      const SizedBox(height: 2),
                      Text(
                        billedStr,
                        style: AppTypography.monoValue.copyWith(
                          color: AppColors.crimson,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.crimsonBg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    deltaStr,
                    style: AppTypography.monoBadge.copyWith(
                      color: AppColors.crimson,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
