// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'team_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TeamModel {

 int? get id; String get name; int get score;@JsonKey(name: 'players_count') int get playersCount;
/// Create a copy of TeamModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TeamModelCopyWith<TeamModel> get copyWith => _$TeamModelCopyWithImpl<TeamModel>(this as TeamModel, _$identity);

  /// Serializes this TeamModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TeamModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.score, score) || other.score == score)&&(identical(other.playersCount, playersCount) || other.playersCount == playersCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,score,playersCount);

@override
String toString() {
  return 'TeamModel(id: $id, name: $name, score: $score, playersCount: $playersCount)';
}


}

/// @nodoc
abstract mixin class $TeamModelCopyWith<$Res>  {
  factory $TeamModelCopyWith(TeamModel value, $Res Function(TeamModel) _then) = _$TeamModelCopyWithImpl;
@useResult
$Res call({
 int? id, String name, int score,@JsonKey(name: 'players_count') int playersCount
});




}
/// @nodoc
class _$TeamModelCopyWithImpl<$Res>
    implements $TeamModelCopyWith<$Res> {
  _$TeamModelCopyWithImpl(this._self, this._then);

  final TeamModel _self;
  final $Res Function(TeamModel) _then;

/// Create a copy of TeamModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? name = null,Object? score = null,Object? playersCount = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,playersCount: null == playersCount ? _self.playersCount : playersCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TeamModel].
extension TeamModelPatterns on TeamModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TeamModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TeamModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TeamModel value)  $default,){
final _that = this;
switch (_that) {
case _TeamModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TeamModel value)?  $default,){
final _that = this;
switch (_that) {
case _TeamModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String name,  int score, @JsonKey(name: 'players_count')  int playersCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TeamModel() when $default != null:
return $default(_that.id,_that.name,_that.score,_that.playersCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String name,  int score, @JsonKey(name: 'players_count')  int playersCount)  $default,) {final _that = this;
switch (_that) {
case _TeamModel():
return $default(_that.id,_that.name,_that.score,_that.playersCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String name,  int score, @JsonKey(name: 'players_count')  int playersCount)?  $default,) {final _that = this;
switch (_that) {
case _TeamModel() when $default != null:
return $default(_that.id,_that.name,_that.score,_that.playersCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TeamModel implements TeamModel {
  const _TeamModel({this.id, required this.name, this.score = 0, @JsonKey(name: 'players_count') this.playersCount = 0});
  factory _TeamModel.fromJson(Map<String, dynamic> json) => _$TeamModelFromJson(json);

@override final  int? id;
@override final  String name;
@override@JsonKey() final  int score;
@override@JsonKey(name: 'players_count') final  int playersCount;

/// Create a copy of TeamModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TeamModelCopyWith<_TeamModel> get copyWith => __$TeamModelCopyWithImpl<_TeamModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TeamModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TeamModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.score, score) || other.score == score)&&(identical(other.playersCount, playersCount) || other.playersCount == playersCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,score,playersCount);

@override
String toString() {
  return 'TeamModel(id: $id, name: $name, score: $score, playersCount: $playersCount)';
}


}

/// @nodoc
abstract mixin class _$TeamModelCopyWith<$Res> implements $TeamModelCopyWith<$Res> {
  factory _$TeamModelCopyWith(_TeamModel value, $Res Function(_TeamModel) _then) = __$TeamModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, String name, int score,@JsonKey(name: 'players_count') int playersCount
});




}
/// @nodoc
class __$TeamModelCopyWithImpl<$Res>
    implements _$TeamModelCopyWith<$Res> {
  __$TeamModelCopyWithImpl(this._self, this._then);

  final _TeamModel _self;
  final $Res Function(_TeamModel) _then;

/// Create a copy of TeamModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? name = null,Object? score = null,Object? playersCount = null,}) {
  return _then(_TeamModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,playersCount: null == playersCount ? _self.playersCount : playersCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
