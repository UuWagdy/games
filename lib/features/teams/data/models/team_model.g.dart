// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TeamModel _$TeamModelFromJson(Map<String, dynamic> json) => _TeamModel(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String,
  score: (json['score'] as num?)?.toInt() ?? 0,
  playersCount: (json['players_count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TeamModelToJson(_TeamModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'score': instance.score,
      'players_count': instance.playersCount,
    };
