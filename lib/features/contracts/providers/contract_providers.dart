import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/document_file_helper.dart';
import '../models/contract_document.dart';

final contractDocumentProvider =
    NotifierProvider<ContractDocumentNotifier, ContractState>(
  ContractDocumentNotifier.new,
);

class ContractDocumentNotifier extends Notifier<ContractState> {
  static const _uuid = Uuid();

  @override
  ContractState build() => const ContractState();

  Future<void> pickAndLoadContract() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final outcome = await DocumentFileHelper.pickAndValidate(
        dialogTitle: 'Select Governing Contract (PDF, Word, or Spreadsheet)',
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
          errorMessage: outcome.errorMessage ?? 'Unable to load selected contract.',
        );
        return;
      }

      final doc = ContractDocument(
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
        errorMessage: 'Failed to load contract document: $e',
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

  void clearContract() {
    state = const ContractState();
  }
}
