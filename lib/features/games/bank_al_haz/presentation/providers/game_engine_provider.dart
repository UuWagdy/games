import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/core/utils/arabic_utils.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/features/questions/domain/entities/question.dart';
import '../../domain/entities/bank_al_haz_entities.dart';
import 'bank_al_haz_providers.dart';
import '../../../../teams/presentation/providers/team_providers.dart';


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
  final double currentCheckInterest;
  final int elapsedSeconds;
  final int turnRemainingSeconds;

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
    this.currentCheckInterest = 0.05,
    this.elapsedSeconds = 0,
    this.turnRemainingSeconds = 0,
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
    double? currentCheckInterest,
    int? elapsedSeconds,
    int? turnRemainingSeconds,
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
      currentCheckInterest: currentCheckInterest ?? this.currentCheckInterest,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
    'players': players.map((p) => p.toJson()).toList(),
    'board': board.map((s) => s.toJson()).toList(),
    'currentPlayerIndex': currentPlayerIndex,
    'currentDiceValue': currentDiceValue,
    'rollCounter': rollCounter,
    'isRollingDice': isRollingDice,
    'isMovingPlayer': isMovingPlayer,
    'isGameOver': isGameOver,
    'message': message,
    'pendingLandingStation': pendingLandingStation?.toJson(),
    'currentCard': currentCard?.toJson(),
    'startTime': startTime?.toIso8601String(),
    'totalTurns': totalTurns,
    'isEndingTurn': isEndingTurn,
    'settings': settings.toJson(),
    'remainingSeconds': remainingSeconds,
    'logs': logs.map((l) => l.toJson()).toList(),
    'winnerIndex': winnerIndex,
    'currentCheckInterest': currentCheckInterest,
    'elapsedSeconds': elapsedSeconds,
    'turnRemainingSeconds': turnRemainingSeconds,
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      players: (json['players'] as List).map((p) => BankAlHazPlayer.fromJson(p)).toList(),
      board: (json['board'] as List).map((s) => Station.fromJson(s)).toList(),
      currentPlayerIndex: json['currentPlayerIndex'],
      currentDiceValue: json['currentDiceValue'],
      rollCounter: json['rollCounter'],
      isRollingDice: json['isRollingDice'],
      isMovingPlayer: json['isMovingPlayer'],
      isGameOver: json['isGameOver'],
      message: json['message'],
      pendingLandingStation: json['pendingLandingStation'] != null ? Station.fromJson(json['pendingLandingStation']) : null,
      currentCard: json['currentCard'] != null ? BankAlHazCard.fromJson(json['currentCard']) : null,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      totalTurns: json['totalTurns'],
      isEndingTurn: json['isEndingTurn'],
      settings: BankAlHazSettings.fromJson(json['settings']),
      remainingSeconds: json['remainingSeconds'],
      logs: (json['logs'] as List).map((l) => GameLog.fromJson(l)).toList(),
      winnerIndex: json['winnerIndex'],
      currentCheckInterest: (json['currentCheckInterest'] as num?)?.toDouble() ?? 0.05,
      elapsedSeconds: json['elapsedSeconds'] ?? 0,
      turnRemainingSeconds: json['turnRemainingSeconds'] ?? 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory GameState.fromJsonString(String jsonStr) => GameState.fromJson(jsonDecode(jsonStr));
}


class GameEngine extends Notifier<GameState> {
  final _random = math.Random();
  Timer? _gameDurationTimer;
  Timer? _turnTimer;

  @override
  GameState build() {
    return const GameState();
  }

  Future<void> _saveState() async {
    final repo = ref.read(bankAlHazRepositoryProvider);
    await repo.saveGameState(state.toJsonString());
  }

  Future<bool> loadSavedGame() async {
    final repo = ref.read(bankAlHazRepositoryProvider);
    final savedJson = await repo.getGameState();
    if (savedJson != null) {
      try {
        final savedState = GameState.fromJsonString(savedJson);
        state = savedState;
        if ((state.remainingSeconds > 0 || state.settings.inflationEnabled) && !state.isGameOver) {
          _startGameDurationTimer();
        }
        _addLog("تم استعادة اللعبة السابقة", type: LogType.info);
        return true;
      } catch (e) {
        print("Error loading saved game: $e");
      }
    }
    return false;
  }

  Future<void> clearSavedGame() async {
    final repo = ref.read(bankAlHazRepositoryProvider);
    await repo.clearGameState();
  }

  Future<void> initGame(List<String> playerNames, BankAlHazSettings settings) async {
    _turnTimer?.cancel();
    _gameDurationTimer?.cancel();
    
    final bankRepo = ref.read(bankAlHazRepositoryProvider);

    int? initialSeconds;
    if (settings.winCondition == WinningCondition.time && settings.maxTimeMinutes > 0) {
      initialSeconds = settings.maxTimeMinutes * 60;
    }
    
    final players = playerNames.asMap().entries.map((entry) {
      return BankAlHazPlayer(
        id: entry.key + 1,
        name: entry.value,
        money: settings.initialMoney,
      );
    }).toList();

    // Auto-link stations with categories if possible
    await bankRepo.autoLinkStationsWithCategories();
    
    // Load stations and ensure that any station with an owner category requires a question
    var updatedStations = await bankRepo.getStations();
    
    // Ensure all linked stations require questions at runtime
    updatedStations = updatedStations.map((s) {
      if ((s.ownerCategoryId != null || s.passerCategoryId != null) && !s.requiresQuestion) {
        return s.copyWith(requiresQuestion: true, type: StationType.question);
      }
      return s;
    }).toList();
    
    state = state.copyWith(
      players: players,
      board: updatedStations,
      currentPlayerIndex: 0,
      isGameOver: false,
      settings: settings,
      remainingSeconds: initialSeconds,
      turnRemainingSeconds: settings.turnTimerEnabled ? settings.turnTimerSeconds : 0,
      currentCheckInterest: settings.checkInterestRate,
      logs: [
        GameLog(
          timestamp: DateTime.now(), 
          message: "بدأت اللعبة برصيد ${settings.initialMoney} P لكل لاعب",
          type: LogType.info,
        )
      ],
    );

    if (initialSeconds != null || settings.inflationEnabled) {
      _startGameDurationTimer();
    }
    _saveState();
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

      int nextElapsed = state.elapsedSeconds + 1;
      state = state.copyWith(elapsedSeconds: nextElapsed);


      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
        if (state.remainingSeconds <= 0) {
          timer.cancel();
          endGame();
        }
      }

      if (state.settings.inflationEnabled && nextElapsed > 0 && nextElapsed % (state.settings.inflationIntervalMinutes * 60) == 0) {
        _applyInflation();
      }
    });
  }


  void syncPlayers(List<String> currentNames) {
    if (state.players.isEmpty) return;
    
    final namesToKeep = currentNames.toSet();
    final List<BankAlHazPlayer> finalPlayers = [];
    final existingPlayerNames = <String>{};
    bool changed = false;
    
    for (var p in state.players) {
      // Keep AI regardless of namesToKeep if it was added manually? No, follow currentNames.
      // Actually, let's keep the logic as is but handle AI specially in toggle.
      if (namesToKeep.contains(p.name)) {
        finalPlayers.add(p);
        existingPlayerNames.add(p.name);
      } else {
        _reclaimProperties(p.id);
        changed = true;
        _addLog("تم استبعاد ${p.name} من اللعبة", type: LogType.info);
      }
    }
    
    double initialMoney = state.settings.initialMoney;
    int maxId = state.players.fold(0, (mx, p) => p.id > mx ? p.id : mx);
    
    for (var name in currentNames) {
      if (!existingPlayerNames.contains(name)) {
        maxId++;
        finalPlayers.add(BankAlHazPlayer(
          id: maxId,
          name: name,
          money: initialMoney,
          currentPosition: 0,
        ));
        changed = true;
        _addLog("انضم ${name} إلى اللعبة", type: LogType.info);
      }
    }
    
    if (changed) {
      int newCurrentIndex = state.currentPlayerIndex;
      if (newCurrentIndex >= finalPlayers.length) {
        newCurrentIndex = 0;
      }
      state = state.copyWith(players: finalPlayers, currentPlayerIndex: newCurrentIndex);
      _saveState();
    }
  }



  void _reclaimProperties(int playerId) {
    final player = state.players.firstWhere((p) => p.id == playerId, orElse: () => const BankAlHazPlayer(id: -1, name: ''));
    if (player.id == -1) return;
    
    final ownedIds = player.ownedStationIds.toSet();
    if (ownedIds.isEmpty) return;

    final updatedBoard = state.board.map((s) {
      if (ownedIds.contains(s.id)) {
        return s.copyWith(
          buildings: s.buildings.map((b) => b.copyWith(isPurchased: false)).toList(),
          hasTax: false,
          taxAmount: 0,
        );
      }
      return s;
    }).toList();
    
    state = state.copyWith(board: updatedBoard);
  }

  Future<void> rollDice() async {
    if (state.isGameOver || state.isMovingPlayer || state.isRollingDice || state.pendingLandingStation != null || state.isEndingTurn) return;
    _turnTimer?.cancel();

    final int diceResult = _random.nextInt(6) + 1;
    final multiplier = state.players[state.currentPlayerIndex].nextDiceMultiplier;
    final int totalSteps = (diceResult * multiplier).toInt();

    state = state.copyWith(
      isRollingDice: true, 
      currentDiceValue: diceResult, 
      rollCounter: state.rollCounter + 1,
      message: "يرمي النرد...",
    );
    _addLog("${state.players[state.currentPlayerIndex].name} يرمي النرد...", type: LogType.info, playerIndex: state.currentPlayerIndex);
    
    await Future.delayed(const Duration(milliseconds: 1600));

    state = state.copyWith(
      isRollingDice: false, 
      message: "لف النرد: $diceResult — تحرك $totalSteps خانات",
    );
    _addLog("النتيجة: $diceResult (تحرك $totalSteps)", type: LogType.info, playerIndex: state.currentPlayerIndex);
    
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
      final int nextPos = (currentPos + 1) % state.board.length;
      final currentPlayer = state.players[currentIdx];
      final List<BankAlHazPlayer> updatedPlayers = [for (var p in state.players) p];
      
      final Station stationPassed = state.board[nextPos];
      final bool isCity = stationPassed.type == StationType.property || stationPassed.type == StationType.question;

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
        
        if (state.settings.certificatesEnabled) {
          _payoutCertificates(currentIdx, isPerCycle: true, isPerStation: true, isCityPassed: isCity);
        }
        _addLog("${currentPlayer.name} أتم دورة وحصل على ${state.settings.salaryPerLap} P", type: LogType.moneyAdd, playerIndex: currentIdx, amount: state.settings.salaryPerLap);
      } else {
        updatedPlayers[currentIdx] = updatedPlayers[currentIdx].copyWith(currentPosition: nextPos);
        state = state.copyWith(players: updatedPlayers);
        if (state.settings.certificatesEnabled) {
          _payoutCertificates(currentIdx, isPerStation: true, isCityPassed: isCity);
        }
      }
      
      bool applyTax = false;
      if (state.settings.taxMode == BankAlHazTaxMode.all) {
        applyTax = stationPassed.type != StationType.card && stationPassed.type != StationType.none;
      } else if (state.settings.taxMode == BankAlHazTaxMode.custom) {
        applyTax = stationPassed.hasTax && stationPassed.taxAmount > 0;
      }

      if (applyTax) {
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
          pUpdated[currentIdx] = pUpdated[currentIdx].copyWith(money: pUpdated[currentIdx].money - taxAmt);
          pUpdated[taxOwnerIdx] = pUpdated[taxOwnerIdx].copyWith(money: pUpdated[taxOwnerIdx].money + taxAmt);
          state = state.copyWith(
            players: pUpdated,
            message: "${currentPlayer.name} دفع ضريبة ${taxAmt.toInt()} لـ ${taxOwner.name} (مرور بـ ${stationPassed.name})",
          );
          _addLog("${currentPlayer.name} دفع ضريبة ${taxAmt.toInt()} لـ ${taxOwner.name} (مرور بـ ${stationPassed.name})", type: LogType.moneyRemove, playerIndex: currentIdx, amount: taxAmt);
          _addLog("${taxOwner.name} حصل على ضريبة ${taxAmt.toInt()} من ${currentPlayer.name}", type: LogType.moneyAdd, playerIndex: taxOwnerIdx, amount: taxAmt);
        }
      }
      await Future.delayed(const Duration(milliseconds: 350));
    }
    
    state = state.copyWith(isMovingPlayer: false);
    _handleLanding(state.players[state.currentPlayerIndex].currentPosition);
    _saveState();
  }

  void _handleLanding(int position) {
    if (position >= state.board.length) return;
    final station = state.board[position];
    final currentPlayer = state.players[state.currentPlayerIndex];
    state = state.copyWith(pendingLandingStation: station, message: "${currentPlayer.name} وصل إلى ${station.name}");
    if (station.type == StationType.none) resolveLanding();
  }

  Future<Question?> getRandomQuestion(int? categoryId, {String? fallbackStationName}) async {
    final qRepo = ref.read(questionRepositoryProvider);

    int? targetId = categoryId;
    
    // Last resort fallback: if no current ID, try to re-link on the fly
    if (targetId == null && fallbackStationName != null) {
       final allCats = await qRepo.getCategories();
       final normalizedStation = ArabicUtils.normalize(fallbackStationName);
       final cleanStation = normalizedStation.replaceAll(' ', '').replaceAll('-', '').replaceAll(RegExp(r'\(.*\)'), '').replaceAll('(', '').replaceAll(')', '');
       
       for (var c in allCats) {
          final normalizedCat = ArabicUtils.normalize(c.name);
          final cleanCat = normalizedCat.replaceAll(' ', '').replaceAll('-', '').replaceAll(RegExp(r'\(.*\)'), '').replaceAll('(', '').replaceAll(')', '');
          if (cleanCat == "${cleanStation}مالك" || cleanCat == "مالك${cleanStation}" || cleanCat == cleanStation) {
             targetId = c.id;
             break;
          }
       }
    }

    if (targetId == null) return null;

    try {
      final questions = await qRepo.getQuestions(targetId);
      if (questions.isEmpty) return null;
      return questions[_random.nextInt(questions.length)];
    } catch (e) {
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
        effectMsg = "حصل على ${card.effectValue}";
        _addLog("كارت ${card.title}: ${currentPlayer.name} حصل على ${card.effectValue} P", type: LogType.moneyAdd, playerIndex: state.currentPlayerIndex, amount: card.effectValue.toDouble());
        break;
      case CardEffectType.removeMoney:
        updatedPlayer = currentPlayer.copyWith(money: currentPlayer.money - card.effectValue);
        effectMsg = "خسر ${card.effectValue}";
        _addLog("كارت ${card.title}: ${currentPlayer.name} دفع ${card.effectValue} P", type: LogType.moneyRemove, playerIndex: state.currentPlayerIndex, amount: card.effectValue.toDouble());
        break;
      case CardEffectType.skipTurn:
        updatedPlayer = currentPlayer.copyWith(skipNextTurn: true);
        effectMsg = "سيفقد دوره القادم";
        break;
      case CardEffectType.diceMultiplier:
        updatedPlayer = currentPlayer.copyWith(nextDiceMultiplier: card.effectValue.toDouble());
        effectMsg = "مضاعف النرد القادم: ${card.effectValue}";
        break;
      case CardEffectType.moveSteps:
        state = state.copyWith(clearPendingLandingStation: true, message: "كارت ${card.title}: ${currentPlayer.name} تحرك ${card.effectValue} خطوات");
        _movePlayerSequentially(card.effectValue);
        return;
      case CardEffectType.moveToStation:
        final targetName = card.targetStationName?.trim() ?? "";
        int targetIdx = state.board.indexWhere((s) => s.name.trim() == targetName);
        if (targetIdx == -1 && targetName.isNotEmpty) {
           targetIdx = state.board.indexWhere((s) => s.name.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('ة', 'ه').contains(targetName.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('ة', 'ه')));
        }
        if (targetIdx != -1) {
           int currentPos = currentPlayer.currentPosition;
           int steps = (targetIdx - currentPos + state.board.length) % state.board.length;
           state = state.copyWith(clearPendingLandingStation: true, message: "كارت ${card.title}: توجه إلى ${state.board[targetIdx].name}...");
           if (steps == 0) _handleLanding(targetIdx); else _movePlayerSequentially(steps);
        } else {
           state = state.copyWith(clearPendingLandingStation: true, message: "كارت ${card.title}: لم تم العثور على وجهة!");
           _scheduleAutoNextTurn();
        }
        return;
    }

    final updatedPlayers = [for (var p in state.players) p];
    updatedPlayers[state.currentPlayerIndex] = updatedPlayer;
    state = state.copyWith(players: updatedPlayers, clearPendingLandingStation: true, message: "كارت ${card.title}: ${currentPlayer.name} $effectMsg", isEndingTurn: true);
    if (state.settings.bankruptcyEnabled && (card.effectType == CardEffectType.removeMoney) && updatedPlayers[state.currentPlayerIndex].money <= 0) {
      if (_checkBankruptcy(state.currentPlayerIndex)) return;
    }
    
       _scheduleAutoNextTurn();
  }

  void forceNextTurn() {
    _turnTimer?.cancel();
    nextTurn();
  }

  void resolveLanding({bool bought = false, bool correctlyAnsweredPasser = false, bool tookPasserQuestion = false, bool skipAutoNextTurn = false}) {
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
    bool chargeLandingTax = false;
    double taxAmtToCharge = 0;

    if (state.settings.taxMode == BankAlHazTaxMode.all) {
        if (station.type != StationType.card && station.type != StationType.none) {
           chargeLandingTax = true;
           taxAmtToCharge = station.taxAmount > 0 ? station.taxAmount : 50.0;
        }
    } else if (state.settings.taxMode == BankAlHazTaxMode.custom) {
        if (station.hasTax && station.taxAmount > 0) {
           chargeLandingTax = true;
           taxAmtToCharge = station.taxAmount;
        }
    }

    if (chargeLandingTax) {
        updatedPlayers[pIdx] = updatedPlayers[pIdx].copyWith(money: updatedPlayers[pIdx].money - taxAmtToCharge);
        _addLog("${currentPlayer.name} دفع ضرائب بقيمة ${taxAmtToCharge.toInt()} في ${station.name}", type: LogType.moneyRemove, playerIndex: pIdx, amount: taxAmtToCharge);
        resultMsg = "${currentPlayer.name} دفع ضرائب بقيمة ${taxAmtToCharge.toInt()} في ${station.name}";
    }

    if (station.isUnbuyable) {
      if (tookPasserQuestion && correctlyAnsweredPasser) {
        updatedPlayers[pIdx] = currentPlayer.copyWith(money: currentPlayer.money + station.buyPrice);
        resultMsg = "${currentPlayer.name} تحدى ${station.name} بنجاح! ربح ${station.buyPrice}";
      } else if (tookPasserQuestion && !correctlyAnsweredPasser) {
        updatedPlayers[pIdx] = currentPlayer.copyWith(money: currentPlayer.money - station.baseRent);
        resultMsg = "${currentPlayer.name} خسر التحدي مع ${station.name}! دفع غرامة ${station.baseRent}";
      } else resultMsg = "${currentPlayer.name} مر بـ ${station.name} بسلام";
    } else if (bought && station.id != null) {
        if (currentPlayer.money >= station.buyPrice) {
           updatedPlayers[pIdx] = currentPlayer.copyWith(money: currentPlayer.money - station.buyPrice, ownedStationIds: [...currentPlayer.ownedStationIds, station.id!]);
           resultMsg = "مبروك ${currentPlayer.name}! اشتريت ${station.name}";
           _addLog("${currentPlayer.name} اشترى ${station.name} بـ ${station.buyPrice} P", type: LogType.purchase, playerIndex: pIdx, amount: station.buyPrice);
        } else resultMsg = "لا تملك رصيداً كافياً لشراء ${station.name}";
    } else if (ownerIdx != null && ownerIdx != pIdx) {
        double rent = station.baseRent > 0 ? station.baseRent : (station.buyPrice * 0.2);
        for (var b in station.buildings) if (b.isPurchased) rent += b.additionalRent;
        if (tookPasserQuestion && correctlyAnsweredPasser) rent = (rent / 2).floorToDouble();
        updatedPlayers[pIdx] = updatedPlayers[pIdx].copyWith(money: updatedPlayers[pIdx].money - rent);
        updatedPlayers[ownerIdx] = updatedPlayers[ownerIdx].copyWith(money: updatedPlayers[ownerIdx].money + rent);
        resultMsg = "${currentPlayer.name} دفع إيجار $rent لـ ${state.players[ownerIdx].name}";
        _addLog("${currentPlayer.name} دفع إيجار $rent لـ ${state.players[ownerIdx].name} في ${station.name}", type: LogType.moneyRemove, playerIndex: pIdx, amount: rent);
    } else if (ownerIdx == pIdx) {
       resultMsg = "${currentPlayer.name} في مدينته ${station.name}";
    } else resultMsg = "تم المرور بـ ${station.name}";

    state = state.copyWith(players: updatedPlayers, clearPendingLandingStation: true, message: resultMsg, isEndingTurn: true);
    if (state.settings.bankruptcyEnabled && updatedPlayers[pIdx].money <= 0) {
       if (_checkBankruptcy(pIdx)) return;
    }
    
    if (!skipAutoNextTurn) {
        _scheduleAutoNextTurn();
    }
    _saveState();
  }

  void _scheduleAutoNextTurn() {
    _turnTimer?.cancel();
    _turnTimer = Timer(const Duration(milliseconds: 300), () => nextTurn());
  }

  void nextTurn() {
    _turnTimer?.cancel();
    if (state.isGameOver || state.isMovingPlayer || state.isRollingDice || state.pendingLandingStation != null) {
       state = state.copyWith(isEndingTurn: false);
       return;
    }

    if (state.settings.loansEnabled) _processLoans();
    
    if (state.settings.bankruptcyEnabled) {
      final player = state.players[state.currentPlayerIndex];
      if (player.money <= 0) {
        if (_checkBankruptcy(state.currentPlayerIndex)) return;
        if (state.players[state.currentPlayerIndex].money <= 0) {
          state = state.copyWith(message: "رصيد ${player.name} هو ${player.money.toInt()}! يجب بيع ممتلكاتك أولاً.", isEndingTurn: true);
          return;
        }
      }
    }

    if (state.settings.winCondition == WinningCondition.time && state.startTime != null) {
      if (DateTime.now().difference(state.startTime!).inMinutes >= state.settings.maxTimeMinutes) {
        endGame();
        return;
      }
    }

    if (state.settings.winCondition == WinningCondition.rounds) {
       if (state.players.every((p) => p.lapsCompleted >= state.settings.maxRounds)) {
         endGame();
         return;
       }
    }

    int nextIndex = (state.currentPlayerIndex + 1) % state.players.length;
    if (state.settings.winCondition == WinningCondition.rounds) {
       int start = nextIndex;
       while (state.players[nextIndex].lapsCompleted >= state.settings.maxRounds) {
         nextIndex = (nextIndex + 1) % state.players.length;
         if (nextIndex == start) { endGame(); return; }
       }
    }

    final nextPlayer = state.players[nextIndex];
    if (nextPlayer.skipNextTurn) {
       final updatedPlayers = [for (var p in state.players) p];
       updatedPlayers[nextIndex] = nextPlayer.copyWith(skipNextTurn: false);
       state = state.copyWith(players: updatedPlayers, currentPlayerIndex: nextIndex, message: "تخطى ${nextPlayer.name} دوره", isEndingTurn: true);
       _turnTimer = Timer(const Duration(milliseconds: 500), () => nextTurn());
       return;
    }

    state = state.copyWith(
      players: state.players,
      currentPlayerIndex: nextIndex,
      isEndingTurn: false,
      message: "دور ${state.players[nextIndex].name}",
      clearPendingLandingStation: true,
      turnRemainingSeconds: state.settings.turnTimerEnabled ? state.settings.turnTimerSeconds : 0,
    );
    
    _saveState();
    _startTurnTimer();
  }

  void _startTurnTimer() {
    _turnTimer?.cancel();
    if (!state.settings.turnTimerEnabled || state.isGameOver) return;

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isGameOver) {
        timer.cancel();
        return;
      }
      
      if (state.turnRemainingSeconds > 0) {
        state = state.copyWith(turnRemainingSeconds: state.turnRemainingSeconds - 1);
      } else {
        timer.cancel();
        _addLog("انتهى وقت الدور لـ ${state.players[state.currentPlayerIndex].name}", type: LogType.info);
        forceNextTurn();
      }
    });
  }

  Future<void> buyBuilding(int stationId, int buildingIdx) async {
    final station = state.board.firstWhere((s) => s.id == stationId);
    if (buildingIdx >= station.buildings.length) return;
    final building = station.buildings[buildingIdx];
    if (building.isPurchased) return;
    
    final pIdx = state.players.indexWhere((p) => p.ownedStationIds.contains(stationId));
    if (pIdx == -1) return;
    
    final owner = state.players[pIdx];
    if (owner.money < building.buyPrice) {
      state = state.copyWith(message: "ليس لدى ${owner.name} رصيد كافي לבناء ${building.name}");
      return;
    }
    final updatedBuildings = [...station.buildings];
    updatedBuildings[buildingIdx] = updatedBuildings[buildingIdx].copyWith(isPurchased: true);
    final updatedBoard = state.board.map((s) => s.id == stationId ? s.copyWith(buildings: updatedBuildings) : s).toList();
    final updatedPlayers = [...state.players];
    updatedPlayers[pIdx] = owner.copyWith(money: owner.money - building.buyPrice);
    state = state.copyWith(board: updatedBoard, players: updatedPlayers, message: "${owner.name} بنى ${building.name} في ${station.name}!");
    _addLog("${owner.name} بنى ${building.name} في ${station.name} بـ ${building.buyPrice} P", type: LogType.purchase, playerIndex: pIdx, amount: building.buyPrice);
    _saveState();
  }

  Future<void> lendToPlayer(int fromIdx, int toIdx, double amount) async {
    if (amount <= 0 || fromIdx == toIdx) return;
    final sender = state.players[fromIdx], receiver = state.players[toIdx];
    final interestRate = state.currentCheckInterest;
    final totalToDeduct = amount * (1 + interestRate);
    if (sender.money < totalToDeduct) return;
    final updatedPlayers = [...state.players];
    updatedPlayers[fromIdx] = sender.copyWith(money: sender.money - totalToDeduct);
    updatedPlayers[toIdx] = receiver.copyWith(money: receiver.money + amount);
    state = state.copyWith(players: updatedPlayers, currentCheckInterest: state.currentCheckInterest + state.settings.checkInterestIncrement, message: "${sender.name} حول ${amount.toInt()} P لـ ${receiver.name}");
    _addLog("${sender.name} حول ${amount.toInt()} P لـ ${receiver.name}", type: LogType.moneyRemove, playerIndex: fromIdx, amount: totalToDeduct);
    _saveState();
  }

  void _payoutCertificates(int playerIndex, {bool isPerStation = false, bool isPerCycle = false, bool isCityPassed = true}) {
    final player = state.players[playerIndex];
    if (player.activeCertificates.isEmpty) return;
    List<BankAlHazCertificate> updatedCerts = [];
    double totalPayout = 0;
    int cityCount = state.board.where((s) => s.type == StationType.property || s.type == StationType.question).length;
    if (cityCount == 0) cityCount = 12;

    for (var cert in player.activeCertificates) {
      double payout = 0;
      int newCycles = cert.cyclesCompleted;
      if (isPerCycle) {
        newCycles++;
        if (state.settings.certificatePayoutMode == CertificatePayoutMode.perCycle) payout += cert.principal * (1 + cert.interestRate);
      }
      if (isPerStation && isCityPassed && state.settings.certificatePayoutMode == CertificatePayoutMode.perStation) {
        payout += (cert.principal * (1 + cert.interestRate)) / cityCount;
      }
      totalPayout += payout;
      if (isPerCycle && newCycles >= cert.totalCycles) {
        totalPayout += cert.principal;
      } else {
        updatedCerts.add(cert.copyWith(cyclesCompleted: newCycles));
      }
    }
    if (totalPayout > 0) {
      final newPlayers = [for (var p in state.players) p];
      newPlayers[playerIndex] = player.copyWith(money: player.money + totalPayout, activeCertificates: updatedCerts);
      state = state.copyWith(players: newPlayers);
      _addLog("فائدة الشهادات لـ ${player.name}: ${totalPayout.toInt()} P", type: LogType.moneyAdd, playerIndex: playerIndex, amount: totalPayout);
    }
  }

  void _applyInflation() {
    final multiplier = 1.0 + state.settings.inflationRate;
    final newBoard = state.board.map((s) => s.id == null ? s : s.copyWith(
      buyPrice: s.buyPrice * multiplier, baseRent: s.baseRent * multiplier,
      buildings: s.buildings.map((b) => b.copyWith(buyPrice: b.buyPrice * multiplier, additionalRent: b.additionalRent * multiplier)).toList(),
    )).toList();
    state = state.copyWith(board: newBoard, settings: state.settings.copyWith(loanInterestRate: state.settings.loanInterestRate * multiplier, salaryPerLap: state.settings.salaryPerLap * multiplier), message: "⚠️ تضخم! ارتفعت الأسعار!");
    _saveState();
  }

  void buyCertificate(double amount) {
    final player = state.players[state.currentPlayerIndex];
    if (player.money < amount) return;
    final newCert = BankAlHazCertificate(principal: amount, interestRate: state.settings.certificateInterestRate, totalCycles: state.settings.certificateCycles, purchaseTime: DateTime.now());
    final newPlayers = [for (var p in state.players) p];
    newPlayers[state.currentPlayerIndex] = player.copyWith(money: player.money - amount, activeCertificates: [...player.activeCertificates, newCert]);
    state = state.copyWith(players: newPlayers, message: "تم شراء شهادة بمبلغ ${amount.toInt()} P");
    _saveState();
  }

  Future<void> sellStation(int stationId) async {
    final sIdx = state.board.indexWhere((s) => s.id == stationId);
    if (sIdx == -1) return;
    final station = state.board[sIdx];
    final pIdx = state.players.indexWhere((p) => p.ownedStationIds.contains(stationId));
    if (pIdx == -1) return;
    double val = station.buyPrice;
    for (var b in station.buildings) if (b.isPurchased) val += b.buyPrice;
    double price = val / 2;
    final updatedPlayers = [...state.players];
    updatedPlayers[pIdx] = updatedPlayers[pIdx].copyWith(money: updatedPlayers[pIdx].money + price, ownedStationIds: updatedPlayers[pIdx].ownedStationIds.where((id) => id != stationId).toList());
    final updatedBoard = [...state.board];
    updatedBoard[sIdx] = updatedBoard[sIdx].copyWith(buildings: updatedBoard[sIdx].buildings.map((b) => b.copyWith(isPurchased: false)).toList(), hasTax: false);
    state = state.copyWith(players: updatedPlayers, board: updatedBoard);
    _saveState();
  }

  void toggleStationTax(int stationId) {
    final updatedBoard = state.board.map((s) => s.id == stationId ? s.copyWith(hasTax: !s.hasTax, taxAmount: !s.hasTax ? (s.buyPrice * 0.15) : 0) : s).toList();
    state = state.copyWith(board: updatedBoard);
    _saveState();
  }

  Future<void> endGame() async {
    _turnTimer?.cancel();
    _gameDurationTimer?.cancel();
    if (state.players.isEmpty) return;
    double maxScore = -1;
    List<int> winners = [];
    for (int i = 0; i < state.players.length; i++) {
      double score = state.players[i].money;
      if (state.settings.winCriteria != WinCriteria.moneyOnly) {
         for (var sid in state.players[i].ownedStationIds) {
           final s = state.board.firstWhere((st) => st.id == sid);
           score += s.buyPrice;
           if (state.settings.winCriteria == WinCriteria.cumulativeValue) for (var b in s.buildings) if (b.isPurchased) score += b.buyPrice;
         }
      }
      if (score > maxScore) { maxScore = score; winners = [i]; } else if (score == maxScore) winners.add(i);
    }
    if (winners.isNotEmpty) {
      state = state.copyWith(isGameOver: true, winnerIndex: winners.length == 1 ? winners.first : null, message: "انتهت اللعبة! الفائز بـ ${maxScore.toInt()} P");
      final teams = await ref.read(teamsListProvider.future);
      for (int wIdx in winners) {
        final winner = state.players[wIdx];
        final team = teams.firstWhere((t) => t.name == winner.name, orElse: () => teams.first);
        if (team.id != null) await ref.read(teamsListProvider.notifier).updateScore(team.id!, state.settings.winPoints);
      }
    }
    clearSavedGame();
  }

  bool _checkBankruptcy(int pIdx) {
    final p = state.players[pIdx];
    if (p.money > 0) return false;
    if (p.ownedStationIds.isEmpty) { _eliminatePlayer(pIdx); return true; }
    state = state.copyWith(message: "رصيد ${p.name} سالب! يجب بيع الممتلكات.");
    return false;
  }

  void _eliminatePlayer(int pIdx) {
    final p = state.players[pIdx];
    final newBoard = state.board.map((s) => p.ownedStationIds.contains(s.id) ? s.copyWith(buildings: s.buildings.map((b) => b.copyWith(isPurchased: false)).toList(), hasTax: false) : s).toList();
    final newPlayers = state.players.where((pl) => pl.id != p.id).toList();
    state = state.copyWith(players: newPlayers, board: newBoard, message: "خرج ${p.name} من اللعبة!");
    if (newPlayers.length <= 1) endGame(); else nextTurn();
  }

  void addGameLog(String message, {LogType type = LogType.info, int? playerIndex, double? amount}) {
    final newLog = GameLog(
      timestamp: DateTime.now(),
      message: message,
      type: type,
      playerIndex: playerIndex,
      amount: amount,
    );
    state = state.copyWith(logs: [newLog, ...state.logs]);
    _saveState();
  }

  void restartGame() {
    if (state.players.isEmpty) return;
    initGame(state.players.map((p) => p.name).toList(), state.settings);
  }

  Future<void> sellStationToPlayer(int sId, int bIdx, double price) async {
    final sIdx = state.players.indexWhere((p) => p.ownedStationIds.contains(sId));
    if (sIdx == -1 || bIdx == -1 || state.players[bIdx].money < price) return;
    final newPlayers = state.players.map((p) {
      if (state.players.indexOf(p) == sIdx) return p.copyWith(money: p.money + price, ownedStationIds: p.ownedStationIds.where((id) => id != sId).toList());
      if (state.players.indexOf(p) == bIdx) return p.copyWith(money: p.money - price, ownedStationIds: [...p.ownedStationIds, sId]);
      return p;
    }).toList();
    state = state.copyWith(players: newPlayers);
    _saveState();
  }

  void sellStationToBank(int sId, [double? price]) {
    final sIdx = state.players.indexWhere((p) => p.ownedStationIds.contains(sId));
    if (sIdx == -1) return;
    final station = state.board.firstWhere((s) => s.id == sId);
    double amt = price ?? (station.buyPrice / 2);
    if (price == null) for (var b in station.buildings) if (b.isPurchased) amt += b.buyPrice / 2;
    final newPlayers = [...state.players];
    newPlayers[sIdx] = newPlayers[sIdx].copyWith(money: newPlayers[sIdx].money + amt, ownedStationIds: newPlayers[sIdx].ownedStationIds.where((id) => id != sId).toList());
    final newBoard = state.board.map((s) => s.id == sId ? s.copyWith(buildings: s.buildings.map((b) => b.copyWith(isPurchased: false)).toList(), hasTax: false) : s).toList();
    state = state.copyWith(players: newPlayers, board: newBoard);
    _checkBankruptcy(sIdx);
    _saveState();
  }

  Future<void> takeLoan(double amt, int dur) async {
    final player = state.players[state.currentPlayerIndex];
    final loan = Loan(amountBorrowed: amt, amountToRepay: amt * (1 + state.settings.loanInterestRate), remainingTurns: dur, startTurn: state.totalTurns);
    final newPlayers = [...state.players];
    newPlayers[state.currentPlayerIndex] = player.copyWith(money: player.money + amt, activeLoans: [...player.activeLoans, loan]);
    state = state.copyWith(players: newPlayers);
    _saveState();
  }

  void repayLoan(int idx) {
    final p = state.players[state.currentPlayerIndex];
    final loan = p.activeLoans[idx];
    if (p.money < loan.amountToRepay) return;
    final newLoans = [...p.activeLoans]..removeAt(idx);
    final newPlayers = [...state.players];
    newPlayers[state.currentPlayerIndex] = p.copyWith(money: p.money - loan.amountToRepay, activeLoans: newLoans);
    state = state.copyWith(players: newPlayers);
    _saveState();
  }

  void _processLoans() {
    final p = state.players[state.currentPlayerIndex];
    if (p.activeLoans.isEmpty) return;
    final newLoans = <Loan>[];
    double total = 0;
    bool expired = false;
    for (var l in p.activeLoans) {
      if (l.remainingTurns <= 1) { total += l.amountToRepay; expired = true; }
      else newLoans.add(l.copyWith(remainingTurns: l.remainingTurns - 1));
    }
    if (expired) {
      final newPlayers = [...state.players];
      newPlayers[state.currentPlayerIndex] = p.copyWith(money: p.money - total, activeLoans: newLoans);
      state = state.copyWith(players: newPlayers);
      _checkBankruptcy(state.currentPlayerIndex);
    } else {
      final newPlayers = [...state.players];
      newPlayers[state.currentPlayerIndex] = p.copyWith(activeLoans: newLoans);
      state = state.copyWith(players: newPlayers);
    }
  }

  Future<void> saveCurrentSetupAsTemplate(String name) async {
    final repo = ref.read(bankAlHazRepositoryProvider);
    final id = await repo.saveTemplate(BankAlHazTemplate(name: name));
    await repo.deleteAllStations(templateId: id);
    for (var s in state.board) await repo.addStation(s.copyWith(buildings: s.buildings.map((b) => b.copyWith(isPurchased: false)).toList(), hasTax: false), templateId: id);
    ref.invalidate(templatesProvider);
  }

}

final gameEngineProvider = NotifierProvider<GameEngine, GameState>(GameEngine.new);
