import '../models/player.dart';
import '../models/settings.dart';
import '../models/word.dart';

enum SpyGameStatus { setup, reveal, gameplay, voting, spyGuess, result }

class SpyGameState {
  final List<SpyPlayer> players;
  final SpyGameSettings settings;
  final SpyGameStatus status;
  final int currentRound;
  final SpyWord? currentWord;
  final int currentPlayerRevealIndex;
  final bool isWordRevealed;
  final int winnerTeam; // 0: none, 1: spy, 2: players
  final Map<String, String> votingResults; // Map<VoterId, SuspectedId>
  final String? randomQuestionerId;
  final String? randomAnswererId;
  final List<String> interactionHistory; // List of "QuestionerId-AnswererId" strings

  SpyGameState({
    this.players = const [],
    this.settings = const SpyGameSettings(),
    this.status = SpyGameStatus.setup,
    this.currentRound = 0,
    this.currentWord,
    this.currentPlayerRevealIndex = 0,
    this.isWordRevealed = false,
    this.winnerTeam = 0,
    this.votingResults = const {},
    this.randomQuestionerId,
    this.randomAnswererId,
    this.interactionHistory = const [],
  });

  factory SpyGameState.initial() => SpyGameState();

  SpyGameState copyWith({
    List<SpyPlayer>? players,
    SpyGameSettings? settings,
    SpyGameStatus? status,
    int? currentRound,
    SpyWord? currentWord,
    int? currentPlayerRevealIndex,
    bool? isWordRevealed,
    int? winnerTeam,
    Map<String, String>? votingResults,
    String? randomQuestionerId,
    String? randomAnswererId,
    List<String>? interactionHistory,
  }) {
    return SpyGameState(
      players: players ?? this.players,
      settings: settings ?? this.settings,
      status: status ?? this.status,
      currentRound: currentRound ?? this.currentRound,
      currentWord: currentWord ?? this.currentWord,
      currentPlayerRevealIndex: currentPlayerRevealIndex ?? this.currentPlayerRevealIndex,
      isWordRevealed: isWordRevealed ?? this.isWordRevealed,
      winnerTeam: winnerTeam ?? this.winnerTeam,
      votingResults: votingResults ?? this.votingResults,
      randomQuestionerId: randomQuestionerId ?? this.randomQuestionerId,
      randomAnswererId: randomAnswererId ?? this.randomAnswererId,
      interactionHistory: interactionHistory ?? this.interactionHistory,
    );
  }

  bool get isCycleCompleted {
    if (players.isEmpty) return false;
    // Each player should ask and be asked by every other player 'numberOfRounds' times.
    // Total turns needed = players.length * (players.length - 1) * settings.numberOfRounds
    final totalTurns = players.length * (players.length - 1) * settings.numberOfRounds;
    return interactionHistory.length >= totalTurns;
  }

  double get cycleProgress {
    if (players.isEmpty) return 0;
    final totalTurns = players.length * (players.length - 1) * settings.numberOfRounds;
    if (totalTurns == 0) return 0;
    return (interactionHistory.length / totalTurns).clamp(0, 1);
  }
}
