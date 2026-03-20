import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../questions/presentation/providers/question_providers.dart';
import '../../../../teams/presentation/providers/team_providers.dart';
import '../../../../teams/domain/entities/team.dart';
import 'package:games/features/games/under_pressure/domain/entities/under_pressure_state.dart';
import './under_pressure_settings_provider.dart';
import '../../../../questions/domain/repositories/question_repository.dart';
import '../../../../questions/presentation/providers/question_providers.dart';

part 'under_pressure_provider.g.dart';

@riverpod
class UnderPressure extends _$UnderPressure {
  Timer? _timer;

  @override
  UnderPressureState build() {
    final teamsAsync = ref.watch(teamsListProvider);
    final teams = teamsAsync.value ?? [];
    return UnderPressureState(teams: teams);
  }

  Future<void> startGame(Team t1, Team t2, List<int>? categoryIds) async {
    final settingsAsync = await ref.read(underPressureSettingsProvider.future);
    final countLimit = settingsAsync['question_count'] ?? 15;
    final timeLimit = settingsAsync['timer_duration'] ?? 60;

    final repo = ref.read(questionRepositoryProvider);
    final allQuestions = await repo.getQuestions(null);
    
    var filtered = categoryIds == null || categoryIds.isEmpty 
      ? allQuestions 
      : allQuestions.where((q) => q.categoryIds.any((cid) => categoryIds.contains(cid))).toList();
    
    filtered.shuffle();
    if (filtered.length > countLimit) {
      filtered = filtered.sublist(0, countLimit);
    }

    final teamResults = List.filled(filtered.length, QuestionResult.pending);

    state = state.copyWith(
      team1: t1,
      team2: t2,
      questions: filtered,
      currentQuestionIndex: 0,
      team1Score: 0,
      team2Score: 0,
      timeLeft: timeLimit,
      status: UnderPressureStatus.playing,
      isTeam2Turn: false,
      winnerTeamId: null,
      isTie: false,
      team1Results: teamResults,
      team2Results: teamResults,
      categoryIds: categoryIds,
      team1PointsAdded: 0,
      team2PointsAdded: 0,
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft > 0) {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      } else {
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    _timer?.cancel();
    if (!state.isTeam2Turn) {
      // Team 1 finished, switch to Team 2
      _prepareTeam2Turn();
    } else {
      // Both finished
      _finalizeGame();
    }
  }

  void _prepareTeam2Turn() async {
    final settingsAsync = await ref.read(underPressureSettingsProvider.future);
    final timeLimit = settingsAsync['timer_duration'] ?? 60;
    
    // We shuffle questions again or just reset index? 
    // Usually Team 2 should get different questions or same count but different set.
    // Let's just reset index for now or fetch new batch.
    // User said "Team 1 finishes, Team 2 enters".
    state = state.copyWith(
      isTeam2Turn: true,
      currentQuestionIndex: 0,
      timeLeft: timeLimit,
      status: UnderPressureStatus.paused, // Wait for manual start? 
    );
  }

  void startTeam2() {
    state = state.copyWith(status: UnderPressureStatus.playing);
    _startTimer();
  }

  Future<void> _finalizeGame() async {
    final settingsAsync = await ref.read(underPressureSettingsProvider.future);
    final int pointsPerQ = (settingsAsync['points_per_question'] ?? 1).toInt();
    final int bonus = (settingsAsync['bonus_points'] ?? 10).toInt();

    int t1Final = state.team1Score * pointsPerQ;
    int t2Final = state.team2Score * pointsPerQ;

    int? winnerId;
    bool isTie = false;

    if (t1Final > t2Final) {
      winnerId = state.team1?.id;
      t1Final += bonus;
    } else if (t2Final > t1Final) {
      winnerId = state.team2?.id;
      t2Final += bonus;
    } else {
      isTie = true;
      t1Final += bonus;
      t2Final += bonus;
    }

    // Persist to DB
    if (state.team1?.id != null) {
      await ref.read(teamsListProvider.notifier).updateScore(state.team1!.id!, t1Final, reason: 'تحت الضغط');
    }
    if (state.team2?.id != null) {
      await ref.read(teamsListProvider.notifier).updateScore(state.team2!.id!, t2Final, reason: 'تحت الضغط');
    }

    state = state.copyWith(
      status: UnderPressureStatus.finished,
      winnerTeamId: winnerId,
      isTie: isTie,
      team1PointsAdded: t1Final,
      team2PointsAdded: t2Final,
    );
  }

  void nextQuestion(bool correct) {
    if (state.status != UnderPressureStatus.playing) return;

    if (!state.isTeam2Turn) {
      final newResults = [...state.team1Results];
      newResults[state.currentQuestionIndex] = correct ? QuestionResult.correct : QuestionResult.wrong;
      
      state = state.copyWith(
        team1Score: state.team1Score + (correct ? 1 : 0),
        team1Results: newResults,
      );
    } else {
      final newResults = [...state.team2Results];
      newResults[state.currentQuestionIndex] = correct ? QuestionResult.correct : QuestionResult.wrong;

      state = state.copyWith(
        team2Score: state.team2Score + (correct ? 1 : 0),
        team2Results: newResults,
      );
    }

    state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);

    if (state.currentQuestionIndex >= state.questions.length) {
      _handleTimeUp();
    }
  }

  void skipQuestion() {
    if (state.status != UnderPressureStatus.playing) return;

    if (!state.isTeam2Turn) {
      final newResults = [...state.team1Results];
      newResults[state.currentQuestionIndex] = QuestionResult.skipped;
      state = state.copyWith(team1Results: newResults);
    } else {
      final newResults = [...state.team2Results];
      newResults[state.currentQuestionIndex] = QuestionResult.skipped;
      state = state.copyWith(team2Results: newResults);
    }

    state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
    if (state.currentQuestionIndex >= state.questions.length) {
      _handleTimeUp();
    }
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(
      status: UnderPressureStatus.idle,
      team1: null,
      team2: null,
      team1Score: 0,
      team2Score: 0,
      timeLeft: 60,
      currentQuestionIndex: 0,
      isTeam2Turn: false,
      team1Results: [],
      team2Results: [],
      team1PointsAdded: 0,
      team2PointsAdded: 0,
    );
  }

  void restartGame() {
    if (state.team1 != null && state.team2 != null) {
      startGame(state.team1!, state.team2!, state.categoryIds);
    }
  }
}
