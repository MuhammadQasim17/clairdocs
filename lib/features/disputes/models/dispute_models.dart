import 'package:freezed_annotation/freezed_annotation.dart';
import '../../audit/models/audit_models.dart';

part 'dispute_models.freezed.dart';

enum DisputeTone {
  firmLegal(
    'Firm Legal',
    'Adopt an authoritative, formal corporate legal tone emphasizing contractual compliance, audit rights, and strict reservation of remedies.',
  ),
  collaborativePartner(
    'Collaborative Partner',
    'Adopt a professional, constructive partner tone seeking swift billing reconciliation while preserving the ongoing vendor relationship.',
  ),
  strictBreach(
    'Strict Breach',
    'Adopt an urgent, uncompromising formal breach notice tone demanding immediate credit memo issuance and warning of payment hold escalation.',
  );

  final String label;
  final String promptDirective;

  const DisputeTone(this.label, this.promptDirective);
}

enum DisputeGenerationStatus {
  idle,
  generating,
  ready,
  error,
}

@freezed
abstract class DisputeState with _$DisputeState {
  const factory DisputeState({
    @Default(DisputeGenerationStatus.idle) DisputeGenerationStatus status,
    @Default(DisputeTone.firmLegal) DisputeTone tone,
    @Default('') String draftText,
    @Default('Vendor Accounts Receivable') String vendorName,
    @Default('') String vendorEmail,
    @Default('Enterprise Finance & Procurement') String clientName,
    @Default('INV-2026-889') String invoiceReference,
    @Default('Master Services Agreement') String contractReference,
    @Default(0.0) double totalWithheld,
    @Default(0.0) double totalInvoiced,
    @Default(0.0) double approvedPayment,
    @Default('USD') String currency,
    @Default(false) bool usedFallback,
    @Default(false) bool isRefiningWithAi,
    @Default('GEMINI 3.8 LEGAL DRAFT') String draftEngine,
    @Default(false) bool isExportingPdf,
    String? errorMessage,
    AuditResult? sourceAuditResult,
  }) = _DisputeState;
}
