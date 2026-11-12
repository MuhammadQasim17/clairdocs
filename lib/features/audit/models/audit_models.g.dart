// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuditResult _$AuditResultFromJson(Map<String, dynamic> json) => _AuditResult(
  currency: json['currency'] as String? ?? 'USD',
  totalVarianceAmount: (json['totalVarianceAmount'] as num).toDouble(),
  invoicedTotal: (json['invoicedTotal'] as num).toDouble(),
  verifiedContractBase: (json['verifiedContractBase'] as num).toDouble(),
  variancePercentage: (json['variancePercentage'] as num).toDouble(),
  findings:
      (json['findings'] as List<dynamic>?)
          ?.map((e) => AuditFinding.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  auditEngine: json['auditEngine'] as String? ?? 'Gemini 3.8',
  vendorName: json['vendorName'] as String?,
  vendorEmail: json['vendorEmail'] as String?,
  clientName: json['clientName'] as String?,
  invoiceNumber: json['invoiceNumber'] as String?,
  contractReference: json['contractReference'] as String?,
);

Map<String, dynamic> _$AuditResultToJson(_AuditResult instance) =>
    <String, dynamic>{
      'currency': instance.currency,
      'totalVarianceAmount': instance.totalVarianceAmount,
      'invoicedTotal': instance.invoicedTotal,
      'verifiedContractBase': instance.verifiedContractBase,
      'variancePercentage': instance.variancePercentage,
      'findings': instance.findings.map((e) => e.toJson()).toList(),
      'auditEngine': instance.auditEngine,
      'vendorName': instance.vendorName,
      'vendorEmail': instance.vendorEmail,
      'clientName': instance.clientName,
      'invoiceNumber': instance.invoiceNumber,
      'contractReference': instance.contractReference,
    };

_AuditFinding _$AuditFindingFromJson(Map<String, dynamic> json) =>
    _AuditFinding(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      clauseReference: json['clauseReference'] as String,
      invoiceLineReference: json['invoiceLineReference'] as String,
      searchKeyword: json['searchKeyword'] as String?,
      agreedRate: (json['agreedRate'] as num?)?.toDouble(),
      billedRate: (json['billedRate'] as num?)?.toDouble(),
      varianceAmount: (json['varianceAmount'] as num).toDouble(),
      severity: json['severity'] as String,
    );

Map<String, dynamic> _$AuditFindingToJson(_AuditFinding instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'category': instance.category,
      'description': instance.description,
      'clauseReference': instance.clauseReference,
      'invoiceLineReference': instance.invoiceLineReference,
      'searchKeyword': instance.searchKeyword,
      'agreedRate': instance.agreedRate,
      'billedRate': instance.billedRate,
      'varianceAmount': instance.varianceAmount,
      'severity': instance.severity,
    };
