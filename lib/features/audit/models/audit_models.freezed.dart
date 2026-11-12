// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audit_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuditResult {

 String get currency; double get totalVarianceAmount; double get invoicedTotal; double get verifiedContractBase; double get variancePercentage; List<AuditFinding> get findings; String get auditEngine; String? get vendorName; String? get vendorEmail; String? get clientName; String? get invoiceNumber; String? get contractReference;
/// Create a copy of AuditResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditResultCopyWith<AuditResult> get copyWith => _$AuditResultCopyWithImpl<AuditResult>(this as AuditResult, _$identity);

  /// Serializes this AuditResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AuditResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditResult&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.totalVarianceAmount, _this.totalVarianceAmount) || other.totalVarianceAmount == _this.totalVarianceAmount)&&(identical(other.invoicedTotal, _this.invoicedTotal) || other.invoicedTotal == _this.invoicedTotal)&&(identical(other.verifiedContractBase, _this.verifiedContractBase) || other.verifiedContractBase == _this.verifiedContractBase)&&(identical(other.variancePercentage, _this.variancePercentage) || other.variancePercentage == _this.variancePercentage)&&const DeepCollectionEquality().equals(other.findings, _this.findings)&&(identical(other.auditEngine, _this.auditEngine) || other.auditEngine == _this.auditEngine)&&(identical(other.vendorName, _this.vendorName) || other.vendorName == _this.vendorName)&&(identical(other.vendorEmail, _this.vendorEmail) || other.vendorEmail == _this.vendorEmail)&&(identical(other.clientName, _this.clientName) || other.clientName == _this.clientName)&&(identical(other.invoiceNumber, _this.invoiceNumber) || other.invoiceNumber == _this.invoiceNumber)&&(identical(other.contractReference, _this.contractReference) || other.contractReference == _this.contractReference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AuditResult;
  return Object.hash(runtimeType,_this.currency,_this.totalVarianceAmount,_this.invoicedTotal,_this.verifiedContractBase,_this.variancePercentage,const DeepCollectionEquality().hash(_this.findings),_this.auditEngine,_this.vendorName,_this.vendorEmail,_this.clientName,_this.invoiceNumber,_this.contractReference);
}

@override
String toString() {
  final _this = this as AuditResult;
  return 'AuditResult(currency: ${_this.currency}, totalVarianceAmount: ${_this.totalVarianceAmount}, invoicedTotal: ${_this.invoicedTotal}, verifiedContractBase: ${_this.verifiedContractBase}, variancePercentage: ${_this.variancePercentage}, findings: ${_this.findings}, auditEngine: ${_this.auditEngine}, vendorName: ${_this.vendorName}, vendorEmail: ${_this.vendorEmail}, clientName: ${_this.clientName}, invoiceNumber: ${_this.invoiceNumber}, contractReference: ${_this.contractReference})';
}


}

/// @nodoc
abstract mixin class $AuditResultCopyWith<$Res>  {
  factory $AuditResultCopyWith(AuditResult value, $Res Function(AuditResult) _then) = _$AuditResultCopyWithImpl;
@useResult
$Res call({
 String currency, double totalVarianceAmount, double invoicedTotal, double verifiedContractBase, double variancePercentage, List<AuditFinding> findings, String auditEngine, String? vendorName, String? vendorEmail, String? clientName, String? invoiceNumber, String? contractReference
});




}
/// @nodoc
class _$AuditResultCopyWithImpl<$Res>
    implements $AuditResultCopyWith<$Res> {
  _$AuditResultCopyWithImpl(this._self, this._then);

  final AuditResult _self;
  final $Res Function(AuditResult) _then;

/// Create a copy of AuditResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currency = null,Object? totalVarianceAmount = null,Object? invoicedTotal = null,Object? verifiedContractBase = null,Object? variancePercentage = null,Object? findings = null,Object? auditEngine = null,Object? vendorName = freezed,Object? vendorEmail = freezed,Object? clientName = freezed,Object? invoiceNumber = freezed,Object? contractReference = freezed,}) {
  return _then(AuditResult(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,totalVarianceAmount: null == totalVarianceAmount ? _self.totalVarianceAmount : totalVarianceAmount // ignore: cast_nullable_to_non_nullable
as double,invoicedTotal: null == invoicedTotal ? _self.invoicedTotal : invoicedTotal // ignore: cast_nullable_to_non_nullable
as double,verifiedContractBase: null == verifiedContractBase ? _self.verifiedContractBase : verifiedContractBase // ignore: cast_nullable_to_non_nullable
as double,variancePercentage: null == variancePercentage ? _self.variancePercentage : variancePercentage // ignore: cast_nullable_to_non_nullable
as double,findings: null == findings ? _self.findings : findings // ignore: cast_nullable_to_non_nullable
as List<AuditFinding>,auditEngine: null == auditEngine ? _self.auditEngine : auditEngine // ignore: cast_nullable_to_non_nullable
as String,vendorName: freezed == vendorName ? _self.vendorName : vendorName // ignore: cast_nullable_to_non_nullable
as String?,vendorEmail: freezed == vendorEmail ? _self.vendorEmail : vendorEmail // ignore: cast_nullable_to_non_nullable
as String?,clientName: freezed == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String?,invoiceNumber: freezed == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String?,contractReference: freezed == contractReference ? _self.contractReference : contractReference // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditResult].
extension AuditResultPatterns on AuditResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditResult value)  $default,){
final _that = this;
switch (_that) {
case _AuditResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditResult value)?  $default,){
final _that = this;
switch (_that) {
case _AuditResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String currency,  double totalVarianceAmount,  double invoicedTotal,  double verifiedContractBase,  double variancePercentage,  List<AuditFinding> findings,  String auditEngine,  String? vendorName,  String? vendorEmail,  String? clientName,  String? invoiceNumber,  String? contractReference)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditResult() when $default != null:
return $default(_that.currency,_that.totalVarianceAmount,_that.invoicedTotal,_that.verifiedContractBase,_that.variancePercentage,_that.findings,_that.auditEngine,_that.vendorName,_that.vendorEmail,_that.clientName,_that.invoiceNumber,_that.contractReference);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String currency,  double totalVarianceAmount,  double invoicedTotal,  double verifiedContractBase,  double variancePercentage,  List<AuditFinding> findings,  String auditEngine,  String? vendorName,  String? vendorEmail,  String? clientName,  String? invoiceNumber,  String? contractReference)  $default,) {final _that = this;
switch (_that) {
case _AuditResult():
return $default(_that.currency,_that.totalVarianceAmount,_that.invoicedTotal,_that.verifiedContractBase,_that.variancePercentage,_that.findings,_that.auditEngine,_that.vendorName,_that.vendorEmail,_that.clientName,_that.invoiceNumber,_that.contractReference);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String currency,  double totalVarianceAmount,  double invoicedTotal,  double verifiedContractBase,  double variancePercentage,  List<AuditFinding> findings,  String auditEngine,  String? vendorName,  String? vendorEmail,  String? clientName,  String? invoiceNumber,  String? contractReference)?  $default,) {final _that = this;
switch (_that) {
case _AuditResult() when $default != null:
return $default(_that.currency,_that.totalVarianceAmount,_that.invoicedTotal,_that.verifiedContractBase,_that.variancePercentage,_that.findings,_that.auditEngine,_that.vendorName,_that.vendorEmail,_that.clientName,_that.invoiceNumber,_that.contractReference);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _AuditResult implements AuditResult {
  const _AuditResult({this.currency = 'USD', required this.totalVarianceAmount, required this.invoicedTotal, required this.verifiedContractBase, required this.variancePercentage,  List<AuditFinding> findings = const [], this.auditEngine = 'Gemini 3.8', this.vendorName, this.vendorEmail, this.clientName, this.invoiceNumber, this.contractReference}): _findings = findings;
  factory _AuditResult.fromJson(Map<String, dynamic> json) => _$AuditResultFromJson(json);

@override@JsonKey() final  String currency;
@override final  double totalVarianceAmount;
@override final  double invoicedTotal;
@override final  double verifiedContractBase;
@override final  double variancePercentage;
 final  List<AuditFinding> _findings;
@override@JsonKey() List<AuditFinding> get findings {
  if (_findings is EqualUnmodifiableListView) return _findings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_findings);
}

@override@JsonKey() final  String auditEngine;
@override final  String? vendorName;
@override final  String? vendorEmail;
@override final  String? clientName;
@override final  String? invoiceNumber;
@override final  String? contractReference;

/// Create a copy of AuditResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditResultCopyWith<_AuditResult> get copyWith => __$AuditResultCopyWithImpl<_AuditResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuditResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditResult&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.totalVarianceAmount, totalVarianceAmount) || other.totalVarianceAmount == totalVarianceAmount)&&(identical(other.invoicedTotal, invoicedTotal) || other.invoicedTotal == invoicedTotal)&&(identical(other.verifiedContractBase, verifiedContractBase) || other.verifiedContractBase == verifiedContractBase)&&(identical(other.variancePercentage, variancePercentage) || other.variancePercentage == variancePercentage)&&const DeepCollectionEquality().equals(other.findings, _findings)&&(identical(other.auditEngine, auditEngine) || other.auditEngine == auditEngine)&&(identical(other.vendorName, vendorName) || other.vendorName == vendorName)&&(identical(other.vendorEmail, vendorEmail) || other.vendorEmail == vendorEmail)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.contractReference, contractReference) || other.contractReference == contractReference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,currency,totalVarianceAmount,invoicedTotal,verifiedContractBase,variancePercentage,const DeepCollectionEquality().hash(_findings),auditEngine,vendorName,vendorEmail,clientName,invoiceNumber,contractReference);
}

@override
String toString() {
    return 'AuditResult(currency: $currency, totalVarianceAmount: $totalVarianceAmount, invoicedTotal: $invoicedTotal, verifiedContractBase: $verifiedContractBase, variancePercentage: $variancePercentage, findings: $findings, auditEngine: $auditEngine, vendorName: $vendorName, vendorEmail: $vendorEmail, clientName: $clientName, invoiceNumber: $invoiceNumber, contractReference: $contractReference)';
}


}

/// @nodoc
abstract mixin class _$AuditResultCopyWith<$Res> implements $AuditResultCopyWith<$Res> {
  factory _$AuditResultCopyWith(_AuditResult value, $Res Function(_AuditResult) _then) = __$AuditResultCopyWithImpl;
@override @useResult
$Res call({
 String currency, double totalVarianceAmount, double invoicedTotal, double verifiedContractBase, double variancePercentage, List<AuditFinding> findings, String auditEngine, String? vendorName, String? vendorEmail, String? clientName, String? invoiceNumber, String? contractReference
});




}
/// @nodoc
class __$AuditResultCopyWithImpl<$Res>
    implements _$AuditResultCopyWith<$Res> {
  __$AuditResultCopyWithImpl(this._self, this._then);

  final _AuditResult _self;
  final $Res Function(_AuditResult) _then;

/// Create a copy of AuditResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currency = null,Object? totalVarianceAmount = null,Object? invoicedTotal = null,Object? verifiedContractBase = null,Object? variancePercentage = null,Object? findings = null,Object? auditEngine = null,Object? vendorName = freezed,Object? vendorEmail = freezed,Object? clientName = freezed,Object? invoiceNumber = freezed,Object? contractReference = freezed,}) {
  return _then(_AuditResult(
currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,totalVarianceAmount: null == totalVarianceAmount ? _self.totalVarianceAmount : totalVarianceAmount // ignore: cast_nullable_to_non_nullable
as double,invoicedTotal: null == invoicedTotal ? _self.invoicedTotal : invoicedTotal // ignore: cast_nullable_to_non_nullable
as double,verifiedContractBase: null == verifiedContractBase ? _self.verifiedContractBase : verifiedContractBase // ignore: cast_nullable_to_non_nullable
as double,variancePercentage: null == variancePercentage ? _self.variancePercentage : variancePercentage // ignore: cast_nullable_to_non_nullable
as double,findings: null == findings ? _self._findings : findings // ignore: cast_nullable_to_non_nullable
as List<AuditFinding>,auditEngine: null == auditEngine ? _self.auditEngine : auditEngine // ignore: cast_nullable_to_non_nullable
as String,vendorName: freezed == vendorName ? _self.vendorName : vendorName // ignore: cast_nullable_to_non_nullable
as String?,vendorEmail: freezed == vendorEmail ? _self.vendorEmail : vendorEmail // ignore: cast_nullable_to_non_nullable
as String?,clientName: freezed == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String?,invoiceNumber: freezed == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String?,contractReference: freezed == contractReference ? _self.contractReference : contractReference // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AuditFinding {

 String get id; String get title; String get category; String get description; String get clauseReference; String get invoiceLineReference; String? get searchKeyword; double? get agreedRate; double? get billedRate; double get varianceAmount; String get severity;
/// Create a copy of AuditFinding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditFindingCopyWith<AuditFinding> get copyWith => _$AuditFindingCopyWithImpl<AuditFinding>(this as AuditFinding, _$identity);

  /// Serializes this AuditFinding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AuditFinding;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditFinding&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.clauseReference, _this.clauseReference) || other.clauseReference == _this.clauseReference)&&(identical(other.invoiceLineReference, _this.invoiceLineReference) || other.invoiceLineReference == _this.invoiceLineReference)&&(identical(other.searchKeyword, _this.searchKeyword) || other.searchKeyword == _this.searchKeyword)&&(identical(other.agreedRate, _this.agreedRate) || other.agreedRate == _this.agreedRate)&&(identical(other.billedRate, _this.billedRate) || other.billedRate == _this.billedRate)&&(identical(other.varianceAmount, _this.varianceAmount) || other.varianceAmount == _this.varianceAmount)&&(identical(other.severity, _this.severity) || other.severity == _this.severity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AuditFinding;
  return Object.hash(runtimeType,_this.id,_this.title,_this.category,_this.description,_this.clauseReference,_this.invoiceLineReference,_this.searchKeyword,_this.agreedRate,_this.billedRate,_this.varianceAmount,_this.severity);
}

@override
String toString() {
  final _this = this as AuditFinding;
  return 'AuditFinding(id: ${_this.id}, title: ${_this.title}, category: ${_this.category}, description: ${_this.description}, clauseReference: ${_this.clauseReference}, invoiceLineReference: ${_this.invoiceLineReference}, searchKeyword: ${_this.searchKeyword}, agreedRate: ${_this.agreedRate}, billedRate: ${_this.billedRate}, varianceAmount: ${_this.varianceAmount}, severity: ${_this.severity})';
}


}

/// @nodoc
abstract mixin class $AuditFindingCopyWith<$Res>  {
  factory $AuditFindingCopyWith(AuditFinding value, $Res Function(AuditFinding) _then) = _$AuditFindingCopyWithImpl;
@useResult
$Res call({
 String id, String title, String category, String description, String clauseReference, String invoiceLineReference, String? searchKeyword, double? agreedRate, double? billedRate, double varianceAmount, String severity
});




}
/// @nodoc
class _$AuditFindingCopyWithImpl<$Res>
    implements $AuditFindingCopyWith<$Res> {
  _$AuditFindingCopyWithImpl(this._self, this._then);

  final AuditFinding _self;
  final $Res Function(AuditFinding) _then;

/// Create a copy of AuditFinding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? category = null,Object? description = null,Object? clauseReference = null,Object? invoiceLineReference = null,Object? searchKeyword = freezed,Object? agreedRate = freezed,Object? billedRate = freezed,Object? varianceAmount = null,Object? severity = null,}) {
  return _then(AuditFinding(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,clauseReference: null == clauseReference ? _self.clauseReference : clauseReference // ignore: cast_nullable_to_non_nullable
as String,invoiceLineReference: null == invoiceLineReference ? _self.invoiceLineReference : invoiceLineReference // ignore: cast_nullable_to_non_nullable
as String,searchKeyword: freezed == searchKeyword ? _self.searchKeyword : searchKeyword // ignore: cast_nullable_to_non_nullable
as String?,agreedRate: freezed == agreedRate ? _self.agreedRate : agreedRate // ignore: cast_nullable_to_non_nullable
as double?,billedRate: freezed == billedRate ? _self.billedRate : billedRate // ignore: cast_nullable_to_non_nullable
as double?,varianceAmount: null == varianceAmount ? _self.varianceAmount : varianceAmount // ignore: cast_nullable_to_non_nullable
as double,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditFinding].
extension AuditFindingPatterns on AuditFinding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditFinding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditFinding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditFinding value)  $default,){
final _that = this;
switch (_that) {
case _AuditFinding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditFinding value)?  $default,){
final _that = this;
switch (_that) {
case _AuditFinding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String category,  String description,  String clauseReference,  String invoiceLineReference,  String? searchKeyword,  double? agreedRate,  double? billedRate,  double varianceAmount,  String severity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditFinding() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.description,_that.clauseReference,_that.invoiceLineReference,_that.searchKeyword,_that.agreedRate,_that.billedRate,_that.varianceAmount,_that.severity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String category,  String description,  String clauseReference,  String invoiceLineReference,  String? searchKeyword,  double? agreedRate,  double? billedRate,  double varianceAmount,  String severity)  $default,) {final _that = this;
switch (_that) {
case _AuditFinding():
return $default(_that.id,_that.title,_that.category,_that.description,_that.clauseReference,_that.invoiceLineReference,_that.searchKeyword,_that.agreedRate,_that.billedRate,_that.varianceAmount,_that.severity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String category,  String description,  String clauseReference,  String invoiceLineReference,  String? searchKeyword,  double? agreedRate,  double? billedRate,  double varianceAmount,  String severity)?  $default,) {final _that = this;
switch (_that) {
case _AuditFinding() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.description,_that.clauseReference,_that.invoiceLineReference,_that.searchKeyword,_that.agreedRate,_that.billedRate,_that.varianceAmount,_that.severity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuditFinding implements AuditFinding {
  const _AuditFinding({required this.id, required this.title, required this.category, required this.description, required this.clauseReference, required this.invoiceLineReference, this.searchKeyword, this.agreedRate, this.billedRate, required this.varianceAmount, required this.severity});
  factory _AuditFinding.fromJson(Map<String, dynamic> json) => _$AuditFindingFromJson(json);

@override final  String id;
@override final  String title;
@override final  String category;
@override final  String description;
@override final  String clauseReference;
@override final  String invoiceLineReference;
@override final  String? searchKeyword;
@override final  double? agreedRate;
@override final  double? billedRate;
@override final  double varianceAmount;
@override final  String severity;

/// Create a copy of AuditFinding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditFindingCopyWith<_AuditFinding> get copyWith => __$AuditFindingCopyWithImpl<_AuditFinding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuditFindingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditFinding&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.clauseReference, clauseReference) || other.clauseReference == clauseReference)&&(identical(other.invoiceLineReference, invoiceLineReference) || other.invoiceLineReference == invoiceLineReference)&&(identical(other.searchKeyword, searchKeyword) || other.searchKeyword == searchKeyword)&&(identical(other.agreedRate, agreedRate) || other.agreedRate == agreedRate)&&(identical(other.billedRate, billedRate) || other.billedRate == billedRate)&&(identical(other.varianceAmount, varianceAmount) || other.varianceAmount == varianceAmount)&&(identical(other.severity, severity) || other.severity == severity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,category,description,clauseReference,invoiceLineReference,searchKeyword,agreedRate,billedRate,varianceAmount,severity);
}

@override
String toString() {
    return 'AuditFinding(id: $id, title: $title, category: $category, description: $description, clauseReference: $clauseReference, invoiceLineReference: $invoiceLineReference, searchKeyword: $searchKeyword, agreedRate: $agreedRate, billedRate: $billedRate, varianceAmount: $varianceAmount, severity: $severity)';
}


}

/// @nodoc
abstract mixin class _$AuditFindingCopyWith<$Res> implements $AuditFindingCopyWith<$Res> {
  factory _$AuditFindingCopyWith(_AuditFinding value, $Res Function(_AuditFinding) _then) = __$AuditFindingCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String category, String description, String clauseReference, String invoiceLineReference, String? searchKeyword, double? agreedRate, double? billedRate, double varianceAmount, String severity
});




}
/// @nodoc
class __$AuditFindingCopyWithImpl<$Res>
    implements _$AuditFindingCopyWith<$Res> {
  __$AuditFindingCopyWithImpl(this._self, this._then);

  final _AuditFinding _self;
  final $Res Function(_AuditFinding) _then;

/// Create a copy of AuditFinding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? category = null,Object? description = null,Object? clauseReference = null,Object? invoiceLineReference = null,Object? searchKeyword = freezed,Object? agreedRate = freezed,Object? billedRate = freezed,Object? varianceAmount = null,Object? severity = null,}) {
  return _then(_AuditFinding(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,clauseReference: null == clauseReference ? _self.clauseReference : clauseReference // ignore: cast_nullable_to_non_nullable
as String,invoiceLineReference: null == invoiceLineReference ? _self.invoiceLineReference : invoiceLineReference // ignore: cast_nullable_to_non_nullable
as String,searchKeyword: freezed == searchKeyword ? _self.searchKeyword : searchKeyword // ignore: cast_nullable_to_non_nullable
as String?,agreedRate: freezed == agreedRate ? _self.agreedRate : agreedRate // ignore: cast_nullable_to_non_nullable
as double?,billedRate: freezed == billedRate ? _self.billedRate : billedRate // ignore: cast_nullable_to_non_nullable
as double?,varianceAmount: null == varianceAmount ? _self.varianceAmount : varianceAmount // ignore: cast_nullable_to_non_nullable
as double,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
