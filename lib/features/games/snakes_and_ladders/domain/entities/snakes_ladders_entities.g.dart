// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snakes_ladders_entities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BoardElement _$BoardElementFromJson(Map<String, dynamic> json) =>
    _BoardElement(
      start: (json['start'] as num).toInt(),
      end: (json['end'] as num).toInt(),
      isLadder: json['isLadder'] as bool,
    );

Map<String, dynamic> _$BoardElementToJson(_BoardElement instance) =>
    <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
      'isLadder': instance.isLadder,
    };

_SnakesLaddersState _$SnakesLaddersStateFromJson(Map<String, dynamic> json) =>
    _SnakesLaddersState(
      boardSize: (json['boardSize'] as num?)?.toInt() ?? 100,
      elements:
          (json['elements'] as List<dynamic>?)
              ?.map((e) => BoardElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      playerPositions:
          (json['playerPositions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
          ) ??
          const {},
      currentPlayerIndex: (json['currentPlayerIndex'] as num?)?.toInt() ?? 0,
      lastDiceValue: (json['lastDiceValue'] as num?)?.toInt(),
      status:
          $enumDecodeNullable(_$SnakesLaddersStatusEnumMap, json['status']) ??
          SnakesLaddersStatus.playing,
      questionsEnabled: json['questionsEnabled'] as bool? ?? false,
      categoryIds:
          (json['categoryIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      isWaitingForQuestion: json['isWaitingForQuestion'] as bool? ?? false,
      currentQuestion: json['currentQuestion'],
      winPoints: (json['winPoints'] as num?)?.toInt() ?? 25,
      wrongAnswerPenalty:
          $enumDecodeNullable(
            _$WrongAnswerPenaltyEnumMap,
            json['wrongAnswerPenalty'],
          ) ??
          WrongAnswerPenalty.skip,
      snakesCount: (json['snakesCount'] as num?)?.toInt() ?? 8,
      laddersCount: (json['laddersCount'] as num?)?.toInt() ?? 8,
    );

Map<String, dynamic> _$SnakesLaddersStateToJson(_SnakesLaddersState instance) =>
    <String, dynamic>{
      'boardSize': instance.boardSize,
      'elements': instance.elements,
      'playerPositions': instance.playerPositions.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
      'currentPlayerIndex': instance.currentPlayerIndex,
      'lastDiceValue': instance.lastDiceValue,
      'status': _$SnakesLaddersStatusEnumMap[instance.status]!,
      'questionsEnabled': instance.questionsEnabled,
      'categoryIds': instance.categoryIds,
      'isWaitingForQuestion': instance.isWaitingForQuestion,
      'currentQuestion': instance.currentQuestion,
      'winPoints': instance.winPoints,
      'wrongAnswerPenalty':
          _$WrongAnswerPenaltyEnumMap[instance.wrongAnswerPenalty]!,
      'snakesCount': instance.snakesCount,
      'laddersCount': instance.laddersCount,
    };

const _$SnakesLaddersStatusEnumMap = {
  SnakesLaddersStatus.playing: 'playing',
  SnakesLaddersStatus.finished: 'finished',
};

const _$WrongAnswerPenaltyEnumMap = {
  WrongAnswerPenalty.skip: 'skip',
  WrongAnswerPenalty.half: 'half',
};
