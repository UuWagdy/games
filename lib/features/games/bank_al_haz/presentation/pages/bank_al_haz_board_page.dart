import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bank_al_haz_entities.dart';
import '../providers/game_engine_provider.dart';
import '../providers/bank_al_haz_providers.dart';
import '../providers/bank_al_haz_template_seeder.dart';
import '../../../../teams/presentation/providers/team_providers.dart';
import '../widgets/three_d_dice.dart';
import '../widgets/player_piece.dart';
import '../../../../questions/domain/entities/question.dart';
import '../../../../teams/presentation/pages/teams_management_page.dart';
import '../../../../settings/presentation/pages/settings_page.dart';
import 'dart:math' as math;
import 'dart:async';

enum _StationAction { buy, passerQuestion, pass }

class BankAlHazBoardPage extends ConsumerStatefulWidget {
  const BankAlHazBoardPage({super.key});

  @override
  ConsumerState<BankAlHazBoardPage> createState() => _BankAlHazBoardPageState();
}

class _BankAlHazBoardPageState extends ConsumerState<BankAlHazBoardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _boardRevealController;
  Timer? _gameTimer;
  Timer? _pendingLandingTimer;
  String _timeElapsedStr = "00:00";
  bool _isHandlingLanding = false;

  @override
  void initState() {
    super.initState();
    _boardRevealController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();
    _startGameTimer();
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final startTime = ref.read(gameEngineProvider).startTime;
      if (startTime != null) {
        final duration = DateTime.now().difference(startTime);
        final mins = duration.inMinutes.toString().padLeft(2, '0');
        final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
        if (mounted) setState(() => _timeElapsedStr = "$mins:$secs");
      }
    });
  }

  @override
  void dispose() {
    _boardRevealController.dispose();
    _gameTimer?.cancel();
    _pendingLandingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameEngineProvider);
    final engine = ref.read(gameEngineProvider.notifier);

    if (gameState.board.isEmpty) return _buildPreparationScreen(context, ref);

    // Sync players if teams list changes (newly added teams)
    ref.listen(teamsListProvider, (prev, next) {
      next.whenData((teams) {
        final names = teams.map((t) => t.name).toList();
        ref.read(gameEngineProvider.notifier).syncPlayers(names);
      });
    });

    // Listen for landing — use Timer to guarantee clean event loop
    ref.listen<Station?>(
      gameEngineProvider.select((s) => s.pendingLandingStation),
      (prev, next) {
        if (next != null && !_isHandlingLanding) {
          _isHandlingLanding = true;
          // Cancel any pending timer
          _pendingLandingTimer?.cancel();
          // Timer fires in next event loop turn — GUARANTEED outside
          // any frame processing, pointer events, or mouse tracker updates
          _pendingLandingTimer = Timer(const Duration(milliseconds: 200), () {
            if (mounted) _startLandingFlow(next);
          });
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildFloatingHeader(gameState),
            Expanded(
              child: FadeTransition(
                opacity: _boardRevealController,
                child: _buildBoard(gameState, engine),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== LANDING FLOW ====================

  void _startLandingFlow(Station station) async {
    final engine = ref.read(gameEngineProvider.notifier);
    try {
      if (station.type == StationType.card) {
        await _handleCardLanding(station, engine);
      } else if (station.type == StationType.none) {
        // Auto-resolve non-action stations
        engine.resolveLanding();
      } else {
        await _handleStationLanding(station, engine);
      }
    } catch (e) {
      print("Landing flow error: $e");
      if (mounted) engine.resolveLanding();
    }
    _isHandlingLanding = false;
  }

  Future<void> _handleCardLanding(Station station, GameEngine engine) async {
    final card = await engine.drawCard(station.cardType);
    if (card == null || !mounted) {
      engine.resolveLanding();
      return;
    }
    await _showCardDialog(card);
    // Small delay after dialog closes to let Flutter finish cleanup
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) engine.applyCardEffect(card);
  }

  Future<void> _handleStationLanding(Station station, GameEngine engine) async {
    final action = await _showStationDialog(station);
    // Small delay after dialog closes
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    switch (action) {
      case _StationAction.buy:
        if (station.requiresQuestion) {
          final q = await engine.getRandomQuestion(station.ownerCategoryId);
          if (q != null && mounted) {
            final correct = await _showQuestionDialog(q);
            await Future.delayed(const Duration(milliseconds: 150));
            if (mounted) engine.resolveLanding(bought: correct);
          } else {
            if (mounted) engine.resolveLanding(bought: true);
          }
        } else {
          engine.resolveLanding(bought: true);
        }
        break;
      case _StationAction.passerQuestion:
        if (station.requiresQuestion) {
          final q = await engine.getRandomQuestion(station.passerCategoryId);
          if (q != null && mounted) {
            final correct = await _showQuestionDialog(q);
            await Future.delayed(const Duration(milliseconds: 150));
            if (mounted) {
              engine.resolveLanding(
                tookPasserQuestion: true,
                correctlyAnsweredPasser: correct,
              );
            }
          } else {
            if (mounted) engine.resolveLanding();
          }
        } else {
          engine.resolveLanding();
        }
        break;
      case _StationAction.pass:
        engine.resolveLanding();
        break;
    }
  }

  // ==================== DIALOGS (via Navigator) ====================

  Future<_StationAction> _showStationDialog(Station station) async {
    final gameState = ref.read(gameEngineProvider);
    final currentPlayer = gameState.players[gameState.currentPlayerIndex];
    String? ownerName;
    for (var p in gameState.players) {
      if (p.ownedStationIds.contains(station.id)) {
        ownerName = p.name;
        break;
      }
    }
    final bool isOwned = ownerName != null;
    final bool isOwner = ownerName == currentPlayer.name;
    final bool canBuy = !isOwned && currentPlayer.money >= station.buyPrice;

    final result = await showGeneralDialog<_StationAction>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, a1, a2, child) {
        return FadeTransition(
          opacity: a1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogCtx, _, _) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade800, Colors.blue.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          station.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isOwned)
                          Text(
                            "مالك المدينة: $ownerName",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (station.imageData != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.memory(
                              station.imageData!,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          const Icon(
                            Icons.location_city,
                            size: 60,
                            color: Colors.blueGrey,
                          ),
                        const SizedBox(height: 24),
                        _statRow(
                          Icons.payments,
                          "ثمن الشراء",
                          "${station.buyPrice} P",
                          Colors.green,
                        ),
                        const Divider(height: 20),
                        _statRow(
                          Icons.home,
                          station.isUnbuyable
                              ? "غرامة التحدي"
                              : "الإيجار الأساسي",
                          "${station.baseRent} P",
                          Colors.orange,
                        ),
                        const SizedBox(height: 32),
                        if (station.isUnbuyable) ...[
                          const Text(
                            "هذه الشخصية غير قابلة للشراء، يمكنك تحديها للفوز أو دفع غرامة",
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.pop(dialogCtx, _StationAction.buy),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              icon: const Icon(Icons.psychology),
                              label: const Text(
                                'تحدي الشخصية (سؤال)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogCtx, _StationAction.pass),
                            child: const Text("مرور بسلام"),
                          ),
                        ] else if (isOwner) ...[
                          const Text(
                            "أنت تمتلك هذه المدينة بالفعل!",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogCtx, _StationAction.pass),
                            child: const Text("إغلاق"),
                          ),
                        ] else if (isOwned) ...[
                          const Text(
                            "ستدخل تحدي المار لتقليل الإيجار",
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(
                                dialogCtx,
                                _StationAction.passerQuestion,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                'بدء تحدي المار (سؤال)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: canBuy
                                      ? () => Navigator.pop(
                                          dialogCtx,
                                          _StationAction.buy,
                                        )
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    'شراء (سؤال مالك)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(
                                    dialogCtx,
                                    _StationAction.pass,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    'مرور (بدون سؤال)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!canBuy)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                "نقاطك لا تكفي للشراء",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return result ?? _StationAction.pass;
  }

  Future<bool> _showQuestionDialog(Question question) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, a1, a2, child) {
        return FadeTransition(
          opacity: a1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogCtx, _, _) =>
          _QuestionDialogContent(question: question),
    );
    return result ?? false;
  }

  Future<void> _showCardDialog(BankAlHazCard card) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, a1, a2, child) {
        return FadeTransition(
          opacity: a1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: a1, curve: Curves.elasticOut),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogCtx, _, _) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade900,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: card.type == 'chance'
                      ? Colors.amber
                      : Colors.blueAccent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "كارت ${card.type == 'chance' ? 'حظك اليوم' : 'المحكمة'}",
                    style: TextStyle(
                      color: card.type == 'chance'
                          ? Colors.amber
                          : Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (card.imageData != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.memory(
                        card.imageData!,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (card.imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        card.imagePath!,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.auto_awesome,
                          color: Colors.white24,
                          size: 60,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white24,
                      size: 60,
                    ),
                  const SizedBox(height: 20),
                  Text(
                    card.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    card.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: card.type == 'chance'
                          ? Colors.amber
                          : Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "موافق",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: Colors.blueGrey),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ==================== HEADER ====================

  Widget _buildFloatingHeader(GameState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              IconButton(
                icon: const Icon(Icons.group_add, color: Colors.blueAccent, size: 22),
                tooltip: 'إدارة الفرق',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeamsManagementPage()),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70, size: 22),
                tooltip: 'الإعدادات',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
              ),
              const SizedBox(width: 8),
              _buildDynamicStat(
                Icons.timer_outlined,
                _timeElapsedStr,
                Colors.amber,
              ),
              const SizedBox(width: 15),
              _buildDynamicStat(
                Icons.history,
                "الدورات: ${state.totalTurns}",
                Colors.blueAccent,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
            onPressed: () => _restartGamePrompt(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicStat(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOARD ====================
  // KEY FIX: All non-interactive elements wrapped in IgnorePointer
  // so the MouseTracker never tracks them during animations/rebuilds.

  Widget _buildBoard(GameState state, GameEngine engine) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availWidth = constraints.maxWidth;
        final double availHeight = constraints.maxHeight;
        final bool isWideScreen = availWidth > 800;
        // On wide screens, use full width; on smaller, keep square
        final double boardSize = isWideScreen
            ? math.min(availWidth * 0.96, availHeight * 0.96)
            : math.min(availWidth, availHeight) * 0.96;
        int total = state.board.length;
        if (total == 0) return const SizedBox.shrink();

        int pPlus4 = total + 4;
        int sumSides = (pPlus4 / 2).floor();
        int widthCells = (sumSides / 2).ceil();
        int heightCells = sumSides - widthCells;
        if (2 * (widthCells + heightCells) - 4 < total) widthCells++;

        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Center area — HAS interactive buttons, but dice is IgnorePointer
                _buildCenterArea(boardSize, state, engine),
                // Station cells — purely visual, wrapped in IgnorePointer
                IgnorePointer(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (int i = 0; i < total; i++)
                        _buildStationCell(
                          i,
                          state.board[i],
                          boardSize,
                          widthCells,
                          heightCells,
                        ),
                    ],
                  ),
                ),
                // Player pieces — animated, wrapped in IgnorePointer
                IgnorePointer(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (int pIdx = 0; pIdx < state.players.length; pIdx++)
                        _buildAnimatedPlayerPiece(
                          pIdx,
                          state,
                          boardSize,
                          widthCells,
                          heightCells,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterArea(
    double boardSize,
    GameState gameState,
    GameEngine engine,
  ) {
    bool isLock =
        gameState.isMovingPlayer ||
        gameState.isRollingDice ||
        gameState.isEndingTurn;
    bool hasPending =
        gameState.pendingLandingStation != null || _isHandlingLanding;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IgnorePointer(
            child: Opacity(
              opacity: 0.04,
              child: Icon(
                Icons.directions_car_filled,
                size: boardSize * 0.18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (gameState.message.isNotEmpty)
            IgnorePointer(
              child: Container(
                width: boardSize * 0.7,
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  gameState.message,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: boardSize > 800 ? 45 : boardSize * 0.04,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                label: "نرد",
                icon: Icons.casino,
                active: !isLock && !hasPending,
                onTap: () => engine.rollDice(),
                color: Colors.orangeAccent,
                size: boardSize * 0.08,
              ),
              const SizedBox(width: 15),
              // Dice — IgnorePointer so rotating faces don't trigger MouseTracker
              // Dice — Interactive roll
              GestureDetector(
                onTap: (!isLock && !hasPending) ? () => engine.rollDice() : null,
                child: ThreeDDice(
                  value: gameState.currentDiceValue,
                  rollCounter: gameState.rollCounter,
                  onAnimationComplete: () {},
                ),
              ),
              const SizedBox(width: 15),
              _buildActionButton(
                label: "إنهاء",
                icon: Icons.check_circle,
                active: !isLock && !hasPending,
                onTap: () {
                  print("DEBUG: Finish button clicked! Forcing next turn.");
                  engine.forceNextTurn();
                },
                color: Colors.greenAccent,
                size: boardSize * 0.08,
              ),
            ],
          ),
          const SizedBox(height: 20),
          IgnorePointer(
            child: _buildInternalPlayerStatsBar(gameState, boardSize),
          ),
        ],
      ),
    );
  }

  Widget _buildInternalPlayerStatsBar(GameState state, double boardSize) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: state.players.asMap().entries.map((entry) {
          final isCurrent = state.currentPlayerIndex == entry.key;
          final p = entry.value;
          final color = [
            Colors.red,
            Colors.green,
            Colors.blue,
            Colors.orange,
          ][entry.key % 4];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isCurrent ? Colors.white.withOpacity(0.9) : Colors.white10,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrent ? color.withOpacity(0.5) : Colors.white10,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car, color: color, size: 12),
                const SizedBox(width: 5),
                Text(
                  "${p.name}: ${p.money.toInt()}",
                  style: TextStyle(
                    color: isCurrent ? Colors.black87 : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStationCell(
    int index,
    Station station,
    double boardSize,
    int wCount,
    int hCount,
  ) {
    final pos = _calculateRectOffset(index, wCount, hCount, boardSize);
    double cw = boardSize / wCount;
    double ch = boardSize / hCount;
    bool isCorner =
        index == 0 ||
        index == wCount - 1 ||
        index == wCount + hCount - 2 ||
        index == 2 * wCount + hCount - 3;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Container(
        width: cw,
        height: ch,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black26, width: 0.5),
        ),
        child: Column(
          children: [
            Container(
              height: ch * 0.22,
              color: isCorner ? Colors.grey.shade900 : _getCityColor(index),
              child: isCorner
                  ? const Center(
                      child: Icon(Icons.star, size: 12, color: Colors.amber),
                    )
                  : null,
            ),
            Expanded(
              child: Stack(
                children: [
                  if (station.imageData != null)
                    Opacity(
                      opacity: 0.15,
                      child: Image.memory(
                        station.imageData!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                        station.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900, // VERY BOLD
                          fontSize: ch * 0.24, // MUCH LARGER FONT
                          color: Colors.black87,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 1,
                              offset: const Offset(0.5, 0.5),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildOwnerIndicator(station, cw, ch, ref.read(gameEngineProvider)),
          ],
        ),
      ),
    );
  }

  Offset _calculateRectOffset(int index, int w, int h, double size) {
    double cw = size / w;
    double ch = size / h;
    if (index < w) return Offset(index * cw, 0);
    if (index < w + h - 1) return Offset(size - cw, (index - w + 1) * ch);
    if (index < 2 * w + h - 2) {
      return Offset(size - cw - (index - (w + h - 2)) * cw, size - ch);
    }
    return Offset(0, size - ch - (index - (2 * w + h - 3)) * ch);
  }

  Widget _buildOwnerIndicator(
    Station station,
    double cw,
    double ch,
    GameState state,
  ) {
    int? ownerIdx;
    for (int i = 0; i < state.players.length; i++) {
      if (state.players[i].ownedStationIds.contains(station.id)) {
        ownerIdx = i;
        break;
      }
    }
    if (ownerIdx == null) return Container(height: 3);
    return Container(
      height: 6,
      width: double.infinity,
      color: [
        Colors.red,
        Colors.green,
        Colors.blue,
        Colors.orange,
      ][ownerIdx % 4],
    );
  }

  Widget _buildAnimatedPlayerPiece(
    int index,
    GameState state,
    double boardSize,
    int w,
    int h,
  ) {
    final p = state.players[index];
    final pos = _calculateRectOffset(p.currentPosition, w, h, boardSize);
    double cw = boardSize / w;
    double ch = boardSize / h;
    final int r = index % 2, c = (index / 2).floor();
    // Calculate rotation and flip based on which side the player is on
    double rotation = 0;
    bool flip = false;
    int idx = p.currentPosition;
    if (idx < w) {
      rotation = 0; // Top - Moving Left
    } else if (idx < w + h - 1) {
      rotation = -math.pi / 2; // Left side - Facing Down
    } else if (idx < 2 * w + h - 2) {
      rotation = 0; // Bottom - Faces Left normally, we flip it to face Right
      flip = true;
    } else {
      rotation = math.pi / 2; // Right side - Facing Up
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      left: pos.dx + (cw * 0.2 + (r * cw * 0.3)) - 25,
      top: pos.dy + (ch * 0.4 + (c * ch * 0.15)) - 15,
      child: PlayerPiece(
        color: [
          Colors.red,
          Colors.green,
          Colors.blue,
          Colors.orange,
        ][index % 4],
        label: (state.currentPlayerIndex == index) ? p.name : '',
        isMoving: state.isMovingPlayer && state.currentPlayerIndex == index,
        rotation: rotation,
        flip: flip,
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    required Color color,
    required double size,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: active ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.all(size * 0.25),
            decoration: BoxDecoration(
              color: active ? color : Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? Colors.white38 : Colors.transparent,
              ),
            ),
            child: Icon(
              icon,
              color: active ? Colors.black87 : Colors.white24,
              size: size,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  // ==================== PREPARATION & RESTART ====================

  Widget _buildPreparationScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 64),
            const SizedBox(height: 24),
            const Text(
              "اللوحة فارغة!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "يمكنك البدء بالقالب الديني الجاهز أو إضافة مدن مخصصة.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome, color: Colors.amber),
              label: const Text(
                'العب باستخدام القالب الديني ✨',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () => _restartGamePrompt(context, ref),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.location_city, color: Colors.white70),
              label: const Text(
                'إضافة مدن مخصصة',
                style: TextStyle(color: Colors.white70),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _restartGamePrompt(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 10),
            Text("تطبيق القالب الديني؟", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          "سيتم توزيع مدن العهد القديم والجديد (22 محطة) لتشكيل اللوحة الجديدة. سيتم تصفير اللعبة الحالية.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await BankAlHazTemplateSeeder(ref).seedGame();
                await Future.delayed(const Duration(milliseconds: 600));
                ref.invalidate(gameEngineProvider);
                ref.invalidate(stationsProvider);
                ref.invalidate(cardsProvider);
                final teams = await ref.read(teamsListProvider.future);
                final settings = await ref.read(gameSettingsProvider.future);
                if (teams.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "يرجى إضافة فرق أولاً من القائمة الرئيسية",
                        ),
                      ),
                    );
                  }
                  return;
                }
                await ref
                    .read(gameEngineProvider.notifier)
                    .initGame(teams.map((t) => t.name).toList(), settings);
              } catch (e) {
                print("Error: $e");
              }
            },
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );
  }

  Color _getCityColor(int index) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.pink,
    ];
    return colors[(index / 2).floor() % colors.length].shade400;
  }
}

// ==================== QUESTION DIALOG (Wheel-game style) ====================
// Shows question + options → "إظهار الإجابة" → correct/incorrect buttons

class _QuestionDialogContent extends StatefulWidget {
  final Question question;
  const _QuestionDialogContent({required this.question});

  @override
  State<_QuestionDialogContent> createState() => _QuestionDialogContentState();
}

class _QuestionDialogContentState extends State<_QuestionDialogContent> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.blue.shade100, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.quiz_outlined,
                          size: 20,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'سؤال التحدي',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Question text
                  Text(
                    widget.question.text,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Options display (only for multipleChoice)
                  if (widget.question.type == QuestionType.multipleChoice &&
                      widget.question.options != null &&
                      widget.question.options!.isNotEmpty)
                    ...widget.question.options!.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final opt = entry.value;
                      final isCorrectOpt =
                          widget.question.correctOptionIndices?.contains(idx) ??
                          false;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _showAnswer && isCorrectOpt
                                ? Colors.green.shade50
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _showAnswer && isCorrectOpt
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              width: _showAnswer && isCorrectOpt ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _showAnswer && isCorrectOpt
                                      ? Colors.green
                                      : Colors.grey.shade300,
                                ),
                                child: Center(
                                  child: Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _showAnswer && isCorrectOpt
                                          ? Colors.white
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  opt,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: _showAnswer && isCorrectOpt
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _showAnswer && isCorrectOpt
                                        ? Colors.green.shade700
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (_showAnswer && isCorrectOpt)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      );
                    }),

                  // True/False display
                  if (widget.question.type == QuestionType.trueFalse)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTFChip(
                          "صح",
                          true,
                          widget.question.tfValue == true,
                        ),
                        const SizedBox(width: 16),
                        _buildTFChip(
                          "خطأ",
                          false,
                          widget.question.tfValue == false,
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Show answer section
                  if (_showAnswer) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'الإجابة الصحيحة:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.question.answer,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action buttons
                  if (!_showAnswer)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _showAnswer = true),
                        icon: const Icon(Icons.visibility),
                        label: const Text(
                          'إظهار الإجابة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                  if (_showAnswer)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context, true),
                            icon: const Icon(Icons.check_circle),
                            label: const Text(
                              'إجابة صحيحة',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context, false),
                            icon: const Icon(Icons.cancel),
                            label: const Text(
                              'إجابة خاطئة',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTFChip(String text, bool value, bool isCorrect) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _showAnswer && isCorrect
              ? Colors.green.shade50
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _showAnswer && isCorrect
                ? Colors.green
                : Colors.grey.shade300,
            width: _showAnswer && isCorrect ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _showAnswer && isCorrect
                    ? Colors.green.shade700
                    : Colors.black87,
              ),
            ),
            if (_showAnswer && isCorrect) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
