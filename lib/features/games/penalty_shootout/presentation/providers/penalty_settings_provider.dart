import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'penalty_settings_provider.g.dart';

@riverpod
class PenaltySettings extends _$PenaltySettings {
  static const _competitiveModeKey = 'penalty_competitive_mode';
  static const _teamAKeyKey = 'penalty_team_a_key';
  static const _teamBKeyKey = 'penalty_team_b_key';
  static const _timerDurationKey = 'penalty_timer_duration';

  @override
  Future<Map<String, dynamic>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'competitive_mode': prefs.getBool(_competitiveModeKey) ?? false,
      'team_a_key': prefs.getString(_teamAKeyKey) ?? 'a',
      'team_b_key': prefs.getString(_teamBKeyKey) ?? 'l',
      'timer_duration': prefs.getInt(_timerDurationKey) ?? 10,
    };
  }

  Future<void> setCompetitiveMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_competitiveModeKey, value);
    ref.invalidateSelf();
  }

  Future<void> setTeamAKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_teamAKeyKey, key.toLowerCase());
    ref.invalidateSelf();
  }

  Future<void> setTeamBKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_teamBKeyKey, key.toLowerCase());
    ref.invalidateSelf();
  }

  Future<void> setTimerDuration(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timerDurationKey, seconds);
    ref.invalidateSelf();
  }
}
