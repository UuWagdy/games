class SpyPlayer {
  final String id;
  final String name;
  final bool isSpy;
  final int score;

  SpyPlayer({
    required this.id,
    required this.name,
    this.isSpy = false,
    this.score = 0,
  });

  SpyPlayer copyWith({
    String? id,
    String? name,
    bool? isSpy,
    int? score,
  }) {
    return SpyPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isSpy: isSpy ?? this.isSpy,
      score: score ?? this.score,
    );
  }
}
