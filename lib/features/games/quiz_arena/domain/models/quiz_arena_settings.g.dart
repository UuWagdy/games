// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_arena_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuizArenaSettings _$QuizArenaSettingsFromJson(Map<String, dynamic> json) =>
    _QuizArenaSettings(
      categoryIds:
          (json['categoryIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      selectedTeamIds:
          (json['selectedTeamIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      categoryPoints:
          (json['categoryPoints'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(int.parse(k), (e as num).toInt()),
          ) ??
          const {},
      numberOfTeams: (json['numberOfTeams'] as num?)?.toInt() ?? 2,
      teamNames:
          (json['teamNames'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      timerEnabled: json['timerEnabled'] as bool? ?? true,
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt() ?? 30,
      negativePoints: (json['negativePoints'] as num?)?.toInt() ?? 0,
      rounds: (json['rounds'] as num?)?.toInt() ?? 10,
      winPoints: (json['winPoints'] as num?)?.toInt() ?? 50,
    );

Map<String, dynamic> _$QuizArenaSettingsToJson(_QuizArenaSettings instance) =>
    <String, dynamic>{
      'categoryIds': instance.categoryIds,
      'selectedTeamIds': instance.selectedTeamIds,
      'categoryPoints': instance.categoryPoints.map(
        (k, e) => MapEntry(k.toString(), e),
      ),
      'numberOfTeams': instance.numberOfTeams,
      'teamNames': instance.teamNames,
      'timerEnabled': instance.timerEnabled,
      'timeLimitSeconds': instance.timeLimitSeconds,
      'negativePoints': instance.negativePoints,
      'rounds': instance.rounds,
      'winPoints': instance.winPoints,
    };
