import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';
import '../models/team_model.dart';
import '../../../../core/database/database_service.dart';

class TeamRepositoryImpl implements TeamRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  Future<List<Team>> getTeams() async {
    final db = await _dbService.database;
    final result = await db.query('teams');
    return result.map((json) {
      final model = TeamModel.fromJson(json);
      return Team(
        id: model.id,
        name: model.name,
        score: model.score,
        playersCount: model.playersCount,
      );
    }).toList();
  }

  @override
  Future<int> addTeam(Team team) async {
    final db = await _dbService.database;
    return await db.insert('teams', {
      'name': team.name,
      'score': team.score,
      'players_count': team.playersCount,
    });
  }

  @override
  Future<void> updateTeam(Team team) async {
    final db = await _dbService.database;
    await db.update(
      'teams',
      {
        'name': team.name,
        'score': team.score,
        'players_count': team.playersCount,
      },
      where: 'id = ?',
      whereArgs: [team.id],
    );
  }

  @override
  Future<void> deleteTeam(int id) async {
    final db = await _dbService.database;
    await db.delete('teams', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> updateScore(int id, int newScore) async {
    final db = await _dbService.database;
    await db.update(
      'teams',
      {'score': newScore},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
