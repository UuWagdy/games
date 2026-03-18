import 'package:freezed_annotation/freezed_annotation.dart';

part 'wheel_segment_model.freezed.dart';
part 'wheel_segment_model.g.dart';

@freezed
abstract class WheelSegmentModel with _$WheelSegmentModel {
  const factory WheelSegmentModel({
    int? id,
    required String text,
    required int points,
    @Default(false) @JsonKey(name: 'is_question') bool isQuestion,
    @JsonKey(name: 'category_id') int? categoryId,
  }) = _WheelSegmentModel;

  factory WheelSegmentModel.fromJson(Map<String, dynamic> json) =>
      _$WheelSegmentModelFromJson(json);
}
