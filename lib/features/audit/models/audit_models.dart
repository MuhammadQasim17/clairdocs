import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_models.freezed.dart';
part 'audit_models.g.dart';

@freezed
abstract class AuditResult with _$AuditResult {
  @JsonSerializable(explicitToJson: true)
  const factory AuditResult({
    @Default('USD') String currency,
    required double totalVarianceAmount,
    required double invoicedTotal,
    required double verifiedContractBase,
    required double variancePercentage,
    @Default([]) List<AuditFinding> findings,
    @Default('Gemini 3.8') String auditEngine,
    String? vendorName,
    String? vendorEmail,
    String? clientName,
    String? invoiceNumber,
    String? contractReference,
  }) = _AuditResult;

  factory AuditResult.fromJson(Map<String, dynamic> json) =>
      _$AuditResultFromJson(json);

  factory AuditResult.demoSample() => const AuditResult(
        currency: 'USD',
        totalVarianceAmount: 4850.00,
        invoicedTotal: 48250.00,
        verifiedContractBase: 43400.00,
        variancePercentage: 11.2,
        auditEngine: 'Gemini 3.8',
        vendorName: 'Apex Technologies Inc.',
        vendorEmail: 'billing@apextech.io',
        clientName: 'ClairDocs Enterprise Procurement',
        invoiceNumber: 'INV-2026-889',
        contractReference: 'MSA-2026-APEX',
        findings: [
          AuditFinding(
            id: 'finding-01',
            title: 'Rate Overcharge: Lead Cloud Architect',
            category: 'rate_breach',
            description:
                'Vendor invoiced 120 hours at \$210.00/hr, exceeding the contractual rate cap of \$185.00/hr without written procurement authorization.',
            clauseReference: 'Section 4.2 (Exhibit B)',
            invoiceLineReference: 'Line Item #01',
            searchKeyword: 'Lead Cloud Architect',
            agreedRate: 185.00,
            billedRate: 210.00,
            varianceAmount: 3000.00,
            severity: 'high',
          ),
          AuditFinding(
            id: 'finding-02',
            title: 'Unapproved First-Class Airfare & Transit',
            category: 'unapproved_expense',
            description:
                'Domestic airfare billed for premium cabin travel. Governing agreement restricts reimbursable travel strictly to standard economy class.',
            clauseReference: 'Section 9.1 (Travel Policy)',
            invoiceLineReference: 'Line Item #03',
            searchKeyword: 'First-Class',
            agreedRate: 0.00,
            billedRate: 1250.00,
            varianceAmount: 1250.00,
            severity: 'high',
          ),
          AuditFinding(
            id: 'finding-03',
            title: 'Omitted 5% Quarterly Volume Discount',
            category: 'term_mismatch',
            description:
                'Cumulative quarterly billing exceeded \$40,000 threshold, triggering a mandatory 5% volume rebate that was omitted from invoice subtotal.',
            clauseReference: 'Section 12.3 (Volume Rebates)',
            invoiceLineReference: 'Line Item #05',
            searchKeyword: 'Volume Rebate',
            agreedRate: null,
            billedRate: null,
            varianceAmount: 600.00,
            severity: 'medium',
          ),
        ],
      );
}

@freezed
abstract class AuditFinding with _$AuditFinding {
  const factory AuditFinding({
    required String id,
    required String title,
    required String category,
    required String description,
    required String clauseReference,
    required String invoiceLineReference,
    String? searchKeyword,
    double? agreedRate,
    double? billedRate,
    required double varianceAmount,
    required String severity,
  }) = _AuditFinding;

  factory AuditFinding.fromJson(Map<String, dynamic> json) =>
      _$AuditFindingFromJson(json);
}
