import 'dart:convert';
import '../../audit/models/audit_models.dart';
import '../../disputes/models/dispute_models.dart';

/// Persistent local SQLite record for a completed contract-vs-invoice audit.
class AuditRecord {
  final String id;
  final String timestamp;
  final String contractName;
  final String invoiceName;
  final String vendorName;
  final double invoicedTotal;
  final double contractBase;
  final double totalVariance;
  final String findingsJson;
  final String noticeText;

  const AuditRecord({
    required this.id,
    required this.timestamp,
    required this.contractName,
    required this.invoiceName,
    required this.vendorName,
    required this.invoicedTotal,
    required this.contractBase,
    required this.totalVariance,
    required this.findingsJson,
    required this.noticeText,
  });

  factory AuditRecord.fromMap(Map<String, Object?> map) {
    return AuditRecord(
      id: (map['id'] as String?) ?? '',
      timestamp: (map['timestamp'] as String?) ?? '',
      contractName: (map['contract_name'] as String?) ?? 'Contract Document',
      invoiceName: (map['invoice_name'] as String?) ?? 'Vendor Invoice',
      vendorName: (map['vendor_name'] as String?) ?? 'Unknown Vendor',
      invoicedTotal: (map['invoiced_total'] as num?)?.toDouble() ?? 0.0,
      contractBase: (map['contract_base'] as num?)?.toDouble() ?? 0.0,
      totalVariance: (map['total_variance'] as num?)?.toDouble() ?? 0.0,
      findingsJson: (map['findings_json'] as String?) ?? '[]',
      noticeText: (map['notice_text'] as String?) ?? '',
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'timestamp': timestamp,
      'contract_name': contractName,
      'invoice_name': invoiceName,
      'vendor_name': vendorName,
      'invoiced_total': invoicedTotal,
      'contract_base': contractBase,
      'total_variance': totalVariance,
      'findings_json': findingsJson,
      'notice_text': noticeText,
    };
  }

  DateTime? get parsedTimestamp => DateTime.tryParse(timestamp);

  List<AuditFinding> decodeFindings() {
    try {
      final decoded = jsonDecode(findingsJson);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((raw) => AuditFinding.fromJson(Map<String, dynamic>.from(raw)))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Rebuilds a full [AuditResult] so a historical vault entry can be reloaded
  /// seamlessly into the Discrepancy & Action Studio.
  AuditResult toAuditResult() {
    final findings = decodeFindings();
    final variancePct =
        contractBase > 0 ? (totalVariance / contractBase) * 100.0 : 0.0;
    return AuditResult(
      currency: 'USD',
      totalVarianceAmount: totalVariance,
      invoicedTotal: invoicedTotal,
      verifiedContractBase: contractBase,
      variancePercentage: double.parse(variancePct.toStringAsFixed(1)),
      findings: findings,
      auditEngine: 'Audit Vault',
      vendorName: vendorName,
      clientName: 'Enterprise Finance & Procurement',
      invoiceNumber: invoiceName,
      contractReference: contractName,
    );
  }

  /// Rebuilds a [DisputeState] ready for direct PDF export or Studio editing.
  DisputeState toDisputeState({AuditResult? auditResult}) {
    final resolvedAudit = auditResult ?? toAuditResult();
    return DisputeState(
      status: DisputeGenerationStatus.ready,
      tone: DisputeTone.firmLegal,
      draftText: noticeText,
      vendorName: vendorName,
      clientName: resolvedAudit.clientName ?? 'Enterprise Finance & Procurement',
      invoiceReference: invoiceName,
      contractReference: contractName,
      totalWithheld: totalVariance,
      totalInvoiced: invoicedTotal,
      approvedPayment: contractBase,
      currency: resolvedAudit.currency,
      usedFallback: true,
      isRefiningWithAi: false,
      draftEngine: 'AUDIT VAULT RECORD',
      sourceAuditResult: resolvedAudit,
    );
  }
}
