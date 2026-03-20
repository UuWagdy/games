import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../questions/domain/entities/question.dart';
import '../../../../teams/domain/entities/team.dart';

part 'quiz_arena_game_state.freezed.dart';

@freezed
abstract class QuizArenaGameState with _$QuizArenaGameState {
  const factory QuizArenaGameState({
    @Default([]) List<Team> teams,
    @Default(0) int currentTeamIndex,
    Question? currentQuestion,
    @Default(30) int remainingTime,
    @Default(false) bool isTimerRunning,
    @Default(0) int currentRound,
    @Default(false) bool showAnswer,
    @Default(false) bool hasVerdict,
    @Default(false) bool isGameOver,
    @Default(false) bool isLoading,
    @Default([]) List<int> answeredQuestionIds,
    @Default([]) List<Team> winners,
  }) = _QuizArenaGameState;
}
