class ScoreLog {
  final int? id;
  final int teamId;
  final int points;
  final String? reason;
  final String? gameName;
  final String? question;
  final String? answer;
  final DateTime timestamp;

  ScoreLog({
    this.id,
    required this.teamId,
    required this.points,
    this.reason,
    this.gameName,
    this.question,
    this.answer,
    required this.timestamp,
  });
}
