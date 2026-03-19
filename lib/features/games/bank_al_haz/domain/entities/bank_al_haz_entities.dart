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

class Building {
  final int? id;
  final int? stationId;
  final String name;
  final double buyPrice;
  final double additionalRent;

  const Building({
    this.id,
    this.stationId,
    required this.name,
    required this.buyPrice,
    required this.additionalRent,
  });
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
  });
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

  const BankAlHazSettings({
    this.initialMoney = 1500,
    this.salaryPerLap = 200,
    this.enableQuestions = true,
    this.totalTurns = 12,
    this.winCondition = WinningCondition.rounds,
    this.winCriteria = WinCriteria.cumulativeValue,
    this.maxRounds = 10,
    this.maxTimeMinutes = 30,
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
    );
  }
}
