import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/document_file_helper.dart';
import '../models/invoice_document.dart';

final invoiceDocumentProvider =
    NotifierProvider<InvoiceDocumentNotifier, InvoiceState>(
  InvoiceDocumentNotifier.new,
);

class InvoiceDocumentNotifier extends Notifier<InvoiceState> {
  static const _uuid = Uuid();

  @override
  InvoiceState build() => const InvoiceState();

  Future<void> pickAndLoadInvoice() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final outcome = await DocumentFileHelper.pickAndValidate(
        dialogTitle: 'Select Target Invoice (PDF, Word, or Spreadsheet)',
      );
      if (!ref.mounted) return;

      if (outcome.isCancelled) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final metadata = outcome.metadata;
      if (metadata == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: outcome.errorMessage ?? 'Unable to load selected invoice.',
        );
        return;
      }

      final doc = InvoiceDocument(
        id: _uuid.v4(),
        filePath: metadata.filePath,
        fileName: metadata.fileName,
        fileSizeBytes: metadata.fileSizeBytes,
        sha256Hash: metadata.sha256Hash,
        pageCount: 0,
        loadedAt: DateTime.now(),
      );

      state = state.copyWith(
        document: doc,
        isLoading: false,
        isDemoMode: false,
        errorMessage: null,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load invoice document: $e',
      );
    }
  }

  void updatePageCount(int pageCount) {
    final current = state.document;
    if (current != null && current.pageCount != pageCount) {
      state = state.copyWith(
        document: current.copyWith(pageCount: pageCount),
      );
    }
  }

  void toggleDemoMode() {
    state = state.copyWith(
      isDemoMode: !state.isDemoMode,
      errorMessage: null,
    );
  }

  void setDemoMode(bool enabled) {
    state = state.copyWith(
      isDemoMode: enabled,
      errorMessage: null,
    );
  }

  void clearInvoice() {
    state = const InvoiceState();
  }
}
