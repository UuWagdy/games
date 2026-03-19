import '../../domain/entities/score_log.dart';

class ScoreLogModel extends ScoreLog {
  ScoreLogModel({
    super.id,
    required super.teamId,
    required super.points,
    super.reason,
    super.gameName,
    super.question,
    super.answer,
    required super.timestamp,
  });

  factory ScoreLogModel.fromMap(Map<String, dynamic> map) {
    return ScoreLogModel(
      id: map['id'],
      teamId: map['team_id'],
      points: map['points'],
      reason: map['reason'],
      gameName: map['game_name'],
      question: map['question'],
      answer: map['answer'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'team_id': teamId,
      'points': points,
      'reason': reason,
      'game_name': gameName,
      'question': question,
      'answer': answer,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
