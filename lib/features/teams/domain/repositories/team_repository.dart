import '../entities/team.dart';

abstract class TeamRepository {
  Future<List<Team>> getTeams();
  Future<int> addTeam(Team team);
  Future<void> updateTeam(Team team);
  Future<void> deleteTeam(int id);
  Future<void> updateScore(int id, int newScore);
}
