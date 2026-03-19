import '../../domain/entities/score_log.dart';
import '../../domain/entities/team.dart';
import '../../domain/repositories/team_repository.dart';
import '../models/score_log_model.dart';
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
  Future<void> updateScore(
    int id,
    int pointsChange, {
    String? reason,
    String? gameName,
    String? question,
    String? answer,
  }) async {
    final db = await _dbService.database;
    
    // 1. Update team score (increment)
    await db.rawUpdate(
      'UPDATE teams SET score = score + ? WHERE id = ?',
      [pointsChange, id],
    );

    // 2. Add score log
    final log = ScoreLogModel(
      teamId: id,
      points: pointsChange,
      reason: reason,
      gameName: gameName,
      question: question,
      answer: answer,
      timestamp: DateTime.now(),
    );
    await db.insert('score_logs', log.toMap());
  }

  @override
  Future<void> resetAllScores() async {
    final db = await _dbService.database;
    
    // Log resets before clearing
    final teams = await getTeams();
    for (var team in teams) {
      if (team.score != 0) {
        final log = ScoreLogModel(
          teamId: team.id!,
          points: -team.score,
          reason: 'تصفير النقاط',
          gameName: 'الإعدادات العامة',
          timestamp: DateTime.now(),
        );
        await db.insert('score_logs', log.toMap());
      }
    }

    await db.update('teams', {'score': 0});
  }

  @override
  Future<void> deleteAllScoreLogs() async {
    final db = await _dbService.database;
    await db.delete('score_logs');
  }

  @override
  Future<List<ScoreLog>> getScoreLogs(int teamId) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'score_logs',
      where: 'team_id = ?',
      whereArgs: [teamId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => ScoreLogModel.fromMap(map)).toList();
  }
}
