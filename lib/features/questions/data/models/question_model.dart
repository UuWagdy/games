import 'package:freezed_annotation/freezed_annotation.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

@freezed
abstract class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    int? id,
    required String text,
    required String answer,
    @JsonKey(name: 'category_id') required int categoryId,
    @Default(false) @JsonKey(name: 'is_used') bool isUsed,
  }) = _QuestionModel;

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);
}
