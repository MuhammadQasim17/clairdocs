import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../audit/models/audit_models.dart';
import '../../disputes/models/dispute_models.dart';
import '../../disputes/services/dispute_generator_service.dart';
import '../models/audit_record.dart';
import '../services/audit_database_service.dart';

final auditDatabaseServiceProvider = Provider<AuditDatabaseService>((ref) {
  final service = AuditDatabaseService();
  ref.onDispose(service.close);
  return service;
});

final auditHistoryProvider =
    AsyncNotifierProvider<AuditHistoryNotifier, List<AuditRecord>>(
  AuditHistoryNotifier.new,
);

class AuditHistoryNotifier extends AsyncNotifier<List<AuditRecord>> {
  static const _uuid = Uuid();

  @override
  Future<List<AuditRecord>> build() async {
    final db = ref.watch(auditDatabaseServiceProvider);
    return db.fetchAllAudits();
  }

  Future<void> refresh() async {
    final db = ref.read(auditDatabaseServiceProvider);
    state = const AsyncLoading();
    final next = await AsyncValue.guard(db.fetchAllAudits);
    if (!ref.mounted) return;
    state = next;
  }

  Future<void> saveAuditResult({
    required AuditResult result,
    required String contractName,
    required String invoiceName,
    String? noticeText,
  }) async {
    final db = ref.read(auditDatabaseServiceProvider);
    final resolvedVendor = _nonEmpty(result.vendorName) ??
        _vendorFallbackFromFileName(invoiceName);
    final resolvedContract = _nonEmpty(result.contractReference) ?? contractName;
    final resolvedInvoice = _nonEmpty(result.invoiceNumber) ?? invoiceName;
    final resolvedClient =
        _nonEmpty(result.clientName) ?? 'Enterprise Finance & Procurement';

    final generatedNotice = (noticeText != null && noticeText.trim().isNotEmpty)
        ? noticeText
        : DisputeGeneratorService().generateFallbackNotice(
            result,
            DisputeTone.firmLegal,
            contractReference: resolvedContract,
            invoiceReference: resolvedInvoice,
            vendorName: resolvedVendor,
            clientName: resolvedClient,
          );

    final record = AuditRecord(
      id: _uuid.v4(),
      timestamp: DateTime.now().toIso8601String(),
      contractName: resolvedContract,
      invoiceName: resolvedInvoice,
      vendorName: resolvedVendor,
      invoicedTotal: result.invoicedTotal,
      contractBase: result.verifiedContractBase,
      totalVariance: result.totalVarianceAmount,
      findingsJson: jsonEncode(
        result.findings.map((f) => f.toJson()).toList(growable: false),
      ),
      noticeText: generatedNotice,
    );

    await db.saveAuditRecord(record);
    if (!ref.mounted) return;
    final updated = await db.fetchAllAudits();
    if (!ref.mounted) return;
    state = AsyncData(updated);
  }

  Future<void> deleteRecord(String id) async {
    final db = ref.read(auditDatabaseServiceProvider);
    await db.deleteAuditRecord(id);
    if (!ref.mounted) return;
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(
        current.where((r) => r.id != id).toList(growable: false),
      );
    } else {
      final updated = await db.fetchAllAudits();
      if (!ref.mounted) return;
      state = AsyncData(updated);
    }
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
  }

  String _vendorFallbackFromFileName(String fileName) {
    final cleaned = fileName
        .replaceAll(RegExp(r'\.[^.]+$'), '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
    return cleaned.isEmpty ? 'Vendor Accounts Receivable' : cleaned;
  }
}
