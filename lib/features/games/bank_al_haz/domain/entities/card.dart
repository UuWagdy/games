enum CardEffectType { 
  moveSteps, 
  moveToStation, 
  addMoney, 
  removeMoney, 
  diceMultiplier, 
  skipTurn 
}

class BankAlHazCard {
  final int? id;
  final String title;
  final String description;
  final String? imagePath;
  final String? type; // "Luck" or "Chance" etc.
  final CardEffectType effectType;
  final int effectValue;
  final String? targetStationName;

  const BankAlHazCard({
    this.id,
    required this.title,
    required this.description,
    this.imagePath,
    this.type,
    this.effectType = CardEffectType.addMoney,
    this.effectValue = 0,
    this.targetStationName,
  });

  factory BankAlHazCard.fromJson(Map<String, dynamic> json) {
    return BankAlHazCard(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String,
      imagePath: json['imagePath'] as String?,
      type: json['type'] as String?,
      effectType: CardEffectType.values.firstWhere((e) => e.name == json['effectType'], orElse: () => CardEffectType.addMoney),
      effectValue: json['effectValue'] as int? ?? 0,
      targetStationName: json['targetStationName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'imagePath': imagePath,
    'type': type,
    'effectType': effectType.name,
    'effectValue': effectValue,
    'targetStationName': targetStationName,
  };

  BankAlHazCard copyWith({
    int? id,
    String? title,
    String? description,
    String? imagePath,
    String? type,
    CardEffectType? effectType,
    int? effectValue,
    String? targetStationName,
  }) {
    return BankAlHazCard(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      type: type ?? this.type,
      effectType: effectType ?? this.effectType,
      effectValue: effectValue ?? this.effectValue,
      targetStationName: targetStationName ?? this.targetStationName,
    );
  }
}
