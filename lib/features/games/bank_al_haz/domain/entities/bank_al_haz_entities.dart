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
  final List<Loan> activeLoans;
  final List<BankAlHazCertificate> activeCertificates;
  final int loansTakenCount;


  const BankAlHazPlayer({
    required this.id,
    required this.name,
    this.money = 0,
    this.currentPosition = 0,
    this.ownedStationIds = const [],
    this.skipNextTurn = false,
    this.nextDiceMultiplier = 1.0,
    this.lapsCompleted = 0,
    this.activeLoans = const [],
    this.activeCertificates = const [],
    this.loansTakenCount = 0,
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
    List<Loan>? activeLoans,
    List<BankAlHazCertificate>? activeCertificates,
    int? loansTakenCount,
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
      activeLoans: activeLoans ?? this.activeLoans,
      activeCertificates: activeCertificates ?? this.activeCertificates,
      loansTakenCount: loansTakenCount ?? this.loansTakenCount,
    );
  }


  factory BankAlHazPlayer.fromJson(Map<String, dynamic> json) {
    return BankAlHazPlayer(
      id: json['id'] as int,
      name: json['name'] as String,
      money: (json['money'] as num).toDouble(),
      currentPosition: json['currentPosition'] as int,
      ownedStationIds: (json['ownedStationIds'] as List).cast<int>(),
      skipNextTurn: json['skipNextTurn'] ?? false,
      nextDiceMultiplier: (json['nextDiceMultiplier'] as num?)?.toDouble() ?? 1.0,
      lapsCompleted: json['lapsCompleted'] as int? ?? 0,
      activeLoans: (json['activeLoans'] as List? ?? []).map((l) => Loan.fromJson(l)).toList(),
      activeCertificates: (json['activeCertificates'] as List? ?? []).map((c) => BankAlHazCertificate.fromJson(c)).toList(),
      loansTakenCount: json['loansTakenCount'] as int? ?? 0,
    );
  }


  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'money': money,
    'currentPosition': currentPosition,
    'ownedStationIds': ownedStationIds,
    'skipNextTurn': skipNextTurn,
    'loansTakenCount': loansTakenCount,
    'nextDiceMultiplier': nextDiceMultiplier,
    'lapsCompleted': lapsCompleted,
    'activeLoans': activeLoans.map((l) => l.toJson()).toList(),
    'activeCertificates': activeCertificates.map((c) => c.toJson()).toList(),
  };
}


class Loan {
  final double amountBorrowed;
  final double amountToRepay;
  final int remainingTurns;
  final int startTurn;

  const Loan({
    required this.amountBorrowed,
    required this.amountToRepay,
    required this.remainingTurns,
    required this.startTurn,
  });

  Loan copyWith({
    double? amountBorrowed,
    double? amountToRepay,
    int? remainingTurns,
    int? startTurn,
  }) {
    return Loan(
      amountBorrowed: amountBorrowed ?? this.amountBorrowed,
      amountToRepay: amountToRepay ?? this.amountToRepay,
      remainingTurns: remainingTurns ?? this.remainingTurns,
      startTurn: startTurn ?? this.startTurn,
    );
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      amountBorrowed: (json['amountBorrowed'] as num).toDouble(),
      amountToRepay: (json['amountToRepay'] as num).toDouble(),
      remainingTurns: json['remainingTurns'] as int,
      startTurn: json['startTurn'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'amountBorrowed': amountBorrowed,
    'amountToRepay': amountToRepay,
    'remainingTurns': remainingTurns,
    'startTurn': startTurn,
  };
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

  BankAlHazTemplate copyWith({int? id, String? name}) {
    return BankAlHazTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
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

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] as int?,
      name: json['name'] as String,
      buyPrice: (json['buyPrice'] as num).toDouble(),
      baseRent: (json['baseRent'] as num).toDouble(),
      requiresQuestion: json['requiresQuestion'] ?? false,
      ownerCategoryId: json['ownerCategoryId'] as int?,
      passerCategoryId: json['passerCategoryId'] as int?,
      imagePath: json['imagePath'] as String?,
      type: StationType.values.byName(json['type'] as String? ?? 'property'),
      cardType: json['cardType'] as String?,
      buildings: (json['buildings'] as List? ?? []).map((b) => Building.fromJson(b)).toList(),
      isUnbuyable: json['isUnbuyable'] ?? false,
      templateId: json['templateId'] as int?,
      era: Era.values.byName(json['era'] as String? ?? 'none'),
      hasTax: json['hasTax'] ?? false,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      allowsTax: json['allowsTax'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'buyPrice': buyPrice,
    'baseRent': baseRent,
    'requiresQuestion': requiresQuestion,
    'ownerCategoryId': ownerCategoryId,
    'passerCategoryId': passerCategoryId,
    'imagePath': imagePath,
    'type': type.name,
    'cardType': cardType,
    'buildings': buildings.map((b) => b.toJson()).toList(),
    'isUnbuyable': isUnbuyable,
    'templateId': templateId,
    'era': era.name,
    'hasTax': hasTax,
    'taxAmount': taxAmount,
    'allowsTax': allowsTax,
  };
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

  factory BankAlHazCard.fromJson(Map<String, dynamic> json) {
    return BankAlHazCard(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String?,
      imagePath: json['imagePath'] as String?,
      effectType: CardEffectType.values.byName(json['effectType'] as String),
      effectValue: json['effectValue'] as int,
      targetStationName: json['targetStationName'] as String?,
      templateId: json['templateId'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type,
    'imagePath': imagePath,
    'effectType': effectType.name,
    'effectValue': effectValue,
    'targetStationName': targetStationName,
    'templateId': templateId,
  };
}

enum WinningCondition { rounds, time, bankruptcy }
enum WinCriteria { moneyOnly, moneyAndStations, cumulativeValue }
enum BankAlHazTaxMode { custom, all, none }
enum CertificatePayoutMode { perStation, perCycle }

class BankAlHazCertificate {
  final double principal;
  final double interestRate;
  final int totalCycles;
  final int cyclesCompleted;
  final DateTime purchaseTime;

  const BankAlHazCertificate({
    required this.principal,
    required this.interestRate,
    required this.totalCycles,
    this.cyclesCompleted = 0,
    required this.purchaseTime,
  });

  BankAlHazCertificate copyWith({
    double? principal,
    double? interestRate,
    int? totalCycles,
    int? cyclesCompleted,
    DateTime? purchaseTime,
  }) {
    return BankAlHazCertificate(
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      totalCycles: totalCycles ?? this.totalCycles,
      cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
      purchaseTime: purchaseTime ?? this.purchaseTime,
    );
  }

  factory BankAlHazCertificate.fromJson(Map<String, dynamic> json) {
    return BankAlHazCertificate(
      principal: (json['principal'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      totalCycles: json['totalCycles'] as int,
      cyclesCompleted: json['cyclesCompleted'] as int? ?? 0,
      purchaseTime: DateTime.parse(json['purchaseTime'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'principal': principal,
    'interestRate': interestRate,
    'totalCycles': totalCycles,
    'cyclesCompleted': cyclesCompleted,
    'purchaseTime': purchaseTime.toIso8601String(),
  };
}


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
  final bool loansEnabled;
  final int maxLoanDurationTurns;
  final double maxLoanAmount;
  final double loanInterestRate;
  final double loanInterestPenalty;
  final bool allowLoanRefinancing;
  final BankAlHazTaxMode taxMode;
  final bool checksEnabled;
  final double checkInterestRate;
  final double checkInterestIncrement;
  final bool certificatesEnabled;
  final double minCertificateAmount;
  final double certificateInterestRate;
  final int certificateCycles;
  final CertificatePayoutMode certificatePayoutMode;
  final bool inflationEnabled;
  final int inflationIntervalMinutes;
  final double inflationRate;
  final bool turnTimerEnabled;
  final int turnTimerSeconds;


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
    this.loansEnabled = false,
    this.maxLoanDurationTurns = 5,
    this.maxLoanAmount = 2000,
    this.loanInterestRate = 0.2, // 20%
    this.loanInterestPenalty = 0.04, // 4%
    this.allowLoanRefinancing = false,
    this.taxMode = BankAlHazTaxMode.custom,
    this.checksEnabled = false,
    this.checkInterestRate = 0.05, // 5%
    this.checkInterestIncrement = 0.0,
    this.certificatesEnabled = false,
    this.minCertificateAmount = 500.0,
    this.certificateInterestRate = 0.25, // 25%
    this.certificateCycles = 3,
    this.certificatePayoutMode = CertificatePayoutMode.perCycle,
    this.inflationEnabled = false,
    this.inflationIntervalMinutes = 5,
    this.inflationRate = 0.05, // 5%
    this.turnTimerEnabled = false,
    this.turnTimerSeconds = 30,
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
    bool? loansEnabled,
    int? maxLoanDurationTurns,
    double? maxLoanAmount,
    double? loanInterestRate,
    double? loanInterestPenalty,
    bool? allowLoanRefinancing,
    BankAlHazTaxMode? taxMode,
    bool? checksEnabled,
    double? checkInterestRate,
    double? checkInterestIncrement,
    bool? certificatesEnabled,
    double? minCertificateAmount,
    double? certificateInterestRate,
    int? certificateCycles,
    CertificatePayoutMode? certificatePayoutMode,
    bool? inflationEnabled,
    int? inflationIntervalMinutes,
    double? inflationRate,
    bool? turnTimerEnabled,
    int? turnTimerSeconds,
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
      loansEnabled: loansEnabled ?? this.loansEnabled,
      maxLoanDurationTurns: maxLoanDurationTurns ?? this.maxLoanDurationTurns,
      maxLoanAmount: maxLoanAmount ?? this.maxLoanAmount,
      loanInterestRate: loanInterestRate ?? this.loanInterestRate,
      loanInterestPenalty: loanInterestPenalty ?? this.loanInterestPenalty,
      allowLoanRefinancing: allowLoanRefinancing ?? this.allowLoanRefinancing,
      taxMode: taxMode ?? this.taxMode,
      checksEnabled: checksEnabled ?? this.checksEnabled,
      checkInterestRate: checkInterestRate ?? this.checkInterestRate,
      checkInterestIncrement: checkInterestIncrement ?? this.checkInterestIncrement,
      certificatesEnabled: certificatesEnabled ?? this.certificatesEnabled,
      minCertificateAmount: minCertificateAmount ?? this.minCertificateAmount,
      certificateInterestRate: certificateInterestRate ?? this.certificateInterestRate,
      certificateCycles: certificateCycles ?? this.certificateCycles,
      certificatePayoutMode: certificatePayoutMode ?? this.certificatePayoutMode,
      inflationEnabled: inflationEnabled ?? this.inflationEnabled,
      inflationIntervalMinutes: inflationIntervalMinutes ?? this.inflationIntervalMinutes,
      inflationRate: inflationRate ?? this.inflationRate,
      turnTimerEnabled: turnTimerEnabled ?? this.turnTimerEnabled,
      turnTimerSeconds: turnTimerSeconds ?? this.turnTimerSeconds,
    );
  }


  factory BankAlHazSettings.fromJson(Map<String, dynamic> json) {
    return BankAlHazSettings(
      initialMoney: (json['initialMoney'] as num?)?.toDouble() ?? 1500,
      salaryPerLap: (json['salaryPerLap'] as num?)?.toDouble() ?? 200,
      enableQuestions: json['enableQuestions'] ?? true,
      totalTurns: json['totalTurns'] ?? 12,
      winCondition: WinningCondition.values.byName(json['winCondition'] as String? ?? 'rounds'),
      winCriteria: WinCriteria.values.byName(json['winCriteria'] as String? ?? 'cumulativeValue'),
      maxRounds: json['maxRounds'] ?? 10,
      maxTimeMinutes: json['maxTimeMinutes'] ?? 30,
      winPoints: json['winPoints'] ?? 50,
      activeTemplateId: json['activeTemplateId'] as int?,
      bankruptcyEnabled: json['bankruptcyEnabled'] ?? false,
      loansEnabled: json['loansEnabled'] ?? false,
      maxLoanDurationTurns: json['maxLoanDurationTurns'] ?? json['loanDurationTurns'] ?? 5,
      maxLoanAmount: (json['maxLoanAmount'] as num?)?.toDouble() ?? 2000,
      loanInterestRate: (json['loanInterestRate'] as num?)?.toDouble() ?? 0.2,
      loanInterestPenalty: (json['loanInterestPenalty'] as num?)?.toDouble() ?? 0.04,
      allowLoanRefinancing: json['allowLoanRefinancing'] ?? false,
      taxMode: BankAlHazTaxMode.values.byName(json['taxMode'] as String? ?? 'custom'),
      checksEnabled: json['checksEnabled'] ?? false,
      checkInterestRate: (json['checkInterestRate'] as num?)?.toDouble() ?? 0.05,
      checkInterestIncrement: (json['checkInterestIncrement'] as num?)?.toDouble() ?? 0.0,
      certificatesEnabled: json['certificatesEnabled'] ?? false,
      minCertificateAmount: (json['minCertificateAmount'] as num?)?.toDouble() ?? 500.0,
      certificateInterestRate: (json['certificateInterestRate'] as num?)?.toDouble() ?? 0.25,
      certificateCycles: json['certificateCycles'] ?? 3,
      certificatePayoutMode: CertificatePayoutMode.values.byName(json['certificatePayoutMode'] as String? ?? 'perCycle'),
      inflationEnabled: json['inflationEnabled'] ?? false,
      inflationIntervalMinutes: json['inflationIntervalMinutes'] ?? 5,
      inflationRate: (json['inflationRate'] as num?)?.toDouble() ?? 0.05,
      turnTimerEnabled: json['turnTimerEnabled'] ?? false,
      turnTimerSeconds: json['turnTimerSeconds'] ?? 30,
    );
  }


  Map<String, dynamic> toJson() => {
    'initialMoney': initialMoney,
    'salaryPerLap': salaryPerLap,
    'enableQuestions': enableQuestions,
    'totalTurns': totalTurns,
    'winCondition': winCondition.name,
    'winCriteria': winCriteria.name,
    'maxRounds': maxRounds,
    'maxTimeMinutes': maxTimeMinutes,
    'winPoints': winPoints,
    'activeTemplateId': activeTemplateId,
    'bankruptcyEnabled': bankruptcyEnabled,
    'loansEnabled': loansEnabled,
    'maxLoanDurationTurns': maxLoanDurationTurns,
    'maxLoanAmount': maxLoanAmount,
    'loanInterestRate': loanInterestRate,
    'loanInterestPenalty': loanInterestPenalty,
    'allowLoanRefinancing': allowLoanRefinancing,
    'taxMode': taxMode.name,
    'checksEnabled': checksEnabled,
    'checkInterestRate': checkInterestRate,
    'checkInterestIncrement': checkInterestIncrement,
    'certificatesEnabled': certificatesEnabled,
    'minCertificateAmount': minCertificateAmount,
    'certificateInterestRate': certificateInterestRate,
    'certificateCycles': certificateCycles,
    'certificatePayoutMode': certificatePayoutMode.name,
    'inflationEnabled': inflationEnabled,
    'inflationIntervalMinutes': inflationIntervalMinutes,
    'inflationRate': inflationRate,
    'turnTimerEnabled': turnTimerEnabled,
    'turnTimerSeconds': turnTimerSeconds,
  };
}


enum LogType { info, moneyAdd, moneyRemove, movement, purchase, warning }

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

  factory GameLog.fromJson(Map<String, dynamic> json) {
    return GameLog(
      timestamp: DateTime.parse(json['timestamp'] as String),
      message: json['message'] as String,
      type: LogType.values.byName(json['type'] as String? ?? 'info'),
      playerIndex: json['playerIndex'] as int?,
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'message': message,
    'type': type.name,
    'playerIndex': playerIndex,
    'amount': amount,
  };
}
