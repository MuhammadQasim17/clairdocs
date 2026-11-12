import 'package:freezed_annotation/freezed_annotation.dart';

part 'contract_document.freezed.dart';
part 'contract_document.g.dart';

@freezed
abstract class ContractDocument with _$ContractDocument {
  const ContractDocument._();

  const factory ContractDocument({
    required String id,
    required String filePath,
    required String fileName,
    required int fileSizeBytes,
    required String sha256Hash,
    @Default(0) int pageCount,
    required DateTime loadedAt,
  }) = _ContractDocument;

  factory ContractDocument.fromJson(Map<String, Object?> json) =>
      _$ContractDocumentFromJson(json);

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

@freezed
abstract class ContractState with _$ContractState {
  const factory ContractState({
    ContractDocument? document,
    @Default(false) bool isLoading,
    @Default(false) bool isDemoMode,
    String? errorMessage,
  }) = _ContractState;
}
