import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../history/models/audit_record.dart';

class VendorVarianceStat {
  final String vendorName;
  final double totalVariance;
  final double invoicedTotal;
  final int auditCount;

  const VendorVarianceStat({
    required this.vendorName,
    required this.totalVariance,
    required this.invoicedTotal,
    required this.auditCount,
  });
}

class CategoryVarianceStat {
  final String categoryKey;
  final String label;
  final double amount;
  final double percentage;
  final Color color;

  const CategoryVarianceStat({
    required this.categoryKey,
    required this.label,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

/// Aggregated KPI and chart dataset derived from local SQLite [AuditRecord]s.
class AnalyticsSummary {
  final int totalAuditsPerformed;
  final double totalDollarsWithheld;
  final double totalInvoicedVolume;
  final double totalContractBase;
  final double averageVariancePercentage;
  final List<VendorVarianceStat> topVendors;
  final List<CategoryVarianceStat> categoryBreakdown;

  const AnalyticsSummary({
    required this.totalAuditsPerformed,
    required this.totalDollarsWithheld,
    required this.totalInvoicedVolume,
    required this.totalContractBase,
    required this.averageVariancePercentage,
    required this.topVendors,
    required this.categoryBreakdown,
  });

  factory AnalyticsSummary.fromRecords(List<AuditRecord> records) {
    if (records.isEmpty) {
      return const AnalyticsSummary(
        totalAuditsPerformed: 0,
        totalDollarsWithheld: 0.0,
        totalInvoicedVolume: 0.0,
        totalContractBase: 0.0,
        averageVariancePercentage: 0.0,
        topVendors: [],
        categoryBreakdown: [],
      );
    }

    var totalWithheld = 0.0;
    var totalInvoiced = 0.0;
    var totalBase = 0.0;
    var variancePctSum = 0.0;

    final vendorBuckets = <String, _MutableVendorBucket>{};
    final categoryTotals = <String, double>{};

    for (final record in records) {
      totalWithheld += record.totalVariance;
      totalInvoiced += record.invoicedTotal;
      totalBase += record.contractBase;

      final recordPct = record.contractBase > 0
          ? (record.totalVariance / record.contractBase) * 100.0
          : (record.invoicedTotal > 0
              ? (record.totalVariance / record.invoicedTotal) * 100.0
              : 0.0);
      variancePctSum += recordPct;

      final vendorKey = record.vendorName.trim().isEmpty
          ? 'Unknown Vendor'
          : record.vendorName.trim();
      final bucket = vendorBuckets.putIfAbsent(
        vendorKey,
        () => _MutableVendorBucket(vendorKey),
      );
      bucket.totalVariance += record.totalVariance;
      bucket.invoicedTotal += record.invoicedTotal;
      bucket.auditCount += 1;

      final findings = record.decodeFindings();
      var findingsSum = 0.0;
      for (final finding in findings) {
        final normalizedCat = _normalizeCategoryKey(finding.category);
        final amt = finding.varianceAmount;
        if (amt > 0) {
          categoryTotals[normalizedCat] =
              (categoryTotals[normalizedCat] ?? 0.0) + amt;
          findingsSum += amt;
        }
      }

      if (findings.isEmpty && record.totalVariance > 0) {
        categoryTotals['general_variance'] =
            (categoryTotals['general_variance'] ?? 0.0) + record.totalVariance;
      } else if (record.totalVariance - findingsSum > 0.01 &&
          findingsSum == 0) {
        categoryTotals['general_variance'] =
            (categoryTotals['general_variance'] ?? 0.0) + record.totalVariance;
      }
    }

    final vendors = vendorBuckets.values
        .map(
          (b) => VendorVarianceStat(
            vendorName: b.vendorName,
            totalVariance: b.totalVariance,
            invoicedTotal: b.invoicedTotal,
            auditCount: b.auditCount,
          ),
        )
        .toList()
      ..sort((a, b) => b.totalVariance.compareTo(a.totalVariance));

    final top5Vendors = vendors.take(5).toList(growable: false);

    final categorySum =
        categoryTotals.values.fold<double>(0.0, (prev, val) => prev + val);
    final categories = categoryTotals.entries.map((entry) {
      final pct = categorySum > 0 ? (entry.value / categorySum) * 100.0 : 0.0;
      return CategoryVarianceStat(
        categoryKey: entry.key,
        label: _labelForCategory(entry.key),
        amount: entry.value,
        percentage: pct,
        color: _colorForCategory(entry.key),
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return AnalyticsSummary(
      totalAuditsPerformed: records.length,
      totalDollarsWithheld: totalWithheld,
      totalInvoicedVolume: totalInvoiced,
      totalContractBase: totalBase,
      averageVariancePercentage: variancePctSum / records.length,
      topVendors: top5Vendors,
      categoryBreakdown: categories,
    );
  }

  static String _normalizeCategoryKey(String raw) {
    final lower = raw.trim().toLowerCase();
    return switch (lower) {
      'rate_breach' || 'rate_overcharge' => 'rate_breach',
      'unapproved_expense' || 'travel_expense' => 'unapproved_expense',
      'hour_cap_exceeded' || 'overtime_surcharge' => 'hour_cap_exceeded',
      'term_mismatch' => 'term_mismatch',
      '' => 'general_variance',
      _ => lower,
    };
  }

  static String _labelForCategory(String key) {
    return switch (key) {
      'rate_breach' => 'Hourly Rate Breaches',
      'unapproved_expense' => 'Unapproved Travel & Expenses',
      'hour_cap_exceeded' => 'Overtime & Hour Caps',
      'term_mismatch' => 'Term & Rebate Mismatches',
      'general_variance' => 'Other Billing Variances',
      _ => key
          .split('_')
          .where((s) => s.isNotEmpty)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' '),
    };
  }

  static Color _colorForCategory(String key) {
    return switch (key) {
      'rate_breach' => AppColors.crimson,
      'unapproved_expense' => AppColors.amber,
      'hour_cap_exceeded' => AppColors.brandAccent,
      'term_mismatch' => AppColors.sky,
      'general_variance' => AppColors.emerald,
      _ => const Color(0xFFEC4899),
    };
  }
}

class _MutableVendorBucket {
  final String vendorName;
  double totalVariance = 0.0;
  double invoicedTotal = 0.0;
  int auditCount = 0;

  _MutableVendorBucket(this.vendorName);
}
