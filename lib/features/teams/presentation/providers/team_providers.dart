import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/team.dart';
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

  Future<void> deleteTeam(int id) async {
    await ref.read(teamRepositoryProvider).deleteTeam(id);
    ref.invalidateSelf();
  }

  Future<void> updateScore(int id, int points) async {
    final teams = await future;
    final team = teams.firstWhere((t) => t.id == id);
    final newScore = team.score + points;
    await ref.read(teamRepositoryProvider).updateScore(id, newScore);
    ref.invalidateSelf();
  }
}

@riverpod
class CurrentTeamIndex extends _$CurrentTeamIndex {
  @override
  int build() => 0;

  void nextTeam(int totalTeams) {
    state = (state + 1) % totalTeams;
  }
}
