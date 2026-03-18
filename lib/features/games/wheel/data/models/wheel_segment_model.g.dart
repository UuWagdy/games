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
      categoryId: (json['category_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$WheelSegmentModelToJson(_WheelSegmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'points': instance.points,
      'is_question': instance.isQuestion,
      'category_id': instance.categoryId,
    };
