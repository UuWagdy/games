import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:games/features/games/snakes_and_ladders/domain/entities/snakes_ladders_entities.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';

part 'snakes_ladders_providers.g.dart';

@Riverpod(keepAlive: true)
class SnakesLaddersGame extends _$SnakesLaddersGame {
  static const _key = 'snakes_ladders_state';

  @override
  SnakesLaddersState build() {
    _loadState();
    // Default for 100 board is 8/8, but we will adjust in initializeGame or reset.
    return _generateInitialState(100, 8, 8);
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        state = SnakesLaddersState.fromJson(json.decode(jsonStr));
      } catch (e) {
        print('Error loading Snakes & Ladders state: $e');
      }
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(state.toJson()));
  }

  SnakesLaddersState _generateInitialState(int size, int snakeCount, int ladderCount) {
    final elements = _generateElements(size, snakeCount, ladderCount);
    return SnakesLaddersState(
      boardSize: size,
      elements: elements,
      playerPositions: {},
      currentPlayerIndex: 0,
      status: SnakesLaddersStatus.playing,
      winPoints: 25,
      wrongAnswerPenalty: WrongAnswerPenalty.skip,
      snakesCount: snakeCount,
      laddersCount: ladderCount,
    );
  }

  List<BoardElement> _generateElements(int size, int snakeCount, int ladderCount) {
    final List<BoardElement> elements = [];
    final Random random = Random();
    final usedCells = <int>{1, size};
    
    int columnsCount;
    if (size == 50) {
      columnsCount = 5;
    } else if (size == 64) {
      columnsCount = 8;
    } else if (size == 100) {
      columnsCount = 10;
    } else {
      columnsCount = sqrt(size).ceil();
    }
    
    final int sideSize = columnsCount;

    // Ladders
    int currentLadders = 0;
    int attempts = 0;
    while (currentLadders < ladderCount && attempts < 500) {
      attempts++;
      // Ladders start in bottom half mostly, end in top half
      int start = random.nextInt(size - (sideSize * 2)) + 2;
      int end = random.nextInt(size - start - sideSize) + start + sideSize;
      
      int startRow = (start - 1) ~/ sideSize;
      int endRow = (end - 1) ~/ sideSize;

      if (startRow == endRow) continue; // Must span at least one row
      if ((endRow - startRow).abs() < 2 && size >= 100) continue; // Long boards need longer ladders

      bool overlap = elements.any((e) => 
        e.start == start || e.end == end || 
        e.start == end || e.end == start ||
        (e.start - start).abs() < 2 || (e.end - end).abs() < 2
      );
      
      if (!overlap && !usedCells.contains(start) && !usedCells.contains(end)) {
        elements.add(BoardElement(start: start, end: end, isLadder: true));
        usedCells.add(start);
        usedCells.add(end);
        currentLadders++;
      }
    }

    // Snakes
    int currentSnakes = 0;
    attempts = 0;
    while (currentSnakes < snakeCount && attempts < 500) {
      attempts++;
      int start = random.nextInt(size - sideSize - 5) + sideSize + 5;
      int end = random.nextInt(start - sideSize) + 2;
      
      int startRow = (start - 1) ~/ sideSize;
      int endRow = (end - 1) ~/ sideSize;

      if (startRow == endRow) continue; // Must span at least one row

      bool overlap = elements.any((e) => 
        e.start == start || e.end == end || 
        e.start == end || e.end == start ||
        (e.start - start).abs() < 2 || (e.end - end).abs() < 2
      );

      if (!overlap && !usedCells.contains(start) && !usedCells.contains(end)) {
        elements.add(BoardElement(start: start, end: end, isLadder: false));
        usedCells.add(start);
        usedCells.add(end);
        currentSnakes++;
      }
    }
    return elements;
  }

  void initializeGame(int size, bool questionsEnabled, List<int> categoryIds, 
      {int winPoints = 25, 
       WrongAnswerPenalty penalty = WrongAnswerPenalty.skip,
       int? snakesCount,
       int? laddersCount}) {
    final teamsAsync = ref.read(teamsListProvider);
    final teams = teamsAsync.value ?? [];

    final Map<int, int> positions = {};
    for (var team in teams) {
      positions[team.id!] = 1;
    }
    
    int actualSnakes = snakesCount ?? (size <= 64 ? 5 : 8);
    int actualLadders = laddersCount ?? (size <= 64 ? 5 : 8);

    state = _generateInitialState(size, actualSnakes, actualLadders).copyWith(
      playerPositions: positions,
      questionsEnabled: questionsEnabled,
      categoryIds: categoryIds,
      winPoints: winPoints,
      wrongAnswerPenalty: penalty,
    );
    _saveState();
  }

  void setDiceValue(int val) {
    state = state.copyWith(lastDiceValue: val);
    _saveState();
  }

  Future<void> moveCurrentPlayer(int steps) async {
    final teamsAsync = ref.read(teamsListProvider);
    final teams = teamsAsync.value ?? [];
    if (teams.isEmpty) return;
    
    final currentTeam = teams[state.currentPlayerIndex % teams.length];
    int currentPos = state.playerPositions[currentTeam.id!] ?? 1;

    // 1. Move step by step
    for (int i = 0; i < steps; i++) {
      if (currentPos >= state.boardSize) break;
      
      currentPos++;
      final updatedPositions = Map<int, int>.from(state.playerPositions);
      updatedPositions[currentTeam.id!] = currentPos;
      state = state.copyWith(playerPositions: updatedPositions);
      _saveState();
      
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    // 2. Check for snake or ladder
    final element = state.elements.where((e) => e.start == currentPos).firstOrNull;
    if (element != null) {
      await Future.delayed(const Duration(milliseconds: 500)); // Pause to let user see landing
      
      final jumpedPositions = Map<int, int>.from(state.playerPositions);
      jumpedPositions[currentTeam.id!] = element.end;
      state = state.copyWith(playerPositions: jumpedPositions);
      _saveState();
    }

    // 3. Finalize turn or game
    if (state.playerPositions[currentTeam.id!] == state.boardSize) {
      state = state.copyWith(status: SnakesLaddersStatus.finished);
      _saveState();
      // Update points for winner
      ref.read(teamsListProvider.notifier).updateScore(
         currentTeam.id!,
         state.winPoints,
         gameName: 'السلم والثعبان',
         reason: 'الفوز في لعبة السلم والثعبان',
      );
    } else {
      state = state.copyWith(currentPlayerIndex: (state.currentPlayerIndex + 1) % teams.length);
      _saveState();
    }
  }

  void skipTurn() {
    final teamsAsync = ref.read(teamsListProvider);
    final teams = teamsAsync.value ?? [];
    if (teams.isEmpty) return;
    state = state.copyWith(currentPlayerIndex: (state.currentPlayerIndex + 1) % teams.length);
    _saveState();
  }

  void resetPositions() {
    final newPositions = Map<int, int>.from(state.playerPositions);
    newPositions.updateAll((key, value) => 1);
    state = state.copyWith(
      playerPositions: newPositions,
      currentPlayerIndex: 0,
      status: SnakesLaddersStatus.playing,
      lastDiceValue: null,
    );
    _saveState();
  }

  void setWinPoints(int val) {
    state = state.copyWith(winPoints: val);
    _saveState();
  }

  void setQuestionsEnabled(bool val) {
    state = state.copyWith(questionsEnabled: val);
    _saveState();
  }

  void setBoardSize(int size) {
    if (state.boardSize == size) return;
    initializeGame(size, state.questionsEnabled, state.categoryIds, 
      winPoints: state.winPoints, 
      penalty: state.wrongAnswerPenalty,
      snakesCount: state.snakesCount,
      laddersCount: state.laddersCount
    );
  }

  void setSnakesLaddersCount(int snacks, int ladders) {
    initializeGame(state.boardSize, state.questionsEnabled, state.categoryIds, 
      winPoints: state.winPoints, 
      penalty: state.wrongAnswerPenalty,
      snakesCount: snacks,
      laddersCount: ladders
    );
  }
}
