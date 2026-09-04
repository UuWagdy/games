import 'saint_picture.dart';

enum HazerFazerGameMode {
  shared, // صورة واحدة مشتركة
  perTeam, // صورة مستقلة لكل فريق
}

enum HazerFazerPerTeamView {
  single, // صورة الفريق الحالي فقط تعرض
  all, // صور كل الفرق تعرض معاً جنباً إلى جنب
}

class HazerFazerTeamProgress {
  final SaintPicture saint;
  final Set<int> revealedTiles;
  final bool isWon;

  const HazerFazerTeamProgress({
    required this.saint,
    required this.revealedTiles,
    this.isWon = false,
  });

  HazerFazerTeamProgress copyWith({
    SaintPicture? saint,
    Set<int>? revealedTiles,
    bool? isWon,
  }) {
    return HazerFazerTeamProgress(
      saint: saint ?? this.saint,
      revealedTiles: revealedTiles ?? this.revealedTiles,
      isWon: isWon ?? this.isWon,
    );
  }
}

class HazerFazerState {
  final SaintPicture currentSaint;
  final List<SaintPicture> allSaints;
  final int tileCount;
  final Set<int> revealedTiles;
  final bool canGuess;
  final bool isWon;
  final int? winningTeamId;
  final String? winningTeamName;
  final int winPoints;
  final List<String> historySaintIds;
  final int roundNumber;
  final int currentTeamIndex;
  final HazerFazerGameMode gameMode;
  final HazerFazerPerTeamView perTeamView;
  final Map<int, HazerFazerTeamProgress> teamProgress;

  const HazerFazerState({
    required this.currentSaint,
    required this.allSaints,
    required this.tileCount,
    required this.revealedTiles,
    required this.canGuess,
    required this.isWon,
    this.winningTeamId,
    this.winningTeamName,
    required this.winPoints,
    required this.historySaintIds,
    required this.roundNumber,
    required this.currentTeamIndex,
    required this.gameMode,
    required this.perTeamView,
    required this.teamProgress,
  });

  factory HazerFazerState.initial({
    int tileCount = 9,
    int winPoints = 15,
    SaintPicture? saint,
    List<SaintPicture>? saints,
    HazerFazerGameMode gameMode = HazerFazerGameMode.shared,
    HazerFazerPerTeamView perTeamView = HazerFazerPerTeamView.all,
  }) {
    final list = saints ?? SaintPicture.defaultSaints;
    final defaultSaint = saint ?? (list.isNotEmpty ? list.first : SaintPicture.defaultSaints.first);
    return HazerFazerState(
      currentSaint: defaultSaint,
      allSaints: list,
      tileCount: tileCount,
      revealedTiles: const {},
      canGuess: false,
      isWon: false,
      winningTeamId: null,
      winningTeamName: null,
      winPoints: winPoints,
      historySaintIds: [defaultSaint.id],
      roundNumber: 1,
      currentTeamIndex: 0,
      gameMode: gameMode,
      perTeamView: perTeamView,
      teamProgress: const {},
    );
  }

  SaintPicture getActiveSaint(int? activeTeamId) {
    if (gameMode == HazerFazerGameMode.perTeam && activeTeamId != null) {
      return teamProgress[activeTeamId]?.saint ?? currentSaint;
    }
    return currentSaint;
  }

  Set<int> getActiveRevealedTiles(int? activeTeamId) {
    if (gameMode == HazerFazerGameMode.perTeam && activeTeamId != null) {
      return teamProgress[activeTeamId]?.revealedTiles ?? const {};
    }
    return revealedTiles;
  }

  (int, int) get gridDimensions {
    switch (tileCount) {
      case 4:
        return (2, 2);
      case 6:
        return (2, 3); // 2 rows, 3 cols
      case 9:
        return (3, 3);
      case 12:
        return (3, 4); // 3 rows, 4 cols
      case 16:
        return (4, 4);
      case 20:
        return (4, 5); // 4 rows, 5 cols
      case 25:
        return (5, 5);
      default:
        return (3, 3);
    }
  }

  int get rows => gridDimensions.$1;
  int get cols => gridDimensions.$2;

  HazerFazerState copyWith({
    SaintPicture? currentSaint,
    List<SaintPicture>? allSaints,
    int? tileCount,
    Set<int>? revealedTiles,
    bool? canGuess,
    bool? isWon,
    int? winningTeamId,
    String? winningTeamName,
    int? winPoints,
    List<String>? historySaintIds,
    int? roundNumber,
    int? currentTeamIndex,
    HazerFazerGameMode? gameMode,
    HazerFazerPerTeamView? perTeamView,
    Map<int, HazerFazerTeamProgress>? teamProgress,
  }) {
    return HazerFazerState(
      currentSaint: currentSaint ?? this.currentSaint,
      allSaints: allSaints ?? this.allSaints,
      tileCount: tileCount ?? this.tileCount,
      revealedTiles: revealedTiles ?? this.revealedTiles,
      canGuess: canGuess ?? this.canGuess,
      isWon: isWon ?? this.isWon,
      winningTeamId: winningTeamId ?? this.winningTeamId,
      winningTeamName: winningTeamName ?? this.winningTeamName,
      winPoints: winPoints ?? this.winPoints,
      historySaintIds: historySaintIds ?? this.historySaintIds,
      roundNumber: roundNumber ?? this.roundNumber,
      currentTeamIndex: currentTeamIndex ?? this.currentTeamIndex,
      gameMode: gameMode ?? this.gameMode,
      perTeamView: perTeamView ?? this.perTeamView,
      teamProgress: teamProgress ?? this.teamProgress,
    );
  }
}
