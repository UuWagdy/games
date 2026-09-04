import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import '../../domain/entities/saint_picture.dart';
import '../../domain/entities/hazer_fazer_state.dart';

final hazerFazerControllerProvider = NotifierProvider<HazerFazerController, HazerFazerState>(() {
  return HazerFazerController();
});

class HazerFazerController extends Notifier<HazerFazerState> {
  static const _customSaintsKey = 'hazer_fazer_custom_saints_json';
  final Random _random = Random();

  @override
  HazerFazerState build() {
    final settingsMap = ref.watch(generalSettingsProvider).value;
    final tileCount = (settingsMap?['hazer_fazer_tile_count'] as int?) ?? 9;
    final winPoints = (settingsMap?['hazer_fazer_win_points'] as int?) ?? 15;
    final modeStr = (settingsMap?['hazer_fazer_game_mode'] as String?) ?? 'shared';
    final gameMode = modeStr == 'per_team' ? HazerFazerGameMode.perTeam : HazerFazerGameMode.shared;

    final viewStr = (settingsMap?['hazer_fazer_per_team_view'] as String?) ?? 'all';
    final perTeamView = viewStr == 'single' ? HazerFazerPerTeamView.single : HazerFazerPerTeamView.all;

    // Load saved custom saints asynchronously
    _loadSavedSaints();

    final initialSaint = SaintPicture.defaultSaints.first;
    return HazerFazerState.initial(
      tileCount: tileCount,
      winPoints: winPoints,
      saint: initialSaint,
      saints: SaintPicture.defaultSaints,
      gameMode: gameMode,
      perTeamView: perTeamView,
    );
  }

  Future<void> _loadSavedSaints() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString(_customSaintsKey);
    if (savedJson != null && savedJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(savedJson);
        final list = decoded.map((e) => SaintPicture.fromJson(e as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) {
          final nextSaint = list.firstWhere(
            (s) => s.id == state.currentSaint.id,
            orElse: () => list.first,
          );
          state = state.copyWith(allSaints: list, currentSaint: nextSaint);
          _setupPerTeamProgressIfNeeded();
        }
      } catch (e) {
        // Fallback to default
      }
    } else {
      _setupPerTeamProgressIfNeeded();
    }
  }

  void _setupPerTeamProgressIfNeeded() {
    if (state.gameMode != HazerFazerGameMode.perTeam) return;

    final teams = ref.read(teamsListProvider).value ?? [];
    if (teams.isEmpty) return;

    final pool = List<SaintPicture>.from(state.allSaints.isNotEmpty ? state.allSaints : SaintPicture.defaultSaints);
    pool.shuffle(_random);

    final Map<int, HazerFazerTeamProgress> progress = {};
    for (int i = 0; i < teams.length; i++) {
      final team = teams[i];
      final saint = pool[i % pool.length];
      progress[team.id!] = HazerFazerTeamProgress(
        saint: saint,
        revealedTiles: const {},
        isWon: false,
      );
    }
    state = state.copyWith(teamProgress: progress);
  }

  void setGameMode(HazerFazerGameMode mode) {
    state = state.copyWith(gameMode: mode);
    ref.read(generalSettingsProvider.notifier).setHazerFazerGameMode(
          mode == HazerFazerGameMode.perTeam ? 'per_team' : 'shared',
        );
    if (mode == HazerFazerGameMode.perTeam) {
      _setupPerTeamProgressIfNeeded();
    }
  }

  void setPerTeamView(HazerFazerPerTeamView view) {
    state = state.copyWith(perTeamView: view);
    ref.read(generalSettingsProvider.notifier).setHazerFazerPerTeamView(
          view == HazerFazerPerTeamView.single ? 'single' : 'all',
        );
  }

  Future<void> saveSaintsList(List<SaintPicture> saints) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(saints.map((s) => s.toJson()).toList());
    await prefs.setString(_customSaintsKey, encoded);

    final currentUpdated = saints.firstWhere(
      (s) => s.id == state.currentSaint.id,
      orElse: () => saints.isNotEmpty ? saints.first : SaintPicture.defaultSaints.first,
    );

    state = state.copyWith(allSaints: saints, currentSaint: currentUpdated);
  }

  Future<void> addOrUpdateSaint(SaintPicture saint) async {
    final list = List<SaintPicture>.from(state.allSaints);
    final index = list.indexWhere((s) => s.id == saint.id);
    if (index >= 0) {
      list[index] = saint;
    } else {
      list.add(saint);
    }
    await saveSaintsList(list);
  }

  Future<void> deleteSaint(String id) async {
    final list = List<SaintPicture>.from(state.allSaints)..removeWhere((s) => s.id == id);
    if (list.isEmpty) {
      list.addAll(SaintPicture.defaultSaints);
    }
    await saveSaintsList(list);
  }

  Future<void> resetSaintsToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customSaintsKey);
    state = state.copyWith(
      allSaints: SaintPicture.defaultSaints,
      currentSaint: SaintPicture.defaultSaints.first,
    );
  }

  void nextTeamTurn() {
    final teams = ref.read(teamsListProvider).value ?? [];
    if (teams.isEmpty) return;
    final nextIndex = (state.currentTeamIndex + 1) % teams.length;
    state = state.copyWith(currentTeamIndex: nextIndex);
  }

  void setTeamTurn(int index) {
    state = state.copyWith(currentTeamIndex: index);
  }

  void startNewRound({SaintPicture? specificSaint}) {
    final all = state.allSaints.isNotEmpty ? state.allSaints : SaintPicture.defaultSaints;
    SaintPicture nextSaint;
    List<String> nextHistory = List<String>.from(state.historySaintIds);

    if (specificSaint != null) {
      nextSaint = specificSaint;
      if (!nextHistory.contains(nextSaint.id)) {
        nextHistory.add(nextSaint.id);
      }
    } else {
      final available = all.where((s) => !nextHistory.contains(s.id)).toList();
      if (available.isNotEmpty) {
        nextSaint = available[_random.nextInt(available.length)];
        nextHistory.add(nextSaint.id);
      } else {
        final otherSaints = all.where((s) => s.id != state.currentSaint.id).toList();
        nextSaint = otherSaints.isNotEmpty
            ? otherSaints[_random.nextInt(otherSaints.length)]
            : all[_random.nextInt(all.length)];
        nextHistory = [nextSaint.id];
      }
    }

    final settingsMap = ref.read(generalSettingsProvider).value;
    final tileCount = (settingsMap?['hazer_fazer_tile_count'] as int?) ?? state.tileCount;
    final winPoints = (settingsMap?['hazer_fazer_win_points'] as int?) ?? state.winPoints;

    final teams = ref.read(teamsListProvider).value ?? [];
    final nextTeamIdx = teams.isNotEmpty ? (state.currentTeamIndex + 1) % teams.length : 0;

    // Build per-team progress if mode is perTeam
    final Map<int, HazerFazerTeamProgress> progress = {};
    if (state.gameMode == HazerFazerGameMode.perTeam && teams.isNotEmpty) {
      final pool = List<SaintPicture>.from(all);
      pool.shuffle(_random);
      for (int i = 0; i < teams.length; i++) {
        final t = teams[i];
        progress[t.id!] = HazerFazerTeamProgress(
          saint: pool[i % pool.length],
          revealedTiles: const {},
          isWon: false,
        );
      }
    }

    state = HazerFazerState(
      currentSaint: nextSaint,
      allSaints: all,
      tileCount: tileCount,
      revealedTiles: const {},
      canGuess: false,
      isWon: false,
      winningTeamId: null,
      winningTeamName: null,
      winPoints: winPoints,
      historySaintIds: nextHistory,
      roundNumber: state.roundNumber + 1,
      currentTeamIndex: nextTeamIdx,
      gameMode: state.gameMode,
      perTeamView: state.perTeamView,
      teamProgress: progress,
    );
  }

  void revealTile(int index, {int? activeTeamId}) {
    if (state.isWon) return;

    if (state.gameMode == HazerFazerGameMode.perTeam && activeTeamId != null) {
      final curProgress = state.teamProgress[activeTeamId];
      if (curProgress == null || curProgress.revealedTiles.contains(index)) return;

      final updatedRevealed = Set<int>.from(curProgress.revealedTiles)..add(index);
      final updatedMap = Map<int, HazerFazerTeamProgress>.from(state.teamProgress);
      updatedMap[activeTeamId] = curProgress.copyWith(revealedTiles: updatedRevealed);

      state = state.copyWith(
        teamProgress: updatedMap,
        canGuess: true,
      );
    } else {
      if (state.revealedTiles.contains(index)) return;
      final newRevealed = Set<int>.from(state.revealedTiles)..add(index);
      state = state.copyWith(
        revealedTiles: newRevealed,
        canGuess: true,
      );
    }
  }

  void setCanGuess(bool val) {
    state = state.copyWith(canGuess: val);
  }

  Future<void> submitGuess({
    required bool isCorrect,
    required int? teamId,
    String? teamName,
    int? customPoints,
  }) async {
    if (!isCorrect) return;

    final allTiles = List.generate(state.tileCount, (i) => i).toSet();
    final awardedPoints = customPoints ?? state.winPoints;

    if (state.gameMode == HazerFazerGameMode.perTeam && teamId != null) {
      final curProgress = state.teamProgress[teamId];
      final updatedMap = Map<int, HazerFazerTeamProgress>.from(state.teamProgress);
      if (curProgress != null) {
        updatedMap[teamId] = curProgress.copyWith(
          revealedTiles: allTiles,
          isWon: true,
        );
      }
      state = state.copyWith(
        teamProgress: updatedMap,
        isWon: true,
        winningTeamId: teamId,
        winningTeamName: teamName,
        canGuess: false,
      );
    } else {
      state = state.copyWith(
        revealedTiles: allTiles,
        isWon: true,
        winningTeamId: teamId,
        winningTeamName: teamName,
        canGuess: false,
      );
    }

    // Award points
    final settingsMap = ref.read(generalSettingsProvider).value;
    final syncScores = settingsMap?['sync_scores'] ?? true;

    if (teamId != null && syncScores) {
      final saintName = (state.gameMode == HazerFazerGameMode.perTeam && teamId != null)
          ? (state.teamProgress[teamId]?.saint.name ?? state.currentSaint.name)
          : state.currentSaint.name;

      await ref.read(teamsListProvider.notifier).updateScore(
            teamId,
            awardedPoints,
            reason: 'فوز في لعبة حزر فزر ($saintName)',
            gameName: 'حزر فزر',
          );
    }
  }

  void setTileCount(int count) {
    state = state.copyWith(
      tileCount: count,
      revealedTiles: const {},
      canGuess: false,
      isWon: false,
    );
    ref.read(generalSettingsProvider.notifier).setHazerFazerTileCount(count);
  }

  void setWinPoints(int points) {
    state = state.copyWith(winPoints: points);
    ref.read(generalSettingsProvider.notifier).setHazerFazerWinPoints(points);
  }

  void selectSaint(SaintPicture saint) {
    state = state.copyWith(
      currentSaint: saint,
      revealedTiles: const {},
      canGuess: false,
      isWon: false,
    );
  }

  void restartCurrentRound() {
    state = state.copyWith(
      revealedTiles: const {},
      canGuess: false,
      isWon: false,
      winningTeamId: null,
      winningTeamName: null,
    );
  }
}
