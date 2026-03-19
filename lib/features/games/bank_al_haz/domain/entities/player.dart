class BankAlHazPlayer {
  final int id;
  final String name;
  final double money;
  final int currentPosition;
  final List<int> ownedStationIds;
  final double nextDiceMultiplier;
  final bool skipNextTurn;
  final bool isEliminated;

  const BankAlHazPlayer({
    required this.id,
    required this.name,
    this.money = 0.0,
    this.currentPosition = 0,
    this.ownedStationIds = const [],
    this.nextDiceMultiplier = 1.0,
    this.skipNextTurn = false,
    this.isEliminated = false,
  });

  factory BankAlHazPlayer.fromJson(Map<String, dynamic> json) {
    return BankAlHazPlayer(
      id: json['id'] as int,
      name: json['name'] as String,
      money: (json['money'] as num).toDouble(),
      currentPosition: json['currentPosition'] as int,
      ownedStationIds: List<int>.from(json['ownedStationIds'] ?? []),
      nextDiceMultiplier: (json['nextDiceMultiplier'] as num).toDouble(),
      skipNextTurn: json['skipNextTurn'] as bool,
      isEliminated: json['isEliminated'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'money': money,
    'currentPosition': currentPosition,
    'ownedStationIds': ownedStationIds,
    'nextDiceMultiplier': nextDiceMultiplier,
    'skipNextTurn': skipNextTurn,
    'isEliminated': isEliminated,
  };

  BankAlHazPlayer copyWith({
    int? id,
    String? name,
    double? money,
    int? currentPosition,
    List<int>? ownedStationIds,
    double? nextDiceMultiplier,
    bool? skipNextTurn,
    bool? isEliminated,
  }) {
    return BankAlHazPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      money: money ?? this.money,
      currentPosition: currentPosition ?? this.currentPosition,
      ownedStationIds: ownedStationIds ?? this.ownedStationIds,
      nextDiceMultiplier: nextDiceMultiplier ?? this.nextDiceMultiplier,
      skipNextTurn: skipNextTurn ?? this.skipNextTurn,
      isEliminated: isEliminated ?? this.isEliminated,
    );
  }
}
