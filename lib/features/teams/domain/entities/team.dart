class Team {
  final int? id;
  final String name;
  final int score;
  final int playersCount;

  Team({
    this.id,
    required this.name,
    this.score = 0,
    this.playersCount = 0,
  });

  Team copyWith({
    int? id,
    String? name,
    int? score,
    int? playersCount,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
      playersCount: playersCount ?? this.playersCount,
    );
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          score == other.score &&
          playersCount == other.playersCount;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ score.hashCode ^ playersCount.hashCode;
}
