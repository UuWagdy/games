import 'dart:typed_data';

class BankAlHazPlayer {
  final int id;
  final String name;
  final double money;
  final int currentPosition;
  final List<int> ownedStationIds;
  final bool skipNextTurn;
  final double nextDiceMultiplier;
  final int lapsCompleted;

  const BankAlHazPlayer({
    required this.id,
    required this.name,
    this.money = 0,
    this.currentPosition = 0,
    this.ownedStationIds = const [],
    this.skipNextTurn = false,
    this.nextDiceMultiplier = 1.0,
    this.lapsCompleted = 0,
  });

  BankAlHazPlayer copyWith({
    int? id,
    String? name,
    double? money,
    int? currentPosition,
    List<int>? ownedStationIds,
    bool? skipNextTurn,
    double? nextDiceMultiplier,
    int? lapsCompleted,
  }) {
    return BankAlHazPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      money: money ?? this.money,
      currentPosition: currentPosition ?? this.currentPosition,
      ownedStationIds: ownedStationIds ?? this.ownedStationIds,
      skipNextTurn: skipNextTurn ?? this.skipNextTurn,
      nextDiceMultiplier: nextDiceMultiplier ?? this.nextDiceMultiplier,
      lapsCompleted: lapsCompleted ?? this.lapsCompleted,
    );
  }
}

enum StationType { property, card, tax, none, question }
enum Era { oldTestament, newTestament, none }

class Building {
  final int? id;
  final int? stationId;
  final String name;
  final double buyPrice;
  final double additionalRent;
  final bool isPurchased;

  const Building({
    this.id,
    this.stationId,
    required this.name,
    required this.buyPrice,
    required this.additionalRent,
    this.isPurchased = false,
  });

  Building copyWith({
    int? id,
    int? stationId,
    String? name,
    double? buyPrice,
    double? additionalRent,
    bool? isPurchased,
  }) {
    return Building(
      id: id ?? this.id,
      stationId: stationId ?? this.stationId,
      name: name ?? this.name,
      buyPrice: buyPrice ?? this.buyPrice,
      additionalRent: additionalRent ?? this.additionalRent,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'] as int?,
      stationId: json['stationId'] as int?,
      name: json['name'] as String,
      buyPrice: (json['buyPrice'] as num).toDouble(),
      additionalRent: (json['additionalRent'] as num).toDouble(),
      isPurchased: json['isPurchased'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'stationId': stationId,
    'name': name,
    'buyPrice': buyPrice,
    'additionalRent': additionalRent,
    'isPurchased': isPurchased,
  };
}

class BankAlHazTemplate {
  final int? id;
  final String name;

  const BankAlHazTemplate({this.id, required this.name});
}

class Station {
  final int? id;
  final String name;
  final double buyPrice;
  final double baseRent;
  final bool requiresQuestion;
  final int? ownerCategoryId;
  final int? passerCategoryId;
  final String? imagePath;
  final Uint8List? imageData;
  final StationType type;
  final String? cardType;
  final List<Building> buildings;
  final bool isUnbuyable;
  final int? templateId;
  final Era era;
  final bool hasTax;
  final double taxAmount;
  final bool allowsTax;

  const Station({
    this.id,
    required this.name,
    this.buyPrice = 0,
    this.baseRent = 0,
    this.requiresQuestion = false,
    this.ownerCategoryId,
    this.passerCategoryId,
    this.imagePath,
    this.imageData,
    this.type = StationType.property,
    this.cardType,
    this.buildings = const [],
    this.isUnbuyable = false,
    this.templateId,
    this.era = Era.none,
    this.hasTax = false,
    this.taxAmount = 0.0,
    this.allowsTax = true,
  });

  Station copyWith({
    int? id,
    String? name,
    double? buyPrice,
    double? baseRent,
    bool? requiresQuestion,
    int? ownerCategoryId,
    int? passerCategoryId,
    String? imagePath,
    Uint8List? imageData,
    StationType? type,
    String? cardType,
    List<Building>? buildings,
    bool? isUnbuyable,
    int? templateId,
    Era? era,
    bool? hasTax,
    double? taxAmount,
    bool? allowsTax,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      buyPrice: buyPrice ?? this.buyPrice,
      baseRent: baseRent ?? this.baseRent,
      requiresQuestion: requiresQuestion ?? this.requiresQuestion,
      ownerCategoryId: ownerCategoryId ?? this.ownerCategoryId,
      passerCategoryId: passerCategoryId ?? this.passerCategoryId,
      imagePath: imagePath ?? this.imagePath,
      imageData: imageData ?? this.imageData,
      type: type ?? this.type,
      cardType: cardType ?? this.cardType,
      buildings: buildings ?? this.buildings,
      isUnbuyable: isUnbuyable ?? this.isUnbuyable,
      templateId: templateId ?? this.templateId,
      era: era ?? this.era,
      hasTax: hasTax ?? this.hasTax,
      taxAmount: taxAmount ?? this.taxAmount,
      allowsTax: allowsTax ?? this.allowsTax,
    );
  }
}

enum CardEffectType { addMoney, removeMoney, skipTurn, diceMultiplier, moveSteps, moveToStation }

class BankAlHazCard {
  final int? id;
  final String title;
  final String description;
  final String? type;
  final String? imagePath;
  final Uint8List? imageData;
  final CardEffectType effectType;
  final int effectValue;
  final String? targetStationName;
  final int? templateId;

  const BankAlHazCard({
    this.id,
    required this.title,
    required this.description,
    this.type,
    this.imagePath,
    this.imageData,
    required this.effectType,
    required this.effectValue,
    this.targetStationName,
    this.templateId,
  });

  BankAlHazCard copyWith({
    int? id,
    String? title,
    String? description,
    String? type,
    String? imagePath,
    Uint8List? imageData,
    CardEffectType? effectType,
    int? effectValue,
    String? targetStationName,
    int? templateId,
  }) {
    return BankAlHazCard(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      imagePath: imagePath ?? this.imagePath,
      imageData: imageData ?? this.imageData,
      effectType: effectType ?? this.effectType,
      effectValue: effectValue ?? this.effectValue,
      targetStationName: targetStationName ?? this.targetStationName,
      templateId: templateId ?? this.templateId,
    );
  }
}

enum WinningCondition { rounds, time, bankruptcy }
enum WinCriteria { moneyOnly, moneyAndStations, cumulativeValue }

class BankAlHazSettings {
  final double initialMoney;
  final double salaryPerLap;
  final bool enableQuestions;
  final int totalTurns;
  final WinningCondition winCondition;
  final WinCriteria winCriteria;
  final int maxRounds;
  final int maxTimeMinutes;
  final int winPoints;
  final int? activeTemplateId;
  final bool bankruptcyEnabled;

  const BankAlHazSettings({
    this.initialMoney = 1500,
    this.salaryPerLap = 200,
    this.enableQuestions = true,
    this.totalTurns = 12,
    this.winCondition = WinningCondition.rounds,
    this.winCriteria = WinCriteria.cumulativeValue,
    this.maxRounds = 10,
    this.maxTimeMinutes = 30,
    this.winPoints = 50,
    this.activeTemplateId,
    this.bankruptcyEnabled = false,
  });

  BankAlHazSettings copyWith({
    double? initialMoney,
    double? salaryPerLap,
    bool? enableQuestions,
    int? totalTurns,
    WinningCondition? winCondition,
    WinCriteria? winCriteria,
    int? maxRounds,
    int? maxTimeMinutes,
    int? winPoints,
    int? activeTemplateId,
    bool? bankruptcyEnabled,
  }) {
    return BankAlHazSettings(
      initialMoney: initialMoney ?? this.initialMoney,
      salaryPerLap: salaryPerLap ?? this.salaryPerLap,
      enableQuestions: enableQuestions ?? this.enableQuestions,
      totalTurns: totalTurns ?? this.totalTurns,
      winCondition: winCondition ?? this.winCondition,
      winCriteria: winCriteria ?? this.winCriteria,
      maxRounds: maxRounds ?? this.maxRounds,
      maxTimeMinutes: maxTimeMinutes ?? this.maxTimeMinutes,
      winPoints: winPoints ?? this.winPoints,
      activeTemplateId: activeTemplateId ?? this.activeTemplateId,
      bankruptcyEnabled: bankruptcyEnabled ?? this.bankruptcyEnabled,
    );
  }
}

enum LogType { info, moneyAdd, moneyRemove, movement, purchase }

class GameLog {
  final DateTime timestamp;
  final String message;
  final LogType type;
  final int? playerIndex;
  final double? amount;

  const GameLog({
    required this.timestamp,
    required this.message,
    this.type = LogType.info,
    this.playerIndex,
    this.amount,
  });
}
