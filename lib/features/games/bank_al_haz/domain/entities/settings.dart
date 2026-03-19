enum WinningCondition { rounds, finishQuestions, time }
enum WinCriteria { moneyOnly, moneyAndStations, fullAssets }

class BankAlHazSettings {
  final double initialMoney;
  final WinningCondition winCondition;
  final WinCriteria winCriteria;
  final int maxRounds;
  final int maxTimeMinutes;

  const BankAlHazSettings({
    this.initialMoney = 1000.0,
    this.winCondition = WinningCondition.rounds,
    this.winCriteria = WinCriteria.moneyOnly,
    this.maxRounds = 10,
    this.maxTimeMinutes = 30,
  });

  factory BankAlHazSettings.fromJson(Map<String, dynamic> json) {
    return BankAlHazSettings(
      initialMoney: (json['initialMoney'] as num).toDouble(),
      winCondition: WinningCondition.values.firstWhere((e) => e.name == json['winCondition'], orElse: () => WinningCondition.rounds),
      winCriteria: WinCriteria.values.firstWhere((e) => e.name == json['winCriteria'], orElse: () => WinCriteria.moneyOnly),
      maxRounds: json['maxRounds'] as int,
      maxTimeMinutes: json['maxTimeMinutes'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'initialMoney': initialMoney,
    'winCondition': winCondition.name,
    'winCriteria': winCriteria.name,
    'maxRounds': maxRounds,
    'maxTimeMinutes': maxTimeMinutes,
  };
}
