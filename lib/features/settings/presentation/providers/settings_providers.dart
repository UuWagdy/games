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
}
