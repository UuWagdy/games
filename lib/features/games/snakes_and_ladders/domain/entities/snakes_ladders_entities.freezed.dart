// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'snakes_ladders_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BoardElement {

 int get start; int get end; bool get isLadder;
/// Create a copy of BoardElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoardElementCopyWith<BoardElement> get copyWith => _$BoardElementCopyWithImpl<BoardElement>(this as BoardElement, _$identity);

  /// Serializes this BoardElement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoardElement&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.isLadder, isLadder) || other.isLadder == isLadder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,start,end,isLadder);

@override
String toString() {
  return 'BoardElement(start: $start, end: $end, isLadder: $isLadder)';
}


}

/// @nodoc
abstract mixin class $BoardElementCopyWith<$Res>  {
  factory $BoardElementCopyWith(BoardElement value, $Res Function(BoardElement) _then) = _$BoardElementCopyWithImpl;
@useResult
$Res call({
 int start, int end, bool isLadder
});




}
/// @nodoc
class _$BoardElementCopyWithImpl<$Res>
    implements $BoardElementCopyWith<$Res> {
  _$BoardElementCopyWithImpl(this._self, this._then);

  final BoardElement _self;
  final $Res Function(BoardElement) _then;

/// Create a copy of BoardElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? end = null,Object? isLadder = null,}) {
  return _then(_self.copyWith(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as int,isLadder: null == isLadder ? _self.isLadder : isLadder // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BoardElement].
extension BoardElementPatterns on BoardElement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BoardElement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BoardElement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BoardElement value)  $default,){
final _that = this;
switch (_that) {
case _BoardElement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BoardElement value)?  $default,){
final _that = this;
switch (_that) {
case _BoardElement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int start,  int end,  bool isLadder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BoardElement() when $default != null:
return $default(_that.start,_that.end,_that.isLadder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int start,  int end,  bool isLadder)  $default,) {final _that = this;
switch (_that) {
case _BoardElement():
return $default(_that.start,_that.end,_that.isLadder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int start,  int end,  bool isLadder)?  $default,) {final _that = this;
switch (_that) {
case _BoardElement() when $default != null:
return $default(_that.start,_that.end,_that.isLadder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BoardElement implements BoardElement {
  const _BoardElement({required this.start, required this.end, required this.isLadder});
  factory _BoardElement.fromJson(Map<String, dynamic> json) => _$BoardElementFromJson(json);

@override final  int start;
@override final  int end;
@override final  bool isLadder;

/// Create a copy of BoardElement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BoardElementCopyWith<_BoardElement> get copyWith => __$BoardElementCopyWithImpl<_BoardElement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BoardElementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BoardElement&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.isLadder, isLadder) || other.isLadder == isLadder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,start,end,isLadder);

@override
String toString() {
  return 'BoardElement(start: $start, end: $end, isLadder: $isLadder)';
}


}

/// @nodoc
abstract mixin class _$BoardElementCopyWith<$Res> implements $BoardElementCopyWith<$Res> {
  factory _$BoardElementCopyWith(_BoardElement value, $Res Function(_BoardElement) _then) = __$BoardElementCopyWithImpl;
@override @useResult
$Res call({
 int start, int end, bool isLadder
});




}
/// @nodoc
class __$BoardElementCopyWithImpl<$Res>
    implements _$BoardElementCopyWith<$Res> {
  __$BoardElementCopyWithImpl(this._self, this._then);

  final _BoardElement _self;
  final $Res Function(_BoardElement) _then;

/// Create a copy of BoardElement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = null,Object? isLadder = null,}) {
  return _then(_BoardElement(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as int,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as int,isLadder: null == isLadder ? _self.isLadder : isLadder // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SnakesLaddersState {

 int get boardSize; List<BoardElement> get elements; Map<int, int> get playerPositions; int get currentPlayerIndex; int? get lastDiceValue; SnakesLaddersStatus get status; bool get questionsEnabled; List<int> get categoryIds; bool get isWaitingForQuestion; dynamic get currentQuestion; int get winPoints; WrongAnswerPenalty get wrongAnswerPenalty; int get snakesCount; int get laddersCount;
/// Create a copy of SnakesLaddersState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SnakesLaddersStateCopyWith<SnakesLaddersState> get copyWith => _$SnakesLaddersStateCopyWithImpl<SnakesLaddersState>(this as SnakesLaddersState, _$identity);

  /// Serializes this SnakesLaddersState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SnakesLaddersState&&(identical(other.boardSize, boardSize) || other.boardSize == boardSize)&&const DeepCollectionEquality().equals(other.elements, elements)&&const DeepCollectionEquality().equals(other.playerPositions, playerPositions)&&(identical(other.currentPlayerIndex, currentPlayerIndex) || other.currentPlayerIndex == currentPlayerIndex)&&(identical(other.lastDiceValue, lastDiceValue) || other.lastDiceValue == lastDiceValue)&&(identical(other.status, status) || other.status == status)&&(identical(other.questionsEnabled, questionsEnabled) || other.questionsEnabled == questionsEnabled)&&const DeepCollectionEquality().equals(other.categoryIds, categoryIds)&&(identical(other.isWaitingForQuestion, isWaitingForQuestion) || other.isWaitingForQuestion == isWaitingForQuestion)&&const DeepCollectionEquality().equals(other.currentQuestion, currentQuestion)&&(identical(other.winPoints, winPoints) || other.winPoints == winPoints)&&(identical(other.wrongAnswerPenalty, wrongAnswerPenalty) || other.wrongAnswerPenalty == wrongAnswerPenalty)&&(identical(other.snakesCount, snakesCount) || other.snakesCount == snakesCount)&&(identical(other.laddersCount, laddersCount) || other.laddersCount == laddersCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,boardSize,const DeepCollectionEquality().hash(elements),const DeepCollectionEquality().hash(playerPositions),currentPlayerIndex,lastDiceValue,status,questionsEnabled,const DeepCollectionEquality().hash(categoryIds),isWaitingForQuestion,const DeepCollectionEquality().hash(currentQuestion),winPoints,wrongAnswerPenalty,snakesCount,laddersCount);

@override
String toString() {
  return 'SnakesLaddersState(boardSize: $boardSize, elements: $elements, playerPositions: $playerPositions, currentPlayerIndex: $currentPlayerIndex, lastDiceValue: $lastDiceValue, status: $status, questionsEnabled: $questionsEnabled, categoryIds: $categoryIds, isWaitingForQuestion: $isWaitingForQuestion, currentQuestion: $currentQuestion, winPoints: $winPoints, wrongAnswerPenalty: $wrongAnswerPenalty, snakesCount: $snakesCount, laddersCount: $laddersCount)';
}


}

/// @nodoc
abstract mixin class $SnakesLaddersStateCopyWith<$Res>  {
  factory $SnakesLaddersStateCopyWith(SnakesLaddersState value, $Res Function(SnakesLaddersState) _then) = _$SnakesLaddersStateCopyWithImpl;
@useResult
$Res call({
 int boardSize, List<BoardElement> elements, Map<int, int> playerPositions, int currentPlayerIndex, int? lastDiceValue, SnakesLaddersStatus status, bool questionsEnabled, List<int> categoryIds, bool isWaitingForQuestion, dynamic currentQuestion, int winPoints, WrongAnswerPenalty wrongAnswerPenalty, int snakesCount, int laddersCount
});




}
/// @nodoc
class _$SnakesLaddersStateCopyWithImpl<$Res>
    implements $SnakesLaddersStateCopyWith<$Res> {
  _$SnakesLaddersStateCopyWithImpl(this._self, this._then);

  final SnakesLaddersState _self;
  final $Res Function(SnakesLaddersState) _then;

/// Create a copy of SnakesLaddersState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? boardSize = null,Object? elements = null,Object? playerPositions = null,Object? currentPlayerIndex = null,Object? lastDiceValue = freezed,Object? status = null,Object? questionsEnabled = null,Object? categoryIds = null,Object? isWaitingForQuestion = null,Object? currentQuestion = freezed,Object? winPoints = null,Object? wrongAnswerPenalty = null,Object? snakesCount = null,Object? laddersCount = null,}) {
  return _then(_self.copyWith(
boardSize: null == boardSize ? _self.boardSize : boardSize // ignore: cast_nullable_to_non_nullable
as int,elements: null == elements ? _self.elements : elements // ignore: cast_nullable_to_non_nullable
as List<BoardElement>,playerPositions: null == playerPositions ? _self.playerPositions : playerPositions // ignore: cast_nullable_to_non_nullable
as Map<int, int>,currentPlayerIndex: null == currentPlayerIndex ? _self.currentPlayerIndex : currentPlayerIndex // ignore: cast_nullable_to_non_nullable
as int,lastDiceValue: freezed == lastDiceValue ? _self.lastDiceValue : lastDiceValue // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SnakesLaddersStatus,questionsEnabled: null == questionsEnabled ? _self.questionsEnabled : questionsEnabled // ignore: cast_nullable_to_non_nullable
as bool,categoryIds: null == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,isWaitingForQuestion: null == isWaitingForQuestion ? _self.isWaitingForQuestion : isWaitingForQuestion // ignore: cast_nullable_to_non_nullable
as bool,currentQuestion: freezed == currentQuestion ? _self.currentQuestion : currentQuestion // ignore: cast_nullable_to_non_nullable
as dynamic,winPoints: null == winPoints ? _self.winPoints : winPoints // ignore: cast_nullable_to_non_nullable
as int,wrongAnswerPenalty: null == wrongAnswerPenalty ? _self.wrongAnswerPenalty : wrongAnswerPenalty // ignore: cast_nullable_to_non_nullable
as WrongAnswerPenalty,snakesCount: null == snakesCount ? _self.snakesCount : snakesCount // ignore: cast_nullable_to_non_nullable
as int,laddersCount: null == laddersCount ? _self.laddersCount : laddersCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SnakesLaddersState].
extension SnakesLaddersStatePatterns on SnakesLaddersState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SnakesLaddersState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SnakesLaddersState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SnakesLaddersState value)  $default,){
final _that = this;
switch (_that) {
case _SnakesLaddersState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SnakesLaddersState value)?  $default,){
final _that = this;
switch (_that) {
case _SnakesLaddersState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int boardSize,  List<BoardElement> elements,  Map<int, int> playerPositions,  int currentPlayerIndex,  int? lastDiceValue,  SnakesLaddersStatus status,  bool questionsEnabled,  List<int> categoryIds,  bool isWaitingForQuestion,  dynamic currentQuestion,  int winPoints,  WrongAnswerPenalty wrongAnswerPenalty,  int snakesCount,  int laddersCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SnakesLaddersState() when $default != null:
return $default(_that.boardSize,_that.elements,_that.playerPositions,_that.currentPlayerIndex,_that.lastDiceValue,_that.status,_that.questionsEnabled,_that.categoryIds,_that.isWaitingForQuestion,_that.currentQuestion,_that.winPoints,_that.wrongAnswerPenalty,_that.snakesCount,_that.laddersCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int boardSize,  List<BoardElement> elements,  Map<int, int> playerPositions,  int currentPlayerIndex,  int? lastDiceValue,  SnakesLaddersStatus status,  bool questionsEnabled,  List<int> categoryIds,  bool isWaitingForQuestion,  dynamic currentQuestion,  int winPoints,  WrongAnswerPenalty wrongAnswerPenalty,  int snakesCount,  int laddersCount)  $default,) {final _that = this;
switch (_that) {
case _SnakesLaddersState():
return $default(_that.boardSize,_that.elements,_that.playerPositions,_that.currentPlayerIndex,_that.lastDiceValue,_that.status,_that.questionsEnabled,_that.categoryIds,_that.isWaitingForQuestion,_that.currentQuestion,_that.winPoints,_that.wrongAnswerPenalty,_that.snakesCount,_that.laddersCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int boardSize,  List<BoardElement> elements,  Map<int, int> playerPositions,  int currentPlayerIndex,  int? lastDiceValue,  SnakesLaddersStatus status,  bool questionsEnabled,  List<int> categoryIds,  bool isWaitingForQuestion,  dynamic currentQuestion,  int winPoints,  WrongAnswerPenalty wrongAnswerPenalty,  int snakesCount,  int laddersCount)?  $default,) {final _that = this;
switch (_that) {
case _SnakesLaddersState() when $default != null:
return $default(_that.boardSize,_that.elements,_that.playerPositions,_that.currentPlayerIndex,_that.lastDiceValue,_that.status,_that.questionsEnabled,_that.categoryIds,_that.isWaitingForQuestion,_that.currentQuestion,_that.winPoints,_that.wrongAnswerPenalty,_that.snakesCount,_that.laddersCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SnakesLaddersState implements SnakesLaddersState {
  const _SnakesLaddersState({this.boardSize = 100, final  List<BoardElement> elements = const [], final  Map<int, int> playerPositions = const {}, this.currentPlayerIndex = 0, this.lastDiceValue, this.status = SnakesLaddersStatus.playing, this.questionsEnabled = false, final  List<int> categoryIds = const [], this.isWaitingForQuestion = false, this.currentQuestion, this.winPoints = 25, this.wrongAnswerPenalty = WrongAnswerPenalty.skip, this.snakesCount = 8, this.laddersCount = 8}): _elements = elements,_playerPositions = playerPositions,_categoryIds = categoryIds;
  factory _SnakesLaddersState.fromJson(Map<String, dynamic> json) => _$SnakesLaddersStateFromJson(json);

@override@JsonKey() final  int boardSize;
 final  List<BoardElement> _elements;
@override@JsonKey() List<BoardElement> get elements {
  if (_elements is EqualUnmodifiableListView) return _elements;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_elements);
}

 final  Map<int, int> _playerPositions;
@override@JsonKey() Map<int, int> get playerPositions {
  if (_playerPositions is EqualUnmodifiableMapView) return _playerPositions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_playerPositions);
}

@override@JsonKey() final  int currentPlayerIndex;
@override final  int? lastDiceValue;
@override@JsonKey() final  SnakesLaddersStatus status;
@override@JsonKey() final  bool questionsEnabled;
 final  List<int> _categoryIds;
@override@JsonKey() List<int> get categoryIds {
  if (_categoryIds is EqualUnmodifiableListView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryIds);
}

@override@JsonKey() final  bool isWaitingForQuestion;
@override final  dynamic currentQuestion;
@override@JsonKey() final  int winPoints;
@override@JsonKey() final  WrongAnswerPenalty wrongAnswerPenalty;
@override@JsonKey() final  int snakesCount;
@override@JsonKey() final  int laddersCount;

/// Create a copy of SnakesLaddersState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SnakesLaddersStateCopyWith<_SnakesLaddersState> get copyWith => __$SnakesLaddersStateCopyWithImpl<_SnakesLaddersState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SnakesLaddersStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SnakesLaddersState&&(identical(other.boardSize, boardSize) || other.boardSize == boardSize)&&const DeepCollectionEquality().equals(other._elements, _elements)&&const DeepCollectionEquality().equals(other._playerPositions, _playerPositions)&&(identical(other.currentPlayerIndex, currentPlayerIndex) || other.currentPlayerIndex == currentPlayerIndex)&&(identical(other.lastDiceValue, lastDiceValue) || other.lastDiceValue == lastDiceValue)&&(identical(other.status, status) || other.status == status)&&(identical(other.questionsEnabled, questionsEnabled) || other.questionsEnabled == questionsEnabled)&&const DeepCollectionEquality().equals(other._categoryIds, _categoryIds)&&(identical(other.isWaitingForQuestion, isWaitingForQuestion) || other.isWaitingForQuestion == isWaitingForQuestion)&&const DeepCollectionEquality().equals(other.currentQuestion, currentQuestion)&&(identical(other.winPoints, winPoints) || other.winPoints == winPoints)&&(identical(other.wrongAnswerPenalty, wrongAnswerPenalty) || other.wrongAnswerPenalty == wrongAnswerPenalty)&&(identical(other.snakesCount, snakesCount) || other.snakesCount == snakesCount)&&(identical(other.laddersCount, laddersCount) || other.laddersCount == laddersCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,boardSize,const DeepCollectionEquality().hash(_elements),const DeepCollectionEquality().hash(_playerPositions),currentPlayerIndex,lastDiceValue,status,questionsEnabled,const DeepCollectionEquality().hash(_categoryIds),isWaitingForQuestion,const DeepCollectionEquality().hash(currentQuestion),winPoints,wrongAnswerPenalty,snakesCount,laddersCount);

@override
String toString() {
  return 'SnakesLaddersState(boardSize: $boardSize, elements: $elements, playerPositions: $playerPositions, currentPlayerIndex: $currentPlayerIndex, lastDiceValue: $lastDiceValue, status: $status, questionsEnabled: $questionsEnabled, categoryIds: $categoryIds, isWaitingForQuestion: $isWaitingForQuestion, currentQuestion: $currentQuestion, winPoints: $winPoints, wrongAnswerPenalty: $wrongAnswerPenalty, snakesCount: $snakesCount, laddersCount: $laddersCount)';
}


}

/// @nodoc
abstract mixin class _$SnakesLaddersStateCopyWith<$Res> implements $SnakesLaddersStateCopyWith<$Res> {
  factory _$SnakesLaddersStateCopyWith(_SnakesLaddersState value, $Res Function(_SnakesLaddersState) _then) = __$SnakesLaddersStateCopyWithImpl;
@override @useResult
$Res call({
 int boardSize, List<BoardElement> elements, Map<int, int> playerPositions, int currentPlayerIndex, int? lastDiceValue, SnakesLaddersStatus status, bool questionsEnabled, List<int> categoryIds, bool isWaitingForQuestion, dynamic currentQuestion, int winPoints, WrongAnswerPenalty wrongAnswerPenalty, int snakesCount, int laddersCount
});




}
/// @nodoc
class __$SnakesLaddersStateCopyWithImpl<$Res>
    implements _$SnakesLaddersStateCopyWith<$Res> {
  __$SnakesLaddersStateCopyWithImpl(this._self, this._then);

  final _SnakesLaddersState _self;
  final $Res Function(_SnakesLaddersState) _then;

/// Create a copy of SnakesLaddersState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? boardSize = null,Object? elements = null,Object? playerPositions = null,Object? currentPlayerIndex = null,Object? lastDiceValue = freezed,Object? status = null,Object? questionsEnabled = null,Object? categoryIds = null,Object? isWaitingForQuestion = null,Object? currentQuestion = freezed,Object? winPoints = null,Object? wrongAnswerPenalty = null,Object? snakesCount = null,Object? laddersCount = null,}) {
  return _then(_SnakesLaddersState(
boardSize: null == boardSize ? _self.boardSize : boardSize // ignore: cast_nullable_to_non_nullable
as int,elements: null == elements ? _self._elements : elements // ignore: cast_nullable_to_non_nullable
as List<BoardElement>,playerPositions: null == playerPositions ? _self._playerPositions : playerPositions // ignore: cast_nullable_to_non_nullable
as Map<int, int>,currentPlayerIndex: null == currentPlayerIndex ? _self.currentPlayerIndex : currentPlayerIndex // ignore: cast_nullable_to_non_nullable
as int,lastDiceValue: freezed == lastDiceValue ? _self.lastDiceValue : lastDiceValue // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SnakesLaddersStatus,questionsEnabled: null == questionsEnabled ? _self.questionsEnabled : questionsEnabled // ignore: cast_nullable_to_non_nullable
as bool,categoryIds: null == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<int>,isWaitingForQuestion: null == isWaitingForQuestion ? _self.isWaitingForQuestion : isWaitingForQuestion // ignore: cast_nullable_to_non_nullable
as bool,currentQuestion: freezed == currentQuestion ? _self.currentQuestion : currentQuestion // ignore: cast_nullable_to_non_nullable
as dynamic,winPoints: null == winPoints ? _self.winPoints : winPoints // ignore: cast_nullable_to_non_nullable
as int,wrongAnswerPenalty: null == wrongAnswerPenalty ? _self.wrongAnswerPenalty : wrongAnswerPenalty // ignore: cast_nullable_to_non_nullable
as WrongAnswerPenalty,snakesCount: null == snakesCount ? _self.snakesCount : snakesCount // ignore: cast_nullable_to_non_nullable
as int,laddersCount: null == laddersCount ? _self.laddersCount : laddersCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
