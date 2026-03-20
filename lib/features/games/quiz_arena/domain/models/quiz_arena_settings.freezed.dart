// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_arena_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuizArenaSettings {

 List<int> get categoryIds; List<int> get selectedTeamIds; Map<int, int> get categoryPoints;// categoryId -> points
 int get numberOfTeams; List<String> get teamNames; bool get timerEnabled; int get timeLimitSeconds; int get negativePoints; int get rounds;
/// Create a copy of QuizArenaSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizArenaSettingsCopyWith<QuizArenaSettings> get copyWith => _$QuizArenaSettingsCopyWithImpl<QuizArenaSettings>(this as QuizArenaSettings, _$identity);

  /// Serializes this QuizArenaSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizArenaSettings&&const DeepCollectionEquality().equals(other.categoryIds, categoryIds)&&const DeepCollectionEquality().equals(other.selectedTeamIds, selectedTeamIds)&&const DeepCollectionEquality().equals(other.categoryPoints, categoryPoints)&&(identical(other.numberOfTeams, numberOfTeams) || other.numberOfTeams == numberOfTeams)&&const DeepCollectionEquality().equals(other.teamNames, teamNames)&&(identical(other.timerEnabled, timerEnabled) || other.timerEnabled == timerEnabled)&&(identical(other.timeLimitSeconds, timeLimitSeconds) || other.timeLimitSeconds == timeLimitSeconds)&&(identical(other.negativePoints, negativePoints) || other.negativePoints == negativePoints)&&(identical(other.rounds, rounds) || other.rounds == rounds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categoryIds),const DeepCollectionEquality().hash(selectedTeamIds),const DeepCollectionEquality().hash(categoryPoints),numberOfTeams,const DeepCollectionEquality().hash(teamNames),timerEnabled,timeLimitSeconds,negativePoints,rounds);

@override
String toString() {
  return 'QuizArenaSettings(categoryIds: $categoryIds, selectedTeamIds: $selectedTeamIds, categoryPoints: $categoryPoints, numberOfTeams: $numberOfTeams, teamNames: $teamNames, timerEnabled: $timerEnabled, timeLimitSeconds: $timeLimitSeconds, negativePoints: $negativePoints, rounds: $rounds)';
}


}

/// @nodoc
abstract mixin class $QuizArenaSettingsCopyWith<$Res>  {
  factory $QuizArenaSettingsCopyWith(QuizArenaSettings value, $Res Function(QuizArenaSettings) _then) = _$QuizArenaSettingsCopyWithImpl;
@useResult
$Res call({
 List<int> categoryIds, List<int> selectedTeamIds, Map<int, int> categoryPoints, int numberOfTeams, List<String> teamNames, bool timerEnabled, int timeLimitSeconds, int negativePoints, int rounds
});




}
/// @nodoc
class _$QuizArenaSettingsCopyWithImpl<$Res>
    implements $QuizArenaSettingsCopyWith<$Res> {
  _$QuizArenaSettingsCopyWithImpl(this._self, this._then);

  final QuizArenaSettings _self;
  final $Res Function(QuizArenaSettings) _then;

/// Create a copy of QuizArenaSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryIds = null,Object? selectedTeamIds = null,Object? categoryPoints = null,Object? numberOfTeams = null,Object? teamNames = null,Object? timerEnabled = null,Object? timeLimitSeconds = null,Object? negativePoints = null,Object? rounds = null,}) {
  return _then(_self.copyWith(
categoryIds: null == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,selectedTeamIds: null == selectedTeamIds ? _self.selectedTeamIds : selectedTeamIds // ignore: cast_nullable_to_non_nullable
as List<int>,categoryPoints: null == categoryPoints ? _self.categoryPoints : categoryPoints // ignore: cast_nullable_to_non_nullable
as Map<int, int>,numberOfTeams: null == numberOfTeams ? _self.numberOfTeams : numberOfTeams // ignore: cast_nullable_to_non_nullable
as int,teamNames: null == teamNames ? _self.teamNames : teamNames // ignore: cast_nullable_to_non_nullable
as List<String>,timerEnabled: null == timerEnabled ? _self.timerEnabled : timerEnabled // ignore: cast_nullable_to_non_nullable
as bool,timeLimitSeconds: null == timeLimitSeconds ? _self.timeLimitSeconds : timeLimitSeconds // ignore: cast_nullable_to_non_nullable
as int,negativePoints: null == negativePoints ? _self.negativePoints : negativePoints // ignore: cast_nullable_to_non_nullable
as int,rounds: null == rounds ? _self.rounds : rounds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [QuizArenaSettings].
extension QuizArenaSettingsPatterns on QuizArenaSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizArenaSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizArenaSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizArenaSettings value)  $default,){
final _that = this;
switch (_that) {
case _QuizArenaSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizArenaSettings value)?  $default,){
final _that = this;
switch (_that) {
case _QuizArenaSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<int> categoryIds,  List<int> selectedTeamIds,  Map<int, int> categoryPoints,  int numberOfTeams,  List<String> teamNames,  bool timerEnabled,  int timeLimitSeconds,  int negativePoints,  int rounds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizArenaSettings() when $default != null:
return $default(_that.categoryIds,_that.selectedTeamIds,_that.categoryPoints,_that.numberOfTeams,_that.teamNames,_that.timerEnabled,_that.timeLimitSeconds,_that.negativePoints,_that.rounds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<int> categoryIds,  List<int> selectedTeamIds,  Map<int, int> categoryPoints,  int numberOfTeams,  List<String> teamNames,  bool timerEnabled,  int timeLimitSeconds,  int negativePoints,  int rounds)  $default,) {final _that = this;
switch (_that) {
case _QuizArenaSettings():
return $default(_that.categoryIds,_that.selectedTeamIds,_that.categoryPoints,_that.numberOfTeams,_that.teamNames,_that.timerEnabled,_that.timeLimitSeconds,_that.negativePoints,_that.rounds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<int> categoryIds,  List<int> selectedTeamIds,  Map<int, int> categoryPoints,  int numberOfTeams,  List<String> teamNames,  bool timerEnabled,  int timeLimitSeconds,  int negativePoints,  int rounds)?  $default,) {final _that = this;
switch (_that) {
case _QuizArenaSettings() when $default != null:
return $default(_that.categoryIds,_that.selectedTeamIds,_that.categoryPoints,_that.numberOfTeams,_that.teamNames,_that.timerEnabled,_that.timeLimitSeconds,_that.negativePoints,_that.rounds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizArenaSettings implements QuizArenaSettings {
  const _QuizArenaSettings({final  List<int> categoryIds = const [], final  List<int> selectedTeamIds = const [], final  Map<int, int> categoryPoints = const {}, this.numberOfTeams = 2, final  List<String> teamNames = const [], this.timerEnabled = true, this.timeLimitSeconds = 30, this.negativePoints = 0, this.rounds = 10}): _categoryIds = categoryIds,_selectedTeamIds = selectedTeamIds,_categoryPoints = categoryPoints,_teamNames = teamNames;
  factory _QuizArenaSettings.fromJson(Map<String, dynamic> json) => _$QuizArenaSettingsFromJson(json);

 final  List<int> _categoryIds;
@override@JsonKey() List<int> get categoryIds {
  if (_categoryIds is EqualUnmodifiableListView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryIds);
}

 final  List<int> _selectedTeamIds;
@override@JsonKey() List<int> get selectedTeamIds {
  if (_selectedTeamIds is EqualUnmodifiableListView) return _selectedTeamIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedTeamIds);
}

 final  Map<int, int> _categoryPoints;
@override@JsonKey() Map<int, int> get categoryPoints {
  if (_categoryPoints is EqualUnmodifiableMapView) return _categoryPoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categoryPoints);
}

// categoryId -> points
@override@JsonKey() final  int numberOfTeams;
 final  List<String> _teamNames;
@override@JsonKey() List<String> get teamNames {
  if (_teamNames is EqualUnmodifiableListView) return _teamNames;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_teamNames);
}

@override@JsonKey() final  bool timerEnabled;
@override@JsonKey() final  int timeLimitSeconds;
@override@JsonKey() final  int negativePoints;
@override@JsonKey() final  int rounds;

/// Create a copy of QuizArenaSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizArenaSettingsCopyWith<_QuizArenaSettings> get copyWith => __$QuizArenaSettingsCopyWithImpl<_QuizArenaSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizArenaSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizArenaSettings&&const DeepCollectionEquality().equals(other._categoryIds, _categoryIds)&&const DeepCollectionEquality().equals(other._selectedTeamIds, _selectedTeamIds)&&const DeepCollectionEquality().equals(other._categoryPoints, _categoryPoints)&&(identical(other.numberOfTeams, numberOfTeams) || other.numberOfTeams == numberOfTeams)&&const DeepCollectionEquality().equals(other._teamNames, _teamNames)&&(identical(other.timerEnabled, timerEnabled) || other.timerEnabled == timerEnabled)&&(identical(other.timeLimitSeconds, timeLimitSeconds) || other.timeLimitSeconds == timeLimitSeconds)&&(identical(other.negativePoints, negativePoints) || other.negativePoints == negativePoints)&&(identical(other.rounds, rounds) || other.rounds == rounds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categoryIds),const DeepCollectionEquality().hash(_selectedTeamIds),const DeepCollectionEquality().hash(_categoryPoints),numberOfTeams,const DeepCollectionEquality().hash(_teamNames),timerEnabled,timeLimitSeconds,negativePoints,rounds);

@override
String toString() {
  return 'QuizArenaSettings(categoryIds: $categoryIds, selectedTeamIds: $selectedTeamIds, categoryPoints: $categoryPoints, numberOfTeams: $numberOfTeams, teamNames: $teamNames, timerEnabled: $timerEnabled, timeLimitSeconds: $timeLimitSeconds, negativePoints: $negativePoints, rounds: $rounds)';
}


}

/// @nodoc
abstract mixin class _$QuizArenaSettingsCopyWith<$Res> implements $QuizArenaSettingsCopyWith<$Res> {
  factory _$QuizArenaSettingsCopyWith(_QuizArenaSettings value, $Res Function(_QuizArenaSettings) _then) = __$QuizArenaSettingsCopyWithImpl;
@override @useResult
$Res call({
 List<int> categoryIds, List<int> selectedTeamIds, Map<int, int> categoryPoints, int numberOfTeams, List<String> teamNames, bool timerEnabled, int timeLimitSeconds, int negativePoints, int rounds
});




}
/// @nodoc
class __$QuizArenaSettingsCopyWithImpl<$Res>
    implements _$QuizArenaSettingsCopyWith<$Res> {
  __$QuizArenaSettingsCopyWithImpl(this._self, this._then);

  final _QuizArenaSettings _self;
  final $Res Function(_QuizArenaSettings) _then;

/// Create a copy of QuizArenaSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryIds = null,Object? selectedTeamIds = null,Object? categoryPoints = null,Object? numberOfTeams = null,Object? teamNames = null,Object? timerEnabled = null,Object? timeLimitSeconds = null,Object? negativePoints = null,Object? rounds = null,}) {
  return _then(_QuizArenaSettings(
categoryIds: null == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,selectedTeamIds: null == selectedTeamIds ? _self._selectedTeamIds : selectedTeamIds // ignore: cast_nullable_to_non_nullable
as List<int>,categoryPoints: null == categoryPoints ? _self._categoryPoints : categoryPoints // ignore: cast_nullable_to_non_nullable
as Map<int, int>,numberOfTeams: null == numberOfTeams ? _self.numberOfTeams : numberOfTeams // ignore: cast_nullable_to_non_nullable
as int,teamNames: null == teamNames ? _self._teamNames : teamNames // ignore: cast_nullable_to_non_nullable
as List<String>,timerEnabled: null == timerEnabled ? _self.timerEnabled : timerEnabled // ignore: cast_nullable_to_non_nullable
as bool,timeLimitSeconds: null == timeLimitSeconds ? _self.timeLimitSeconds : timeLimitSeconds // ignore: cast_nullable_to_non_nullable
as int,negativePoints: null == negativePoints ? _self.negativePoints : negativePoints // ignore: cast_nullable_to_non_nullable
as int,rounds: null == rounds ? _self.rounds : rounds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
