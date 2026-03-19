// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'question_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuestionModel {

 int? get id; String get text; String get answer;@JsonKey(name: 'category_id') int get categoryId;@JsonKey(name: 'is_used') bool get isUsed;
/// Create a copy of QuestionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionModelCopyWith<QuestionModel> get copyWith => _$QuestionModelCopyWithImpl<QuestionModel>(this as QuestionModel, _$identity);

  /// Serializes this QuestionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.answer, answer) || other.answer == answer)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isUsed, isUsed) || other.isUsed == isUsed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text,answer,categoryId,isUsed);

@override
String toString() {
  return 'QuestionModel(id: $id, text: $text, answer: $answer, categoryId: $categoryId, isUsed: $isUsed)';
}


}

/// @nodoc
abstract mixin class $QuestionModelCopyWith<$Res>  {
  factory $QuestionModelCopyWith(QuestionModel value, $Res Function(QuestionModel) _then) = _$QuestionModelCopyWithImpl;
@useResult
$Res call({
 int? id, String text, String answer,@JsonKey(name: 'category_id') int categoryId,@JsonKey(name: 'is_used') bool isUsed
});




}
/// @nodoc
class _$QuestionModelCopyWithImpl<$Res>
    implements $QuestionModelCopyWith<$Res> {
  _$QuestionModelCopyWithImpl(this._self, this._then);

  final QuestionModel _self;
  final $Res Function(QuestionModel) _then;

/// Create a copy of QuestionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? text = null,Object? answer = null,Object? categoryId = null,Object? isUsed = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,isUsed: null == isUsed ? _self.isUsed : isUsed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [QuestionModel].
extension QuestionModelPatterns on QuestionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuestionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuestionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuestionModel value)  $default,){
final _that = this;
switch (_that) {
case _QuestionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuestionModel value)?  $default,){
final _that = this;
switch (_that) {
case _QuestionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String text,  String answer, @JsonKey(name: 'category_id')  int categoryId, @JsonKey(name: 'is_used')  bool isUsed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuestionModel() when $default != null:
return $default(_that.id,_that.text,_that.answer,_that.categoryId,_that.isUsed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String text,  String answer, @JsonKey(name: 'category_id')  int categoryId, @JsonKey(name: 'is_used')  bool isUsed)  $default,) {final _that = this;
switch (_that) {
case _QuestionModel():
return $default(_that.id,_that.text,_that.answer,_that.categoryId,_that.isUsed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String text,  String answer, @JsonKey(name: 'category_id')  int categoryId, @JsonKey(name: 'is_used')  bool isUsed)?  $default,) {final _that = this;
switch (_that) {
case _QuestionModel() when $default != null:
return $default(_that.id,_that.text,_that.answer,_that.categoryId,_that.isUsed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuestionModel implements QuestionModel {
  const _QuestionModel({this.id, required this.text, required this.answer, @JsonKey(name: 'category_id') required this.categoryId, @JsonKey(name: 'is_used') this.isUsed = false});
  factory _QuestionModel.fromJson(Map<String, dynamic> json) => _$QuestionModelFromJson(json);

@override final  int? id;
@override final  String text;
@override final  String answer;
@override@JsonKey(name: 'category_id') final  int categoryId;
@override@JsonKey(name: 'is_used') final  bool isUsed;

/// Create a copy of QuestionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionModelCopyWith<_QuestionModel> get copyWith => __$QuestionModelCopyWithImpl<_QuestionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuestionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.answer, answer) || other.answer == answer)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isUsed, isUsed) || other.isUsed == isUsed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text,answer,categoryId,isUsed);

@override
String toString() {
  return 'QuestionModel(id: $id, text: $text, answer: $answer, categoryId: $categoryId, isUsed: $isUsed)';
}


}

/// @nodoc
abstract mixin class _$QuestionModelCopyWith<$Res> implements $QuestionModelCopyWith<$Res> {
  factory _$QuestionModelCopyWith(_QuestionModel value, $Res Function(_QuestionModel) _then) = __$QuestionModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String text, String answer,@JsonKey(name: 'category_id') int categoryId,@JsonKey(name: 'is_used') bool isUsed
});




}
/// @nodoc
class __$QuestionModelCopyWithImpl<$Res>
    implements _$QuestionModelCopyWith<$Res> {
  __$QuestionModelCopyWithImpl(this._self, this._then);

  final _QuestionModel _self;
  final $Res Function(_QuestionModel) _then;

/// Create a copy of QuestionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? text = null,Object? answer = null,Object? categoryId = null,Object? isUsed = null,}) {
  return _then(_QuestionModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,isUsed: null == isUsed ? _self.isUsed : isUsed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
