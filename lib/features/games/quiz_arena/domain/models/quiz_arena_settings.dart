import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_arena_settings.freezed.dart';
part 'quiz_arena_settings.g.dart';

@freezed
abstract class QuizArenaSettings with _$QuizArenaSettings {
  const factory QuizArenaSettings({
    @Default([]) List<int> categoryIds,
    @Default([]) List<int> selectedTeamIds,
    @Default({}) Map<int, int> categoryPoints, // categoryId -> points
    @Default(2) int numberOfTeams,
    @Default([]) List<String> teamNames,
    @Default(true) bool timerEnabled,
    @Default(30) int timeLimitSeconds,
    @Default(0) int negativePoints,
    @Default(10) int rounds,
    @Default(50) int winPoints,
  }) = _QuizArenaSettings;

  factory QuizArenaSettings.fromJson(Map<String, dynamic> json) => _$QuizArenaSettingsFromJson(json);
}
