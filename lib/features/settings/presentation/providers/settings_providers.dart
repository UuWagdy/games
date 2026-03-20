import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_providers.g.dart';

@riverpod
class GeneralSettings extends _$GeneralSettings {
  static const _repeatQuestionsKey = 'repeat_questions';
  static const _wheelSpinDurationKey = 'wheel_spin_duration';
  static const _selectionModeKey = 'selection_mode'; // 'random' or 'manual'
  static const _usageTrackingModeKey = 'usage_tracking_mode'; // 'per_category' or 'per_question'
  static const _enableQuestionTimerKey = 'enable_question_timer';
  static const _questionTimerDurationKey = 'question_timer_duration';
  static const _syncScoresKey = 'sync_scores';
  static const _penaltyWinPointsKey = 'penalty_win_points';
  static const _bankAlHazWinPointsKey = 'bank_al_haz_win_points';

  @override
  Future<Map<String, dynamic>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'repeat_questions': prefs.getBool(_repeatQuestionsKey) ?? true,
      'wheel_spin_duration': prefs.getInt(_wheelSpinDurationKey) ?? 5,
      'selection_mode': prefs.getString(_selectionModeKey) ?? 'random',
      'usage_tracking_mode': prefs.getString(_usageTrackingModeKey) ?? 'per_category',
      'enable_question_timer': prefs.getBool(_enableQuestionTimerKey) ?? false,
      'question_timer_duration': prefs.getInt(_questionTimerDurationKey) ?? 30, // Default 30s
      'sync_scores': prefs.getBool(_syncScoresKey) ?? true,
      'penalty_win_points': prefs.getInt(_penaltyWinPointsKey) ?? 25,
      'bank_al_haz_win_points': prefs.getInt(_bankAlHazWinPointsKey) ?? 50,
    };
  }

  Future<void> setEnableQuestionTimer(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableQuestionTimerKey, value);
    ref.invalidateSelf();
  }

  Future<void> setQuestionTimerDuration(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_questionTimerDurationKey, seconds);
    ref.invalidateSelf();
  }

  Future<void> setRepeatQuestions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_repeatQuestionsKey, value);
    ref.invalidateSelf();
  }

  Future<void> setWheelSpinDuration(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_wheelSpinDurationKey, seconds);
    ref.invalidateSelf();
  }

  Future<void> setSelectionMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectionModeKey, mode);
    ref.invalidateSelf();
  }

  Future<void> setUsageTrackingMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usageTrackingModeKey, mode);
    ref.invalidateSelf();
  }

  Future<void> setSyncScores(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncScoresKey, value);
    ref.invalidateSelf();
  }

  Future<void> setPenaltyWinPoints(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_penaltyWinPointsKey, value);
    ref.invalidateSelf();
  }

  Future<void> setBankAlHazWinPoints(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bankAlHazWinPointsKey, value);
    ref.invalidateSelf();
  }
}
