import 'dart:async';
import 'dart:math';
import 'package:games/features/games/penalty_shootout/domain/entities/penalty_shootout_state.dart';
import 'package:games/features/games/penalty_shootout/presentation/providers/penalty_settings_provider.dart';
import 'package:games/features/questions/domain/entities/question.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/features/teams/domain/entities/team.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';

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
    final settingsAsync = await ref.read(penaltySettingsProvider.future);

    state = PenaltyShootoutState(
      teamAAttempts: List.filled(5, null),
      teamBAttempts: List.filled(5, null),
      teamA: tA,
      teamB: tB,
      status: PenaltyGameStatus.playing,
      isCompetitiveMode: settingsAsync['competitive_mode'] ?? false,
      teamAKey: settingsAsync['team_a_key'] ?? 'a',
      teamBKey: settingsAsync['team_b_key'] ?? 'l',
      timerDuration: settingsAsync['timer_duration'] ?? 10,
      timer: settingsAsync['timer_duration'] ?? 10,
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
      clearBuzzedTurn: true,
      failedTurnsInCurrentQuestion: [],
    );
    _startTimer(forceReset: true);
  }

  void _startTimer({bool forceReset = false}) {
    _timer?.cancel();
    if (forceReset || state.timer <= 0) {
      state = state.copyWith(timer: state.timerDuration);
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timer > 0) {
        state = state.copyWith(timer: state.timer - 1);
      } else {
        _timer?.cancel();
        if (state.isCompetitiveMode) {
          if (state.buzzedTurn != null) {
            submitAnswer(false);
          } else {
            _handleGeneralMiss();
          }
        } else {
          submitAnswer(false);
        }
      }
    });
  }

  void onBuzzerPressed(PenaltyTurn turn) {
    if (state.status != PenaltyGameStatus.playing || state.buzzedTurn != null)
      return;
    if (state.failedTurnsInCurrentQuestion.contains(turn)) return;

    _timer?.cancel();
    state = state.copyWith(buzzedTurn: turn);
  }

  void _handleGeneralMiss() {
    _timer?.cancel();
    List<bool?> teamAAttempts = List.from(state.teamAAttempts);
    List<bool?> teamBAttempts = List.from(state.teamBAttempts);

    final currentRound = state.currentRound;
    if (state.isSuddenDeath) {
      teamAAttempts.add(false);
      teamBAttempts.add(false);
    } else {
      teamAAttempts[currentRound - 1] = false;
      teamBAttempts[currentRound - 1] = false;
    }

    state = state.copyWith(
      teamAAttempts: teamAAttempts,
      teamBAttempts: teamBAttempts,
      lastResult: false,
      status: PenaltyGameStatus.feedback,
      clearBuzzedTurn: true,
    );
    _calculateWinner();
  }

  void submitAnswer(bool correct) {
    _timer?.cancel();

    if (state.isCompetitiveMode) {
      _submitCompetitiveAnswer(correct);
      return;
    }

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

    final newTeamAScore = currentTurn == PenaltyTurn.teamA
        ? state.teamAScore + (correct ? 1 : 0)
        : state.teamAScore;
    final newTeamBScore = currentTurn == PenaltyTurn.teamB
        ? state.teamBScore + (correct ? 1 : 0)
        : state.teamBScore;

    state = state.copyWith(
      teamAAttempts: teamAAttempts,
      teamBAttempts: teamBAttempts,
      teamAScore: newTeamAScore,
      teamBScore: newTeamBScore,
      lastResult: correct,
      status: PenaltyGameStatus.feedback,
    );
    _calculateWinner();
  }

  void _submitCompetitiveAnswer(bool correct) {
    final buzzedTurn = state.buzzedTurn;
    if (buzzedTurn == null) return;

    if (correct) {
      // Buzzed team gets Goal, Other team gets Miss for this round
      List<bool?> teamAAttempts = List.from(state.teamAAttempts);
      List<bool?> teamBAttempts = List.from(state.teamBAttempts);
      final currentRound = state.currentRound;

      if (buzzedTurn == PenaltyTurn.teamA) {
        if (state.isSuddenDeath) {
          teamAAttempts.add(true);
          teamBAttempts.add(false);
        } else {
          teamAAttempts[currentRound - 1] = true;
          teamBAttempts[currentRound - 1] = false;
        }
      } else {
        if (state.isSuddenDeath) {
          teamBAttempts.add(true);
          teamAAttempts.add(false);
        } else {
          teamBAttempts[currentRound - 1] = true;
          teamAAttempts[currentRound - 1] = false;
        }
      }

      state = state.copyWith(
        teamAAttempts: teamAAttempts,
        teamBAttempts: teamBAttempts,
        teamAScore:
            state.teamAScore + (buzzedTurn == PenaltyTurn.teamA ? 1 : 0),
        teamBScore:
            state.teamBScore + (buzzedTurn == PenaltyTurn.teamB ? 1 : 0),
        lastResult: true,
        status: PenaltyGameStatus.feedback,
        clearBuzzedTurn: true,
      );
      _calculateWinner();
      _timer?.cancel();
    } else {
      // Buzzed team gets Miss.
      List<PenaltyTurn> failed = List.from(state.failedTurnsInCurrentQuestion);
      failed.add(buzzedTurn);

      List<bool?> teamAAttempts = List.from(state.teamAAttempts);
      List<bool?> teamBAttempts = List.from(state.teamBAttempts);
      final currentRound = state.currentRound;

      if (buzzedTurn == PenaltyTurn.teamA) {
        if (state.isSuddenDeath) {
          teamAAttempts.add(false);
        } else {
          teamAAttempts[currentRound - 1] = false;
        }
      } else {
        if (state.isSuddenDeath) {
          teamBAttempts.add(false);
        } else {
          teamBAttempts[currentRound - 1] = false;
        }
      }

      state = state.copyWith(
        teamAAttempts: teamAAttempts,
        teamBAttempts: teamBAttempts,
        clearBuzzedTurn: true,
        failedTurnsInCurrentQuestion: failed,
      );

      // If all teams failed, round ends as feedback
      if (failed.length >= 2) {
        state = state.copyWith(
          status: PenaltyGameStatus.feedback,
          lastResult: false,
        );
        _calculateWinner();
      } else {
        // We stay in playing status with no buzzed turn,
        // allowing the remaining team to buzzer.
        // Resume the timer per user request!
        _startTimer();
      }
    }
  }

  void _calculateWinner() {
    final newTeamAScore = state.teamAScore;
    final newTeamBScore = state.teamBScore;

    String? winner;
    int? winnerId;
    bool decided = false;

    if (state.isSuddenDeath) {
      if (state.teamAAttempts.length == state.teamBAttempts.length) {
        if (newTeamAScore != newTeamBScore) {
          decided = true;
          winner = newTeamAScore > newTeamBScore
              ? state.teamA?.name
              : state.teamB?.name;
          winnerId = newTeamAScore > newTeamBScore
              ? state.teamA?.id
              : state.teamB?.id;
        }
      }
    } else {
      int shotsTakenByA = state.teamAAttempts.where((e) => e != null).length;
      int shotsTakenByB = state.teamBAttempts.where((e) => e != null).length;

      int remainingA = 5 - shotsTakenByA;
      int remainingB = 5 - shotsTakenByB;

      if (newTeamAScore > newTeamBScore + remainingB) {
        decided = true;
        winner = state.teamA?.name;
        winnerId = state.teamA?.id;
      } else if (newTeamBScore > newTeamAScore + remainingA) {
        decided = true;
        winner = state.teamB?.name;
        winnerId = state.teamB?.id;
      }
    }

    state = state.copyWith(winner: winner, winnerId: winnerId);
  }

  void nextTurn(List<int>? categoryIds) async {
    if (state.status != PenaltyGameStatus.feedback) return;

    if (state.winner != null) {
      state = state.copyWith(status: PenaltyGameStatus.finished);

      if (state.winnerId != null) {
        final settings = ref.read(generalSettingsProvider).value;
        final winPoints = settings?['penalty_win_points'] ?? 25;
        try {
          await ref
              .read(teamsListProvider.notifier)
              .updateScore(
                state.winnerId!,
                winPoints,
                reason: 'فوز في ضربات الجزاء',
              );
        } catch (e) {
          // Provider might be disposed
        }
      }
      return;
    }

    if (state.isCompetitiveMode) {
      if (state.currentRound < 5) {
        state = state.copyWith(
          currentRound: state.currentRound + 1,
          status: PenaltyGameStatus.playing,
          clearLastResult: true,
          clearBuzzedTurn: true,
        );
        _nextQuestion(categoryIds);
      } else {
        state = state.copyWith(
          isSuddenDeath: true,
          currentRound: state.currentRound + 1,
          status: PenaltyGameStatus.playing,
          clearLastResult: true,
          clearBuzzedTurn: true,
        );
        _nextQuestion(categoryIds);
      }
      return;
    }

    if (state.currentTurn == PenaltyTurn.teamA) {
      state = state.copyWith(
        currentTurn: PenaltyTurn.teamB,
        status: PenaltyGameStatus.playing,
        clearLastResult: true,
        clearBuzzedTurn: true,
      );
      _nextQuestion(categoryIds);
    } else {
      if (state.currentRound < 5) {
        state = state.copyWith(
          currentTurn: PenaltyTurn.teamA,
          currentRound: state.currentRound + 1,
          status: PenaltyGameStatus.playing,
          clearLastResult: true,
          clearBuzzedTurn: true,
        );
        _nextQuestion(categoryIds);
      } else {
        state = state.copyWith(
          isSuddenDeath: true,
          currentTurn: PenaltyTurn.teamA,
          currentRound: state.currentRound + 1,
          status: PenaltyGameStatus.playing,
          clearLastResult: true,
          clearBuzzedTurn: true,
        );
        _nextQuestion(categoryIds);
      }
    }
  }

  void reset() {
    state = build();
  }
}
