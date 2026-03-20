// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_arena_game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuizArenaGameState {

 List<Team> get teams; int get currentTeamIndex; Question? get currentQuestion; int get remainingTime; bool get isTimerRunning; int get currentRound; bool get showAnswer; bool get hasVerdict; bool get isGameOver; bool get isLoading; List<int> get answeredQuestionIds; List<Team> get winners;
/// Create a copy of QuizArenaGameState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizArenaGameStateCopyWith<QuizArenaGameState> get copyWith => _$QuizArenaGameStateCopyWithImpl<QuizArenaGameState>(this as QuizArenaGameState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizArenaGameState&&const DeepCollectionEquality().equals(other.teams, teams)&&(identical(other.currentTeamIndex, currentTeamIndex) || other.currentTeamIndex == currentTeamIndex)&&(identical(other.currentQuestion, currentQuestion) || other.currentQuestion == currentQuestion)&&(identical(other.remainingTime, remainingTime) || other.remainingTime == remainingTime)&&(identical(other.isTimerRunning, isTimerRunning) || other.isTimerRunning == isTimerRunning)&&(identical(other.currentRound, currentRound) || other.currentRound == currentRound)&&(identical(other.showAnswer, showAnswer) || other.showAnswer == showAnswer)&&(identical(other.hasVerdict, hasVerdict) || other.hasVerdict == hasVerdict)&&(identical(other.isGameOver, isGameOver) || other.isGameOver == isGameOver)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other.answeredQuestionIds, answeredQuestionIds)&&const DeepCollectionEquality().equals(other.winners, winners));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(teams),currentTeamIndex,currentQuestion,remainingTime,isTimerRunning,currentRound,showAnswer,hasVerdict,isGameOver,isLoading,const DeepCollectionEquality().hash(answeredQuestionIds),const DeepCollectionEquality().hash(winners));

@override
String toString() {
  return 'QuizArenaGameState(teams: $teams, currentTeamIndex: $currentTeamIndex, currentQuestion: $currentQuestion, remainingTime: $remainingTime, isTimerRunning: $isTimerRunning, currentRound: $currentRound, showAnswer: $showAnswer, hasVerdict: $hasVerdict, isGameOver: $isGameOver, isLoading: $isLoading, answeredQuestionIds: $answeredQuestionIds, winners: $winners)';
}


}

/// @nodoc
abstract mixin class $QuizArenaGameStateCopyWith<$Res>  {
  factory $QuizArenaGameStateCopyWith(QuizArenaGameState value, $Res Function(QuizArenaGameState) _then) = _$QuizArenaGameStateCopyWithImpl;
@useResult
$Res call({
 List<Team> teams, int currentTeamIndex, Question? currentQuestion, int remainingTime, bool isTimerRunning, int currentRound, bool showAnswer, bool hasVerdict, bool isGameOver, bool isLoading, List<int> answeredQuestionIds, List<Team> winners
});




}
/// @nodoc
class _$QuizArenaGameStateCopyWithImpl<$Res>
    implements $QuizArenaGameStateCopyWith<$Res> {
  _$QuizArenaGameStateCopyWithImpl(this._self, this._then);

  final QuizArenaGameState _self;
  final $Res Function(QuizArenaGameState) _then;

/// Create a copy of QuizArenaGameState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? teams = null,Object? currentTeamIndex = null,Object? currentQuestion = freezed,Object? remainingTime = null,Object? isTimerRunning = null,Object? currentRound = null,Object? showAnswer = null,Object? hasVerdict = null,Object? isGameOver = null,Object? isLoading = null,Object? answeredQuestionIds = null,Object? winners = null,}) {
  return _then(_self.copyWith(
teams: null == teams ? _self.teams : teams // ignore: cast_nullable_to_non_nullable
as List<Team>,currentTeamIndex: null == currentTeamIndex ? _self.currentTeamIndex : currentTeamIndex // ignore: cast_nullable_to_non_nullable
as int,currentQuestion: freezed == currentQuestion ? _self.currentQuestion : currentQuestion // ignore: cast_nullable_to_non_nullable
as Question?,remainingTime: null == remainingTime ? _self.remainingTime : remainingTime // ignore: cast_nullable_to_non_nullable
as int,isTimerRunning: null == isTimerRunning ? _self.isTimerRunning : isTimerRunning // ignore: cast_nullable_to_non_nullable
as bool,currentRound: null == currentRound ? _self.currentRound : currentRound // ignore: cast_nullable_to_non_nullable
as int,showAnswer: null == showAnswer ? _self.showAnswer : showAnswer // ignore: cast_nullable_to_non_nullable
as bool,hasVerdict: null == hasVerdict ? _self.hasVerdict : hasVerdict // ignore: cast_nullable_to_non_nullable
as bool,isGameOver: null == isGameOver ? _self.isGameOver : isGameOver // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,answeredQuestionIds: null == answeredQuestionIds ? _self.answeredQuestionIds : answeredQuestionIds // ignore: cast_nullable_to_non_nullable
as List<int>,winners: null == winners ? _self.winners : winners // ignore: cast_nullable_to_non_nullable
as List<Team>,
  ));
}

}


/// Adds pattern-matching-related methods to [QuizArenaGameState].
extension QuizArenaGameStatePatterns on QuizArenaGameState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizArenaGameState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizArenaGameState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizArenaGameState value)  $default,){
final _that = this;
switch (_that) {
case _QuizArenaGameState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizArenaGameState value)?  $default,){
final _that = this;
switch (_that) {
case _QuizArenaGameState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Team> teams,  int currentTeamIndex,  Question? currentQuestion,  int remainingTime,  bool isTimerRunning,  int currentRound,  bool showAnswer,  bool hasVerdict,  bool isGameOver,  bool isLoading,  List<int> answeredQuestionIds,  List<Team> winners)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizArenaGameState() when $default != null:
return $default(_that.teams,_that.currentTeamIndex,_that.currentQuestion,_that.remainingTime,_that.isTimerRunning,_that.currentRound,_that.showAnswer,_that.hasVerdict,_that.isGameOver,_that.isLoading,_that.answeredQuestionIds,_that.winners);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Team> teams,  int currentTeamIndex,  Question? currentQuestion,  int remainingTime,  bool isTimerRunning,  int currentRound,  bool showAnswer,  bool hasVerdict,  bool isGameOver,  bool isLoading,  List<int> answeredQuestionIds,  List<Team> winners)  $default,) {final _that = this;
switch (_that) {
case _QuizArenaGameState():
return $default(_that.teams,_that.currentTeamIndex,_that.currentQuestion,_that.remainingTime,_that.isTimerRunning,_that.currentRound,_that.showAnswer,_that.hasVerdict,_that.isGameOver,_that.isLoading,_that.answeredQuestionIds,_that.winners);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Team> teams,  int currentTeamIndex,  Question? currentQuestion,  int remainingTime,  bool isTimerRunning,  int currentRound,  bool showAnswer,  bool hasVerdict,  bool isGameOver,  bool isLoading,  List<int> answeredQuestionIds,  List<Team> winners)?  $default,) {final _that = this;
switch (_that) {
case _QuizArenaGameState() when $default != null:
return $default(_that.teams,_that.currentTeamIndex,_that.currentQuestion,_that.remainingTime,_that.isTimerRunning,_that.currentRound,_that.showAnswer,_that.hasVerdict,_that.isGameOver,_that.isLoading,_that.answeredQuestionIds,_that.winners);case _:
  return null;

}
}

}

/// @nodoc


class _QuizArenaGameState implements QuizArenaGameState {
  const _QuizArenaGameState({final  List<Team> teams = const [], this.currentTeamIndex = 0, this.currentQuestion, this.remainingTime = 30, this.isTimerRunning = false, this.currentRound = 0, this.showAnswer = false, this.hasVerdict = false, this.isGameOver = false, this.isLoading = false, final  List<int> answeredQuestionIds = const [], final  List<Team> winners = const []}): _teams = teams,_answeredQuestionIds = answeredQuestionIds,_winners = winners;
  

 final  List<Team> _teams;
@override@JsonKey() List<Team> get teams {
  if (_teams is EqualUnmodifiableListView) return _teams;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_teams);
}

@override@JsonKey() final  int currentTeamIndex;
@override final  Question? currentQuestion;
@override@JsonKey() final  int remainingTime;
@override@JsonKey() final  bool isTimerRunning;
@override@JsonKey() final  int currentRound;
@override@JsonKey() final  bool showAnswer;
@override@JsonKey() final  bool hasVerdict;
@override@JsonKey() final  bool isGameOver;
@override@JsonKey() final  bool isLoading;
 final  List<int> _answeredQuestionIds;
@override@JsonKey() List<int> get answeredQuestionIds {
  if (_answeredQuestionIds is EqualUnmodifiableListView) return _answeredQuestionIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_answeredQuestionIds);
}

 final  List<Team> _winners;
@override@JsonKey() List<Team> get winners {
  if (_winners is EqualUnmodifiableListView) return _winners;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_winners);
}


/// Create a copy of QuizArenaGameState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizArenaGameStateCopyWith<_QuizArenaGameState> get copyWith => __$QuizArenaGameStateCopyWithImpl<_QuizArenaGameState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizArenaGameState&&const DeepCollectionEquality().equals(other._teams, _teams)&&(identical(other.currentTeamIndex, currentTeamIndex) || other.currentTeamIndex == currentTeamIndex)&&(identical(other.currentQuestion, currentQuestion) || other.currentQuestion == currentQuestion)&&(identical(other.remainingTime, remainingTime) || other.remainingTime == remainingTime)&&(identical(other.isTimerRunning, isTimerRunning) || other.isTimerRunning == isTimerRunning)&&(identical(other.currentRound, currentRound) || other.currentRound == currentRound)&&(identical(other.showAnswer, showAnswer) || other.showAnswer == showAnswer)&&(identical(other.hasVerdict, hasVerdict) || other.hasVerdict == hasVerdict)&&(identical(other.isGameOver, isGameOver) || other.isGameOver == isGameOver)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other._answeredQuestionIds, _answeredQuestionIds)&&const DeepCollectionEquality().equals(other._winners, _winners));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_teams),currentTeamIndex,currentQuestion,remainingTime,isTimerRunning,currentRound,showAnswer,hasVerdict,isGameOver,isLoading,const DeepCollectionEquality().hash(_answeredQuestionIds),const DeepCollectionEquality().hash(_winners));

@override
String toString() {
  return 'QuizArenaGameState(teams: $teams, currentTeamIndex: $currentTeamIndex, currentQuestion: $currentQuestion, remainingTime: $remainingTime, isTimerRunning: $isTimerRunning, currentRound: $currentRound, showAnswer: $showAnswer, hasVerdict: $hasVerdict, isGameOver: $isGameOver, isLoading: $isLoading, answeredQuestionIds: $answeredQuestionIds, winners: $winners)';
}


}

/// @nodoc
abstract mixin class _$QuizArenaGameStateCopyWith<$Res> implements $QuizArenaGameStateCopyWith<$Res> {
  factory _$QuizArenaGameStateCopyWith(_QuizArenaGameState value, $Res Function(_QuizArenaGameState) _then) = __$QuizArenaGameStateCopyWithImpl;
@override @useResult
$Res call({
 List<Team> teams, int currentTeamIndex, Question? currentQuestion, int remainingTime, bool isTimerRunning, int currentRound, bool showAnswer, bool hasVerdict, bool isGameOver, bool isLoading, List<int> answeredQuestionIds, List<Team> winners
});




}
/// @nodoc
class __$QuizArenaGameStateCopyWithImpl<$Res>
    implements _$QuizArenaGameStateCopyWith<$Res> {
  __$QuizArenaGameStateCopyWithImpl(this._self, this._then);

  final _QuizArenaGameState _self;
  final $Res Function(_QuizArenaGameState) _then;

/// Create a copy of QuizArenaGameState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? teams = null,Object? currentTeamIndex = null,Object? currentQuestion = freezed,Object? remainingTime = null,Object? isTimerRunning = null,Object? currentRound = null,Object? showAnswer = null,Object? hasVerdict = null,Object? isGameOver = null,Object? isLoading = null,Object? answeredQuestionIds = null,Object? winners = null,}) {
  return _then(_QuizArenaGameState(
teams: null == teams ? _self._teams : teams // ignore: cast_nullable_to_non_nullable
as List<Team>,currentTeamIndex: null == currentTeamIndex ? _self.currentTeamIndex : currentTeamIndex // ignore: cast_nullable_to_non_nullable
as int,currentQuestion: freezed == currentQuestion ? _self.currentQuestion : currentQuestion // ignore: cast_nullable_to_non_nullable
as Question?,remainingTime: null == remainingTime ? _self.remainingTime : remainingTime // ignore: cast_nullable_to_non_nullable
as int,isTimerRunning: null == isTimerRunning ? _self.isTimerRunning : isTimerRunning // ignore: cast_nullable_to_non_nullable
as bool,currentRound: null == currentRound ? _self.currentRound : currentRound // ignore: cast_nullable_to_non_nullable
as int,showAnswer: null == showAnswer ? _self.showAnswer : showAnswer // ignore: cast_nullable_to_non_nullable
as bool,hasVerdict: null == hasVerdict ? _self.hasVerdict : hasVerdict // ignore: cast_nullable_to_non_nullable
as bool,isGameOver: null == isGameOver ? _self.isGameOver : isGameOver // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,answeredQuestionIds: null == answeredQuestionIds ? _self._answeredQuestionIds : answeredQuestionIds // ignore: cast_nullable_to_non_nullable
as List<int>,winners: null == winners ? _self._winners : winners // ignore: cast_nullable_to_non_nullable
as List<Team>,
  ));
}


}

// dart format on
