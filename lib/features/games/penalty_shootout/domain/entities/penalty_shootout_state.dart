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
  final int timerDuration;
  final Team? teamA;
  final Team? teamB;
  final bool? lastResult; // true for goal, false for miss, null for none
  final String? winner;
  final int? winnerId;
  final bool isSuddenDeath;

  // Competitive Mode fields
  final bool isCompetitiveMode;
  final String teamAKey;
  final String teamBKey;
  final PenaltyTurn? buzzedTurn; // Which team's turn it is currently due to buzzer
  final List<PenaltyTurn> failedTurnsInCurrentQuestion;
  final int maxPenalties;
  final List<Question>? templateQuestions;
  final String? templateName;
  final bool isTie;
  final int currentQuestionIndex;

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
    this.timerDuration = 10,
    this.teamA,
    this.teamB,
    this.lastResult,
    this.winner,
    this.winnerId,
    this.isSuddenDeath = false,
    this.isCompetitiveMode = false,
    this.teamAKey = 'a',
    this.teamBKey = 'l',
    this.buzzedTurn,
    this.failedTurnsInCurrentQuestion = const [],
    this.maxPenalties = 20,
    this.templateQuestions,
    this.templateName,
    this.isTie = false,
    this.currentQuestionIndex = 0,
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
    int? timerDuration,
    Team? teamA,
    Team? teamB,
    bool? lastResult,
    String? winner,
    int? winnerId,
    bool? isSuddenDeath,
    bool? isCompetitiveMode,
    String? teamAKey,
    String? teamBKey,
    PenaltyTurn? buzzedTurn,
    List<PenaltyTurn>? failedTurnsInCurrentQuestion,
    int? maxPenalties,
    List<Question>? templateQuestions,
    String? templateName,
    bool? isTie,
    int? currentQuestionIndex,
    bool clearLastResult = false,
    bool clearBuzzedTurn = false,
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
      timerDuration: timerDuration ?? this.timerDuration,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
      winner: winner ?? this.winner,
      winnerId: winnerId ?? this.winnerId,
      isSuddenDeath: isSuddenDeath ?? this.isSuddenDeath,
      isCompetitiveMode: isCompetitiveMode ?? this.isCompetitiveMode,
      teamAKey: teamAKey ?? this.teamAKey,
      teamBKey: teamBKey ?? this.teamBKey,
      buzzedTurn: clearBuzzedTurn ? null : (buzzedTurn ?? this.buzzedTurn),
      failedTurnsInCurrentQuestion: failedTurnsInCurrentQuestion ?? this.failedTurnsInCurrentQuestion,
      maxPenalties: maxPenalties ?? this.maxPenalties,
      templateQuestions: templateQuestions ?? this.templateQuestions,
      templateName: templateName ?? this.templateName,
      isTie: isTie ?? this.isTie,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    );
  }
}
