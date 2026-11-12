import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice_document.freezed.dart';
part 'invoice_document.g.dart';

@freezed
abstract class InvoiceDocument with _$InvoiceDocument {
  const InvoiceDocument._();

  const factory InvoiceDocument({
    required String id,
    required String filePath,
    required String fileName,
    required int fileSizeBytes,
    required String sha256Hash,
    @Default(0) int pageCount,
    required DateTime loadedAt,
  }) = _InvoiceDocument;

  factory InvoiceDocument.fromJson(Map<String, Object?> json) =>
      _$InvoiceDocumentFromJson(json);

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

@freezed
abstract class InvoiceState with _$InvoiceState {
  const factory InvoiceState({
    InvoiceDocument? document,
    @Default(false) bool isLoading,
    @Default(false) bool isDemoMode,
    String? errorMessage,
  }) = _InvoiceState;
}
