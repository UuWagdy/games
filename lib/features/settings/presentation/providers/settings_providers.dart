import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:games/features/games/bank_al_haz/presentation/providers/bank_al_haz_providers.dart';
import 'package:games/core/design/app_themes.dart';
import 'package:games/core/design/app_design.dart';

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
  static const _autoShowAnswerKey = 'auto_show_answer';
  static const _ticTacToeWinPointsKey = 'tic_tac_toe_win_points';
  static const _ticTacToeQuestionsEnabledKey = 'tic_tac_toe_questions_enabled';
  static const _ticTacToeCategoryIdsKey = 'tic_tac_toe_category_ids';
  static const _ticTacToeVsComputerKey = 'tic_tac_toe_vs_computer';
  static const _ludoVsComputerKey = 'ludo_vs_computer';
  static const _snakesVsComputerKey = 'snakes_vs_computer';
  static const _bankAlHazVsComputerKey = 'bank_al_haz_vs_computer';
  static const _ticTacToeSwapRolesKey = 'tic_tac_toe_swap_roles';
  static const _ticTacToeTeamXIdKey = 'tic_tac_toe_team_x_id';
  static const _ticTacToeTeamOIdKey = 'tic_tac_toe_team_o_id';
  static const _christmasMusicEnabledKey = 'christmas_music_enabled';
  static const _appThemeKey = 'app_theme'; // 'default', 'christmas', 'custom'
  static const _globalAiEnabledKey = 'global_ai_enabled';
  static const _customPrimaryColorKey = 'custom_primary_color';
  static const _customBgDeepKey = 'custom_bg_deep';
  static const _customBgSoftKey = 'custom_bg_soft';
  static const _customIsGradientKey = 'custom_is_gradient';
  static const _customIconsKey = 'custom_icons'; // JSON list of codePoints
  static const _customIconFilesKey = 'custom_icon_files'; // JSON list of file paths
  static const _customBgImageKey = 'custom_bg_image';
  static const _customMusicPathKey = 'custom_music_path';
  static const _customMusicEnabledKey = 'custom_music_enabled';

  @override
  Future<Map<String, dynamic>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'global_ai_enabled': prefs.getBool(_globalAiEnabledKey) ?? false,
      'repeat_questions': prefs.getBool(_repeatQuestionsKey) ?? true,
      'wheel_spin_duration': prefs.getInt(_wheelSpinDurationKey) ?? 5,
      'selection_mode': prefs.getString(_selectionModeKey) ?? 'random',
      'usage_tracking_mode': prefs.getString(_usageTrackingModeKey) ?? 'per_category',
      'enable_question_timer': prefs.getBool(_enableQuestionTimerKey) ?? false,
      'question_timer_duration': prefs.getInt(_questionTimerDurationKey) ?? 30,
      'sync_scores': prefs.getBool(_syncScoresKey) ?? true,
      'penalty_win_points': prefs.getInt(_penaltyWinPointsKey) ?? 25,
      'bank_al_haz_win_points': prefs.getInt(_bankAlHazWinPointsKey) ?? 50,
      'auto_show_answer': prefs.getBool(_autoShowAnswerKey) ?? false,
      'tic_tac_toe_win_points': prefs.getInt(_ticTacToeWinPointsKey) ?? 20,
      'tic_tac_toe_questions_enabled': prefs.getBool(_ticTacToeQuestionsEnabledKey) ?? false,
      'tic_tac_toe_category_ids': (prefs.getStringList(_ticTacToeCategoryIdsKey) ?? []).map(int.parse).toList(),
      'tic_tac_toe_vs_computer': prefs.getBool(_ticTacToeVsComputerKey) ?? true,
      'ludo_vs_computer': prefs.getBool(_ludoVsComputerKey) ?? false,
      'snakes_vs_computer': prefs.getBool(_snakesVsComputerKey) ?? false,
      'bank_al_haz_vs_computer': prefs.getBool(_bankAlHazVsComputerKey) ?? false,
      'tic_tac_toe_swap_roles': prefs.getBool(_ticTacToeSwapRolesKey) ?? false,
      'tic_tac_toe_team_x_id': prefs.getInt(_ticTacToeTeamXIdKey),
      'tic_tac_toe_team_o_id': prefs.getInt(_ticTacToeTeamOIdKey),
      'christmas_music_enabled': prefs.getBool(_christmasMusicEnabledKey) ?? true,
      'app_theme': prefs.getString(_appThemeKey) ?? 'default',
      'custom_primary_color': prefs.getInt(_customPrimaryColorKey) ?? 0xFF00BCD4,
      'custom_bg_deep': prefs.getInt(_customBgDeepKey) ?? 0xFF001F3F,
      'custom_bg_soft': prefs.getInt(_customBgSoftKey) ?? 0xFF003366,
      'custom_is_gradient': prefs.getBool(_customIsGradientKey) ?? true,
      'custom_icons': prefs.getStringList(_customIconsKey) ?? ['58713', '58137', '58138'],
      'custom_icon_files': prefs.getStringList(_customIconFilesKey) ?? [],
      'custom_bg_image': prefs.getString(_customBgImageKey),
      'custom_music_path': prefs.getString(_customMusicPathKey),
      'custom_music_enabled': prefs.getBool(_customMusicEnabledKey) ?? true,
    };
  }

  Future<void> setCustomThemeData({
    int? primaryColor,
    int? bgDeep,
    int? bgSoft,
    bool? isGradient,
    List<String>? icons,
    List<String>? iconFiles,
    String? bgImage,
    String? musicPath,
    bool? musicEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (primaryColor != null) await prefs.setInt(_customPrimaryColorKey, primaryColor);
    if (bgDeep != null) await prefs.setInt(_customBgDeepKey, bgDeep);
    if (bgSoft != null) await prefs.setInt(_customBgSoftKey, bgSoft);
    if (isGradient != null) await prefs.setBool(_customIsGradientKey, isGradient);
    if (icons != null) await prefs.setStringList(_customIconsKey, icons);
    if (iconFiles != null) await prefs.setStringList(_customIconFilesKey, iconFiles);
    if (bgImage != null) {
      if (bgImage.isEmpty) {
        await prefs.remove(_customBgImageKey);
      } else {
        await prefs.setString(_customBgImageKey, bgImage);
      }
    }
    if (musicPath != null) {
      if (musicPath.isEmpty) {
        await prefs.remove(_customMusicPathKey);
      } else {
        await prefs.setString(_customMusicPathKey, musicPath);
      }
    }
    if (musicEnabled != null) await prefs.setBool(_customMusicEnabledKey, musicEnabled);
    
    ref.invalidateSelf();
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
    
    // Sync with Bank Al Haz internal settings
    try {
      final repo = ref.read(bankAlHazRepositoryProvider);
      final bhSettings = await repo.getSettings();
      await repo.saveSettings(bhSettings.copyWith(winPoints: value));
      ref.invalidate(gameSettingsProvider);
    } catch (e) {
      print('Error syncing Bank Al Haz win points: $e');
    }
    
    ref.invalidateSelf();
  }

  Future<void> setAutoShowAnswer(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoShowAnswerKey, value);
    ref.invalidateSelf();
  }

  Future<void> setAppTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appThemeKey, theme);
    ref.invalidateSelf();
  }

  Future<void> setTicTacToeWinPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ticTacToeWinPointsKey, points);
    ref.invalidateSelf();
  }

  Future<void> setTicTacToeTeamXId(int? teamId) async {
    final prefs = await SharedPreferences.getInstance();
    if (teamId != null) {
      await prefs.setInt(_ticTacToeTeamXIdKey, teamId);
    } else {
      await prefs.remove(_ticTacToeTeamXIdKey);
    }
    ref.invalidateSelf();
  }

  Future<void> setTicTacToeTeamOId(int? teamId) async {
    final prefs = await SharedPreferences.getInstance();
    if (teamId != null) {
      await prefs.setInt(_ticTacToeTeamOIdKey, teamId);
    } else {
      await prefs.remove(_ticTacToeTeamOIdKey);
    }
    ref.invalidateSelf();
  }

  Future<void> setTicTacToeQuestionsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ticTacToeQuestionsEnabledKey, value);
    ref.invalidateSelf();
  }

  Future<void> setTicTacToeCategoryIds(List<int> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_ticTacToeCategoryIdsKey, values.map((e) => e.toString()).toList());
    ref.invalidateSelf();
  }

  Future<void> setTicTacToeVsComputer(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ticTacToeVsComputerKey, value);
    ref.invalidateSelf();
  }

  Future<void> setLudoVsComputer(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ludoVsComputerKey, value);
    ref.invalidateSelf();
  }

  Future<void> setSnakesVsComputer(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_snakesVsComputerKey, value);
    ref.invalidateSelf();
  }

  Future<void> setBankAlHazVsComputer(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bankAlHazVsComputerKey, value);
    ref.invalidateSelf();
  }

  Future<void> setTicTacToeSwapRoles(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ticTacToeSwapRolesKey, value);
    ref.invalidateSelf();
  }

  Future<void> setGlobalAiEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_globalAiEnabledKey, value);
    ref.invalidateSelf();
  }

  Future<void> setChristmasMusicEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_christmasMusicEnabledKey, value);
    ref.invalidateSelf();
  }
}

@riverpod
Future<ThemeConfig> currentTheme(Ref ref) async {
  final settings = await ref.watch(generalSettingsProvider.future);
  final themeId = settings['app_theme'] as String? ?? 'default';
  return AppThemes.getThemeById(themeId, customParams: settings);
}
