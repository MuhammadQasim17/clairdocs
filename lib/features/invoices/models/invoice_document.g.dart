// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvoiceDocument _$InvoiceDocumentFromJson(Map<String, dynamic> json) =>
    _InvoiceDocument(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      fileName: json['fileName'] as String,
      fileSizeBytes: (json['fileSizeBytes'] as num).toInt(),
      sha256Hash: json['sha256Hash'] as String,
      pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
      loadedAt: DateTime.parse(json['loadedAt'] as String),
    );

Map<String, dynamic> _$InvoiceDocumentToJson(_InvoiceDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'filePath': instance.filePath,
      'fileName': instance.fileName,
      'fileSizeBytes': instance.fileSizeBytes,
      'sha256Hash': instance.sha256Hash,
      'pageCount': instance.pageCount,
      'loadedAt': instance.loadedAt.toIso8601String(),
    };
