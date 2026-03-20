// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wheel_segment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WheelSegmentModel _$WheelSegmentModelFromJson(Map<String, dynamic> json) =>
    _WheelSegmentModel(
      id: (json['id'] as num?)?.toInt(),
      text: json['text'] as String,
      points: (json['points'] as num).toInt(),
      isQuestion: json['is_question'] as bool? ?? false,
      categoryIds:
          (json['category_ids'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      isSwitch: json['is_switch'] as bool? ?? false,
      isJoker: json['is_joker'] as bool? ?? false,
    );

Map<String, dynamic> _$WheelSegmentModelToJson(_WheelSegmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'points': instance.points,
      'is_question': instance.isQuestion,
      'category_ids': instance.categoryIds,
      'is_switch': instance.isSwitch,
      'is_joker': instance.isJoker,
    };
