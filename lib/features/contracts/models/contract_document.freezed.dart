// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'contract_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ContractDocument {

 String get id; String get filePath; String get fileName; int get fileSizeBytes; String get sha256Hash; int get pageCount; DateTime get loadedAt;
/// Create a copy of ContractDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractDocumentCopyWith<ContractDocument> get copyWith => _$ContractDocumentCopyWithImpl<ContractDocument>(this as ContractDocument, _$identity);

  /// Serializes this ContractDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ContractDocument;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractDocument&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.filePath, _this.filePath) || other.filePath == _this.filePath)&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.fileSizeBytes, _this.fileSizeBytes) || other.fileSizeBytes == _this.fileSizeBytes)&&(identical(other.sha256Hash, _this.sha256Hash) || other.sha256Hash == _this.sha256Hash)&&(identical(other.pageCount, _this.pageCount) || other.pageCount == _this.pageCount)&&(identical(other.loadedAt, _this.loadedAt) || other.loadedAt == _this.loadedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ContractDocument;
  return Object.hash(runtimeType,_this.id,_this.filePath,_this.fileName,_this.fileSizeBytes,_this.sha256Hash,_this.pageCount,_this.loadedAt);
}

@override
String toString() {
  final _this = this as ContractDocument;
  return 'ContractDocument(id: ${_this.id}, filePath: ${_this.filePath}, fileName: ${_this.fileName}, fileSizeBytes: ${_this.fileSizeBytes}, sha256Hash: ${_this.sha256Hash}, pageCount: ${_this.pageCount}, loadedAt: ${_this.loadedAt})';
}


}

/// @nodoc
abstract mixin class $ContractDocumentCopyWith<$Res>  {
  factory $ContractDocumentCopyWith(ContractDocument value, $Res Function(ContractDocument) _then) = _$ContractDocumentCopyWithImpl;
@useResult
$Res call({
 String id, String filePath, String fileName, int fileSizeBytes, String sha256Hash, int pageCount, DateTime loadedAt
});




}
/// @nodoc
class _$ContractDocumentCopyWithImpl<$Res>
    implements $ContractDocumentCopyWith<$Res> {
  _$ContractDocumentCopyWithImpl(this._self, this._then);

  final ContractDocument _self;
  final $Res Function(ContractDocument) _then;

/// Create a copy of ContractDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? filePath = null,Object? fileName = null,Object? fileSizeBytes = null,Object? sha256Hash = null,Object? pageCount = null,Object? loadedAt = null,}) {
  return _then(ContractDocument(
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


/// Adds pattern-matching-related methods to [ContractDocument].
extension ContractDocumentPatterns on ContractDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContractDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContractDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContractDocument value)  $default,){
final _that = this;
switch (_that) {
case _ContractDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContractDocument value)?  $default,){
final _that = this;
switch (_that) {
case _ContractDocument() when $default != null:
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
case _ContractDocument() when $default != null:
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
case _ContractDocument():
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
case _ContractDocument() when $default != null:
return $default(_that.id,_that.filePath,_that.fileName,_that.fileSizeBytes,_that.sha256Hash,_that.pageCount,_that.loadedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ContractDocument extends ContractDocument {
  const _ContractDocument({required this.id, required this.filePath, required this.fileName, required this.fileSizeBytes, required this.sha256Hash, this.pageCount = 0, required this.loadedAt}): super._();
  factory _ContractDocument.fromJson(Map<String, dynamic> json) => _$ContractDocumentFromJson(json);

@override final  String id;
@override final  String filePath;
@override final  String fileName;
@override final  int fileSizeBytes;
@override final  String sha256Hash;
@override@JsonKey() final  int pageCount;
@override final  DateTime loadedAt;

/// Create a copy of ContractDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractDocumentCopyWith<_ContractDocument> get copyWith => __$ContractDocumentCopyWithImpl<_ContractDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContractDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileSizeBytes, fileSizeBytes) || other.fileSizeBytes == fileSizeBytes)&&(identical(other.sha256Hash, sha256Hash) || other.sha256Hash == sha256Hash)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.loadedAt, loadedAt) || other.loadedAt == loadedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,filePath,fileName,fileSizeBytes,sha256Hash,pageCount,loadedAt);
}

@override
String toString() {
    return 'ContractDocument(id: $id, filePath: $filePath, fileName: $fileName, fileSizeBytes: $fileSizeBytes, sha256Hash: $sha256Hash, pageCount: $pageCount, loadedAt: $loadedAt)';
}


}

/// @nodoc
abstract mixin class _$ContractDocumentCopyWith<$Res> implements $ContractDocumentCopyWith<$Res> {
  factory _$ContractDocumentCopyWith(_ContractDocument value, $Res Function(_ContractDocument) _then) = __$ContractDocumentCopyWithImpl;
@override @useResult
$Res call({
 String id, String filePath, String fileName, int fileSizeBytes, String sha256Hash, int pageCount, DateTime loadedAt
});




}
/// @nodoc
class __$ContractDocumentCopyWithImpl<$Res>
    implements _$ContractDocumentCopyWith<$Res> {
  __$ContractDocumentCopyWithImpl(this._self, this._then);

  final _ContractDocument _self;
  final $Res Function(_ContractDocument) _then;

/// Create a copy of ContractDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? filePath = null,Object? fileName = null,Object? fileSizeBytes = null,Object? sha256Hash = null,Object? pageCount = null,Object? loadedAt = null,}) {
  return _then(_ContractDocument(
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
mixin _$ContractState {

 ContractDocument? get document; bool get isLoading; bool get isDemoMode; String? get errorMessage;
/// Create a copy of ContractState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContractStateCopyWith<ContractState> get copyWith => _$ContractStateCopyWithImpl<ContractState>(this as ContractState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ContractState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContractState&&(identical(other.document, _this.document) || other.document == _this.document)&&(identical(other.isLoading, _this.isLoading) || other.isLoading == _this.isLoading)&&(identical(other.isDemoMode, _this.isDemoMode) || other.isDemoMode == _this.isDemoMode)&&(identical(other.errorMessage, _this.errorMessage) || other.errorMessage == _this.errorMessage));
}


@override
int get hashCode {
  final _this = this as ContractState;
  return Object.hash(runtimeType,_this.document,_this.isLoading,_this.isDemoMode,_this.errorMessage);
}

@override
String toString() {
  final _this = this as ContractState;
  return 'ContractState(document: ${_this.document}, isLoading: ${_this.isLoading}, isDemoMode: ${_this.isDemoMode}, errorMessage: ${_this.errorMessage})';
}


}

/// @nodoc
abstract mixin class $ContractStateCopyWith<$Res>  {
  factory $ContractStateCopyWith(ContractState value, $Res Function(ContractState) _then) = _$ContractStateCopyWithImpl;
@useResult
$Res call({
 ContractDocument? document, bool isLoading, bool isDemoMode, String? errorMessage
});


$ContractDocumentCopyWith<$Res>? get document;

}
/// @nodoc
class _$ContractStateCopyWithImpl<$Res>
    implements $ContractStateCopyWith<$Res> {
  _$ContractStateCopyWithImpl(this._self, this._then);

  final ContractState _self;
  final $Res Function(ContractState) _then;

/// Create a copy of ContractState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? document = freezed,Object? isLoading = null,Object? isDemoMode = null,Object? errorMessage = freezed,}) {
  return _then(ContractState(
document: freezed == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as ContractDocument?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isDemoMode: null == isDemoMode ? _self.isDemoMode : isDemoMode // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ContractState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContractDocumentCopyWith<$Res>? get document {
    if (_self.document == null) {
    return null;
  }

  return $ContractDocumentCopyWith<$Res>(_self.document!, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}


/// Adds pattern-matching-related methods to [ContractState].
extension ContractStatePatterns on ContractState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ContractState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ContractState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ContractState value)  $default,){
final _that = this;
switch (_that) {
case _ContractState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ContractState value)?  $default,){
final _that = this;
switch (_that) {
case _ContractState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ContractDocument? document,  bool isLoading,  bool isDemoMode,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ContractState() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ContractDocument? document,  bool isLoading,  bool isDemoMode,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _ContractState():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ContractDocument? document,  bool isLoading,  bool isDemoMode,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _ContractState() when $default != null:
return $default(_that.document,_that.isLoading,_that.isDemoMode,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _ContractState implements ContractState {
  const _ContractState({this.document, this.isLoading = false, this.isDemoMode = false, this.errorMessage});
  

@override final  ContractDocument? document;
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isDemoMode;
@override final  String? errorMessage;

/// Create a copy of ContractState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContractStateCopyWith<_ContractState> get copyWith => __$ContractStateCopyWithImpl<_ContractState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ContractState&&(identical(other.document, document) || other.document == document)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isDemoMode, isDemoMode) || other.isDemoMode == isDemoMode)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode {
    return Object.hash(runtimeType,document,isLoading,isDemoMode,errorMessage);
}

@override
String toString() {
    return 'ContractState(document: $document, isLoading: $isLoading, isDemoMode: $isDemoMode, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$ContractStateCopyWith<$Res> implements $ContractStateCopyWith<$Res> {
  factory _$ContractStateCopyWith(_ContractState value, $Res Function(_ContractState) _then) = __$ContractStateCopyWithImpl;
@override @useResult
$Res call({
 ContractDocument? document, bool isLoading, bool isDemoMode, String? errorMessage
});


@override $ContractDocumentCopyWith<$Res>? get document;

}
/// @nodoc
class __$ContractStateCopyWithImpl<$Res>
    implements _$ContractStateCopyWith<$Res> {
  __$ContractStateCopyWithImpl(this._self, this._then);

  final _ContractState _self;
  final $Res Function(_ContractState) _then;

/// Create a copy of ContractState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? document = freezed,Object? isLoading = null,Object? isDemoMode = null,Object? errorMessage = freezed,}) {
  return _then(_ContractState(
document: freezed == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as ContractDocument?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isDemoMode: null == isDemoMode ? _self.isDemoMode : isDemoMode // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ContractState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContractDocumentCopyWith<$Res>? get document {
    if (_self.document == null) {
    return null;
  }

  return $ContractDocumentCopyWith<$Res>(_self.document!, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}

// dart format on
