import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'under_pressure_settings_provider.g.dart';

@riverpod
class UnderPressureSettings extends _$UnderPressureSettings {
  static const _questionCountKey = 'up_question_count';
  static const _timerDurationKey = 'up_timer_duration';
  static const _pointsPerQuestionKey = 'up_points_per_question';
  static const _bonusPointsKey = 'up_bonus_points';

  @override
  Future<Map<String, dynamic>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'question_count': prefs.getInt(_questionCountKey) ?? 15,
      'timer_duration': prefs.getInt(_timerDurationKey) ?? 60,
      'points_per_question': prefs.getInt(_pointsPerQuestionKey) ?? 1,
      'bonus_points': prefs.getInt(_bonusPointsKey) ?? 10,
    };
  }

  Future<void> setQuestionCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_questionCountKey, count);
    ref.invalidateSelf();
  }

  Future<void> setTimerDuration(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timerDurationKey, seconds);
    ref.invalidateSelf();
  }

  Future<void> setPointsPerQuestion(int points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointsPerQuestionKey, points);
    ref.invalidateSelf();
  }

  Future<void> setBonusPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bonusPointsKey, points);
    ref.invalidateSelf();
  }
}
