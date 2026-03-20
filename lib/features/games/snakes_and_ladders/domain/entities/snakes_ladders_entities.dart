import 'package:freezed_annotation/freezed_annotation.dart';

part 'snakes_ladders_entities.freezed.dart';
part 'snakes_ladders_entities.g.dart';

enum SnakesLaddersStatus { playing, finished }
enum WrongAnswerPenalty { skip, half }

@freezed
abstract class BoardElement with _$BoardElement {
  const factory BoardElement({
    required int start,
    required int end,
    required bool isLadder,
  }) = _BoardElement;

  factory BoardElement.fromJson(Map<String, dynamic> json) => _$BoardElementFromJson(json);
}

@freezed
abstract class SnakesLaddersState with _$SnakesLaddersState {
  const factory SnakesLaddersState({
    @Default(100) int boardSize,
    @Default([]) List<BoardElement> elements,
    @Default({}) Map<int, int> playerPositions,
    @Default(0) int currentPlayerIndex,
    int? lastDiceValue,
    @Default(SnakesLaddersStatus.playing) SnakesLaddersStatus status,
    @Default(false) bool questionsEnabled,
    @Default([]) List<int> categoryIds,
    @Default(false) bool isWaitingForQuestion,
    dynamic currentQuestion,
    @Default(25) int winPoints,
    @Default(WrongAnswerPenalty.skip) WrongAnswerPenalty wrongAnswerPenalty,
    @Default(8) int snakesCount,
    @Default(8) int laddersCount,
  }) = _SnakesLaddersState;

  factory SnakesLaddersState.fromJson(Map<String, dynamic> json) => _$SnakesLaddersStateFromJson(json);
}
