import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/quiz_arena_settings.dart';
import '../../domain/models/quiz_arena_game_state.dart';
import '../../../../teams/domain/entities/team.dart';
import '../../../../questions/domain/entities/question.dart';
import '../../../../questions/presentation/providers/question_providers.dart';
import '../../../../teams/presentation/providers/team_providers.dart';

part 'quiz_arena_provider.g.dart';

@Riverpod(keepAlive: true)
class QuizArenaSettingsNotifier extends _$QuizArenaSettingsNotifier {
  static const _key = 'quiz_arena_settings';

  @override
  QuizArenaSettings build() {
    _loadSettings();
    return const QuizArenaSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        state = QuizArenaSettings.fromJson(Map<String, dynamic>.from(
          Uri.decodeComponent(jsonStr).split('&').fold({}, (p, e) {
            // This is a simple fallback if we don't use real JSON for some reason
            // But let's assume JSON is better.
            return {};
          }),
        ));
      } catch (_) {
        // Fallback to real JSON parsing
        try {
          final data = json.decode(jsonStr);
          state = QuizArenaSettings.fromJson(data);
        } catch (e) {
          print('Error loading Quiz Arena settings: $e');
        }
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(state.toJson()));
  }

  void updateSettings(QuizArenaSettings settings) {
    state = settings;
    _saveSettings();
  }

  void updateCategoryPoints(int categoryId, int points) {
    final updatedPoints = Map<int, int>.from(state.categoryPoints);
    updatedPoints[categoryId] = points;
    state = state.copyWith(categoryPoints: updatedPoints);
    _saveSettings();
  }

  void toggleCategory(int categoryId) {
    final updatedCategories = List<int>.from(state.categoryIds);
    if (updatedCategories.contains(categoryId)) {
      updatedCategories.remove(categoryId);
    } else {
      updatedCategories.add(categoryId);
    }
    state = state.copyWith(categoryIds: updatedCategories);
    _saveSettings();
  }

  void toggleTeamSelection(int teamId) {
    final updatedTeams = List<int>.from(state.selectedTeamIds);
    if (updatedTeams.contains(teamId)) {
      if (updatedTeams.length > 1) { // Reduced to 1 for flexibility during selection
        updatedTeams.remove(teamId);
      }
    } else {
      updatedTeams.add(teamId);
    }
    state = state.copyWith(selectedTeamIds: updatedTeams);
    _saveSettings();
  }

  void initializeSelections(List<int> allCatIds, List<int> allTeamIds) {
    if (state.categoryIds.isEmpty && state.selectedTeamIds.isEmpty) {
      state = state.copyWith(
        categoryIds: List.from(allCatIds),
        selectedTeamIds: List.from(allTeamIds),
      );
      _saveSettings();
    }
  }

  void selectAllCategories(List<int> allIds) {
    if (state.categoryIds.length == allIds.length) {
      state = state.copyWith(categoryIds: []);
    } else {
      state = state.copyWith(categoryIds: List.from(allIds));
    }
    _saveSettings();
  }
}

@Riverpod(keepAlive: true)
class QuizArenaGame extends _$QuizArenaGame {
  Timer? _timer;
  List<Question> _questionsPool = [];

  @override
  QuizArenaGameState build() {
    ref.onDispose(() => _timer?.cancel());
    return const QuizArenaGameState();
  }

  Future<void> startGame(QuizArenaSettings settings, List<Team> initialTeams) async {
    state = QuizArenaGameState(
      teams: initialTeams, // Use existing scores for game-wide sync
      remainingTime: settings.timeLimitSeconds,
      isTimerRunning: settings.timerEnabled,
      currentTeamIndex: 0,
      currentRound: 1,
      isLoading: true, // Initialized
    );

    _questionsPool = [];
    final repo = ref.read(questionRepositoryProvider);
    
    // Fetch questions from selected categories
    for (final categoryId in settings.categoryIds) {
      final questions = await repo.getQuestions(categoryId);
      _questionsPool.addAll(questions);
    }
    
    _questionsPool.shuffle();

    state = state.copyWith(isLoading: false); // Loading done

    _loadNextQuestion();
    if (settings.timerEnabled) _startTimer();
  }

  void _loadNextQuestion() {
    if (_questionsPool.isEmpty) {
      state = state.copyWith(isGameOver: true);
      _timer?.cancel();
      return;
    }

    final question = _questionsPool.removeAt(0);
    state = state.copyWith(
      currentQuestion: question,
      showAnswer: false,
      hasVerdict: false, // Reset
      remainingTime: ref.read(quizArenaSettingsProvider).timeLimitSeconds,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingTime > 0) {
        state = state.copyWith(remainingTime: state.remainingTime - 1);
      } else {
        _timer?.cancel();
        handleTimeOut();
      }
    });
  }

  void handleTimeOut() {
    state = state.copyWith(isTimerRunning: false, showAnswer: true, hasVerdict: false);
  }

  void showAnswer() {
    _timer?.cancel();
    state = state.copyWith(showAnswer: true, isTimerRunning: false);
  }

  void answerCorrectly() {
    _timer?.cancel();
    final settings = ref.read(quizArenaSettingsProvider);
    final currentQuestion = state.currentQuestion;
    
    if (currentQuestion == null) return;

    // Get points for the primary category of the question
    final categoryId = currentQuestion.categoryIds.isNotEmpty ? currentQuestion.categoryIds.first : -1;
    final points = settings.categoryPoints[categoryId] ?? 10;

    final updatedTeams = List<Team>.from(state.teams);
    final currentTeam = updatedTeams[state.currentTeamIndex];
    updatedTeams[state.currentTeamIndex] = currentTeam.copyWith(score: currentTeam.score + points);

    state = state.copyWith(teams: updatedTeams, hasVerdict: true); // Step 3 verdict reached
    
    // Proactively update scores in the database
    ref.read(teamsListProvider.notifier).updateScore(
          currentTeam.id!,
          points,
          gameName: 'Quiz Arena',
          question: currentQuestion.text,
          answer: currentQuestion.answer,
        );

    // Auto-advance if timer is disabled
    if (!settings.timerEnabled) {
      Future.delayed(const Duration(milliseconds: 300), () => nextTurn());
    }
  }

  void answerWrong() {
    _timer?.cancel();
    final settings = ref.read(quizArenaSettingsProvider);
    final negativePoints = settings.negativePoints;
    final currentQuestion = state.currentQuestion;

    final updatedTeams = List<Team>.from(state.teams);
    final currentTeam = updatedTeams[state.currentTeamIndex];
    updatedTeams[state.currentTeamIndex] = currentTeam.copyWith(score: currentTeam.score - negativePoints);

    state = state.copyWith(teams: updatedTeams, hasVerdict: true);
    
    if (negativePoints > 0) {
      ref.read(teamsListProvider.notifier).updateScore(
            currentTeam.id!,
            -negativePoints,
            gameName: 'Quiz Arena',
            question: currentQuestion?.text ?? '',
            reason: 'Wrong Answer',
          );
    }

    // Auto-advance if timer is disabled
    if (!settings.timerEnabled) {
      Future.delayed(const Duration(milliseconds: 300), () => nextTurn());
    }
  }

  void nextTurn() {
    final settings = ref.read(quizArenaSettingsProvider);
    int nextTeamIndex = state.currentTeamIndex + 1;
    int nextRound = state.currentRound;

    if (nextTeamIndex >= state.teams.length) {
      nextTeamIndex = 0;
      nextRound++;
    }

    if (nextRound > settings.rounds) {
      _finishGame();
      return;
    }

    state = state.copyWith(
      currentTeamIndex: nextTeamIndex,
      currentRound: nextRound,
    );

    _loadNextQuestion();
    if (settings.timerEnabled) _startTimer();
  }

  Future<void> syncLocalScoresWithGlobal(List<int> participatingIds) async {
    final teamsAsync = ref.read(teamsListProvider);
    final allTeams = teamsAsync.value ?? [];
    
    final updatedParticipating = allTeams.where((t) => participatingIds.contains(t.id)).toList();
    if (updatedParticipating.isNotEmpty) {
      state = state.copyWith(teams: updatedParticipating);
    }
  }

  void _finishGame() {
    _timer?.cancel();
    final winners = _calculateWinners();
    state = state.copyWith(isGameOver: true, winners: winners);
  }

  List<Team> _calculateWinners() {
    if (state.teams.isEmpty) return [];
    final maxScore = state.teams.map((t) => t.score).reduce((a, b) => a > b ? a : b);
    return state.teams.where((t) => t.score == maxScore).toList();
  }

  void restartGame() {
    final settings = ref.read(quizArenaSettingsProvider);
    startGame(settings, state.teams);
  }
}
