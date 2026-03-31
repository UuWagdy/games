import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../questions/presentation/providers/question_providers.dart';
import '../../../../teams/presentation/providers/team_providers.dart';
import '../../../../teams/domain/entities/team.dart';
import 'package:games/features/games/under_pressure/domain/entities/under_pressure_state.dart';
import './under_pressure_settings_provider.dart';
import '../../../../questions/domain/entities/question.dart';

part 'under_pressure_provider.g.dart';

@Riverpod(keepAlive: true)
class UnderPressure extends _$UnderPressure {
  Timer? _timer;

  @override
  UnderPressureState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    final teamsAsync = ref.watch(teamsListProvider);
    final teams = teamsAsync.value ?? [];
    
    // Preserve existing state if we are already in a game
    if (stateOrNull != null) {
      return stateOrNull!.copyWith(teams: teams);
    }
    return UnderPressureState(teams: teams);
  }

  Future<void> generateTemplate(List<int>? categoryIds, String name) async {
    final settingsAsync = await ref.read(underPressureSettingsProvider.future);
    final countLimit = settingsAsync['question_count'] ?? 15;

    final repo = ref.read(questionRepositoryProvider);
    final allQuestions = await repo.getQuestions(null);
    
    var filtered = categoryIds == null || categoryIds.isEmpty 
      ? allQuestions 
      : allQuestions.where((q) => q.categoryIds.any((cid) => categoryIds.contains(cid))).toList();
    
    filtered.shuffle();
    if (filtered.length > countLimit) {
      filtered = filtered.sublist(0, countLimit);
    }
    
    state = state.copyWith(templateQuestions: filtered, templateName: name);
  }

  Future<void> startGame(Team t1, Team t2, List<int>? categoryIds) async {
    final settingsAsync = await ref.read(underPressureSettingsProvider.future);
    final timeLimit = settingsAsync['timer_duration'] ?? 60;

    if (state.templateQuestions == null || state.templateQuestions!.isEmpty) {
        await generateTemplate(categoryIds, 'قالب مقترح');
    }

    final questionsToPlay = List<Question>.from(state.templateQuestions!);
    final List<QuestionResult> initialResults = List.filled(questionsToPlay.length, QuestionResult.pending);

    state = state.copyWith(
      team1: t1,
      team2: t2,
      questions: questionsToPlay,
      currentQuestionIndex: 0,
      team1Score: 0,
      team2Score: 0,
      timeLeft: timeLimit,
      status: UnderPressureStatus.playing,
      isTeam2Turn: false,
      winnerTeamId: null,
      isTie: false,
      team1Results: List.from(initialResults), // Separate copy for Team 1
      team2Results: List.from(initialResults), // Separate copy for Team 2 (Fairness: same questions later)
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
    
    // FAIRNESS PRINCIPLE: Team 2 MUST face the exact same questions as Team 1
    // in the exact same order. We reset the index to 0 while keeping state.questions frozen.
    state = state.copyWith(
      isTeam2Turn: true,
      currentQuestionIndex: 0,
      timeLeft: timeLimit,
      status: UnderPressureStatus.paused,
    );
  }

  void startTeam1() {
    state = state.copyWith(status: UnderPressureStatus.playing);
    _startTimer();
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

    state = state.copyWith(
      status: UnderPressureStatus.finished,
      winnerTeamId: winnerId,
      isTie: isTie,
      team1PointsAdded: t1Final,
      team2PointsAdded: t2Final,
    );

    // Persist to DB
    if (state.team1?.id != null) {
      await ref.read(teamsListProvider.notifier).updateScore(state.team1!.id!, t1Final, reason: 'تحت الضغط');
    }
    if (state.team2?.id != null) {
      await ref.read(teamsListProvider.notifier).updateScore(state.team2!.id!, t2Final, reason: 'تحت الضغط');
    }
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
