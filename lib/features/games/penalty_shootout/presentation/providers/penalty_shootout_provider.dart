import 'dart:async';
import 'dart:math';
import 'package:games/features/games/penalty_shootout/domain/entities/penalty_shootout_state.dart';
import 'package:games/features/questions/domain/entities/question.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/features/teams/domain/entities/team.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'penalty_shootout_provider.g.dart';

@riverpod
class PenaltyShootout extends _$PenaltyShootout {
  Timer? _timer;

  @override
  PenaltyShootoutState build() {
    return PenaltyShootoutState(
      teamAAttempts: List.filled(5, null),
      teamBAttempts: List.filled(5, null),
    );
  }

  void startGame(Team tA, Team tB, List<int>? categoryIds) async {
    state = PenaltyShootoutState(
      teamAAttempts: List.filled(5, null),
      teamBAttempts: List.filled(5, null),
      teamA: tA,
      teamB: tB,
      status: PenaltyGameStatus.playing,
    );
    _nextQuestion(categoryIds);
  }

  Future<void> _nextQuestion(List<int>? categoryIds) async {
    List<Question> questions = [];
    if (categoryIds == null || categoryIds.isEmpty) {
      questions = await ref.read(questionsProvider(null).future);
    } else {
      for (var id in categoryIds) {
        questions.addAll(await ref.read(questionsProvider(id).future));
      }
    }

    if (questions.isEmpty) return;

    final question = questions[Random().nextInt(questions.length)];
    state = state.copyWith(
      currentQuestion: question,
      status: PenaltyGameStatus.playing,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    state = state.copyWith(timer: 10);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timer > 0) {
        state = state.copyWith(timer: state.timer - 1);
      } else {
        _timer?.cancel();
        submitAnswer(false); 
      }
    });
  }

  void submitAnswer(bool correct) {
    _timer?.cancel();
    
    final currentRound = state.currentRound;
    final currentTurn = state.currentTurn;

    // Update attempts
    List<bool?> teamAAttempts = List.from(state.teamAAttempts);
    List<bool?> teamBAttempts = List.from(state.teamBAttempts);
    
    if (currentTurn == PenaltyTurn.teamA) {
      if (state.isSuddenDeath) {
        teamAAttempts.add(correct);
      } else {
        teamAAttempts[currentRound - 1] = correct;
      }
    } else {
      if (state.isSuddenDeath) {
        teamBAttempts.add(correct);
      } else {
        teamBAttempts[currentRound - 1] = correct;
      }
    }

    final newTeamAScore = currentTurn == PenaltyTurn.teamA ? state.teamAScore + (correct ? 1 : 0) : state.teamAScore;
    final newTeamBScore = currentTurn == PenaltyTurn.teamB ? state.teamBScore + (correct ? 1 : 0) : state.teamBScore;

    // CALCULATE WINNER (Early Win Check)
    String? winner;
    bool decided = false;

    if (state.isSuddenDeath) {
      // Sudden death check only after Team B shoots (equal number of shots)
      if (currentTurn == PenaltyTurn.teamB) {
        if (newTeamAScore != newTeamBScore) {
          decided = true;
          winner = newTeamAScore > newTeamBScore ? state.teamA?.name : state.teamB?.name;
        }
      }
    } else {
      // Normal rounds (1-5)
      int shotsTakenByA = (currentTurn == PenaltyTurn.teamA) ? currentRound : currentRound;
      int shotsTakenByB = (currentTurn == PenaltyTurn.teamB) ? currentRound : currentRound - 1;
      
      int remainingA = 5 - shotsTakenByA;
      int remainingB = 5 - shotsTakenByB;

      if (newTeamAScore > newTeamBScore + remainingB) {
        decided = true;
        winner = state.teamA?.name;
      } else if (newTeamBScore > newTeamAScore + remainingA) {
        decided = true;
        winner = state.teamB?.name;
      }
    }

    state = state.copyWith(
      teamAAttempts: teamAAttempts,
      teamBAttempts: teamBAttempts,
      teamAScore: newTeamAScore,
      teamBScore: newTeamBScore,
      lastResult: correct,
      status: PenaltyGameStatus.feedback,
      winner: winner,
    );
  }

  void nextTurn(List<int>? categoryIds) {
    if (state.status != PenaltyGameStatus.feedback) return;

    // 1. Check if game was decided in submitAnswer
    if (state.winner != null) {
      state = state.copyWith(status: PenaltyGameStatus.finished);
      return;
    }

    // 2. Check turn rotation
    if (state.currentTurn == PenaltyTurn.teamA) {
      // Switch to Team B in SAME round
      state = state.copyWith(
        currentTurn: PenaltyTurn.teamB,
        status: PenaltyGameStatus.playing,
      );
      _nextQuestion(categoryIds);
    } else {
      // Both took their shots in current round
      if (state.currentRound < 5) {
        // Move to next normal round
        state = state.copyWith(
          currentTurn: PenaltyTurn.teamA,
          currentRound: state.currentRound + 1,
          status: PenaltyGameStatus.playing,
        );
        _nextQuestion(categoryIds);
      } else {
        // Round 5 finished and not decided -> Sudden Death
        state = state.copyWith(
          isSuddenDeath: true,
          currentTurn: PenaltyTurn.teamA,
          currentRound: state.currentRound + 1,
          status: PenaltyGameStatus.playing,
        );
        _nextQuestion(categoryIds);
      }
    }
  }

  void reset() {
    state = build();
  }
}
