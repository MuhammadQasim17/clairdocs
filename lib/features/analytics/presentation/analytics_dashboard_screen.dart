import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../history/providers/audit_history_provider.dart';
import '../models/analytics_summary.dart';
import '../providers/analytics_provider.dart';

/// Dedicated full-screen financial analytics and savings recovery dashboard
/// driven dynamically from local `clairdocs_vault.db` audit records.
class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  int _touchedBarIndex = -1;
  int _touchedPieIndex = -1;

  String _compactVendorAxisLabel(String vendor) {
    final clean = vendor.trim();
    if (clean.length <= 14) return clean;
    final words = clean.split(RegExp(r'\s+'));
    if (words.isNotEmpty && words.first.length >= 4) {
      final first = words.first;
      return first.length <= 13 ? first : '${first.substring(0, 12)}...';
    }
    return '${clean.substring(0, 12)}...';
  }

  String _compactCurrencyTick(double value) {
    if (value <= 0) return '\$0';
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      final k = value / 1000;
      return k % 1 == 0 ? '\$${k.toInt()}k' : '\$${k.toStringAsFixed(1)}k';
    }
    return '\$${value.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(auditAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Command Strip
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 15),
                    label: const Text('Back to Workbench'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: AppColors.emerald.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      size: 16,
                      color: AppColors.emerald,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analytics & Savings Dashboard',
                          style: AppTypography.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Financial recovery metrics & vendor risk intelligence from clairdocs_vault.db',
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(auditHistoryProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh_rounded, size: 15),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ),

            // Dashboard Body
            Expanded(
              child: analyticsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'Failed to load SQLite analytics: $err',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.crimson,
                      ),
                    ),
                  ),
                ),
                data: (summary) {
                  if (summary.totalAuditsPerformed == 0) {
                    return _buildEmptyDashboard(context);
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1360),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildKpiRow(summary),
                            const SizedBox(height: AppSpacing.lg),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth >= 880;
                                if (isWide) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 11,
                                        child: _buildTopVendorsBarCard(summary),
                                      ),
                                      const SizedBox(width: AppSpacing.lg),
                                      Expanded(
                                        flex: 9,
                                        child: _buildCategoryDonutCard(summary),
                                      ),
                                    ],
                                  );
                                }
                                return Column(
                                  children: [
                                    _buildTopVendorsBarCard(summary),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildCategoryDonutCard(summary),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
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

  Widget _buildEmptyDashboard(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderSubtle),
          ),
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
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 32,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No Historical Audit Data Yet',
                style: AppTypography.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Run an AI Audit on a contract and invoice pair (or test Demo Sample mode) to automatically record savings metrics into clairdocs_vault.db.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 15),
                label: const Text('Return to Audit Workbench'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiRow(AnalyticsSummary summary) {
    final withheldStr =
        CurrencyFormatter.formatUsd(summary.totalDollarsWithheld);
    final invoicedStr =
        CurrencyFormatter.formatUsd(summary.totalInvoicedVolume);
    final baseStr = CurrencyFormatter.formatUsd(summary.totalContractBase);
    final avgPctStr = '${summary.averageVariancePercentage.toStringAsFixed(1)}%';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final cards = [
          _AnalyticsKpiCard(
            label: 'TOTAL AUDITS PERFORMED',
            value: '${summary.totalAuditsPerformed}',
            subtitle: 'Invoiced volume: $invoicedStr',
            icon: Icons.fact_check_outlined,
            accentColor: AppColors.sky,
            badgeText: 'SQLITE VAULT',
          ),
          _AnalyticsKpiCard(
            label: 'TOTAL DOLLARS WITHHELD / RECOVERED',
            value: withheldStr,
            subtitle: 'Verified contract base: $baseStr',
            icon: Icons.savings_outlined,
            accentColor: AppColors.emerald,
            badgeText: 'NET SAVINGS',
          ),
          _AnalyticsKpiCard(
            label: 'AVERAGE VARIANCE PERCENTAGE',
            value: avgPctStr,
            subtitle: 'Mean overcharge across ${summary.totalAuditsPerformed} audits',
            icon: Icons.percent_rounded,
            accentColor: AppColors.amber,
            badgeText: 'OVERCHARGE RATE',
          ),
        ];

        if (isCompact) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: AppSpacing.md),
              cards[1],
              const SizedBox(height: AppSpacing.md),
              cards[2],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: cards[1]),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _buildTopVendorsBarCard(AnalyticsSummary summary) {
    final vendors = summary.topVendors;
    final rawMaxY = vendors.isEmpty
        ? 1000.0
        : vendors.map((v) => v.totalVariance).reduce(math.max);
    final maxY = rawMaxY <= 0 ? 1000.0 : rawMaxY * 1.22;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top 5 Overcharging Vendors',
                      style: AppTypography.titleMedium,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ranked by cumulative disputed billing variance',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.crimsonBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'TOP ${vendors.length} VENDORS',
                  style: AppTypography.monoBadge.copyWith(
                    color: AppColors.crimson,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 290,
            child: vendors.isEmpty
                ? const Center(
                    child: Text(
                      'No vendor variances recorded.',
                      style: AppTypography.bodySmall,
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: AppColors.borderSubtle,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          bottom: BorderSide(color: AppColors.borderSubtle),
                          left: BorderSide(color: AppColors.borderSubtle),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surfaceElevate,
                          tooltipRoundedRadius: 6,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final v = vendors[groupIndex];
                            final amt =
                                CurrencyFormatter.formatUsd(v.totalVariance);
                            return BarTooltipItem(
                              '${v.vendorName}\n',
                              const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '$amt (${v.auditCount} ${v.auditCount == 1 ? 'audit' : 'audits'})',
                                  style: const TextStyle(
                                    color: AppColors.crimson,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.spot == null) {
                              _touchedBarIndex = -1;
                              return;
                            }
                            _touchedBarIndex =
                                response.spot!.touchedBarGroupIndex;
                          });
                        },
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 54,
                            interval: maxY / 4,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 6,
                                child: Text(
                                  _compactCurrencyTick(value),
                                  style: AppTypography.monoCitation.copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= vendors.length) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8,
                                child: Text(
                                  _compactVendorAxisLabel(
                                    vendors[idx].vendorName,
                                  ),
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 10.5,
                                    color: _touchedBarIndex == idx
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < vendors.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: vendors[i].totalVariance,
                                width: 28,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: _touchedBarIndex == i
                                      ? const [
                                          AppColors.amber,
                                          AppColors.crimson,
                                        ]
                                      : const [
                                          AppColors.brandAccent,
                                          AppColors.crimson,
                                        ],
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: maxY,
                                  color: AppColors.surfaceElevate
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDonutCard(AnalyticsSummary summary) {
    final categories = summary.categoryBreakdown;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Variance Breakdown by Category',
                      style: AppTypography.titleMedium,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Share of disputed dollars by breach classification',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.skyBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '${categories.length} CATEGORIES',
                  style: AppTypography.monoBadge.copyWith(color: AppColors.sky),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (categories.isEmpty)
            const SizedBox(
              height: 290,
              child: Center(
                child: Text(
                  'No categorized findings recorded.',
                  style: AppTypography.bodySmall,
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 210,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: 50,
                          sectionsSpace: 3,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    response == null ||
                                    response.touchedSection == null) {
                                  _touchedPieIndex = -1;
                                  return;
                                }
                                _touchedPieIndex = response
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          sections: [
                            for (var i = 0; i < categories.length; i++)
                              PieChartSectionData(
                                color: categories[i].color,
                                value: categories[i].amount,
                                radius: _touchedPieIndex == i ? 48 : 40,
                                showTitle: categories[i].percentage >= 8,
                                title:
                                    '${categories[i].percentage.toStringAsFixed(0)}%',
                                titleStyle: const TextStyle(
                                  fontFamily: AppTypography.fontFamilySans,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'WITHHELD',
                            style: AppTypography.labelMicro,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _compactCurrencyTick(summary.totalDollarsWithheld),
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < categories.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: categories[i].color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            categories[i].label,
                            style: AppTypography.bodySmall.copyWith(
                              color: _touchedPieIndex == i
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: _touchedPieIndex == i
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${CurrencyFormatter.formatUsd(categories[i].amount)}  (${categories[i].percentage.toStringAsFixed(1)}%)',
                          style: AppTypography.monoCitation.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _AnalyticsKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String badgeText;

  const _AnalyticsKpiCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 15, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelMicro,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  badgeText,
                  style: AppTypography.monoBadge.copyWith(
                    color: accentColor,
                    fontSize: 8.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.monoMetricLarge.copyWith(
              fontSize: 26,
              color: accentColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTypography.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
