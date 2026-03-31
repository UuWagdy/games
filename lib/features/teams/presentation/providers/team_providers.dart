import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/score_log.dart';
import '../../data/repositories/team_repository_impl.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/repositories/team_repository.dart';

part 'team_providers.g.dart';

@riverpod
TeamRepository teamRepository(Ref ref) {
  return TeamRepositoryImpl();
}

@Riverpod(keepAlive: true)
class TeamsList extends _$TeamsList {
  final Map<int, int> _sessionScores = {};

  @override
  Future<List<Team>> build() async {
    final repo = ref.watch(teamRepositoryProvider);
    final teams = await repo.getTeams();
    
    // Ensure "AI" team exists
    bool hasAI = false;
    for (var t in teams) {
       if (t.name == 'AI') {
          hasAI = true;
          break;
       }
    }
    
    if (!hasAI) {
       await repo.addTeam(Team(name: 'AI', score: 0));
       ref.invalidateSelf(); // This will trigger a re-fetch
       return teams; // Temporary return
    }

    final settings = await ref.watch(generalSettingsProvider.future);
    final syncScores = settings['sync_scores'] ?? true;
    
    // Always hide AI from the main teams panel
    final filteredTeams = teams.where((t) => t.name.toUpperCase() != 'AI' && t.name != 'الآلي' && t.name.toUpperCase() != 'COMPUTER').toList();

    if (!syncScores) {
      return filteredTeams.map((t) => t.copyWith(score: _sessionScores[t.id] ?? 0)).toList();
    }
    return filteredTeams;
  }

  Future<void> updateScoreForName(
    String name,
    int pointsChange, {
    String? reason,
    String? gameName,
    String? question,
    String? answer,
  }) async {
    final teams = await ref.read(teamRepositoryProvider).getTeams();
    final team = teams.firstWhere((t) => t.name == name, orElse: () => Team(id: -1, name: ''));
    if (team.id != null && team.id != -1) {
       await updateScore(team.id!, pointsChange, reason: reason, gameName: gameName, question: question, answer: answer);
    }
  }

  Future<void> addTeam(String name) async {
    await ref.read(teamRepositoryProvider).addTeam(Team(name: name));
    ref.invalidateSelf();
  }

  Future<void> updateTeam(Team team) async {
    await ref.read(teamRepositoryProvider).updateTeam(team);
    ref.invalidateSelf();
  }

  Future<void> deleteTeam(int id) async {
    final teams = await future;
    try {
      final teamToDelete = teams.firstWhere((t) => t.id == id);
      if (teamToDelete.name == 'AI') return; // Cannot delete AI team
    } catch (_) {}

    await ref.read(teamRepositoryProvider).deleteTeam(id);
    _sessionScores.remove(id);
    ref.invalidateSelf();
  }

  Future<void> updateScore(
    int id,
    int pointsChange, {
    String? reason,
    String? gameName,
    String? question,
    String? answer,
  }) async {
    final settings = await ref.read(generalSettingsProvider.future);
    final syncScores = settings['sync_scores'] ?? true;

    if (syncScores) {
      await ref.read(teamRepositoryProvider).updateScore(
            id,
            pointsChange,
            reason: reason,
            gameName: gameName,
            question: question,
            answer: answer,
          );
      ref.invalidateSelf();
      ref.invalidate(scoreLogsProvider(id));
    } else {
      _sessionScores[id] = (_sessionScores[id] ?? 0) + pointsChange;
      ref.invalidateSelf();
      // We don't log session scores to the permanent DB logs for now
      // as they are "each game alone".
    }
  }

  void resetSessionScores() {
    _sessionScores.clear();
    ref.invalidateSelf();
  }

  Future<void> resetScores() async {
    await ref.read(teamRepositoryProvider).resetAllScores();
    _sessionScores.clear();
    ref.invalidateSelf();
  }

  Future<void> resetScoresAndClearLogs() async {
    await ref.read(teamRepositoryProvider).resetAllScores();
    await ref.read(teamRepositoryProvider).deleteAllScoreLogs();
    _sessionScores.clear();
    ref.invalidateSelf();
    // Invalidate all score logs
    final teams = await ref.read(teamRepositoryProvider).getTeams();
    for (var team in teams) {
      if (team.id != null) ref.invalidate(scoreLogsProvider(team.id!));
    }
  }
}

@riverpod
class CurrentTeamIndex extends _$CurrentTeamIndex {
  @override
  int build() => 0;

  void nextTeam(int totalTeams) {
    if (totalTeams <= 1) return;
    state = (state + 1) % totalTeams;
  }
}

@riverpod
Future<List<ScoreLog>> scoreLogs(Ref ref, int teamId) {
  return ref.watch(teamRepositoryProvider).getScoreLogs(teamId);
}
