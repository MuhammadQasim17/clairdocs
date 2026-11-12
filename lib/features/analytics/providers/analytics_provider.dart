import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../history/providers/audit_history_provider.dart';
import '../models/analytics_summary.dart';

/// Reactive analytics summary automatically computed from SQLite Vault history.
final auditAnalyticsProvider = Provider<AsyncValue<AnalyticsSummary>>((ref) {
  final historyAsync = ref.watch(auditHistoryProvider);
  return historyAsync.whenData(AnalyticsSummary.fromRecords);
});
