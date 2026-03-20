import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/models/settings.dart';
import '../../domain/repositories/word_repository.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';

final spyGameProvider = NotifierProvider<SpyGameController, SpyGameState>(() {
  return SpyGameController();
});

class SpyGameController extends Notifier<SpyGameState> {
  late final Random _random;

  @override
  SpyGameState build() {
    _random = Random();
    return SpyGameState.initial();
  }

  void updateSettings(SpyGameSettings settings) {
    state = state.copyWith(settings: settings);
  }

  Future<void> syncPlayersWithTeams() async {
    final teamsAsync = ref.read(teamsListProvider);
    final teams = teamsAsync.value ?? [];
    state = state.copyWith(
      players: teams.map((t) => SpyPlayer(
        id: (t.id ?? DateTime.now().millisecondsSinceEpoch).toString(),
        name: t.name,
      )).toList(),
    );
  }

  Future<void> addPlayer(String name) async {
    if (name.trim().isEmpty) return;
    await ref.read(teamsListProvider.notifier).addTeam(name.trim());
    await syncPlayersWithTeams();
  }

  Future<void> removePlayer(String id) async {
    final teamId = int.tryParse(id);
    if (teamId != null) {
      await ref.read(teamsListProvider.notifier).deleteTeam(teamId);
      await syncPlayersWithTeams();
    }
  }

  Future<void> startRound() async {
    print("SpyGame: Starting round...");
    
    final teamsAsync = ref.read(teamsListProvider);
    final teams = teamsAsync.value ?? [];
    var currentPlayers = teams.map((t) => SpyPlayer(
      id: (t.id ?? DateTime.now().millisecondsSinceEpoch).toString(),
      name: t.name,
    )).toList();

    if (currentPlayers.length < 3) {
      print("SpyGame: Not enough players (${currentPlayers.length})");
      return;
    }

    final categories = state.settings.selectedCategories;
    final words = SpyWordRepository.getWords(categories);
    if (words.isEmpty) {
      print("SpyGame: No words found for categories $categories");
      return;
    }

    final currentWord = words[_random.nextInt(words.length)];

    final playerIndices = List.generate(currentPlayers.length, (i) => i);
    playerIndices.shuffle(_random);
    final spyIndices = playerIndices.take(state.settings.numberOfSpies).toList();

    final updatedPlayers = currentPlayers.asMap().entries.map((entry) {
      final isSpy = spyIndices.contains(entry.key);
      return entry.value.copyWith(isSpy: isSpy);
    }).toList();

    // Calculate timer if enabled: Every player asks every other player once (N*(N-1) turns)
    int roundSeconds = state.settings.roundTimerSeconds;
    if (state.settings.timerEnabled) {
      final totalTurns = currentPlayers.length * (currentPlayers.length - 1) * state.settings.numberOfRounds;
      roundSeconds = totalTurns * 180; // 3 minutes per turn
    }

    state = state.copyWith(
      status: SpyGameStatus.reveal,
      currentRound: state.currentRound + 1,
      players: updatedPlayers,
      currentWord: currentWord,
      votingResults: {},
      currentPlayerRevealIndex: 0,
      isWordRevealed: false,
      winnerTeam: 0,
      interactionHistory: [],
      settings: state.settings.copyWith(roundTimerSeconds: roundSeconds),
    );
  }

  void revealWord() {
    state = state.copyWith(isWordRevealed: true);
  }

  void hideWord() {
    state = state.copyWith(isWordRevealed: false);
  }

  void nextPlayerReveal() {
    if (state.currentPlayerRevealIndex < state.players.length - 1) {
      state = state.copyWith(
        currentPlayerRevealIndex: state.currentPlayerRevealIndex + 1,
        isWordRevealed: false,
      );
    } else {
      nextTurn();
      state = state.copyWith(status: SpyGameStatus.gameplay);
    }
  }

  void nextTurn() {
    if (state.players.length < 2) return;

    final allPossiblePairs = <String>[];
    for (final q in state.players) {
      for (final a in state.players) {
        if (q.id != a.id) allPossiblePairs.add("${q.id}-${a.id}");
      }
    }

    final availablePairs = allPossiblePairs.where((pair) {
      final pairCount = state.interactionHistory.where((p) => p == pair).length;
      return pairCount < state.settings.numberOfRounds;
    }).toList();

    if (availablePairs.isEmpty) return;

    // Pick a pair while balancing who asks
    availablePairs.shuffle(_random);
    availablePairs.sort((a, b) {
      final aQId = a.split("-")[0];
      final bQId = b.split("-")[0];
      
      final aQCount = state.interactionHistory.where((p) => p.startsWith("$aQId-")).length;
      final bQCount = state.interactionHistory.where((p) => p.startsWith("$bQId-")).length;
      
      return aQCount.compareTo(bQCount);
    });
    
    final chosenPair = availablePairs.first;
    final parts = chosenPair.split("-");
    
    state = state.copyWith(
      randomQuestionerId: parts[0],
      randomAnswererId: parts[1],
      interactionHistory: [...state.interactionHistory, chosenPair],
    );
  }

  void startVoting() {
    state = state.copyWith(status: SpyGameStatus.voting);
  }

  void castVote(String voterId, String suspectedId) {
    final results = Map<String, String>.from(state.votingResults);
    results[voterId] = suspectedId;
    
    if (results.length == state.players.length) {
      state = state.copyWith(votingResults: results);
      _processVotingResults();
    } else {
      state = state.copyWith(votingResults: results);
    }
  }

  void _processVotingResults() {
    state = state.copyWith(status: SpyGameStatus.spyGuess);
  }

  void handleSpyGuess(String guess) {
    final wordText = state.currentWord?.text.trim().toLowerCase() ?? "";
    final isGuessCorrect = guess.trim().toLowerCase() == wordText;
    
    // Logic: 
    // 1. Spy gets points if guess correct.
    // 2. Players get points if they voted for the REAL spy.
    _finishRoundWithEnhancedScoring(isGuessCorrect);
  }

  void nextRound() {
    startRound();
  }

  void _finishRoundWithEnhancedScoring(bool spyGuessedCorrect) {
    // Determine winner purely for UI display (priority to players if they caught him, but user wants points for both)
    // Actually, let's just use winnerTeam = 1 if spy guessed right, 2 if not?
    // Or just show total points.
    
    final realSpiesIds = state.players.where((p) => p.isSpy).map((p) => p.id).toList();
    
    final updatedPlayers = state.players.map((p) {
      int pointsEarned = 0;
      String reason = "";

      if (p.isSpy) {
        if (spyGuessedCorrect) {
          pointsEarned = state.settings.spyWinPoints;
          reason = "تخمين صحيح";
        }
      } else {
        // Player: Did they vote for a real spy?
        final votedFor = state.votingResults[p.id];
        if (votedFor != null && realSpiesIds.contains(votedFor)) {
          pointsEarned = state.settings.playersWinPoints;
          reason = "كشف الجاسوس";
        }
      }

      if (pointsEarned > 0) {
        _syncTeamScore(p.id, pointsEarned, reason);
      }
      return p.copyWith(score: p.score + pointsEarned);
    }).toList();

    state = state.copyWith(
      status: SpyGameStatus.result,
      players: updatedPlayers,
      winnerTeam: (spyGuessedCorrect) ? 1 : 2,
    );
  }

  void _syncTeamScore(String id, int points, String reason) {
    final teamId = int.tryParse(id);
    if (teamId != null) {
      ref.read(teamsListProvider.notifier).updateScore(teamId, points, reason: reason);
    }
  }

  void endGame() {
    resetGame();
  }

  void resetGame() {
    state = SpyGameState.initial();
    syncPlayersWithTeams();
  }
}
