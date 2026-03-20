class SpyGameSettings {
  final int numberOfSpies;
  final int roundTimerSeconds;
  final bool timerEnabled;
  final bool soundEnabled;
  final bool animationsEnabled;
  final List<String> selectedCategories;
  final int numberOfRounds;
  final int spyWinPoints;
  final int playersWinPoints;

  const SpyGameSettings({
    this.numberOfSpies = 1,
    this.roundTimerSeconds = 180,
    this.numberOfRounds = 1,
    this.timerEnabled = false,
    this.soundEnabled = true,
    this.animationsEnabled = true,
    this.selectedCategories = const ['أماكن', 'وظائف', 'أشياء'],
    this.spyWinPoints = 20,
    this.playersWinPoints = 10,
  });

  SpyGameSettings copyWith({
    int? numberOfSpies,
    int? roundTimerSeconds,
    int? numberOfRounds,
    bool? timerEnabled,
    bool? soundEnabled,
    bool? animationsEnabled,
    List<String>? selectedCategories,
    int? spyWinPoints,
    int? playersWinPoints,
  }) {
    return SpyGameSettings(
      numberOfSpies: numberOfSpies ?? this.numberOfSpies,
      roundTimerSeconds: roundTimerSeconds ?? this.roundTimerSeconds,
      numberOfRounds: numberOfRounds ?? this.numberOfRounds,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      spyWinPoints: spyWinPoints ?? this.spyWinPoints,
      playersWinPoints: playersWinPoints ?? this.playersWinPoints,
    );
  }
}
