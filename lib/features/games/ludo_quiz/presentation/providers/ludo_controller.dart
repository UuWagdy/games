import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import '../../domain/entities/ludo_entities.dart';
import '../../domain/models/ludo_state.dart';

final ludoControllerProvider = NotifierProvider<LudoController, LudoState>(() {
  return LudoController();
});

class LudoController extends Notifier<LudoState> {
  final Random _random = Random();

  @override
  LudoState build() {
    return const LudoState(
      players: [],
      currentTurn: 0,
      activeColors: [LudoColor.red, LudoColor.green, LudoColor.yellow, LudoColor.blue],
    );
  }

  List<LudoPlayer> _createPlayers(List<LudoColor> colors) {
    return colors.map((LudoColor color) {
      int offset = 0;
      if (color == LudoColor.green) offset = 4;
      if (color == LudoColor.yellow) offset = 8;
      if (color == LudoColor.blue) offset = 12;
      return LudoPlayer(
        color: color,
        tokens: List<LudoToken>.generate(4, (int i) => LudoToken(id: i + offset, color: color, position: -1)),
      );
    }).toList();
  }

  void initGame(Map<LudoColor, String> selection, {bool isTeamMode = false, Map<LudoColor, int> playerTeams = const {}}) {
    if (selection.isEmpty) return;
    final List<LudoColor> selectedColors = selection.keys.toList();
    final List<LudoPlayer> activePlayers = _createPlayers(selectedColors);
    
    state = LudoState(
      players: activePlayers,
      currentTurn: 0,
      activeColors: selectedColors,
      colorTeamNames: selection,
      isTeamMode: isTeamMode,
      playerTeams: playerTeams,
      triggerCategories: state.triggerCategories,
      triggerEnabled: state.triggerEnabled,
      winPoints: state.winPoints,
      isVisionModeEnabled: state.isVisionModeEnabled,
      visionModeScope: state.visionModeScope,
    );
  }

  void rollDice() {
    if (state.phase != LudoGameState.idle) return;
    final int diceValue = _random.nextInt(6) + 1;
    state = state.copyWith(diceValue: diceValue, phase: LudoGameState.rolling);
    
    // Dice spins for 600ms
    Future.delayed(const Duration(milliseconds: 600), () {
      // Transition to 'result' phase so the dice stops spinning and shows the value
      state = state.copyWith(phase: LudoGameState.result);
      
      // Wait another 300ms for result viewing (snappy)
      Future.delayed(const Duration(milliseconds: 300), () {
        _handleDiceResult();
      });
    });
  }

  void _handleDiceResult() {
    if (state.players.isEmpty) return;
    final LudoPlayer currentPlayer = state.players[state.currentTurn];
    final List<LudoToken> selectable = <LudoToken>[];
    final bool isExitNumber = state.exitNumbers.contains(state.diceValue);

    for (final LudoToken t in currentPlayer.tokens) {
      if (t.position == -1 && isExitNumber) {
        selectable.add(t);
      } else if (t.position != -1 && t.position + state.diceValue <= 57) {
        selectable.add(t);
      }
    }

    if (selectable.isEmpty) {
      // If no moves, stay in result/idle for 400ms then next turn (No bonus if no move possible)
      state = state.copyWith(phase: LudoGameState.result);
      Future.delayed(const Duration(milliseconds: 400), () {
        _baseNextTurn();
      });
    } else {
      state = state.copyWith(
        selectableTokens: selectable,
        phase: LudoGameState.choosingToken,
      );
    }
  }

  void selectToken(LudoToken token) {
    if (state.phase != LudoGameState.choosingToken) return;
    
    if (token.position == -1) {
      _triggerQuestion(QuestionTriggerType.exit, token, () => _moveTokenToBaseStart(token));
    } else {
      _triggerQuestion(QuestionTriggerType.pass, token, () => _startMove(token, state.diceValue));
    }
  }

  void _triggerQuestion(QuestionTriggerType trigger, LudoToken token, VoidCallback onSkip) {
    final bool isEnabled = state.triggerEnabled[trigger] ?? true;
    if (isEnabled) {
      state = state.copyWith(
        movingToken: token,
        currentQuestionTrigger: trigger,
        phase: LudoGameState.answeringQuestion,
      );
    } else {
      state = state.copyWith(movingToken: token, currentQuestionTrigger: trigger);
      onSkip();
    }
  }

  void onQuestionAnsweredCorrectly() {
    if (state.movingToken == null) return;
    
    int points = 10;
    String reason = "إجابة صحيحة";
    
    final QuestionTriggerType? trigger = state.currentQuestionTrigger;
    if (trigger == QuestionTriggerType.exit) {
      points = 15;
      reason = "الخروج من القاعدة";
      _moveTokenToBaseStart(state.movingToken!);
    } else if (trigger == QuestionTriggerType.pass) {
      points = 10;
      reason = "العبور بنجاح";
      _startMove(state.movingToken!, state.diceValue);
    } else if (trigger == QuestionTriggerType.vision) {
      points = 50;
      reason = "استخدام الرؤية الثاقبة";
      _markVisionAsUsed(); // Mark player as used vision if scope is Player
      _moveTokenToHome(state.movingToken!);
    } else if (trigger == QuestionTriggerType.protect) {
      points = 20;
      reason = "تأمين الخانة";
      _protectToken(state.movingToken!);
    } else if (trigger == QuestionTriggerType.attack) {
      points = 30;
      reason = "طرد الخصم";
      _attackOpponent(state.movingToken!, state.targetedTokens ?? <LudoToken>[]);
    }
    
    _addPointsToCurrentTeam(points, reason: reason);
  }

  void _markVisionAsUsed() {
    if (state.visionModeScope == VisionModeScope.player) {
       final List<LudoPlayer> updatedPlayers = state.players.asMap().entries.map((entry) {
        if (entry.key == state.currentTurn) {
          return entry.value.copyWith(hasUsedVision: true);
        }
        return entry.value;
      }).toList();
      state = state.copyWith(players: updatedPlayers);
    }
  }

  void onQuestionAnsweredWrong() {
    _nextTurn();
  }

  void _moveTokenToBaseStart(LudoToken token) {
    _updateTokenPosition(token, 0);
    _nextTurn();
  }

  void _startMove(LudoToken token, int steps) {
    state = state.copyWith(remainingMoveSteps: steps, phase: LudoGameState.moving);
    _stepByStepMove();
  }

  void _stepByStepMove() async {
    while (state.remainingMoveSteps > 0) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (state.movingToken == null) return;
      final int nextPos = state.movingToken!.position + 1;
      _updateTokenPosition(state.movingToken!, nextPos);

      // Half distance is approx 26/27. Let's use 26 as the threshold.
      if (nextPos == 26 && !state.movingToken!.isVisionModeUnlocked) {
        _unlockVisionMode(state.movingToken!);
      }
      state = state.copyWith(remainingMoveSteps: state.remainingMoveSteps - 1);
    }
    _onMoveEnd();
  }

  void _updateTokenPosition(LudoToken token, int newPos) {
    final List<LudoPlayer> updatedPlayers = state.players.map((LudoPlayer p) {
      if (p.color == token.color) {
        return p.copyWith(
          tokens: p.tokens.map((LudoToken t) {
            if (t.id == token.id) {
              // Protection is lost when moving away from a safe area
              bool stillProtected = t.isProtected;
              if (stillProtected && !_isSafeCell(t.copyWith(position: newPos))) {
                stillProtected = false;
              }
              return t.copyWith(position: newPos, isProtected: stillProtected);
            }
            return t;
          }).toList(),
        );
      }
      return p;
    }).toList();

    state = state.copyWith(
      players: updatedPlayers,
      movingToken: updatedPlayers
          .firstWhere((LudoPlayer p) => p.color == token.color)
          .tokens
          .firstWhere((LudoToken t) => t.id == token.id),
    );
  }

  void _unlockVisionMode(LudoToken token) {
    final List<LudoPlayer> updatedPlayers = state.players.map((LudoPlayer p) {
      if (p.color == token.color) {
        return p.copyWith(
          tokens: p.tokens.map((LudoToken t) => t.id == token.id ? t.copyWith(isVisionModeUnlocked: true) : t).toList(),
        );
      }
      return p;
    }).toList();
    state = state.copyWith(players: updatedPlayers);
  }

  void _onMoveEnd() {
    if (state.movingToken == null) return;
    final LudoToken token = state.movingToken!;
    
    if (_isSafeCell(token)) {
      final bool isEnabled = state.triggerEnabled[QuestionTriggerType.protect] ?? true;
      if (isEnabled) {
        state = state.copyWith(currentQuestionTrigger: QuestionTriggerType.protect, phase: LudoGameState.answeringQuestion);
      } else {
        _protectToken(token);
      }
    } else {
      final List<LudoToken> opponents = _getOpponentsAt(token);
      if (opponents.isNotEmpty) {
        _triggerQuestion(QuestionTriggerType.attack, token, () => _attackOpponent(token, opponents));
        if (state.currentQuestionTrigger == QuestionTriggerType.attack) {
            state = state.copyWith(targetedTokens: opponents);
        }
      } else {
        _checkWinner();
      }
    }
  }

  bool _isSafeCell(LudoToken token) {
    if (token.position > 51) return true;
    // New safe indices relative to start position 0
    // 0 is the colored start square, 1 is the star square next to it
    // 13, 14 are the next colored start and star, etc.
    const List<int> safeIndices = [0, 1, 13, 14, 26, 27, 39, 40];
    return safeIndices.contains(token.position);
  }

  List<LudoToken> _getOpponentsAt(LudoToken token) {
    if (token.position > 51) return <LudoToken>[];
    final int globalPos = _getGlobalPosition(token);
    final List<LudoToken> results = <LudoToken>[];
    for (final LudoPlayer p in state.players) {
      if (p.color == token.color) continue;
      
      // Don't attack partner's tokens if team mode is enabled
      if (state.isTeamMode && state.playerTeams[p.color] == state.playerTeams[token.color]) continue;

      for (final LudoToken t in p.tokens) {
        if (t.position != -1 && t.position < 52 && _getGlobalPosition(t) == globalPos && !t.isProtected && !_isSafeCell(t)) {
          results.add(t);
        }
      }
    }
    return results;
  }

  int _getGlobalPosition(LudoToken t) {
    int startOffset = 1; // Red starts at index 1
    if (t.color == LudoColor.green) startOffset = 14;
    if (t.color == LudoColor.yellow) startOffset = 27;
    if (t.color == LudoColor.blue) startOffset = 40;
    return (t.position + startOffset) % 52;
  }

  void _protectToken(LudoToken token) {
    final List<LudoPlayer> updatedPlayers = state.players.map((LudoPlayer p) {
      if (p.color == token.color) {
        return p.copyWith(tokens: p.tokens.map((LudoToken t) => t.id == token.id ? t.copyWith(isProtected: true) : t).toList());
      }
      return p;
    }).toList();
    state = state.copyWith(players: updatedPlayers);
    _nextTurn();
  }

  void _attackOpponent(LudoToken token, List<LudoToken> targets) {
    final List<LudoPlayer> updatedPlayers = state.players.map((LudoPlayer p) {
      return p.copyWith(tokens: p.tokens.map((LudoToken t) {
        if (targets.any((LudoToken target) => target.id == t.id)) return t.copyWith(position: -1, isProtected: false);
        return t;
      }).toList());
    }).toList();
    state = state.copyWith(players: updatedPlayers);
    _nextTurn();
  }

  void _moveTokenToHome(LudoToken token) {
    _updateTokenPosition(token, 57);
    _checkWinner();
  }

  void _checkWinner() {
    if (state.players.isEmpty) return;
    
    if (state.isTeamMode) {
      // Team winning logic: All players in the team must finish
      final currentTeamId = state.playerTeams[state.currentPlayer.color];
      if (currentTeamId != null) {
        final teamPlayers = state.players.where((p) => state.playerTeams[p.color] == currentTeamId).toList();
        final allFinished = teamPlayers.every((p) => p.isWinner);
        
        if (allFinished) {
          state = state.copyWith(phase: LudoGameState.gameOver);
          _addPointsToCurrentTeam(state.winPoints, reason: 'فوز الفريق في لعبة لودو الأسئلة');
        } else {
          _nextTurn();
        }
      } else {
        _nextTurn();
      }
    } else {
      if (state.currentPlayer.isWinner) {
        state = state.copyWith(phase: LudoGameState.gameOver);
        _addPointsToCurrentTeam(state.winPoints, reason: 'الفوز في لعبة لودو الأسئلة');
      } else {
        _nextTurn();
      }
    }
  }

  void _addPointsToCurrentTeam(int points, {required String reason}) {
    try {
      final teamsAsync = ref.read(teamsListProvider);
      final teams = teamsAsync.value ?? [];
      
      if (state.isTeamMode && state.phase == LudoGameState.gameOver) {
        // If team mode and game over, give points to both partners
        final winnerColor = state.currentPlayer.color;
        final teamId = state.playerTeams[winnerColor];
        final partnerColor = state.playerTeams.entries
            .firstWhere((e) => e.value == teamId && e.key != winnerColor)
            .key;
            
        final teamNamesToReward = [
          state.colorTeamNames[winnerColor],
          state.colorTeamNames[partnerColor],
        ];
        
        for (var name in teamNamesToReward) {
          if (name != null) {
            final t = teams.firstWhere((team) => team.name == name);
            ref.read(teamsListProvider.notifier).updateScore(t.id!, points, gameName: 'لودو الأسئلة', reason: reason);
          }
        }
        return;
      }

      final player = state.players[state.currentTurn];
      final String? assignedTeamName = state.colorTeamNames[player.color];

      if (assignedTeamName != null) {
        final team = teams.firstWhere((t) => t.name == assignedTeamName);
        ref.read(teamsListProvider.notifier).updateScore(team.id!, points, gameName: 'لودو الأسئلة', reason: reason);
      } else if (teams.isNotEmpty) {
        final currentTeam = teams[state.currentTurn % teams.length];
        ref.read(teamsListProvider.notifier).updateScore(currentTeam.id!, points, gameName: 'لودو الأسئلة', reason: reason);
      }
    } catch (_) {}
  }

  void _nextTurn() {
    // Double move logic: If enabled, roll matches exit numbers, and not already used this turn
    final bool isExitRoll = state.exitNumbers.contains(state.diceValue);
    if (state.isDoubleMoveEnabled && !state.hasUsedDoubleMoveInTurn && isExitRoll && state.diceValue > 0) {
      // Grant bonus roll
      state = state.copyWith(
        phase: LudoGameState.idle,
        diceValue: 0,
        movingToken: null,
        selectableTokens: [],
        hasUsedDoubleMoveInTurn: true,
      );
      return;
    }
    
    _baseNextTurn();
  }

  void _baseNextTurn() {
    if (state.players.isEmpty) return;
    final int n = (state.currentTurn + 1) % state.players.length;
    state = state.copyWith(
      currentTurn: n,
      phase: LudoGameState.idle,
      diceValue: 0,
      movingToken: null,
      selectableTokens: <LudoToken>[],
      currentQuestionTrigger: null,
      targetedTokens: null,
      hasUsedDoubleMoveInTurn: false,
    );
  }

  void skipQuestion() {
    _nextTurn();
  }

  void activateVisionMode(LudoToken token) {
    if (!state.isVisionModeEnabled) return;
    
    // Check constraints
    final player = state.players[state.currentTurn];
    
    bool canUse = false;
    if (state.visionModeScope == VisionModeScope.token) {
      canUse = token.isVisionModeUnlocked;
    } else {
      // Per player: check if unlocked for this token AND player hasn't used it yet
      canUse = token.isVisionModeUnlocked && !player.hasUsedVision;
    }

    if (canUse) {
      _triggerQuestion(QuestionTriggerType.vision, token, () => onQuestionAnsweredCorrectly());
    }
  }

  void updateSettings({
    int? winPoints, 
    Map<QuestionTriggerType, List<int>>? triggerCategories,
    Map<QuestionTriggerType, bool>? triggerEnabled,
    bool? isVisionModeEnabled,
    VisionModeScope? visionModeScope,
    bool? isTeamMode,
    Map<LudoColor, int>? playerTeams,
    List<int>? exitNumbers,
    bool? isDoubleMoveEnabled,
  }) {
    state = state.copyWith(
      winPoints: winPoints ?? state.winPoints,
      triggerCategories: triggerCategories ?? state.triggerCategories,
      triggerEnabled: triggerEnabled ?? state.triggerEnabled,
      isVisionModeEnabled: isVisionModeEnabled ?? state.isVisionModeEnabled,
      visionModeScope: visionModeScope ?? state.visionModeScope,
      isTeamMode: isTeamMode ?? state.isTeamMode,
      playerTeams: playerTeams ?? this.state.playerTeams,
      exitNumbers: exitNumbers ?? state.exitNumbers,
      isDoubleMoveEnabled: isDoubleMoveEnabled ?? state.isDoubleMoveEnabled,
    );
  }
}
