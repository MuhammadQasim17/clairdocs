// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dispute_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DisputeState {

 DisputeGenerationStatus get status; DisputeTone get tone; String get draftText; String get vendorName; String get vendorEmail; String get clientName; String get invoiceReference; String get contractReference; double get totalWithheld; double get totalInvoiced; double get approvedPayment; String get currency; bool get usedFallback; bool get isRefiningWithAi; String get draftEngine; bool get isExportingPdf; String? get errorMessage; AuditResult? get sourceAuditResult;
/// Create a copy of DisputeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DisputeStateCopyWith<DisputeState> get copyWith => _$DisputeStateCopyWithImpl<DisputeState>(this as DisputeState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DisputeState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DisputeState&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.tone, _this.tone) || other.tone == _this.tone)&&(identical(other.draftText, _this.draftText) || other.draftText == _this.draftText)&&(identical(other.vendorName, _this.vendorName) || other.vendorName == _this.vendorName)&&(identical(other.vendorEmail, _this.vendorEmail) || other.vendorEmail == _this.vendorEmail)&&(identical(other.clientName, _this.clientName) || other.clientName == _this.clientName)&&(identical(other.invoiceReference, _this.invoiceReference) || other.invoiceReference == _this.invoiceReference)&&(identical(other.contractReference, _this.contractReference) || other.contractReference == _this.contractReference)&&(identical(other.totalWithheld, _this.totalWithheld) || other.totalWithheld == _this.totalWithheld)&&(identical(other.totalInvoiced, _this.totalInvoiced) || other.totalInvoiced == _this.totalInvoiced)&&(identical(other.approvedPayment, _this.approvedPayment) || other.approvedPayment == _this.approvedPayment)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.usedFallback, _this.usedFallback) || other.usedFallback == _this.usedFallback)&&(identical(other.isRefiningWithAi, _this.isRefiningWithAi) || other.isRefiningWithAi == _this.isRefiningWithAi)&&(identical(other.draftEngine, _this.draftEngine) || other.draftEngine == _this.draftEngine)&&(identical(other.isExportingPdf, _this.isExportingPdf) || other.isExportingPdf == _this.isExportingPdf)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage)&&(identical(other.sourceAuditResult, _this.sourceAuditResult) || other.sourceAuditResult == _this.sourceAuditResult));
}


@override
int get hashCode {
  final _this = this as DisputeState;
  return Object.hash(runtimeType,_this.status,_this.tone,_this.draftText,_this.vendorName,_this.vendorEmail,_this.clientName,_this.invoiceReference,_this.contractReference,_this.totalWithheld,_this.totalInvoiced,_this.approvedPayment,_this.currency,_this.usedFallback,_this.isRefiningWithAi,_this.draftEngine,_this.isExportingPdf,_this.errorMessage,_this.sourceAuditResult);
}

@override
String toString() {
  final _this = this as DisputeState;
  return 'DisputeState(status: ${_this.status}, tone: ${_this.tone}, draftText: ${_this.draftText}, vendorName: ${_this.vendorName}, vendorEmail: ${_this.vendorEmail}, clientName: ${_this.clientName}, invoiceReference: ${_this.invoiceReference}, contractReference: ${_this.contractReference}, totalWithheld: ${_this.totalWithheld}, totalInvoiced: ${_this.totalInvoiced}, approvedPayment: ${_this.approvedPayment}, currency: ${_this.currency}, usedFallback: ${_this.usedFallback}, isRefiningWithAi: ${_this.isRefiningWithAi}, draftEngine: ${_this.draftEngine}, isExportingPdf: ${_this.isExportingPdf}, errorMessage: ${_this.errorMessage}, sourceAuditResult: ${_this.sourceAuditResult})';
}


}

/// @nodoc
abstract mixin class $DisputeStateCopyWith<$Res>  {
  factory $DisputeStateCopyWith(DisputeState value, $Res Function(DisputeState) _then) = _$DisputeStateCopyWithImpl;
@useResult
$Res call({
 DisputeGenerationStatus status, DisputeTone tone, String draftText, String vendorName, String vendorEmail, String clientName, String invoiceReference, String contractReference, double totalWithheld, double totalInvoiced, double approvedPayment, String currency, bool usedFallback, bool isRefiningWithAi, String draftEngine, bool isExportingPdf, String? errorMessage, AuditResult? sourceAuditResult
});


$AuditResultCopyWith<$Res>? get sourceAuditResult;

}
/// @nodoc
class _$DisputeStateCopyWithImpl<$Res>
    implements $DisputeStateCopyWith<$Res> {
  _$DisputeStateCopyWithImpl(this._self, this._then);

  final DisputeState _self;
  final $Res Function(DisputeState) _then;

/// Create a copy of DisputeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? tone = null,Object? draftText = null,Object? vendorName = null,Object? vendorEmail = null,Object? clientName = null,Object? invoiceReference = null,Object? contractReference = null,Object? totalWithheld = null,Object? totalInvoiced = null,Object? approvedPayment = null,Object? currency = null,Object? usedFallback = null,Object? isRefiningWithAi = null,Object? draftEngine = null,Object? isExportingPdf = null,Object? errorMessage = freezed,Object? sourceAuditResult = freezed,}) {
  return _then(DisputeState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DisputeGenerationStatus,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as DisputeTone,draftText: null == draftText ? _self.draftText : draftText // ignore: cast_nullable_to_non_nullable
as String,vendorName: null == vendorName ? _self.vendorName : vendorName // ignore: cast_nullable_to_non_nullable
as String,vendorEmail: null == vendorEmail ? _self.vendorEmail : vendorEmail // ignore: cast_nullable_to_non_nullable
as String,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,invoiceReference: null == invoiceReference ? _self.invoiceReference : invoiceReference // ignore: cast_nullable_to_non_nullable
as String,contractReference: null == contractReference ? _self.contractReference : contractReference // ignore: cast_nullable_to_non_nullable
as String,totalWithheld: null == totalWithheld ? _self.totalWithheld : totalWithheld // ignore: cast_nullable_to_non_nullable
as double,totalInvoiced: null == totalInvoiced ? _self.totalInvoiced : totalInvoiced // ignore: cast_nullable_to_non_nullable
as double,approvedPayment: null == approvedPayment ? _self.approvedPayment : approvedPayment // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,usedFallback: null == usedFallback ? _self.usedFallback : usedFallback // ignore: cast_nullable_to_non_nullable
as bool,isRefiningWithAi: null == isRefiningWithAi ? _self.isRefiningWithAi : isRefiningWithAi // ignore: cast_nullable_to_non_nullable
as bool,draftEngine: null == draftEngine ? _self.draftEngine : draftEngine // ignore: cast_nullable_to_non_nullable
as String,isExportingPdf: null == isExportingPdf ? _self.isExportingPdf : isExportingPdf // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,sourceAuditResult: freezed == sourceAuditResult ? _self.sourceAuditResult : sourceAuditResult // ignore: cast_nullable_to_non_nullable
as AuditResult?,
  ));
}
/// Create a copy of DisputeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuditResultCopyWith<$Res>? get sourceAuditResult {
    if (_self.sourceAuditResult == null) {
    return null;
  }

  return $AuditResultCopyWith<$Res>(_self.sourceAuditResult!, (value) {
    return _then(_self.copyWith(sourceAuditResult: value));
  });
}
}


/// Adds pattern-matching-related methods to [DisputeState].
extension DisputeStatePatterns on DisputeState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DisputeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DisputeState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DisputeState value)  $default,){
final _that = this;
switch (_that) {
case _DisputeState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DisputeState value)?  $default,){
final _that = this;
switch (_that) {
case _DisputeState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DisputeGenerationStatus status,  DisputeTone tone,  String draftText,  String vendorName,  String vendorEmail,  String clientName,  String invoiceReference,  String contractReference,  double totalWithheld,  double totalInvoiced,  double approvedPayment,  String currency,  bool usedFallback,  bool isRefiningWithAi,  String draftEngine,  bool isExportingPdf,  String? errorMessage,  AuditResult? sourceAuditResult)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DisputeState() when $default != null:
return $default(_that.status,_that.tone,_that.draftText,_that.vendorName,_that.vendorEmail,_that.clientName,_that.invoiceReference,_that.contractReference,_that.totalWithheld,_that.totalInvoiced,_that.approvedPayment,_that.currency,_that.usedFallback,_that.isRefiningWithAi,_that.draftEngine,_that.isExportingPdf,_that.errorMessage,_that.sourceAuditResult);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DisputeGenerationStatus status,  DisputeTone tone,  String draftText,  String vendorName,  String vendorEmail,  String clientName,  String invoiceReference,  String contractReference,  double totalWithheld,  double totalInvoiced,  double approvedPayment,  String currency,  bool usedFallback,  bool isRefiningWithAi,  String draftEngine,  bool isExportingPdf,  String? errorMessage,  AuditResult? sourceAuditResult)  $default,) {final _that = this;
switch (_that) {
case _DisputeState():
return $default(_that.status,_that.tone,_that.draftText,_that.vendorName,_that.vendorEmail,_that.clientName,_that.invoiceReference,_that.contractReference,_that.totalWithheld,_that.totalInvoiced,_that.approvedPayment,_that.currency,_that.usedFallback,_that.isRefiningWithAi,_that.draftEngine,_that.isExportingPdf,_that.errorMessage,_that.sourceAuditResult);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DisputeGenerationStatus status,  DisputeTone tone,  String draftText,  String vendorName,  String vendorEmail,  String clientName,  String invoiceReference,  String contractReference,  double totalWithheld,  double totalInvoiced,  double approvedPayment,  String currency,  bool usedFallback,  bool isRefiningWithAi,  String draftEngine,  bool isExportingPdf,  String? errorMessage,  AuditResult? sourceAuditResult)?  $default,) {final _that = this;
switch (_that) {
case _DisputeState() when $default != null:
return $default(_that.status,_that.tone,_that.draftText,_that.vendorName,_that.vendorEmail,_that.clientName,_that.invoiceReference,_that.contractReference,_that.totalWithheld,_that.totalInvoiced,_that.approvedPayment,_that.currency,_that.usedFallback,_that.isRefiningWithAi,_that.draftEngine,_that.isExportingPdf,_that.errorMessage,_that.sourceAuditResult);case _:
  return null;

}
}

}

/// @nodoc


class _DisputeState implements DisputeState {
  const _DisputeState({this.status = DisputeGenerationStatus.idle, this.tone = DisputeTone.firmLegal, this.draftText = '', this.vendorName = 'Vendor Accounts Receivable', this.vendorEmail = '', this.clientName = 'Enterprise Finance & Procurement', this.invoiceReference = 'INV-2026-889', this.contractReference = 'Master Services Agreement', this.totalWithheld = 0.0, this.totalInvoiced = 0.0, this.approvedPayment = 0.0, this.currency = 'USD', this.usedFallback = false, this.isRefiningWithAi = false, this.draftEngine = 'GEMINI 3.8 LEGAL DRAFT', this.isExportingPdf = false, this.errorMessage, this.sourceAuditResult});
  

@override@JsonKey() final  DisputeGenerationStatus status;
@override@JsonKey() final  DisputeTone tone;
@override@JsonKey() final  String draftText;
@override@JsonKey() final  String vendorName;
@override@JsonKey() final  String vendorEmail;
@override@JsonKey() final  String clientName;
@override@JsonKey() final  String invoiceReference;
@override@JsonKey() final  String contractReference;
@override@JsonKey() final  double totalWithheld;
@override@JsonKey() final  double totalInvoiced;
@override@JsonKey() final  double approvedPayment;
@override@JsonKey() final  String currency;
@override@JsonKey() final  bool usedFallback;
@override@JsonKey() final  bool isRefiningWithAi;
@override@JsonKey() final  String draftEngine;
@override@JsonKey() final  bool isExportingPdf;
@override final  String? errorMessage;
@override final  AuditResult? sourceAuditResult;

/// Create a copy of DisputeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DisputeStateCopyWith<_DisputeState> get copyWith => __$DisputeStateCopyWithImpl<_DisputeState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DisputeState&&(identical(other.status, status) || other.status == status)&&(identical(other.tone, tone) || other.tone == tone)&&(identical(other.draftText, draftText) || other.draftText == draftText)&&(identical(other.vendorName, vendorName) || other.vendorName == vendorName)&&(identical(other.vendorEmail, vendorEmail) || other.vendorEmail == vendorEmail)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.invoiceReference, invoiceReference) || other.invoiceReference == invoiceReference)&&(identical(other.contractReference, contractReference) || other.contractReference == contractReference)&&(identical(other.totalWithheld, totalWithheld) || other.totalWithheld == totalWithheld)&&(identical(other.totalInvoiced, totalInvoiced) || other.totalInvoiced == totalInvoiced)&&(identical(other.approvedPayment, approvedPayment) || other.approvedPayment == approvedPayment)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.usedFallback, usedFallback) || other.usedFallback == usedFallback)&&(identical(other.isRefiningWithAi, isRefiningWithAi) || other.isRefiningWithAi == isRefiningWithAi)&&(identical(other.draftEngine, draftEngine) || other.draftEngine == draftEngine)&&(identical(other.isExportingPdf, isExportingPdf) || other.isExportingPdf == isExportingPdf)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.sourceAuditResult, sourceAuditResult) || other.sourceAuditResult == sourceAuditResult));
}


@override
int get hashCode {
    return Object.hash(runtimeType,status,tone,draftText,vendorName,vendorEmail,clientName,invoiceReference,contractReference,totalWithheld,totalInvoiced,approvedPayment,currency,usedFallback,isRefiningWithAi,draftEngine,isExportingPdf,errorMessage,sourceAuditResult);
}

@override
String toString() {
    return 'DisputeState(status: $status, tone: $tone, draftText: $draftText, vendorName: $vendorName, vendorEmail: $vendorEmail, clientName: $clientName, invoiceReference: $invoiceReference, contractReference: $contractReference, totalWithheld: $totalWithheld, totalInvoiced: $totalInvoiced, approvedPayment: $approvedPayment, currency: $currency, usedFallback: $usedFallback, isRefiningWithAi: $isRefiningWithAi, draftEngine: $draftEngine, isExportingPdf: $isExportingPdf, errorMessage: $errorMessage, sourceAuditResult: $sourceAuditResult)';
}


}

/// @nodoc
abstract mixin class _$DisputeStateCopyWith<$Res> implements $DisputeStateCopyWith<$Res> {
  factory _$DisputeStateCopyWith(_DisputeState value, $Res Function(_DisputeState) _then) = __$DisputeStateCopyWithImpl;
@override @useResult
$Res call({
 DisputeGenerationStatus status, DisputeTone tone, String draftText, String vendorName, String vendorEmail, String clientName, String invoiceReference, String contractReference, double totalWithheld, double totalInvoiced, double approvedPayment, String currency, bool usedFallback, bool isRefiningWithAi, String draftEngine, bool isExportingPdf, String? errorMessage, AuditResult? sourceAuditResult
});


@override $AuditResultCopyWith<$Res>? get sourceAuditResult;

}
/// @nodoc
class __$DisputeStateCopyWithImpl<$Res>
    implements _$DisputeStateCopyWith<$Res> {
  __$DisputeStateCopyWithImpl(this._self, this._then);

  final _DisputeState _self;
  final $Res Function(_DisputeState) _then;

/// Create a copy of DisputeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? tone = null,Object? draftText = null,Object? vendorName = null,Object? vendorEmail = null,Object? clientName = null,Object? invoiceReference = null,Object? contractReference = null,Object? totalWithheld = null,Object? totalInvoiced = null,Object? approvedPayment = null,Object? currency = null,Object? usedFallback = null,Object? isRefiningWithAi = null,Object? draftEngine = null,Object? isExportingPdf = null,Object? errorMessage = freezed,Object? sourceAuditResult = freezed,}) {
  return _then(_DisputeState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DisputeGenerationStatus,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as DisputeTone,draftText: null == draftText ? _self.draftText : draftText // ignore: cast_nullable_to_non_nullable
as String,vendorName: null == vendorName ? _self.vendorName : vendorName // ignore: cast_nullable_to_non_nullable
as String,vendorEmail: null == vendorEmail ? _self.vendorEmail : vendorEmail // ignore: cast_nullable_to_non_nullable
as String,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,invoiceReference: null == invoiceReference ? _self.invoiceReference : invoiceReference // ignore: cast_nullable_to_non_nullable
as String,contractReference: null == contractReference ? _self.contractReference : contractReference // ignore: cast_nullable_to_non_nullable
as String,totalWithheld: null == totalWithheld ? _self.totalWithheld : totalWithheld // ignore: cast_nullable_to_non_nullable
as double,totalInvoiced: null == totalInvoiced ? _self.totalInvoiced : totalInvoiced // ignore: cast_nullable_to_non_nullable
as double,approvedPayment: null == approvedPayment ? _self.approvedPayment : approvedPayment // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,usedFallback: null == usedFallback ? _self.usedFallback : usedFallback // ignore: cast_nullable_to_non_nullable
as bool,isRefiningWithAi: null == isRefiningWithAi ? _self.isRefiningWithAi : isRefiningWithAi // ignore: cast_nullable_to_non_nullable
as bool,draftEngine: null == draftEngine ? _self.draftEngine : draftEngine // ignore: cast_nullable_to_non_nullable
as String,isExportingPdf: null == isExportingPdf ? _self.isExportingPdf : isExportingPdf // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,sourceAuditResult: freezed == sourceAuditResult ? _self.sourceAuditResult : sourceAuditResult // ignore: cast_nullable_to_non_nullable
as AuditResult?,
  ));
}

/// Create a copy of DisputeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuditResultCopyWith<$Res>? get sourceAuditResult {
    if (_self.sourceAuditResult == null) {
    return null;
  }

  return $AuditResultCopyWith<$Res>(_self.sourceAuditResult!, (value) {
    return _then(_self.copyWith(sourceAuditResult: value));
  });
}
}

// dart format on
