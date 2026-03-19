import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/score_log.dart';
import '../../data/repositories/team_repository_impl.dart';
import '../../domain/repositories/team_repository.dart';

part 'team_providers.g.dart';

@riverpod
TeamRepository teamRepository(Ref ref) {
  return TeamRepositoryImpl();
}

@riverpod
class TeamsList extends _$TeamsList {
  @override
  Future<List<Team>> build() async {
    return ref.watch(teamRepositoryProvider).getTeams();
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
    await ref.read(teamRepositoryProvider).deleteTeam(id);
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
  }

  Future<void> resetScores() async {
    await ref.read(teamRepositoryProvider).resetAllScores();
    ref.invalidateSelf();
  }

  Future<void> resetScoresAndClearLogs() async {
    await ref.read(teamRepositoryProvider).resetAllScores();
    await ref.read(teamRepositoryProvider).deleteAllScoreLogs();
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
