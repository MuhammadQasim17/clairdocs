// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvoiceDocument {

 String get id; String get filePath; String get fileName; int get fileSizeBytes; String get sha256Hash; int get pageCount; DateTime get loadedAt;
/// Create a copy of InvoiceDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceDocumentCopyWith<InvoiceDocument> get copyWith => _$InvoiceDocumentCopyWithImpl<InvoiceDocument>(this as InvoiceDocument, _$identity);

  /// Serializes this InvoiceDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InvoiceDocument;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvoiceDocument&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.filePath, _this.filePath) || other.filePath == _this.filePath)&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.fileSizeBytes, _this.fileSizeBytes) || other.fileSizeBytes == _this.fileSizeBytes)&&(identical(other.sha256Hash, _this.sha256Hash) || other.sha256Hash == _this.sha256Hash)&&(identical(other.pageCount, _this.pageCount) || other.pageCount == _this.pageCount)&&(identical(other.loadedAt, _this.loadedAt) || other.loadedAt == _this.loadedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InvoiceDocument;
  return Object.hash(runtimeType,_this.id,_this.filePath,_this.fileName,_this.fileSizeBytes,_this.sha256Hash,_this.pageCount,_this.loadedAt);
}

@override
String toString() {
  final _this = this as InvoiceDocument;
  return 'InvoiceDocument(id: ${_this.id}, filePath: ${_this.filePath}, fileName: ${_this.fileName}, fileSizeBytes: ${_this.fileSizeBytes}, sha256Hash: ${_this.sha256Hash}, pageCount: ${_this.pageCount}, loadedAt: ${_this.loadedAt})';
}


}

/// @nodoc
abstract mixin class $InvoiceDocumentCopyWith<$Res>  {
  factory $InvoiceDocumentCopyWith(InvoiceDocument value, $Res Function(InvoiceDocument) _then) = _$InvoiceDocumentCopyWithImpl;
@useResult
$Res call({
 String id, String filePath, String fileName, int fileSizeBytes, String sha256Hash, int pageCount, DateTime loadedAt
});




}
/// @nodoc
class _$InvoiceDocumentCopyWithImpl<$Res>
    implements $InvoiceDocumentCopyWith<$Res> {
  _$InvoiceDocumentCopyWithImpl(this._self, this._then);

  final InvoiceDocument _self;
  final $Res Function(InvoiceDocument) _then;

/// Create a copy of InvoiceDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? filePath = null,Object? fileName = null,Object? fileSizeBytes = null,Object? sha256Hash = null,Object? pageCount = null,Object? loadedAt = null,}) {
  return _then(InvoiceDocument(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,fileSizeBytes: null == fileSizeBytes ? _self.fileSizeBytes : fileSizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha256Hash: null == sha256Hash ? _self.sha256Hash : sha256Hash // ignore: cast_nullable_to_non_nullable
as String,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,loadedAt: null == loadedAt ? _self.loadedAt : loadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [InvoiceDocument].
extension InvoiceDocumentPatterns on InvoiceDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvoiceDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvoiceDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvoiceDocument value)  $default,){
final _that = this;
switch (_that) {
case _InvoiceDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvoiceDocument value)?  $default,){
final _that = this;
switch (_that) {
case _InvoiceDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String filePath,  String fileName,  int fileSizeBytes,  String sha256Hash,  int pageCount,  DateTime loadedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvoiceDocument() when $default != null:
return $default(_that.id,_that.filePath,_that.fileName,_that.fileSizeBytes,_that.sha256Hash,_that.pageCount,_that.loadedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String filePath,  String fileName,  int fileSizeBytes,  String sha256Hash,  int pageCount,  DateTime loadedAt)  $default,) {final _that = this;
switch (_that) {
case _InvoiceDocument():
return $default(_that.id,_that.filePath,_that.fileName,_that.fileSizeBytes,_that.sha256Hash,_that.pageCount,_that.loadedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String filePath,  String fileName,  int fileSizeBytes,  String sha256Hash,  int pageCount,  DateTime loadedAt)?  $default,) {final _that = this;
switch (_that) {
case _InvoiceDocument() when $default != null:
return $default(_that.id,_that.filePath,_that.fileName,_that.fileSizeBytes,_that.sha256Hash,_that.pageCount,_that.loadedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvoiceDocument extends InvoiceDocument {
  const _InvoiceDocument({required this.id, required this.filePath, required this.fileName, required this.fileSizeBytes, required this.sha256Hash, this.pageCount = 0, required this.loadedAt}): super._();
  factory _InvoiceDocument.fromJson(Map<String, dynamic> json) => _$InvoiceDocumentFromJson(json);

@override final  String id;
@override final  String filePath;
@override final  String fileName;
@override final  int fileSizeBytes;
@override final  String sha256Hash;
@override@JsonKey() final  int pageCount;
@override final  DateTime loadedAt;

/// Create a copy of InvoiceDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceDocumentCopyWith<_InvoiceDocument> get copyWith => __$InvoiceDocumentCopyWithImpl<_InvoiceDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvoiceDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvoiceDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileSizeBytes, fileSizeBytes) || other.fileSizeBytes == fileSizeBytes)&&(identical(other.sha256Hash, sha256Hash) || other.sha256Hash == sha256Hash)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.loadedAt, loadedAt) || other.loadedAt == loadedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,filePath,fileName,fileSizeBytes,sha256Hash,pageCount,loadedAt);
}

@override
String toString() {
    return 'InvoiceDocument(id: $id, filePath: $filePath, fileName: $fileName, fileSizeBytes: $fileSizeBytes, sha256Hash: $sha256Hash, pageCount: $pageCount, loadedAt: $loadedAt)';
}


}

/// @nodoc
abstract mixin class _$InvoiceDocumentCopyWith<$Res> implements $InvoiceDocumentCopyWith<$Res> {
  factory _$InvoiceDocumentCopyWith(_InvoiceDocument value, $Res Function(_InvoiceDocument) _then) = __$InvoiceDocumentCopyWithImpl;
@override @useResult
$Res call({
 String id, String filePath, String fileName, int fileSizeBytes, String sha256Hash, int pageCount, DateTime loadedAt
});




}
/// @nodoc
class __$InvoiceDocumentCopyWithImpl<$Res>
    implements _$InvoiceDocumentCopyWith<$Res> {
  __$InvoiceDocumentCopyWithImpl(this._self, this._then);

  final _InvoiceDocument _self;
  final $Res Function(_InvoiceDocument) _then;

/// Create a copy of InvoiceDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? filePath = null,Object? fileName = null,Object? fileSizeBytes = null,Object? sha256Hash = null,Object? pageCount = null,Object? loadedAt = null,}) {
  return _then(_InvoiceDocument(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,fileSizeBytes: null == fileSizeBytes ? _self.fileSizeBytes : fileSizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha256Hash: null == sha256Hash ? _self.sha256Hash : sha256Hash // ignore: cast_nullable_to_non_nullable
as String,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,loadedAt: null == loadedAt ? _self.loadedAt : loadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$InvoiceState {

 InvoiceDocument? get document; bool get isLoading; bool get isDemoMode; String? get errorMessage;
/// Create a copy of InvoiceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceStateCopyWith<InvoiceState> get copyWith => _$InvoiceStateCopyWithImpl<InvoiceState>(this as InvoiceState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as InvoiceState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvoiceState&&(identical(other.document, _this.document) || other.document == _this.document)&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading)&&(identical(other.isDemoMode, _this.isDemoMode) || other.isDemoMode == _this.isDemoMode)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as InvoiceState;
  return Object.hash(runtimeType,_this.document,_this.isLoading,_this.isDemoMode,_this.errorMessage);
}

@override
String toString() {
  final _this = this as InvoiceState;
  return 'InvoiceState(document: ${_this.document}, isLoading: ${_this.isLoading}, isDemoMode: ${_this.isDemoMode}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $InvoiceStateCopyWith<$Res>  {
  factory $InvoiceStateCopyWith(InvoiceState value, $Res Function(InvoiceState) _then) = _$InvoiceStateCopyWithImpl;
@useResult
$Res call({
 InvoiceDocument? document, bool isLoading, bool isDemoMode, String? errorMessage
});


$InvoiceDocumentCopyWith<$Res>? get document;

}
/// @nodoc
class _$InvoiceStateCopyWithImpl<$Res>
    implements $InvoiceStateCopyWith<$Res> {
  _$InvoiceStateCopyWithImpl(this._self, this._then);

  final InvoiceState _self;
  final $Res Function(InvoiceState) _then;

/// Create a copy of InvoiceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? document = freezed,Object? isLoading = null,Object? isDemoMode = null,Object? errorMessage = freezed,}) {
  return _then(InvoiceState(
document: freezed == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as InvoiceDocument?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isDemoMode: null == isDemoMode ? _self.isDemoMode : isDemoMode // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of InvoiceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvoiceDocumentCopyWith<$Res>? get document {
    if (_self.document == null) {
    return null;
  }

  return $InvoiceDocumentCopyWith<$Res>(_self.document!, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}


/// Adds pattern-matching-related methods to [InvoiceState].
extension InvoiceStatePatterns on InvoiceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvoiceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvoiceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvoiceState value)  $default,){
final _that = this;
switch (_that) {
case _InvoiceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvoiceState value)?  $default,){
final _that = this;
switch (_that) {
case _InvoiceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( InvoiceDocument? document,  bool isLoading,  bool isDemoMode,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvoiceState() when $default != null:
return $default(_that.document,_that.isLoading,_that.isDemoMode,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( InvoiceDocument? document,  bool isLoading,  bool isDemoMode,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _InvoiceState():
return $default(_that.document,_that.isLoading,_that.isDemoMode,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( InvoiceDocument? document,  bool isLoading,  bool isDemoMode,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _InvoiceState() when $default != null:
return $default(_that.document,_that.isLoading,_that.isDemoMode,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _InvoiceState implements InvoiceState {
  const _InvoiceState({this.document, this.isLoading = false, this.isDemoMode = false, this.errorMessage});
  

@override final  InvoiceDocument? document;
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isDemoMode;
@override final  String? errorMessage;

/// Create a copy of InvoiceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceStateCopyWith<_InvoiceState> get copyWith => __$InvoiceStateCopyWithImpl<_InvoiceState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvoiceState&&(identical(other.document, document) || other.document == document)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isDemoMode, isDemoMode) || other.isDemoMode == isDemoMode)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,document,isLoading,isDemoMode,errorMessage);
}

@override
String toString() {
    return 'InvoiceState(document: $document, isLoading: $isLoading, isDemoMode: $isDemoMode, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$InvoiceStateCopyWith<$Res> implements $InvoiceStateCopyWith<$Res> {
  factory _$InvoiceStateCopyWith(_InvoiceState value, $Res Function(_InvoiceState) _then) = __$InvoiceStateCopyWithImpl;
@override @useResult
$Res call({
 InvoiceDocument? document, bool isLoading, bool isDemoMode, String? errorMessage
});


@override $InvoiceDocumentCopyWith<$Res>? get document;

}
/// @nodoc
class __$InvoiceStateCopyWithImpl<$Res>
    implements _$InvoiceStateCopyWith<$Res> {
  __$InvoiceStateCopyWithImpl(this._self, this._then);

  final _InvoiceState _self;
  final $Res Function(_InvoiceState) _then;

/// Create a copy of InvoiceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? document = freezed,Object? isLoading = null,Object? isDemoMode = null,Object? errorMessage = freezed,}) {
  return _then(_InvoiceState(
document: freezed == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as InvoiceDocument?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isDemoMode: null == isDemoMode ? _self.isDemoMode : isDemoMode // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of InvoiceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvoiceDocumentCopyWith<$Res>? get document {
    if (_self.document == null) {
    return null;
  }

  return $InvoiceDocumentCopyWith<$Res>(_self.document!, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}

// dart format on
