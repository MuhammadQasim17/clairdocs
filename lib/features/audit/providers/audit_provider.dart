import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../contracts/models/contract_document.dart';
import '../../contracts/providers/contract_providers.dart';
import '../../history/models/audit_record.dart';
import '../../history/providers/audit_history_provider.dart';
import '../../invoices/models/invoice_document.dart';
import '../../invoices/providers/invoice_providers.dart';
import '../models/audit_models.dart';
import '../services/gemini_audit_service.dart';
import '../services/groq_audit_service.dart';
import '../services/pdf_extraction_service.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService();
});

final apiKeyProvider = NotifierProvider<ApiKeyNotifier, String?>(
  ApiKeyNotifier.new,
);

class ApiKeyNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setKey(String? key) => state = key?.trim();
}

final groqApiKeyProvider = NotifierProvider<GroqApiKeyNotifier, String?>(
  GroqApiKeyNotifier.new,
);

class GroqApiKeyNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setKey(String? key) => state = key?.trim();
}

final auditStatusMessageProvider =
    NotifierProvider<AuditStatusMessageNotifier, String?>(
  AuditStatusMessageNotifier.new,
);

class AuditStatusMessageNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setMessage(String? message) => state = message;
}

final findingHighlightSequenceProvider =
    NotifierProvider<FindingHighlightSequenceNotifier, int>(
  FindingHighlightSequenceNotifier.new,
);

class FindingHighlightSequenceNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final activeSelectedFindingProvider =
    NotifierProvider<ActiveSelectedFindingNotifier, AuditFinding?>(
  ActiveSelectedFindingNotifier.new,
);

class ActiveSelectedFindingNotifier extends Notifier<AuditFinding?> {
  @override
  AuditFinding? build() => null;

  void selectFinding(AuditFinding? finding) {
    state = finding;
    if (finding != null) {
      ref.read(findingHighlightSequenceProvider.notifier).bump();
    }
  }

  void clear() => state = null;
}

final auditCooldownProvider = NotifierProvider<AuditCooldownNotifier, int>(
  AuditCooldownNotifier.new,
);

class AuditCooldownNotifier extends Notifier<int> {
  Timer? _timer;

  @override
  int build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    return 0;
  }

  void startCooldown({int seconds = 3}) {
    _timer?.cancel();
    state = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!ref.mounted) {
        timer.cancel();
        _timer = null;
        return;
      }
      if (state <= 1) {
        timer.cancel();
        _timer = null;
        state = 0;
      } else {
        state = state - 1;
      }
    });
  }
}

final pdfExtractionServiceProvider = Provider<PdfExtractionService>((ref) {
  return const PdfExtractionService();
});

final groqAuditServiceProvider = Provider<GroqAuditService>((ref) {
  return GroqAuditService(
    secureStorage: ref.read(secureStorageServiceProvider),
    inAppKeyReader: () => ref.read(groqApiKeyProvider),
  );
});

final geminiAuditServiceProvider = Provider<GeminiAuditService>((ref) {
  return GeminiAuditService(
    secureStorage: ref.read(secureStorageServiceProvider),
    inAppKeyReader: () => ref.read(apiKeyProvider),
    pdfExtractor: ref.read(pdfExtractionServiceProvider),
    groqService: ref.read(groqAuditServiceProvider),
  );
});

final auditProvider = AsyncNotifierProvider<AuditNotifier, AuditResult?>(
  AuditNotifier.new,
);

class AuditNotifier extends AsyncNotifier<AuditResult?> {
  int _auditRunSeq = 0;

  @override
  FutureOr<AuditResult?> build() {
    ref.listen<ContractState>(contractDocumentProvider, (prev, next) {
      if (_didSelectionChange(
        prevId: prev?.document?.id,
        nextId: next.document?.id,
        prevPath: prev?.document?.filePath,
        nextPath: next.document?.filePath,
        prevDemo: prev?.isDemoMode ?? false,
        nextDemo: next.isDemoMode,
      )) {
        resetAudit();
      }
    });

    ref.listen<InvoiceState>(invoiceDocumentProvider, (prev, next) {
      if (_didSelectionChange(
        prevId: prev?.document?.id,
        nextId: next.document?.id,
        prevPath: prev?.document?.filePath,
        nextPath: next.document?.filePath,
        prevDemo: prev?.isDemoMode ?? false,
        nextDemo: next.isDemoMode,
      )) {
        resetAudit();
      }
    });

    return null;
  }

  bool _didSelectionChange({
    required String? prevId,
    required String? nextId,
    required String? prevPath,
    required String? nextPath,
    required bool prevDemo,
    required bool nextDemo,
  }) {
    return prevId != nextId || prevPath != nextPath || prevDemo != nextDemo;
  }

  Future<void> runAudit() async {
    if (state.isLoading || ref.read(auditCooldownProvider) > 0) {
      return;
    }

    final runSeq = ++_auditRunSeq;
    final contractState = ref.read(contractDocumentProvider);
    final invoiceState = ref.read(invoiceDocumentProvider);

    final contractDoc = contractState.document;
    final invoiceDoc = invoiceState.document;

    // Demo Mode Execution Path when both viewers are in Demo Sample mode
    if ((contractDoc == null || invoiceDoc == null) &&
        contractState.isDemoMode &&
        invoiceState.isDemoMode) {
      ref.read(activeSelectedFindingProvider.notifier).clear();
      ref.read(auditStatusMessageProvider.notifier).setMessage(null);
      state = const AsyncLoading();
      final result = await AsyncValue.guard(() async {
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        return AuditResult.demoSample();
      });
      if (!ref.mounted || _auditRunSeq != runSeq) return;
      state = result;
      final demoData = result.asData?.value;
      if (demoData != null && demoData.findings.isNotEmpty) {
        final historyNotifier = ref.read(auditHistoryProvider.notifier);
        unawaited(
          _persistAuditInBackground(
            historyNotifier: historyNotifier,
            result: demoData,
            contractName: 'Master_Services_Agreement_2026.pdf',
            invoiceName: 'Apex_Tech_Invoice_INV-2026-889.pdf',
          ),
        );
      }
      ref.read(auditCooldownProvider.notifier).startCooldown(seconds: 3);
      return;
    }

    // Require both documents to be loaded
    if (contractDoc == null || invoiceDoc == null) {
      state = AsyncError(
        StateError(
          'Please load both a Governing Contract and a Vendor Invoice (PDF, Word, or Spreadsheet) — or switch both panels to Demo Sample mode — before running an AI audit.',
        ),
        StackTrace.current,
      );
      return;
    }

    ref.read(activeSelectedFindingProvider.notifier).clear();
    ref.read(auditStatusMessageProvider.notifier).setMessage(
          'Extracting text locally from documents...',
        );
    state = const AsyncLoading();

    try {
      final guarded = await AsyncValue.guard(() async {
        final contractFile = File(contractDoc.filePath);
        final invoiceFile = File(invoiceDoc.filePath);
        final extractor = ref.read(pdfExtractionServiceProvider);

        String contractText = '';
        String invoiceText = '';
        try {
          final extracted = await Future.wait<String>([
            extractor.extractDocumentText(contractFile),
            extractor.extractDocumentText(invoiceFile),
          ]);
          contractText = extracted[0];
          invoiceText = extracted[1];
        } catch (e) {
          if (contractText.isEmpty) contractText = 'Extraction failed: $e';
          if (invoiceText.isEmpty) invoiceText = 'Extraction failed: $e';
        }

        if (!ref.mounted || _auditRunSeq != runSeq) {
          throw StateError('Audit superseded by document change.');
        }

        // Transition status promptly before starting cloud audit engine
        ref
            .read(auditStatusMessageProvider.notifier)
            .setMessage('Auditing with Gemini 3.8 / Groq...');

        final service = ref.read(geminiAuditServiceProvider);
        return await service.auditDocuments(
          contractFile: contractFile,
          invoiceFile: invoiceFile,
          preExtractedContractText: contractText,
          preExtractedInvoiceText: invoiceText,
          onRetryStatus: (statusMessage) {
            if (ref.mounted && _auditRunSeq == runSeq) {
              ref
                  .read(auditStatusMessageProvider.notifier)
                  .setMessage(statusMessage);
            }
          },
        );
      });

      if (!ref.mounted || _auditRunSeq != runSeq) return;
      state = guarded;
      final auditData = guarded.asData?.value;
      if (auditData != null && auditData.findings.isNotEmpty) {
        final historyNotifier = ref.read(auditHistoryProvider.notifier);
        unawaited(
          _persistAuditInBackground(
            historyNotifier: historyNotifier,
            result: auditData,
            contractName: contractDoc.fileName,
            invoiceName: invoiceDoc.fileName,
          ),
        );
      }
    } finally {
      if (ref.mounted && _auditRunSeq == runSeq) {
        ref.read(auditStatusMessageProvider.notifier).setMessage(null);
        ref.read(auditCooldownProvider.notifier).startCooldown(seconds: 3);
      }
    }
  }

  Future<void> _persistAuditInBackground({
    required AuditHistoryNotifier historyNotifier,
    required AuditResult result,
    required String contractName,
    required String invoiceName,
  }) async {
    try {
      await historyNotifier.saveAuditResult(
        result: result,
        contractName: contractName,
        invoiceName: invoiceName,
      );
    } catch (_) {
      // Never block or surface persistence errors over completed audit UI.
    }
  }

  /// Restores a previously persisted [AuditRecord] into the active workbench
  /// without triggering an extra AI round-trip.
  AuditResult loadHistoricalAudit(AuditRecord record) {
    _auditRunSeq++;
    ref.read(auditStatusMessageProvider.notifier).setMessage(null);
    ref.read(activeSelectedFindingProvider.notifier).clear();
    ref.read(contractDocumentProvider.notifier).clearContract();
    ref.read(invoiceDocumentProvider.notifier).clearInvoice();

    final restoredResult = record.toAuditResult();
    state = AsyncData(restoredResult);
    return restoredResult;
  }

  void resetAudit() {
    _auditRunSeq++;
    ref.read(auditStatusMessageProvider.notifier).setMessage(null);
    ref.read(activeSelectedFindingProvider.notifier).clear();
    if (state is AsyncData<AuditResult?> &&
        state.asData?.value == null &&
        !state.hasError &&
        !state.isLoading) {
      return;
    }
    state = const AsyncData(null);
  }
}
