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
    @Default([]) @JsonKey(name: 'category_ids') List<int> categoryIds,
    @Default(false) @JsonKey(name: 'is_switch') bool isSwitch,
    @Default(false) @JsonKey(name: 'is_joker') bool isJoker,
  }) = _WheelSegmentModel;

  factory WheelSegmentModel.fromJson(Map<String, dynamic> json) =>
      _$WheelSegmentModelFromJson(json);
}
