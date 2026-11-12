import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audit/models/audit_models.dart';
import '../../audit/providers/audit_provider.dart';
import '../../contracts/models/contract_document.dart';
import '../../contracts/providers/contract_providers.dart';
import '../../history/models/audit_record.dart';
import '../../invoices/models/invoice_document.dart';
import '../../invoices/providers/invoice_providers.dart';
import '../models/dispute_models.dart';
import '../services/dispute_dispatch_service.dart';
import '../services/dispute_generator_service.dart';
import '../services/dispute_pdf_exporter.dart';

export '../../audit/providers/audit_provider.dart'
    show secureStorageServiceProvider;

final disputeGeneratorServiceProvider = Provider<DisputeGeneratorService>((ref) {
  return DisputeGeneratorService(
    auditService: ref.read(geminiAuditServiceProvider),
    groqService: ref.read(groqAuditServiceProvider),
  );
});

final disputePdfExporterProvider = Provider<DisputePdfExporter>((ref) {
  return const DisputePdfExporter();
});

final disputeDispatchServiceProvider = Provider<DisputeDispatchService>((ref) {
  return DisputeDispatchService(
    pdfExporter: ref.read(disputePdfExporterProvider),
    secureStorage: ref.read(secureStorageServiceProvider),
  );
});

final disputeProvider = NotifierProvider<DisputeNotifier, DisputeState>(
  DisputeNotifier.new,
);

class DisputeNotifier extends Notifier<DisputeState> {
  int _generationSeq = 0;

  @override
  DisputeState build() {
    ref.onDispose(() => _generationSeq++);

    ref.listen<AsyncValue<AuditResult?>>(auditProvider, (prev, next) {
      final prevResult = prev?.asData?.value;
      final nextResult = next.asData?.value;
      if (next is AsyncLoading || (prevResult != null && nextResult == null)) {
        reset();
      }
    });

    ref.listen<ContractState>(contractDocumentProvider, (prev, next) {
      if (prev?.document?.id != next.document?.id ||
          prev?.document?.filePath != next.document?.filePath ||
          prev?.isDemoMode != next.isDemoMode) {
        reset();
      }
    });

    ref.listen<InvoiceState>(invoiceDocumentProvider, (prev, next) {
      if (prev?.document?.id != next.document?.id ||
          prev?.document?.filePath != next.document?.filePath ||
          prev?.isDemoMode != next.isDemoMode) {
        reset();
      }
    });

    return const DisputeState();
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
  }

  ({
    String vendorName,
    String vendorEmail,
    String clientName,
    String contractRef,
    String invoiceRef,
  }) _resolveParties(AuditResult auditResult) {
    final contractDoc = ref.read(contractDocumentProvider).document;
    final invoiceDoc = ref.read(invoiceDocumentProvider).document;

    final contractRef = _nonEmpty(auditResult.contractReference) ??
        contractDoc?.fileName ??
        'Master_Services_Agreement_2026.pdf';
    final invoiceRef = _nonEmpty(auditResult.invoiceNumber) ??
        invoiceDoc?.fileName ??
        'INV-2026-889';
    final vendorName = _nonEmpty(auditResult.vendorName) ??
        (invoiceDoc != null
            ? _formatVendorName(invoiceDoc.fileName)
            : 'Apex Technologies Inc.');
    final vendorEmail = _nonEmpty(auditResult.vendorEmail) ?? '';
    final clientName = _nonEmpty(auditResult.clientName) ??
        'Enterprise Finance & Procurement';

    return (
      vendorName: vendorName,
      vendorEmail: vendorEmail,
      clientName: clientName,
      contractRef: contractRef,
      invoiceRef: invoiceRef,
    );
  }

  /// Synchronously renders an instant local dispute notice for [selectedTone]
  /// (`0 ms` delay, zero LLM network calls).
  void _applyInstantTemplate(AuditResult auditResult, DisputeTone selectedTone) {
    final parties = _resolveParties(auditResult);

    final generator = ref.read(disputeGeneratorServiceProvider);
    final instantNotice = generator.generateFallbackNotice(
      auditResult,
      selectedTone,
      contractReference: parties.contractRef,
      invoiceReference: parties.invoiceRef,
      vendorName: parties.vendorName,
      clientName: parties.clientName,
    );

    state = state.copyWith(
      status: DisputeGenerationStatus.ready,
      tone: selectedTone,
      draftText: instantNotice,
      vendorName: parties.vendorName,
      vendorEmail: parties.vendorEmail,
      clientName: parties.clientName,
      invoiceReference: parties.invoiceRef,
      contractReference: parties.contractRef,
      totalWithheld: auditResult.totalVarianceAmount,
      totalInvoiced: auditResult.invoicedTotal,
      approvedPayment: auditResult.verifiedContractBase,
      currency: auditResult.currency,
      usedFallback: true,
      isRefiningWithAi: false,
      draftEngine: 'INSTANT TEMPLATE DRAFT',
      sourceAuditResult: auditResult,
      errorMessage: null,
    );
  }

  /// Restores saved dispute notice text & metadata when reloading an [AuditRecord].
  void loadHistoricalDispute(AuditRecord record, AuditResult auditResult) {
    _generationSeq++;
    state = record.toDisputeState(auditResult: auditResult);
  }

  /// Opens the Interactive Dispute Studio immediately using local template generation.
  void generateDraft({DisputeTone? tone}) {
    final auditResult = ref.read(auditProvider).asData?.value;
    if (auditResult == null) {
      state = state.copyWith(
        status: DisputeGenerationStatus.error,
        errorMessage: 'No active audit result available to draft a dispute notice.',
      );
      return;
    }

    if (tone == null &&
        state.status == DisputeGenerationStatus.ready &&
        state.draftText.isNotEmpty &&
        state.sourceAuditResult == auditResult) {
      return;
    }

    _generationSeq++;
    _applyInstantTemplate(auditResult, tone ?? state.tone);
  }

  /// Switches dispute tone synchronously with local template rendering (`0 ms`).
  void switchTone(DisputeTone tone) {
    final auditResult =
        ref.read(auditProvider).asData?.value ?? state.sourceAuditResult;
    if (auditResult == null) return;

    _generationSeq++;
    _applyInstantTemplate(auditResult, tone);
  }

  /// Explicitly invokes LLM refinement/regeneration when user taps "Regenerate" / "AI Refine".
  Future<void> regenerateWithAi({DisputeTone? tone}) async {
    final auditResult =
        ref.read(auditProvider).asData?.value ?? state.sourceAuditResult;
    if (auditResult == null) {
      state = state.copyWith(
        status: DisputeGenerationStatus.error,
        errorMessage: 'No active audit result available to refine with AI.',
      );
      return;
    }

    final requestSeq = ++_generationSeq;
    final selectedTone = tone ?? state.tone;
    final contractDoc = ref.read(contractDocumentProvider).document;
    final invoiceDoc = ref.read(invoiceDocumentProvider).document;
    final parties = _resolveParties(auditResult);

    state = state.copyWith(
      status: DisputeGenerationStatus.ready,
      tone: selectedTone,
      vendorName: parties.vendorName,
      vendorEmail: parties.vendorEmail,
      clientName: parties.clientName,
      invoiceReference: parties.invoiceRef,
      contractReference: parties.contractRef,
      totalWithheld: auditResult.totalVarianceAmount,
      totalInvoiced: auditResult.invoicedTotal,
      approvedPayment: auditResult.verifiedContractBase,
      currency: auditResult.currency,
      isRefiningWithAi: true,
      sourceAuditResult: auditResult,
      errorMessage: null,
    );

    try {
      final generator = ref.read(disputeGeneratorServiceProvider);
      final generated = await generator.generateDisputeNotice(
        auditResult: auditResult,
        contractDoc: contractDoc,
        invoiceDoc: invoiceDoc,
        tone: selectedTone,
        vendorNameOverride: parties.vendorName,
        clientNameOverride: parties.clientName,
      );

      if (!ref.mounted || _generationSeq != requestSeq) {
        return;
      }

      state = state.copyWith(
        status: DisputeGenerationStatus.ready,
        draftText: generated.letterText,
        usedFallback: generated.usedFallback,
        isRefiningWithAi: false,
        draftEngine: generated.engineLabel,
        errorMessage: null,
      );
    } catch (_) {
      if (ref.mounted && _generationSeq == requestSeq) {
        state = state.copyWith(
          isRefiningWithAi: false,
        );
      }
    }
  }

  void cancelAiRefine() {
    _generationSeq++;
    if (state.isRefiningWithAi) {
      state = state.copyWith(isRefiningWithAi: false);
    }
  }

  void updateDraftText(String text) {
    state = state.copyWith(draftText: text);
  }

  void updateVendorName(String vendorName) {
    state = state.copyWith(vendorName: vendorName);
  }

  Future<Uri?> exportPdf() async {
    state = state.copyWith(isExportingPdf: true, errorMessage: null);
    try {
      final exporter = ref.read(disputePdfExporterProvider);
      final savedUri = await exporter.exportAndSavePdf(disputeState: state);
      if (!ref.mounted) return savedUri;
      state = state.copyWith(isExportingPdf: false);
      return savedUri;
    } catch (e) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        isExportingPdf: false,
        errorMessage: 'Failed to export PDF: $e',
      );
      return null;
    }
  }

  void reset() {
    _generationSeq++;
    if (state == const DisputeState()) return;
    state = const DisputeState();
  }

  String _formatVendorName(String fileName) {
    final cleaned = fileName
        .replaceAll(
          RegExp(r'\.(pdf|docx|doc|csv|xlsx|xls)$', caseSensitive: false),
          '',
        )
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
    return cleaned.isEmpty ? 'Vendor Accounts Receivable' : cleaned;
  }
}

