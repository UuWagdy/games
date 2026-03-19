// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuestionModel _$QuestionModelFromJson(Map<String, dynamic> json) =>
    _QuestionModel(
      id: (json['id'] as num?)?.toInt(),
      text: json['text'] as String,
      answer: json['answer'] as String,
      categoryId: (json['category_id'] as num).toInt(),
      isUsed: json['is_used'] as bool? ?? false,
    );

Map<String, dynamic> _$QuestionModelToJson(_QuestionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'answer': instance.answer,
      'category_id': instance.categoryId,
      'is_used': instance.isUsed,
    };
