import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bank_al_haz_entities.dart';
import '../../../../questions/domain/entities/question.dart';
import 'bank_al_haz_providers.dart';
import '../../../../questions/presentation/providers/question_providers.dart';

class GameState {
  final List<BankAlHazPlayer> players;
  final List<Station> board;
  final int currentPlayerIndex;
  final int currentDiceValue;
  final int rollCounter;
  final bool isRollingDice;
  final bool isMovingPlayer;
  final bool isGameOver;
  final String message;
  final Station? pendingLandingStation;
  final BankAlHazCard? currentCard;
  final DateTime? startTime;
  final int totalTurns;
  final bool isEndingTurn;

  const GameState({
    this.players = const [],
    this.board = const [],
    this.currentPlayerIndex = 0,
    this.currentDiceValue = 1,
    this.rollCounter = 0,
    this.isRollingDice = false,
    this.isMovingPlayer = false,
    this.isGameOver = false,
    this.message = "",
    this.pendingLandingStation,
    this.currentCard,
    this.startTime,
    this.totalTurns = 0,
    this.isEndingTurn = false,
  });

  GameState copyWith({
    List<BankAlHazPlayer>? players,
    List<Station>? board,
    int? currentPlayerIndex,
    int? currentDiceValue,
    int? rollCounter,
    bool? isRollingDice,
    bool? isMovingPlayer,
    bool? isGameOver,
    String? message,
    Station? pendingLandingStation,
    BankAlHazCard? currentCard,
    DateTime? startTime,
    int? totalTurns,
    bool? isEndingTurn,
  }) {
    return GameState(
      players: players ?? this.players,
      board: board ?? this.board,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      currentDiceValue: currentDiceValue ?? this.currentDiceValue,
      rollCounter: rollCounter ?? this.rollCounter,
      isRollingDice: isRollingDice ?? this.isRollingDice,
      isMovingPlayer: isMovingPlayer ?? this.isMovingPlayer,
      isGameOver: isGameOver ?? this.isGameOver,
      message: message ?? this.message,
      pendingLandingStation: pendingLandingStation, 
      currentCard: currentCard ?? this.currentCard,
      startTime: startTime ?? this.startTime,
      totalTurns: totalTurns ?? this.totalTurns,
      isEndingTurn: isEndingTurn ?? this.isEndingTurn,
    );
  }
}

class GameEngine extends Notifier<GameState> {
  final _random = math.Random();
  // Track auto-next-turn timer to prevent double-calling
  Timer? _autoNextTurnTimer;

  @override
  GameState build() {
    return const GameState();
  }

  Future<void> initGame(List<String> playerNames, BankAlHazSettings settings) async {
    _autoNextTurnTimer?.cancel();
    final bankRepo = ref.read(bankAlHazRepositoryProvider);
    final stations = await bankRepo.getStations();
    
    final players = playerNames.asMap().entries.map((entry) => BankAlHazPlayer(
      id: entry.key + 1,
      name: entry.value,
      money: settings.initialMoney,
    )).toList();

    state = state.copyWith(
      players: players,
      board: stations,
      currentPlayerIndex: 0,
      isGameOver: false,
      message: "بدأت اللعبة! دور ${players[0].name}",
      pendingLandingStation: null,
      startTime: DateTime.now(),
      totalTurns: 0,
      isEndingTurn: false,
    );
  }

  void syncPlayers(List<String> currentNames) {
    if (state.players.isEmpty) return;
    
    final existingPlayerNames = state.players.map((p) => p.name).toSet();
    final newPlayersToAdd = <BankAlHazPlayer>[];
    
    // Initial money from first player as fallback
    double initialMoney = state.players.isNotEmpty ? state.players[0].money : 1000;
    
    int maxId = 0;
    for (var p in state.players) {
       if (p.id > maxId) maxId = p.id;
    }
    
    for (var name in currentNames) {
      if (!existingPlayerNames.contains(name)) {
        maxId++;
        newPlayersToAdd.add(BankAlHazPlayer(
          id: maxId,
          name: name,
          money: initialMoney,
          currentPosition: 0,
        ));
      }
    }
    
    if (newPlayersToAdd.isNotEmpty) {
      state = state.copyWith(players: [...state.players, ...newPlayersToAdd]);
    }
  }


  Future<void> rollDice() async {
    if (state.isGameOver || state.isMovingPlayer || state.isRollingDice || state.pendingLandingStation != null || state.isEndingTurn) return;

    _autoNextTurnTimer?.cancel();

    // 1. Generate the final dice result once
    final int diceResult = _random.nextInt(6) + 1;
    final multiplier = state.players[state.currentPlayerIndex].nextDiceMultiplier;
    final int totalSteps = (diceResult * multiplier).toInt();

    // 2. Trigger the dice animation — show spinning message, NOT the result yet
    state = state.copyWith(
      isRollingDice: true, 
      currentDiceValue: diceResult, 
      rollCounter: state.rollCounter + 1,
      message: "يرمي النرد...",
    );
    
    // 3. Wait for the dice animation to complete
    await Future.delayed(const Duration(milliseconds: 1600));

    // 4. NOW show the result after animation finishes
    state = state.copyWith(
      isRollingDice: false, 
      message: "لف النرد: $diceResult — تحرك $totalSteps خانات",
    );
    
    // Clear multiplier for next turn
    if (multiplier != 1.0) {
      final updatedPlayers = [...state.players];
      updatedPlayers[state.currentPlayerIndex] = updatedPlayers[state.currentPlayerIndex].copyWith(nextDiceMultiplier: 1.0);
      state = state.copyWith(players: updatedPlayers);
    }

    await _movePlayerSequentially(totalSteps);
  }

  Future<void> _movePlayerSequentially(int steps) async {
    if (state.board.isEmpty) return;
    state = state.copyWith(isMovingPlayer: true);
    
    for (int i = 0; i < steps; i++) {
      final currentPos = state.players[state.currentPlayerIndex].currentPosition;
      int nextPos = (currentPos + 1) % state.board.length;
      
      final updatedPlayers = [for (var p in state.players) p];
      
      // BUG FIX: ALWAYS update currentPosition regardless of lap bonus
      if (nextPos == 0 && currentPos != 0) {
        // Passing Start: give bonus + update position + increment laps
        updatedPlayers[state.currentPlayerIndex] = updatedPlayers[state.currentPlayerIndex].copyWith(
          currentPosition: nextPos, // ← THIS WAS MISSING! caused infinite loop
          money: updatedPlayers[state.currentPlayerIndex].money + 500,
          lapsCompleted: updatedPlayers[state.currentPlayerIndex].lapsCompleted + 1,
        );
        state = state.copyWith(
          players: updatedPlayers, 
          totalTurns: state.totalTurns + 1,
          message: "مررت بـ البداية! دورة جديدة +500 بركة",
        );
      } else {
        // Normal move
        updatedPlayers[state.currentPlayerIndex] = updatedPlayers[state.currentPlayerIndex].copyWith(
          currentPosition: nextPos,
        );
        state = state.copyWith(players: updatedPlayers);
      }
      
      await Future.delayed(const Duration(milliseconds: 350));
    }
    
    state = state.copyWith(isMovingPlayer: false);
    _handleLanding(state.players[state.currentPlayerIndex].currentPosition);
  }

  void _handleLanding(int position) {
    if (position >= state.board.length) return;
    final station = state.board[position];
    state = state.copyWith(pendingLandingStation: station, message: "وصلت إلى ${station.name}");
    
    // Auto-resolve non-action stations like "Start" or empty paths
    if (station.type == StationType.none) {
       resolveLanding();
    }
  }

  Future<Question?> getRandomQuestion(int? categoryId) async {
    if (categoryId == null) return null;
    try {
      // MUST use the repository directly and await the result.
      final repo = ref.read(questionRepositoryProvider);
      final questions = await repo.getQuestions(categoryId);
      if (questions.isEmpty) return null;
      return questions[_random.nextInt(questions.length)];
    } catch (e) {
      print("Error getting question for category $categoryId: $e");
      return null;
    }
  }

  Future<BankAlHazCard?> drawCard(String? type) async {
    try {
      final allCards = await ref.read(bankAlHazRepositoryProvider).getCards();
      final filterType = type?.toLowerCase();
      final cards = allCards.where((c) => c.type?.toLowerCase() == filterType).toList();
      if (cards.isEmpty) return null;
      return cards[_random.nextInt(cards.length)];
    } catch (e) {
      return null;
    }
  }

  void applyCardEffect(BankAlHazCard card) {
    final currentPlayer = state.players[state.currentPlayerIndex];
    BankAlHazPlayer updatedPlayer = currentPlayer;
    String effectMsg = "";

    switch (card.effectType) {
      case CardEffectType.addMoney:
        updatedPlayer = currentPlayer.copyWith(money: currentPlayer.money + card.effectValue);
        effectMsg = "حصلت على ${card.effectValue}";
        break;
      case CardEffectType.removeMoney:
        updatedPlayer = currentPlayer.copyWith(money: currentPlayer.money - card.effectValue);
        effectMsg = "خسرت ${card.effectValue}";
        break;
      case CardEffectType.skipTurn:
        updatedPlayer = currentPlayer.copyWith(skipNextTurn: true);
        effectMsg = "ستفقد دورك القادم";
        break;
      case CardEffectType.diceMultiplier:
        updatedPlayer = currentPlayer.copyWith(nextDiceMultiplier: card.effectValue.toDouble());
        effectMsg = "مضاعف النرد القادم: ${card.effectValue}";
        break;
      case CardEffectType.moveSteps:
        effectMsg = "تحرك ${card.effectValue} خطوات";
        // Update message first, then move. Return early to avoid state overwrite.
        state = state.copyWith(
          pendingLandingStation: null,
          message: "كارت ${card.title}: $effectMsg",
        );
        _movePlayerSequentially(card.effectValue);
        return; // ← CRITICAL: Don't let code below overwrite player position
      case CardEffectType.moveToStation:
        final targetName = card.targetStationName?.trim() ?? "";
        
        // Find by name - being a bit more flexible with whitespace
        int targetIdx = state.board.indexWhere((s) => s.name.trim() == targetName);
        
        // If not found, try a more aggressive match (contains or similar)
        if (targetIdx == -1 && targetName.isNotEmpty) {
           targetIdx = state.board.indexWhere((s) => s.name.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('ة', 'ه').contains(targetName.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('ة', 'ه')));
        }
        
        if (targetIdx != -1) {
           final finalTarget = state.board[targetIdx];
           int currentPos = state.players[state.currentPlayerIndex].currentPosition;
           int steps = (targetIdx - currentPos + state.board.length) % state.board.length;
           
           // Clear current landing state and update message
           state = state.copyWith(
             pendingLandingStation: null, 
             message: "كارت ${card.title}: توجه إلى ${finalTarget.name}...",
           );
           
           if (steps == 0) {
             _handleLanding(targetIdx);
           } else {
             _movePlayerSequentially(steps);
           }
        } else {
           state = state.copyWith(
             pendingLandingStation: null,
             message: "كارت ${card.title}: لم نجد وجهة '$targetName'!",
           );
           _scheduleAutoNextTurn();
        }
        return; // ← CRITICAL: Don't let code below overwrite player position
    }

    // Only non-movement effects reach here (addMoney, removeMoney, skipTurn, diceMultiplier)
    final updatedPlayers = [for (var p in state.players) p];
    updatedPlayers[state.currentPlayerIndex] = updatedPlayer.copyWith(nextDiceMultiplier: updatedPlayer.nextDiceMultiplier);

    state = state.copyWith(
      players: updatedPlayers,
      pendingLandingStation: null,
      message: "كارت ${card.title}: $effectMsg",
      isEndingTurn: true,
    );

    _scheduleAutoNextTurn();
  }

  /// Cancels any pending auto-turn and advances immediately
  void forceNextTurn() {
    _autoNextTurnTimer?.cancel();
    nextTurn();
  }

  void resolveLanding({bool bought = false, bool correctlyAnsweredPasser = false, bool tookPasserQuestion = false}) {
    try {
      if (state.pendingLandingStation == null) return;
      final station = state.pendingLandingStation!;
      int pIdx = state.currentPlayerIndex;
      final currentPlayer = state.players[pIdx];
      
      int? ownerIdx;
      for (int i = 0; i < state.players.length; i++) {
        if (state.players[i].ownedStationIds.contains(station.id)) {
          ownerIdx = i;
          break;
        }
      }

      final updatedPlayers = [for (var p in state.players) p];
      String resultMsg = "";

      // Logic for Unbuyable Station (NPC/Character)
      if (station.isUnbuyable) {
        if (tookPasserQuestion && correctlyAnsweredPasser) {
          updatedPlayers[pIdx] = currentPlayer.copyWith(money: currentPlayer.money + station.buyPrice);
          resultMsg = "تحديت ${station.name} بنجاح! ربحت ${station.buyPrice}";
        } else if (tookPasserQuestion && !correctlyAnsweredPasser) {
          updatedPlayers[pIdx] = currentPlayer.copyWith(money: currentPlayer.money - station.baseRent);
          resultMsg = "خسرت التحدي مع ${station.name}! دفعت غرامة ${station.baseRent}";
        } else {
          resultMsg = "مررت بـ ${station.name} بسلام";
        }
      } else if (bought && station.id != null) {
          updatedPlayers[pIdx] = currentPlayer.copyWith(
            money: currentPlayer.money - station.buyPrice,
            ownedStationIds: [...currentPlayer.ownedStationIds, station.id!],
          );
          resultMsg = "مبروك! اشتريت ${station.name}";
      } else if (ownerIdx != null && ownerIdx != pIdx) {
         double rent = station.baseRent;
         if (tookPasserQuestion && correctlyAnsweredPasser) {
            rent = rent / 2;
            resultMsg = "إجابة صحيحة! دفعت نصف الإيجار ($rent)";
         } else if (tookPasserQuestion && !correctlyAnsweredPasser) {
            resultMsg = "إجابة خاطئة! دفعت الإيجار كاملاً ($rent)";
         } else {
            resultMsg = "دفعت إيجار بقيمة ($rent)";
         }

         updatedPlayers[pIdx] = updatedPlayers[pIdx].copyWith(money: updatedPlayers[pIdx].money - rent);
         updatedPlayers[ownerIdx] = updatedPlayers[ownerIdx].copyWith(money: updatedPlayers[ownerIdx].money + rent);
      } else if (ownerIdx == pIdx) {
         resultMsg = "أنت في مدينتك ${station.name}";
      } else {
         resultMsg = station.type == StationType.none ? "" : "تم المرور بـ ${station.name}";
      }

      state = state.copyWith(
        players: updatedPlayers,
        pendingLandingStation: null,
        message: resultMsg,
        isEndingTurn: true, // IMPORTANT: Lock buttons until actual nextTurn()
      );

      // Schedule auto-next-turn (cancels any existing timer first)
      _scheduleAutoNextTurn();
    } catch (e) {
      print("Error in resolveLanding: $e");
      state = state.copyWith(pendingLandingStation: null, message: "انتهى الموقف");
      _scheduleAutoNextTurn();
    }
  }

  /// Centralized auto-next-turn with timer management.
  /// Only ONE timer can be active at a time — prevents double nextTurn() calls.
  void _scheduleAutoNextTurn() {
    _autoNextTurnTimer?.cancel();
    _autoNextTurnTimer = Timer(const Duration(milliseconds: 800), () => nextTurn());
  }

  void nextTurn() {
    // Cancel any pending auto-advance timer (user clicked "إنها" manually)
    _autoNextTurnTimer?.cancel();

    if (state.isGameOver || state.isMovingPlayer || state.isRollingDice || state.pendingLandingStation != null) {
       // Reset ending flag if blocked
       state = state.copyWith(isEndingTurn: false);
       return;
    }

    int nextIndex = (state.currentPlayerIndex + 1) % state.players.length;
    final nextPlayer = state.players[nextIndex];

    if (nextPlayer.skipNextTurn) {
       final updatedNextPlayer = nextPlayer.copyWith(skipNextTurn: false);
       final updatedPlayers = [for (var p in state.players) p];
       updatedPlayers[nextIndex] = updatedNextPlayer;
       state = state.copyWith(players: updatedPlayers, currentPlayerIndex: nextIndex, message: "تخطى ${nextPlayer.name} دوره", isEndingTurn: true);
       // Deferred — NOT synchronous recursive call
       _autoNextTurnTimer?.cancel();
       _autoNextTurnTimer = Timer(const Duration(milliseconds: 500), () => nextTurn());
       return;
    }

    state = state.copyWith(
      currentPlayerIndex: nextIndex,
      currentDiceValue: 0, // Reset dice to 0 so next player knows they haven't rolled yet
      message: "دور ${state.players[nextIndex].name}",
      isEndingTurn: false, // Unlock for the new player
    );
  }
}

final gameEngineProvider = NotifierProvider<GameEngine, GameState>(GameEngine.new);
