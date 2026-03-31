import '../../../../questions/domain/entities/question.dart';
import '../../../../teams/domain/entities/team.dart';

enum UnderPressureStatus { idle, playing, paused, finished }

enum QuestionResult { correct, wrong, skipped, pending }

class UnderPressureState {
  final List<Team> teams;
  final Team? team1;
  final Team? team2;
  final List<Question> questions;
  final int currentQuestionIndex;
  final int team1Score;
  final int team2Score;
  final int timeLeft;
  final UnderPressureStatus status;
  final bool isTeam2Turn;
  final int? winnerTeamId;
  final bool isTie;
  final List<QuestionResult> team1Results;
  final List<QuestionResult> team2Results;
  final List<int>? categoryIds;
  final int team1PointsAdded;
  final int team2PointsAdded;
  final List<Question>? templateQuestions;
  final String? templateName;

  UnderPressureState({
    required this.teams,
    this.team1,
    this.team2,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.team1Score = 0,
    this.team2Score = 0,
    this.timeLeft = 60,
    this.status = UnderPressureStatus.idle,
    this.isTeam2Turn = false,
    this.winnerTeamId,
    this.isTie = false,
    this.team1Results = const [],
    this.team2Results = const [],
    this.categoryIds,
    this.team1PointsAdded = 0,
    this.team2PointsAdded = 0,
    this.templateQuestions,
    this.templateName,
  });

  Question? get currentQuestion => 
    (questions.isNotEmpty && currentQuestionIndex < questions.length) 
    ? questions[currentQuestionIndex] : null;

  UnderPressureState copyWith({
    List<Team>? teams,
    Team? team1,
    Team? team2,
    List<Question>? questions,
    int? currentQuestionIndex,
    int? team1Score,
    int? team2Score,
    int? timeLeft,
    UnderPressureStatus? status,
    bool? isTeam2Turn,
    int? winnerTeamId,
    bool? isTie,
    List<QuestionResult>? team1Results,
    List<QuestionResult>? team2Results,
    List<int>? categoryIds,
    int? team1PointsAdded,
    int? team2PointsAdded,
    List<Question>? templateQuestions,
    String? templateName,
  }) {
    return UnderPressureState(
      teams: teams ?? this.teams,
      team1: team1 ?? this.team1,
      team2: team2 ?? this.team2,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      team1Score: team1Score ?? this.team1Score,
      team2Score: team2Score ?? this.team2Score,
      timeLeft: timeLeft ?? this.timeLeft,
      status: status ?? this.status,
      isTeam2Turn: isTeam2Turn ?? this.isTeam2Turn,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
      isTie: isTie ?? this.isTie,
      team1Results: team1Results ?? this.team1Results,
      team2Results: team2Results ?? this.team2Results,
      categoryIds: categoryIds ?? this.categoryIds,
      team1PointsAdded: team1PointsAdded ?? this.team1PointsAdded,
      team2PointsAdded: team2PointsAdded ?? this.team2PointsAdded,
      templateQuestions: templateQuestions ?? this.templateQuestions,
      templateName: templateName ?? this.templateName,
    );
  }
}
