import 'package:games/features/questions/domain/entities/question.dart';
import 'package:games/features/teams/domain/entities/team.dart';

enum PenaltyGameStatus {
  idle,
  playing,
  feedback,
  suddenDeath,
  finished,
}

enum PenaltyTurn {
  teamA,
  teamB,
}

class PenaltyShootoutState {
  final List<bool?> teamAAttempts;
  final List<bool?> teamBAttempts;
  final int teamAScore;
  final int teamBScore;
  final PenaltyTurn currentTurn;
  final int currentRound;
  final PenaltyGameStatus status;
  final Question? currentQuestion;
  final int timer;
  final Team? teamA;
  final Team? teamB;
  final bool? lastResult; // true for goal, false for miss, null for none
  final String? winner;
  final bool isSuddenDeath;

  PenaltyShootoutState({
    required this.teamAAttempts,
    required this.teamBAttempts,
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.currentTurn = PenaltyTurn.teamA,
    this.currentRound = 1,
    this.status = PenaltyGameStatus.idle,
    this.currentQuestion,
    this.timer = 10,
    this.teamA,
    this.teamB,
    this.lastResult,
    this.winner,
    this.isSuddenDeath = false,
  });

  PenaltyShootoutState copyWith({
    List<bool?>? teamAAttempts,
    List<bool?>? teamBAttempts,
    int? teamAScore,
    int? teamBScore,
    PenaltyTurn? currentTurn,
    int? currentRound,
    PenaltyGameStatus? status,
    Question? currentQuestion,
    int? timer,
    Team? teamA,
    Team? teamB,
    bool? lastResult,
    String? winner,
    bool? isSuddenDeath,
  }) {
    return PenaltyShootoutState(
      teamAAttempts: teamAAttempts ?? this.teamAAttempts,
      teamBAttempts: teamBAttempts ?? this.teamBAttempts,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      currentTurn: currentTurn ?? this.currentTurn,
      currentRound: currentRound ?? this.currentRound,
      status: status ?? this.status,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      timer: timer ?? this.timer,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      lastResult: lastResult, // Can be null
      winner: winner ?? this.winner,
      isSuddenDeath: isSuddenDeath ?? this.isSuddenDeath,
    );
  }
}
