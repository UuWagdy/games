// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wheel_segment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WheelSegmentModel {

 int? get id; String get text; int get points;@JsonKey(name: 'is_question') bool get isQuestion;@JsonKey(name: 'category_ids') List<int> get categoryIds;
/// Create a copy of WheelSegmentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WheelSegmentModelCopyWith<WheelSegmentModel> get copyWith => _$WheelSegmentModelCopyWithImpl<WheelSegmentModel>(this as WheelSegmentModel, _$identity);

  /// Serializes this WheelSegmentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WheelSegmentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.points, points) || other.points == points)&&(identical(other.isQuestion, isQuestion) || other.isQuestion == isQuestion)&&const DeepCollectionEquality().equals(other.categoryIds, categoryIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text,points,isQuestion,const DeepCollectionEquality().hash(categoryIds));

@override
String toString() {
  return 'WheelSegmentModel(id: $id, text: $text, points: $points, isQuestion: $isQuestion, categoryIds: $categoryIds)';
}


}

/// @nodoc
abstract mixin class $WheelSegmentModelCopyWith<$Res>  {
  factory $WheelSegmentModelCopyWith(WheelSegmentModel value, $Res Function(WheelSegmentModel) _then) = _$WheelSegmentModelCopyWithImpl;
@useResult
$Res call({
 int? id, String text, int points,@JsonKey(name: 'is_question') bool isQuestion,@JsonKey(name: 'category_ids') List<int> categoryIds
});




}
/// @nodoc
class _$WheelSegmentModelCopyWithImpl<$Res>
    implements $WheelSegmentModelCopyWith<$Res> {
  _$WheelSegmentModelCopyWithImpl(this._self, this._then);

  final WheelSegmentModel _self;
  final $Res Function(WheelSegmentModel) _then;

/// Create a copy of WheelSegmentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? text = null,Object? points = null,Object? isQuestion = null,Object? categoryIds = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,isQuestion: null == isQuestion ? _self.isQuestion : isQuestion // ignore: cast_nullable_to_non_nullable
as bool,categoryIds: null == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}

}


/// Adds pattern-matching-related methods to [WheelSegmentModel].
extension WheelSegmentModelPatterns on WheelSegmentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WheelSegmentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WheelSegmentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WheelSegmentModel value)  $default,){
final _that = this;
switch (_that) {
case _WheelSegmentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WheelSegmentModel value)?  $default,){
final _that = this;
switch (_that) {
case _WheelSegmentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String text,  int points, @JsonKey(name: 'is_question')  bool isQuestion, @JsonKey(name: 'category_ids')  List<int> categoryIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WheelSegmentModel() when $default != null:
return $default(_that.id,_that.text,_that.points,_that.isQuestion,_that.categoryIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String text,  int points, @JsonKey(name: 'is_question')  bool isQuestion, @JsonKey(name: 'category_ids')  List<int> categoryIds)  $default,) {final _that = this;
switch (_that) {
case _WheelSegmentModel():
return $default(_that.id,_that.text,_that.points,_that.isQuestion,_that.categoryIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String text,  int points, @JsonKey(name: 'is_question')  bool isQuestion, @JsonKey(name: 'category_ids')  List<int> categoryIds)?  $default,) {final _that = this;
switch (_that) {
case _WheelSegmentModel() when $default != null:
return $default(_that.id,_that.text,_that.points,_that.isQuestion,_that.categoryIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WheelSegmentModel implements WheelSegmentModel {
  const _WheelSegmentModel({this.id, required this.text, required this.points, @JsonKey(name: 'is_question') this.isQuestion = false, @JsonKey(name: 'category_ids') final  List<int> categoryIds = const []}): _categoryIds = categoryIds;
  factory _WheelSegmentModel.fromJson(Map<String, dynamic> json) => _$WheelSegmentModelFromJson(json);

@override final  int? id;
@override final  String text;
@override final  int points;
@override@JsonKey(name: 'is_question') final  bool isQuestion;
 final  List<int> _categoryIds;
@override@JsonKey(name: 'category_ids') List<int> get categoryIds {
  if (_categoryIds is EqualUnmodifiableListView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryIds);
}


/// Create a copy of WheelSegmentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WheelSegmentModelCopyWith<_WheelSegmentModel> get copyWith => __$WheelSegmentModelCopyWithImpl<_WheelSegmentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WheelSegmentModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WheelSegmentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.points, points) || other.points == points)&&(identical(other.isQuestion, isQuestion) || other.isQuestion == isQuestion)&&const DeepCollectionEquality().equals(other._categoryIds, _categoryIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text,points,isQuestion,const DeepCollectionEquality().hash(_categoryIds));

@override
String toString() {
  return 'WheelSegmentModel(id: $id, text: $text, points: $points, isQuestion: $isQuestion, categoryIds: $categoryIds)';
}


}

/// @nodoc
abstract mixin class _$WheelSegmentModelCopyWith<$Res> implements $WheelSegmentModelCopyWith<$Res> {
  factory _$WheelSegmentModelCopyWith(_WheelSegmentModel value, $Res Function(_WheelSegmentModel) _then) = __$WheelSegmentModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String text, int points,@JsonKey(name: 'is_question') bool isQuestion,@JsonKey(name: 'category_ids') List<int> categoryIds
});




}
/// @nodoc
class __$WheelSegmentModelCopyWithImpl<$Res>
    implements _$WheelSegmentModelCopyWith<$Res> {
  __$WheelSegmentModelCopyWithImpl(this._self, this._then);

  final _WheelSegmentModel _self;
  final $Res Function(_WheelSegmentModel) _then;

/// Create a copy of WheelSegmentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? text = null,Object? points = null,Object? isQuestion = null,Object? categoryIds = null,}) {
  return _then(_WheelSegmentModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,isQuestion: null == isQuestion ? _self.isQuestion : isQuestion // ignore: cast_nullable_to_non_nullable
as bool,categoryIds: null == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

// dart format on
