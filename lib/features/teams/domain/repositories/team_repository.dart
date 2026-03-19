import '../entities/score_log.dart';
import '../entities/team.dart';

abstract class TeamRepository {
  Future<List<Team>> getTeams();
  Future<int> addTeam(Team team);
  Future<void> updateTeam(Team team);
  Future<void> deleteTeam(int id);
  Future<void> updateScore(
    int id,
    int pointsChange, {
    String? reason,
    String? gameName,
    String? question,
    String? answer,
  });
  Future<void> resetAllScores();
  Future<void> deleteAllScoreLogs();
  Future<List<ScoreLog>> getScoreLogs(int teamId);
}
