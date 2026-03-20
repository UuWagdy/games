import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bank_al_haz_entities.dart';
import '../../../../questions/domain/entities/question.dart';
import '../../../../questions/presentation/providers/question_providers.dart';
import '../../../../settings/presentation/providers/settings_providers.dart';
import '../../../../teams/presentation/providers/team_providers.dart';
import 'bank_al_haz_providers.dart';


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
  final BankAlHazSettings settings;
  final int remainingSeconds;
  final List<GameLog> logs;
  final int? winnerIndex;

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
    this.settings = const BankAlHazSettings(),
    this.remainingSeconds = 0,
    this.logs = const [],
    this.winnerIndex,
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
    BankAlHazSettings? settings,
    int? remainingSeconds,
    List<GameLog>? logs,
    int? winnerIndex,
    bool clearPendingLandingStation = false,
    bool clearWinnerIndex = false,
    bool clearCurrentCard = false,
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
      pendingLandingStation: clearPendingLandingStation ? null : (pendingLandingStation ?? this.pendingLandingStation), 
      currentCard: clearCurrentCard ? null : (currentCard ?? this.currentCard),
      startTime: startTime ?? this.startTime,
      totalTurns: totalTurns ?? this.totalTurns,
      isEndingTurn: isEndingTurn ?? this.isEndingTurn,
      settings: settings ?? this.settings,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      logs: logs ?? this.logs,
      winnerIndex: clearWinnerIndex ? null : (winnerIndex ?? this.winnerIndex),
    );
  }
}

class GameEngine extends Notifier<GameState> {
  final _random = math.Random();
  // Track auto-next-turn timer to prevent double-calling
  Timer? _autoNextTurnTimer;
  Timer? _gameDurationTimer;

  @override
  GameState build() {
    return const GameState();
  }

  Future<void> initGame(List<String> playerNames, BankAlHazSettings settings) async {
    _autoNextTurnTimer?.cancel();
    _gameDurationTimer?.cancel();
    
    final bankRepo = ref.read(bankAlHazRepositoryProvider);
    final stations = await bankRepo.getStations();

    int? initialSeconds;
    if (settings.winCondition == WinningCondition.time && settings.maxTimeMinutes > 0) {
      initialSeconds = settings.maxTimeMinutes * 60;
    }
    
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
      clearPendingLandingStation: true,
      startTime: DateTime.now(),
      totalTurns: 0,
      isEndingTurn: false,
      settings: settings,
      remainingSeconds: initialSeconds,
      logs: [
        GameLog(
          timestamp: DateTime.now(), 
          message: "بدأت اللعبة برصيد ${settings.initialMoney} P لكل لاعب",
          type: LogType.info,
        )
      ],
    );

    if (initialSeconds != null) {
      _startGameDurationTimer();
    }
  }

  void _addLog(String message, {LogType type = LogType.info, int? playerIndex, double? amount}) {
    final log = GameLog(
      timestamp: DateTime.now(),
      message: message,
      type: type,
      playerIndex: playerIndex,
      amount: amount,
    );
    state = state.copyWith(logs: [...state.logs, log]);
  }

  void _startGameDurationTimer() {
    _gameDurationTimer?.cancel();
    _gameDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isGameOver) {
        timer.cancel();
        return;
      }

      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
        if (state.remainingSeconds <= 0) {
          timer.cancel();
          endGame();
        }
      }
    });
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
      final currentIdx = state.currentPlayerIndex;
      final currentPos = state.players[currentIdx].currentPosition;
      int nextPos = (currentPos + 1) % state.board.length;
      final currentPlayer = state.players[currentIdx];
      final updatedPlayers = [for (var p in state.players) p];
      
      if (nextPos == 0 && currentPos != 0) {
        updatedPlayers[currentIdx] = updatedPlayers[currentIdx].copyWith(
          currentPosition: nextPos,
          money: updatedPlayers[currentIdx].money + state.settings.salaryPerLap,
          lapsCompleted: updatedPlayers[currentIdx].lapsCompleted + 1,
        );
        state = state.copyWith(
          players: updatedPlayers, 
          totalTurns: state.totalTurns + 1,
          message: "مرت ${currentPlayer.name} بـ البداية! دورة جديدة +${state.settings.salaryPerLap} P",
        );
        _addLog(
          "${currentPlayer.name} أتم دورة وحصل على ${state.settings.salaryPerLap} P",
          type: LogType.moneyAdd,
          playerIndex: currentIdx,
          amount: state.settings.salaryPerLap,
        );
      } else {
        updatedPlayers[currentIdx] = updatedPlayers[currentIdx].copyWith(
          currentPosition: nextPos,
        );
        state = state.copyWith(players: updatedPlayers);
      }
      
      // TAX LOGIC: If the station has tax and is owned by someone else
      final stationPassed = state.board[nextPos];
      if (stationPassed.hasTax && stationPassed.taxAmount > 0) {
        int? taxOwnerIdx;
        for (int j = 0; j < state.players.length; j++) {
          if (state.players[j].ownedStationIds.contains(stationPassed.id)) {
            taxOwnerIdx = j;
            break;
          }
        }
        if (taxOwnerIdx != null && taxOwnerIdx != currentIdx) {
          final taxAmt = stationPassed.taxAmount;
          final taxOwner = state.players[taxOwnerIdx];
          final pUpdated = [for (var p in state.players) p];
          pUpdated[currentIdx] = pUpdated[currentIdx].copyWith(
            money: pUpdated[currentIdx].money - taxAmt,
          );
          pUpdated[taxOwnerIdx] = pUpdated[taxOwnerIdx].copyWith(
            money: pUpdated[taxOwnerIdx].money + taxAmt,
          );
          state = state.copyWith(
            players: pUpdated,
            message: "${currentPlayer.name} دفع ضريبة ${taxAmt.toInt()} لـ ${taxOwner.name} (مرور بـ ${stationPassed.name})",
          );
          _addLog(
            "${currentPlayer.name} دفع ضريبة ${taxAmt.toInt()} لـ ${taxOwner.name} (مرور بـ ${stationPassed.name})",
            type: LogType.moneyRemove,
            playerIndex: currentIdx,
            amount: taxAmt,
          );
          _addLog(
            "${taxOwner.name} حصل على ضريبة ${taxAmt.toInt()} من ${currentPlayer.name}",
            type: LogType.moneyAdd,
            playerIndex: taxOwnerIdx,
            amount: taxAmt,
          );
        }
      }
      
      await Future.delayed(const Duration(milliseconds: 350));
    }
    
    state = state.copyWith(isMovingPlayer: false);
    _handleLanding(state.players[state.currentPlayerIndex].currentPosition);
  }

  void _handleLanding(int position) {
    if (position >= state.board.length) return;
    final station = state.board[position];
    final currentPlayer = state.players[state.currentPlayerIndex];
    state = state.copyWith(pendingLandingStation: station, message: "${currentPlayer.name} وصل إلى ${station.name}");
    
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
    final String pName = currentPlayer.name;
    String effectMsg = "";

    switch (card.effectType) {
      case CardEffectType.addMoney:
        updatedPlayer = currentPlayer.copyWith(money: currentPlayer.money + card.effectValue);
        effectMsg = "مبروك $pName! حصلت على ${card.effectValue}";
        _addLog("كارت ${card.title}: $pName حصل على ${card.effectValue} P", type: LogType.moneyAdd, playerIndex: state.currentPlayerIndex, amount: card.effectValue.toDouble());
        break;
      case CardEffectType.removeMoney:
        updatedPlayer = currentPlayer.copyWith(money: currentPlayer.money - card.effectValue);
        effectMsg = "يا للهول $pName! خسرت ${card.effectValue}";
        _addLog("كارت ${card.title}: $pName دفع ${card.effectValue} P", type: LogType.moneyRemove, playerIndex: state.currentPlayerIndex, amount: card.effectValue.toDouble());
        break;
      case CardEffectType.skipTurn:
        updatedPlayer = currentPlayer.copyWith(skipNextTurn: true);
        effectMsg = "عذراً $pName، ستفقد دورك القادم";
        break;
      case CardEffectType.diceMultiplier:
        updatedPlayer = currentPlayer.copyWith(nextDiceMultiplier: card.effectValue.toDouble());
        effectMsg = "$pName، مضاعف النرد القادم: ${card.effectValue}";
        break;
      case CardEffectType.moveSteps:
        effectMsg = "تحرك ${card.effectValue} خطوات";
        // Update message first, then move. Return early to avoid state overwrite.
        state = state.copyWith(
          clearPendingLandingStation: true,
          message: "كارت ${card.title}: $pName $effectMsg",
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
             clearPendingLandingStation: true, 
             message: "كارت ${card.title}: توجه إلى ${finalTarget.name}...",
           );
           
           if (steps == 0) {
             _handleLanding(targetIdx);
           } else {
             _movePlayerSequentially(steps);
           }
        } else {
           state = state.copyWith(
             clearPendingLandingStation: true,
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
      clearPendingLandingStation: true,
      message: "كارت ${card.title}: $pName $effectMsg",
      isEndingTurn: true,
    );

    _scheduleAutoNextTurn();
  }

  /// Cancels any pending auto-turn and advances immediately
  void forceNextTurn() {
    _autoNextTurnTimer?.cancel();
    nextTurn();
  }

  void resolveLanding({bool bought = false, bool correctlyAnsweredPasser = false, bool tookPasserQuestion = false, bool skipAutoNextTurn = false}) {
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
          resultMsg = "${currentPlayer.name} تحدى ${station.name} بنجاح! ربح ${station.buyPrice}";
          _addLog("${currentPlayer.name} ربح التحدي مع ${station.name} وحصل على ${station.buyPrice} P", type: LogType.moneyAdd, playerIndex: pIdx, amount: station.buyPrice);
        } else if (tookPasserQuestion && !correctlyAnsweredPasser) {
          updatedPlayers[pIdx] = currentPlayer.copyWith(money: currentPlayer.money - station.baseRent);
          resultMsg = "${currentPlayer.name} خسر التحدي مع ${station.name}! دفع غرامة ${station.baseRent}";
          _addLog("${currentPlayer.name} خسر التحدي مع ${station.name} ودفع غرامة ${station.baseRent} P", type: LogType.moneyRemove, playerIndex: pIdx, amount: station.baseRent);
        } else {
          resultMsg = "${currentPlayer.name} مر بـ ${station.name} بسلام";
        }
      } else if (bought && station.id != null) {
          if (currentPlayer.money < station.buyPrice) {
             resultMsg = "لا تملك رصيداً كافياً لشراء ${station.name}"; 
          } else {
             updatedPlayers[pIdx] = currentPlayer.copyWith(
               money: currentPlayer.money - station.buyPrice,
               ownedStationIds: [...currentPlayer.ownedStationIds, station.id!],
             );
             resultMsg = "مبروك ${currentPlayer.name}! اشتريت ${station.name}";
             _addLog("${currentPlayer.name} اشترى ${station.name} بـ ${station.buyPrice} P", type: LogType.purchase, playerIndex: pIdx, amount: station.buyPrice);
          }
      } else if (ownerIdx != null && ownerIdx != pIdx) {
          final ownerName = state.players[ownerIdx].name;
          double rent = station.baseRent > 0 ? station.baseRent : (station.buyPrice * 0.2);
          
          // ADD BUILDINGS RENT
          for (var b in station.buildings) {
            if (b.isPurchased) {
              rent += b.additionalRent;
            }
          }
          
          if (tookPasserQuestion && correctlyAnsweredPasser) {
            rent = (rent / 2).floorToDouble();
            resultMsg = "إجابة صحيحة! ${currentPlayer.name} دفع نصف الإيجار ($rent) لـ ${ownerName}";
          } else if (tookPasserQuestion && !correctlyAnsweredPasser) {
            rent = rent.floorToDouble();
            resultMsg = "إجابة خاطئة! ${currentPlayer.name} دفع الإيجار كاملاً ($rent) لـ ${ownerName}";
          } else {
            rent = rent.floorToDouble();
            resultMsg = "${currentPlayer.name} دفع إيجار بقيمة ($rent) لـ ${ownerName}";
          }

          updatedPlayers[pIdx] = updatedPlayers[pIdx].copyWith(money: updatedPlayers[pIdx].money - rent);
          updatedPlayers[ownerIdx] = updatedPlayers[ownerIdx].copyWith(money: updatedPlayers[ownerIdx].money + rent);
          
          if (updatedPlayers[pIdx].money < 0) {
             _addLog("دخل في غرامة/مديونية بقيمة ${updatedPlayers[pIdx].money.abs().toInt()} P لـ ${state.players[ownerIdx].name}!", type: LogType.moneyRemove, playerIndex: pIdx, amount: rent);
          }
          
          _addLog("${updatedPlayers[pIdx].name} دفع إيجار $rent لـ ${state.players[ownerIdx].name} في ${station.name}", type: LogType.moneyRemove, playerIndex: pIdx, amount: rent);
          _addLog("${state.players[ownerIdx].name} حصل على إيجار $rent من ${state.players[pIdx].name} في ${station.name}", type: LogType.moneyAdd, playerIndex: ownerIdx, amount: rent);
      } else if (ownerIdx == pIdx) {
         resultMsg = "${currentPlayer.name} في مدينته ${station.name}";
      } else {
         resultMsg = station.type == StationType.none ? "" : "تم المرور بـ ${station.name} بواسطة ${currentPlayer.name}";
      }

      state = state.copyWith(
        players: updatedPlayers,
        clearPendingLandingStation: true,
        message: resultMsg,
        isEndingTurn: true, // IMPORTANT: Lock buttons until actual nextTurn()
      );

      // Check for bankruptcy if enabled
      if (state.settings.bankruptcyEnabled && updatedPlayers[pIdx].money < 0) {
         _checkBankruptcy(pIdx);
      }

      // Schedule auto-next-turn (cancels any existing timer first)
      if (!skipAutoNextTurn) {
        _scheduleAutoNextTurn();
      }
    } catch (e) {
      print("Error in resolveLanding: $e");
      state = state.copyWith(clearPendingLandingStation: true, message: "انتهى الموقف");
      _scheduleAutoNextTurn();
    }
  }

  /// Centralized auto-next-turn with timer management.
  /// Only ONE timer can be active at a time — prevents double nextTurn() calls.
  void _scheduleAutoNextTurn() {
    _autoNextTurnTimer?.cancel();
    _autoNextTurnTimer = Timer(const Duration(milliseconds: 300), () => nextTurn());
  }

  void nextTurn() {
    // Cancel any pending auto-advance timer (user clicked "إنها" manually)
    _autoNextTurnTimer?.cancel();

    if (state.isGameOver || state.isMovingPlayer || state.isRollingDice || state.pendingLandingStation != null) {
       // Reset ending flag if blocked
       state = state.copyWith(isEndingTurn: false);
       return;
    }

    // 1. Check Time-based ending
    if (state.settings.winCondition == WinningCondition.time && state.startTime != null) {
      final elapsed = DateTime.now().difference(state.startTime!);
      if (elapsed.inMinutes >= state.settings.maxTimeMinutes) {
        state = state.copyWith(message: "انتهى الوقت لصالح ${state.players[state.currentPlayerIndex].name}!");
        endGame();
        return;
      }
    }

    // 2. Check Round-based ending logic
    if (state.settings.winCondition == WinningCondition.rounds) {
       bool everyoneFinished = state.players.every((p) => p.lapsCompleted >= state.settings.maxRounds);
       if (everyoneFinished) {
         state = state.copyWith(message: "انتهت جميع الدورات!");
         endGame();
         return;
       }
    }

    int nextIndex = (state.currentPlayerIndex + 1) % state.players.length;
    
    // 3. Skip players who have finished their required rounds
    if (state.settings.winCondition == WinningCondition.rounds) {
       int startIndex = nextIndex;
       while (state.players[nextIndex].lapsCompleted >= state.settings.maxRounds) {
         nextIndex = (nextIndex + 1) % state.players.length;
         if (nextIndex == startIndex) {
           // Everyone is finished (this should be caught by everyoneFinished above, but safety first)
           endGame();
           return;
         }
       }
    }

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
      currentDiceValue: 0, 
      message: "دور ${state.players[nextIndex].name}",
      isEndingTurn: false,
    );
  }

  Future<void> buyBuilding(int stationId, int buildingIdx) async {
    final station = state.board.firstWhere((s) => s.id == stationId);
    if (buildingIdx >= station.buildings.length) return;
    
    final building = station.buildings[buildingIdx];
    if (building.isPurchased) return;
    
    final currentPlayer = state.players[state.currentPlayerIndex];
    if (currentPlayer.money < building.buyPrice) {
      state = state.copyWith(message: "ليس لديك بركة كافية لبناء ${building.name}");
      return;
    }

    // Update building
    final updatedBuildings = [...station.buildings];
    updatedBuildings[buildingIdx] = updatedBuildings[buildingIdx].copyWith(isPurchased: true);
    
    // Update station in board
    final updatedBoard = [...state.board];
    final stationIdx = updatedBoard.indexWhere((s) => s.id == stationId);
    updatedBoard[stationIdx] = updatedBoard[stationIdx].copyWith(buildings: updatedBuildings);
    
    // Update player money
    final updatedPlayers = [...state.players];
    updatedPlayers[state.currentPlayerIndex] = currentPlayer.copyWith(
      money: currentPlayer.money - building.buyPrice,
    );
    
    state = state.copyWith(
      board: updatedBoard,
      players: updatedPlayers,
      message: "${currentPlayer.name} بنى ${building.name} في ${station.name}!",
    );
    _addLog("${currentPlayer.name} بنى ${building.name} في ${station.name} بـ ${building.buyPrice} P", type: LogType.purchase, playerIndex: state.currentPlayerIndex, amount: building.buyPrice);
    
    // If we were in a landing state, we keep it so the user can see the result or build more
    // unless you want to end turn. Usually building doesn't end turn in Monopoly.
  }

  Future<void> sellStation(int stationId) async {
    final station = state.board.firstWhere((s) => s.id == stationId);
    final pIdx = state.currentPlayerIndex;
    final player = state.players[pIdx];
    
    if (!player.ownedStationIds.contains(stationId)) return;
    
    // Calculate half price for everything
    double totalValue = station.buyPrice;
    for (var b in station.buildings) {
       if (b.isPurchased) totalValue += b.buyPrice;
    }
    
    double sellPrice = (totalValue / 2).floorToDouble();
    
    // Update player
    final updatedPlayers = [...state.players];
    final updatedOwned = [...player.ownedStationIds]..remove(stationId);
    updatedPlayers[pIdx] = player.copyWith(
      money: player.money + sellPrice,
      ownedStationIds: updatedOwned,
    );
    
    // Reset station in board
    final updatedBoard = [...state.board];
    final sIdx = updatedBoard.indexWhere((s) => s.id == stationId);
    updatedBoard[sIdx] = updatedBoard[sIdx].copyWith(
      buildings: updatedBoard[sIdx].buildings.map((b) => b.copyWith(isPurchased: false)).toList(),
      hasTax: false,
      taxAmount: 0,
    );
    
    state = state.copyWith(players: updatedPlayers, board: updatedBoard);
    _addLog("${player.name} باع ${station.name} وجميع مبانيها للبنك بنصف الثمن ($sellPrice P)", type: LogType.moneyAdd, playerIndex: pIdx, amount: sellPrice);
  }

  void toggleTax(int stationId, bool enabled) {
    final updatedBoard = state.board.map((s) {
      if (s.id == stationId) {
        return s.copyWith(hasTax: enabled);
      }
      return s;
    }).toList();
    state = state.copyWith(board: updatedBoard);
    _addLog("${enabled ? 'تفعيل' : 'إلغاء'} الضريبة على ${state.board.firstWhere((s) => s.id == stationId).name}", type: LogType.info);
  }

  void setTaxAmount(int stationId, double amount) {
    final updatedBoard = [...state.board];
    final idx = updatedBoard.indexWhere((s) => s.id == stationId);
    if (idx != -1) {
      final station = updatedBoard[idx];
      // Max tax: 25% of buy price
      final maxTax = station.buyPrice * 0.25;
      final finalAmount = amount > maxTax ? maxTax : amount;
      
      updatedBoard[idx] = updatedBoard[idx].copyWith(taxAmount: finalAmount);
      state = state.copyWith(board: updatedBoard);
    }
  }

  Future<void> endGame() async {
    _autoNextTurnTimer?.cancel();
    _gameDurationTimer?.cancel();
    if (state.players.isEmpty) return;

    // Find winner by total assets (money + owned station prices)
    BankAlHazPlayer? winner;
    double maxAssets = -1;

    for (var p in state.players) {
      double score = 0;
      
      switch (state.settings.winCriteria) {
        case WinCriteria.moneyOnly:
          score = p.money;
          break;
        case WinCriteria.moneyAndStations:
          double stationValue = 0;
          for (var sid in p.ownedStationIds) {
            final s = state.board.firstWhere((st) => st.id == sid);
            stationValue += s.buyPrice;
          }
          score = p.money + stationValue;
          break;
        case WinCriteria.cumulativeValue:
          double totalValue = 0;
          for (var sid in p.ownedStationIds) {
            final s = state.board.firstWhere((st) => st.id == sid);
            totalValue += s.buyPrice;
            for (var b in s.buildings) {
               if (b.isPurchased) totalValue += b.buyPrice;
            }
          }
          score = p.money + totalValue;
          break;
      }

      if (score > maxAssets) {
        maxAssets = score;
        winner = p;
      }
    }

    if (winner != null) {
      int winnerIdx = state.players.indexOf(winner);
      state = state.copyWith(
        isGameOver: true, 
        winnerIndex: winnerIdx,
        message: "انتهت اللعبة! الفائز هو ${winner.name} بإجمالي ثروة $maxAssets",
      );
      
      // Award winner points
      final teams = await ref.read(teamsListProvider.future);
      final winningTeam = teams.firstWhere((t) => t.name == winner!.name, orElse: () => teams.first);
      
      final winPoints = state.settings.winPoints;
      
      await ref.read(teamsListProvider.notifier).updateScore(winningTeam.id!, winPoints, reason: 'فوز في بنك الحظ');
    }
  }

  void _checkBankruptcy(int playerIdx) {
    if (playerIdx >= state.players.length) return;
    final player = state.players[playerIdx];
    if (player.money >= 0) return;
    
    // Check if they have ANYTHING to sell
    if (player.ownedStationIds.isEmpty) {
        // Bankrupt!
        _addLog("${player.name} أفلس وخرج من اللعبة!", type: LogType.info, playerIndex: playerIdx);
        
        final updatedPlayers = state.players.where((p) => p.id != player.id).toList();
        
        // Return properties to bank is complex since we don't track which station was whose easily here, 
        // but wait, player.ownedStationIds has them.
        final updatedBoard = state.board.map((s) {
          if (player.ownedStationIds.contains(s.id)) {
              return s.copyWith(
                buildings: s.buildings.map((b) => b.copyWith(isPurchased: false)).toList(),
                hasTax: false,
                taxAmount: 0,
              );
          }
          return s;
        }).toList();
        
        state = state.copyWith(players: updatedPlayers, board: updatedBoard, message: "أفلس ${player.name}!");
        
        if (updatedPlayers.length <= 1) {
            endGame();
        }
    } else {
       state = state.copyWith(message: "${player.name} عليه ديون! يجب بيع بعض الممتلكات.");
    }
  }

  void restartGame() {
    if (state.players.isEmpty) return;
    final names = state.players.map((p) => p.name).toList();
    final settings = state.settings;
    initGame(names, settings);
  }

  Future<void> sellStationToPlayer(int stationId, int buyerIndex, double price) async {
    if (buyerIndex < 0 || buyerIndex >= state.players.length) return;
    
    final station = state.board.firstWhere((s) => s.id == stationId);
    final sellerIndex = state.players.indexWhere((p) => p.ownedStationIds.contains(stationId));
    if (sellerIndex == -1) return;
    
    final seller = state.players[sellerIndex];
    final buyer = state.players[buyerIndex];
    
    if (buyer.money < price) {
       _addLog("فشل البيع: ${buyer.name} لا يملك رصيد كافي", type: LogType.info);
       return;
    }

    final updatedPlayers = state.players.map((p) {
      if (p.id == seller.id) {
        return p.copyWith(
          money: p.money + price,
          ownedStationIds: p.ownedStationIds.where((id) => id != stationId).toList(),
        );
      }
      if (p.id == buyer.id) {
        return p.copyWith(
          money: p.money - price,
          ownedStationIds: [...p.ownedStationIds, stationId],
        );
      }
      return p;
    }).toList();
    
    _addLog("${seller.name} باع ${station.name} لـ ${buyer.name} مقابل ${price.toInt()} P", type: LogType.purchase, playerIndex: buyerIndex);
    state = state.copyWith(players: updatedPlayers);
  }

  void sellStationToBank(int stationId) {
    final station = state.board.firstWhere((s) => s.id == stationId);
    final sellerIndex = state.players.indexWhere((p) => p.ownedStationIds.contains(stationId));
    if (sellerIndex == -1) return;

    final seller = state.players[sellerIndex];
    double backAmount = station.buyPrice / 2;
    for (var b in station.buildings) if (b.isPurchased) backAmount += b.buyPrice / 2;

    final updatedPlayers = [...state.players];
    updatedPlayers[sellerIndex] = updatedPlayers[sellerIndex].copyWith(
      money: updatedPlayers[sellerIndex].money + backAmount,
      ownedStationIds: updatedPlayers[sellerIndex].ownedStationIds.where((id) => id != stationId).toList(),
    );

    final updatedBoard = state.board.map((s) {
      if (s.id == stationId) {
        return s.copyWith(
          buildings: s.buildings.map((b) => b.copyWith(isPurchased: false)).toList(),
          hasTax: false,
          taxAmount: 0,
        );
      }
      return s;
    }).toList();

    _addLog("${seller.name} باع ${station.name} للبنك مقابل ${backAmount.toInt()} P", type: LogType.moneyAdd, playerIndex: sellerIndex, amount: backAmount);
    state = state.copyWith(players: updatedPlayers, board: updatedBoard);
  }

  void toggleStationTax(int stationId) {
    final updatedBoard = state.board.map((s) {
      if (s.id == stationId) {
        final newTax = !s.hasTax;
        return s.copyWith(
          hasTax: newTax,
          taxAmount: newTax ? (s.buyPrice * 0.15).clamp(50, 1000).toDouble() : 0,
        );
      }
      return s;
    }).toList();

    final stationName = state.board.firstWhere((s) => s.id == stationId).name;
    final isTaxOn = updatedBoard.firstWhere((s) => s.id == stationId).hasTax;
    _addLog("تغيير حالة الضريبة في $stationName إلى ${isTaxOn ? 'مفعلة' : 'معطلة'}");
    state = state.copyWith(board: updatedBoard);
  }

  void addUpgradeToStation(int stationId, String buildingName) {
    final station = state.board.firstWhere((s) => s.id == stationId);
    final ownerIdx = state.players.indexWhere((p) => p.ownedStationIds.contains(stationId));
    if (ownerIdx == -1) return;

    final building = station.buildings.firstWhere((b) => b.name == buildingName);
    if (state.players[ownerIdx].money < building.buyPrice) return;

    final updatedBoard = state.board.map((s) {
      if (s.id == stationId) {
        return s.copyWith(
          buildings: s.buildings.map((b) => b.name == buildingName ? b.copyWith(isPurchased: true) : b).toList(),
        );
      }
      return s;
    }).toList();

    final updatedPlayers = [...state.players];
    updatedPlayers[ownerIdx] = updatedPlayers[ownerIdx].copyWith(
      money: updatedPlayers[ownerIdx].money - building.buyPrice,
    );

    _addLog("${state.players[ownerIdx].name} بنى $buildingName في ${station.name}", type: LogType.moneyRemove, playerIndex: ownerIdx, amount: building.buyPrice);
    state = state.copyWith(board: updatedBoard, players: updatedPlayers);
  }
}

final gameEngineProvider = NotifierProvider<GameEngine, GameState>(GameEngine.new);
