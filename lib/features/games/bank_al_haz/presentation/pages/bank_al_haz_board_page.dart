import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:games/features/games/bank_al_haz/domain/entities/bank_al_haz_entities.dart';
import 'package:games/features/games/bank_al_haz/presentation/providers/game_engine_provider.dart';
import 'package:games/features/games/bank_al_haz/presentation/providers/bank_al_haz_providers.dart';
import 'package:games/features/games/bank_al_haz/data/sources/bank_al_haz_default_data.dart';
import 'package:games/core/database/database_service.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import 'package:games/features/games/bank_al_haz/presentation/widgets/three_d_dice.dart';
import 'package:games/features/games/bank_al_haz/presentation/widgets/player_piece.dart';
import 'package:games/features/questions/domain/entities/question.dart';
import 'package:games/features/teams/presentation/pages/teams_management_page.dart';
import 'package:games/core/design/app_design.dart';
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
  GameLog? _currentEventLog;
  Timer? _eventClearTimer;

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
      final state = ref.read(gameEngineProvider);
      
      if (state.settings.winCondition == WinningCondition.time) {
         // Rebuild is already handled by GameEngine's state updates (remainingSeconds) every second.
         return;
      }
      
      final startTime = state.startTime;
      if (startTime != null) {
        final duration = DateTime.now().difference(startTime);
        final mins = duration.inMinutes.toString().padLeft(2, '0');
        final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
        if (mounted) setState(() => _timeElapsedStr = "$mins:$secs");
      }
    });
  }

  String _formatTime(int seconds) {
    if (seconds < 0) seconds = 0;
    final mins = (seconds / 60).floor().toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
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

    // Listen for important events from logs
    ref.listen<List<GameLog>>(
      gameEngineProvider.select((s) => s.logs),
      (prev, next) {
        if (next.isNotEmpty && (prev == null || next.length > prev.length)) {
          final lastLog = next.last;
          // Filter for money or purchase events
          if (lastLog.type == LogType.moneyAdd || lastLog.type == LogType.moneyRemove || lastLog.type == LogType.purchase) {
            _eventClearTimer?.cancel();
            if (mounted) {
              setState(() => _currentEventLog = lastLog);
              _eventClearTimer = Timer(const Duration(seconds: 4), () {
                if (mounted) setState(() => _currentEventLog = null);
              });
            }
          }
        }
      },
    );

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

    final bool isLock = gameState.isMovingPlayer || gameState.pendingLandingStation != null;
    final bool hasPending = gameState.pendingLandingStation != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      endDrawer: AppDesign.isSmallScreen(context) ? Drawer(
        backgroundColor: AppDesign.slate900,
        child: _buildMobileDrawer(gameState),
      ) : null,
      body: AppDesign.backgroundWrapper(
        child: Focus(
          autofocus: true,
          onKey: (node, event) {
            if (event is RawKeyDownEvent && 
                (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter)) {
              if (!isLock && !hasPending) {
                engine.rollDice();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildFloatingHeader(gameState, context),
                    Expanded(
                      child: FadeTransition(
                        opacity: _boardRevealController,
                        child: _buildBoard(gameState, engine),
                      ),
                    ),
                  ],
                ),
                
                // Game Over Overlay
                _buildGameOverOverlay(gameState, engine, context),

                // Removed old Positioned toast from here to move it inside _buildBoard for better dynamic positioning
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventToast(GameLog log) {
    bool isMobile = AppDesign.isSmallScreen(context);
    final playerColors = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple];
    final color = log.playerIndex != null 
        ? playerColors[log.playerIndex! % playerColors.length]
        : _getLogColor(log.type);
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, val, child) {
        return Transform.scale(
          scale: val,
          child: Opacity(
            opacity: val.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24, 
          vertical: isMobile ? 10 : 14
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: isMobile ? 12 : 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          child: Stack(
            children: [
              // Shine Effect Animation
              Positioned.fill(
                child: _ShineAnimation(color: color),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                     padding: EdgeInsets.all(isMobile ? 6 : 8),
                     decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                     ),
                     child: Icon(
                       _getLogIcon(log.type), 
                       color: color, 
                       size: isMobile ? 18 : 24
                     ),
                   ),
                   SizedBox(width: isMobile ? 10 : 16),
                   Expanded(
                     child: Text(
                        log.message,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 13 : 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                     ),
                   ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(GameState state) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue.shade900),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance, color: Colors.white, size: 48),
              SizedBox(height: 12),
              Text('بنك الحظ', style: AppDesign.titleStyle),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.timer, color: Colors.amberAccent),
          title: const Text('الوقت المنقضي', style: TextStyle(color: Colors.white)),
          trailing: Text(_timeElapsedStr, style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: const Icon(Icons.history, color: Colors.blueAccent),
          title: const Text('عدد الدورات', style: TextStyle(color: Colors.white)),
          trailing: Text('${state.totalTurns}', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        ),
        const Divider(color: Colors.white10),
        ListTile(
          leading: const Icon(Icons.group_add, color: Colors.greenAccent),
          title: const Text('إدارة الفرق', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamsManagementPage()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.inventory, color: Colors.greenAccent),
          title: const Text('ممتلكاتي', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            _showMyPropertiesDialog(context, state);
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings, color: Colors.white70),
          title: const Text('الإعدادات', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
          title: const Text('تطبيق القالب الديني', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            _restartGamePrompt(context, ref);
          },
        ),
        const Divider(color: Colors.white10),
        ListTile(
          leading: const Icon(Icons.stop_circle, color: Colors.redAccent),
          title: const Text('إنهاء اللعبة', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            _confirmEndGame();
          },
        ),
      ],
    );
  }

  void _confirmEndGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.slate800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('إنهاء اللعبة', style: AppDesign.titleStyle),
        content: const Text('هل أنت متأكد من إنهاء اللعبة الآن؟ سيتم احتساب إجمالي الثروة وتحديد الفائز', style: AppDesign.subtitleStyle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              ref.read(gameEngineProvider.notifier).endGame();
            },
            child: const Text('إنهاء'),
          ),
        ],
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
        bool bought = false;
        if (station.requiresQuestion) {
          final q = await engine.getRandomQuestion(station.ownerCategoryId);
          if (q != null && mounted) {
            bought = await _showQuestionDialog(q);
            await Future.delayed(const Duration(milliseconds: 150));
          } else {
            bought = true;
          }
        } else {
          bought = true;
        }
        
        if (mounted) {
           engine.resolveLanding(bought: bought, skipAutoNextTurn: bought);
           if (bought) {
             await _handlePostPurchaseFlow(station, engine);
             engine.forceNextTurn();
           }
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
        bool isSmall = AppDesign.isSmallScreen(dialogCtx);
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: AppDesign.dialogDecoration,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade900, Colors.blue.shade600],
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
                          style: AppDesign.titleStyle,
                        ),
                        if (isOwned)
                          Text(
                            "مالك المدينة: $ownerName",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
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
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          const Icon(
                            Icons.location_city,
                            size: 80,
                            color: Colors.white24,
                          ),
                        const SizedBox(height: 32),
                        _statRow(
                          Icons.payments,
                          "ثمن الشراء",
                          "${station.buyPrice} P",
                          Colors.greenAccent,
                        ),
                        const Divider(height: 32, color: Colors.white10),
                        _statRow(
                          Icons.home,
                          station.isUnbuyable ? "غرامة التحدي" : "الإيجار الأساسي",
                          "${station.baseRent} P",
                          Colors.amberAccent,
                        ),
                        const SizedBox(height: 40),
                        if (station.isUnbuyable) ...[
                          const Text(
                            "هذه الشخصية غير قابلة للشراء، يمكنك تحديها للفوز أو دفع غرامة",
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(dialogCtx, _StationAction.buy),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amberAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              icon: const Icon(Icons.psychology),
                              label: const Text(
                                'تحدي الشخصية (سؤال)',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, _StationAction.pass),
                            child: const Text("مرور بسلام", style: TextStyle(color: Colors.white70)),
                          ),
                        ] else if (isOwner) ...[
                          const Text(
                            "أنت تمتلك هذه المدينة بالفعل!",
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (station.buildings.isNotEmpty) ...[
                            const Text(
                              "المباني المتاحة:",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ...station.buildings.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final building = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      building.isPurchased ? Icons.check_circle : Icons.home_work,
                                      color: building.isPurchased ? Colors.greenAccent : Colors.white24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(building.name, style: const TextStyle(color: Colors.white)),
                                          Text(
                                            "الثمن: ${building.buyPrice} | إيجار إضافي: +${building.additionalRent}",
                                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!building.isPurchased)
                                      ElevatedButton(
                                        onPressed: currentPlayer.money >= building.buyPrice
                                            ? () async {
                                                await ref.read(gameEngineProvider.notifier).buyBuilding(station.id!, idx);
                                                Navigator.pop(dialogCtx, _StationAction.pass);
                                              }
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.greenAccent.shade700,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                        child: const Text("بناء", style: TextStyle(fontSize: 12)),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("تفعيل الضرائب", style: TextStyle(color: Colors.white)),
                                    Switch(
                                      value: station.hasTax,
                                      onChanged: (val) {
                                        ref.read(gameEngineProvider.notifier).toggleTax(station.id!, val);
                                        Navigator.pop(dialogCtx, _StationAction.pass);
                                      },
                                      activeColor: Colors.redAccent,
                                    ),
                                  ],
                                ),
                                if (station.hasTax) ...[
                                  const SizedBox(height: 8),
                                  TextField(
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: "قيمة الضرائب",
                                      hintStyle: const TextStyle(color: Colors.white24),
                                      prefixIcon: const Icon(Icons.money_off, color: Colors.redAccent),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onSubmitted: (val) {
                                      final amt = double.tryParse(val) ?? 0;
                                      ref.read(gameEngineProvider.notifier).setTaxAmount(station.id!, amt);
                                      Navigator.pop(dialogCtx, _StationAction.pass);
                                    },
                                    controller: TextEditingController(
                                      text: station.taxAmount > 0 ? station.taxAmount.toInt().toString() : "",
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "أي لاعب يمر بهذه المحطة سيدفع هذه القيمة",
                                    style: TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(dialogCtx);
                                _showSellDialog(
                                  context,
                                  station,
                                  gameState,
                                  ref.read(gameEngineProvider.notifier),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.sell),
                              label: const Text("بيع العقار (للبنك أو للاعب)"),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, _StationAction.pass),
                            child: const Text("إغلاق", style: TextStyle(color: Colors.white70)),
                          ),
                        ] else if (isOwned) ...[
                          const Text(
                            "ستدخل تحدي المار لتقليل الإيجار",
                            style: TextStyle(color: Colors.white60, fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(dialogCtx, _StationAction.passerQuestion),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text(
                                'بدء تحدي المار (سؤال)',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.amberAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.account_balance_wallet, color: Colors.amberAccent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "رصيدك: ${currentPlayer.money.toInt()} P",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildBalanceDiff(currentPlayer, station.buyPrice, canBuy),
                          const SizedBox(height: 24),
                          if (isSmall)
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: canBuy ? () => Navigator.pop(dialogCtx, _StationAction.buy) : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.greenAccent.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    ),
                                    child: const Text('شراء (سؤال مالك)', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(dialogCtx, _StationAction.pass),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      side: const BorderSide(color: Colors.white24),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    ),
                                    child: const Text('مرور (بدون سؤال)', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: canBuy ? () => Navigator.pop(dialogCtx, _StationAction.buy) : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.greenAccent.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    ),
                                    child: const Text(
                                      'شراء (سؤال مالك)',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(dialogCtx, _StationAction.pass),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      side: const BorderSide(color: Colors.white24),
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    ),
                                    child: const Text(
                                      'مرور (بدون سؤال)',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (!canBuy)
                            const Padding(
                              padding: EdgeInsets.only(top: 12.0),
                              child: Text(
                                "نقاطك لا تكفي للشراء",
                                style: TextStyle(color: Colors.redAccent, fontSize: 14),
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
              padding: const EdgeInsets.all(32),
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: AppDesign.dialogDecoration,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "كارت ${card.type == 'chance' ? 'حظك اليوم' : 'المحكمة'}",
                    style: TextStyle(
                      color: card.type == 'chance'
                          ? Colors.amberAccent
                          : Colors.blueAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (card.imageData != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(
                        card.imageData!,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Icon(
                      card.type == 'chance' ? Icons.auto_awesome : Icons.gavel,
                      color: Colors.white12,
                      size: 100,
                    ),
                  const SizedBox(height: 32),
                  Text(
                    card.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    card.description,
                    style: const TextStyle(color: Colors.white60, fontSize: 18, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: card.type == 'chance'
                            ? Colors.amberAccent
                            : Colors.blueAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 10,
                      ),
                      child: const Text(
                        "موافق",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
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
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.white60),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  // ==================== HEADER ====================

  Widget _buildFloatingHeader(GameState state, BuildContext context) {
    bool isSmall = AppDesign.isSmallScreen(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmall ? 6 : 20, vertical: isSmall ? 4 : 12),
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 6 : 24, vertical: isSmall ? 4 : 16),
      decoration: AppDesign.glassDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: isSmall ? 18 : 22),
                onPressed: () => Navigator.pop(context),
              ),
              if (isSmall) ...[
                const SizedBox(width: 4),
                if (state.settings.winCondition == WinningCondition.time)
                  _buildDynamicStat(
                    Icons.timer,
                    _formatTime(state.remainingSeconds),
                    state.remainingSeconds < 30 ? Colors.redAccent : Colors.amberAccent,
                    isSmall: true,
                  )
                else
                  _buildDynamicStat(
                    Icons.timer_outlined,
                    _timeElapsedStr,
                    Colors.amberAccent,
                    isSmall: true,
                  ),
                const SizedBox(width: 4),
                _buildDynamicStat(
                  Icons.history,
                  "${state.totalTurns}",
                  Colors.blueAccent,
                  isSmall: true,
                ),
              ],
              if (!isSmall) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.group_add, color: Colors.blueAccent, size: 26),
                  tooltip: 'إدارة الفرق',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeamsManagementPage()),
                  ),
                ),
              ],
            ],
          ),
          if (!isSmall)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white70, size: 26),
                  tooltip: 'الإعدادات',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.inventory, color: Colors.greenAccent, size: 26),
                  tooltip: 'ممتلكاتي',
                  onPressed: () => _showMyPropertiesDialog(context, state),
                ),
                const SizedBox(width: 16),
                if (state.settings.winCondition == WinningCondition.time)
                  _buildDynamicStat(
                    Icons.timer,
                    _formatTime(state.remainingSeconds),
                    state.remainingSeconds < 30 ? Colors.redAccent : Colors.amberAccent,
                  )
                else
                  _buildDynamicStat(
                    Icons.timer_outlined,
                    _timeElapsedStr,
                    Colors.amberAccent,
                  ),
                const SizedBox(width: 20),
                _buildDynamicStat(
                  Icons.history,
                  "الدورات: ${state.totalTurns}",
                  Colors.blueAccent,
                ),
              ],
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSmall) ...[
                IconButton(
                  icon: const Icon(Icons.group_add, color: Colors.blueAccent, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TeamsManagementPage()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.inventory, color: Colors.greenAccent, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showMyPropertiesDialog(context, state),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.list_alt, color: Colors.blueAccent, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showLogsDialog(state.logs),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white70, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _restartGamePrompt(context, ref),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.stop_circle, color: Colors.redAccent, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _confirmEndGame(),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (scaffoldContext) => IconButton(
                    icon: Icon(Icons.menu, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Scaffold.of(scaffoldContext).openEndDrawer(),
                  ),
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.blueAccent, size: 26),
                  tooltip: 'سجل الأحداث',
                  onPressed: () => _showLogsDialog(state.logs),
                ),
                IconButton(
                  icon: const Icon(Icons.stop_circle, color: Colors.redAccent, size: 26),
                  tooltip: 'إنهاء اللعبة',
                  onPressed: () => _confirmEndGame(),
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 26),
                  onPressed: () => _restartGamePrompt(context, ref),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicStat(IconData icon, String value, Color color, {bool isSmall = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 6 : 10, vertical: isSmall ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(isSmall ? 8 : 10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isSmall ? 12 : 14),
          SizedBox(width: isSmall ? 3 : 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isSmall ? 10 : 13,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOARD ====================
  // KEY FIX: All non-interactive elements wrapped in IgnorePointer
  // so the MouseTracker never tracks them during animations/rebuilds.

  double _calculatePlayerWealth(BankAlHazPlayer player, GameState state) {
    double total = player.money;
    if (state.settings.winCriteria == WinCriteria.moneyAndStations || 
        state.settings.winCriteria == WinCriteria.cumulativeValue) {
      for (var sid in player.ownedStationIds) {
        final stations = state.board.where((st) => st.id == sid);
        if (stations.isNotEmpty) {
          final s = stations.first;
          total += s.buyPrice;
          if (state.settings.winCriteria == WinCriteria.cumulativeValue) {
            for (var b in s.buildings) {
              if (b.isPurchased) total += b.buyPrice;
            }
          }
        }
      }
    }
    return total;
  }

  Widget _buildBoard(GameState state, GameEngine engine) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availWidth = constraints.maxWidth;
        final double availHeight = constraints.maxHeight;
        final bool isSmall = AppDesign.isSmallScreen(context);

        int total = state.board.length;
        if (total == 0) return const SizedBox.shrink();

        // Calculate grid dimensions based on aspect ratio
        final double aspect = availWidth / availHeight;
        final int targetSum = ((total + 4) / 2).ceil();
        
        // Find H such that W/H is near aspect and 2W + 2H - 4 >= total
        int hCells = (targetSum / (aspect + 1)).round().clamp(3, 12);
        int wCells = targetSum - hCells;
        
        // Ensure we cover all stations
        while (2 * (wCells + hCells) - 4 < total) {
          wCells++;
        }
        
        final int widthCells = wCells;
        final int heightCells = hCells;
        final int totalSlots = 2 * (widthCells + heightCells) - 4;

        // Board fills ALL available space - no margins
        final double finalWidth = availWidth;
        final double finalHeight = availHeight;

        return Container(
          width: finalWidth,
          height: finalHeight,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white12),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Center area - Constrained to NOT overlap cells
              Positioned(
                left: finalWidth / widthCells,
                top: finalHeight / heightCells,
                right: finalWidth / widthCells,
                bottom: finalHeight / heightCells,
                child: _buildCenterArea(finalWidth, finalHeight, state, engine),
              ),
              // Station cells
              Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int i = 0; i < totalSlots; i++)
                    _buildStationCell(
                      i,
                      i < total ? state.board[i] : Station(id: null, name: ""),
                      finalWidth / widthCells,
                      finalHeight / heightCells,
                      widthCells,
                      heightCells,
                      _calculateRectOffset(i, widthCells, heightCells, finalWidth, finalHeight),
                      state,
                    ),
                ],
              ),
              // Player pieces
              IgnorePointer(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (int pIdx = 0; pIdx < state.players.length; pIdx++)
                      _buildAnimatedPlayerPiece(
                        pIdx,
                        state,
                        finalWidth,
                        finalHeight,
                        widthCells,
                        heightCells,
                      ),
                  ],
                ),
              ),

              // Event Toast - Moved here to be dynamically positioned between cells and center content
              if (_currentEventLog != null)
                Positioned(
                  top: (finalHeight / heightCells) + (isSmall ? 4 : 12),
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isSmall ? 340 : 500),
                        child: _buildEventToast(_currentEventLog!),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCenterArea(
    double boardWidth,
    double boardHeight,
    GameState gameState,
    GameEngine engine,
  ) {
    final bool isSmall = AppDesign.isSmallScreen(context);
    bool isLock =
        gameState.isMovingPlayer ||
        gameState.isRollingDice ||
        gameState.isEndingTurn;
    bool hasPending =
        gameState.pendingLandingStation != null || _isHandlingLanding;
    final currentPlayerColor = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
    ][gameState.currentPlayerIndex % 5];
    
    final winnerColor = gameState.winnerIndex != null 
        ? [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple][gameState.winnerIndex! % 5]
        : currentPlayerColor;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IgnorePointer(
            child: Opacity(
              opacity: 0.04,
              child: Icon(
                Icons.directions_car_filled,
                size: math.min(boardWidth, boardHeight) * 0.08,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: isSmall ? 2 : 10),
          if (gameState.message.isNotEmpty && !gameState.isGameOver)
            IgnorePointer(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: boardWidth * 0.8,
                  maxHeight: boardHeight * 0.4,
                ),
                child: Container(
                  margin: EdgeInsets.only(bottom: isSmall ? 4 : 10),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: isSmall ? 10 : 20,
                  ),
                  decoration: BoxDecoration(
                    color: currentPlayerColor.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: currentPlayerColor.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 8,
                      )
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          gameState.message,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: (math.min(boardWidth, boardHeight) * 0.06)
                                .clamp(20, 40)
                                .toDouble(),
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 3),
                                blurRadius: 6,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!gameState.isGameOver)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  label: "نرد",
                  icon: Icons.casino,
                  active: !isLock && !hasPending,
                  onTap: () => engine.rollDice(),
                  color: Colors.orangeAccent,
                  size: (math.min(boardWidth, boardHeight) * 0.06).clamp(28, 50).toDouble(),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: (!isLock && !hasPending) ? () => engine.rollDice() : null,
                  child: ThreeDDice(
                    size: (math.min(boardWidth, boardHeight) * 0.1).clamp(35, 70).toDouble(),
                    value: gameState.currentDiceValue,
                    rollCounter: gameState.rollCounter,
                    onAnimationComplete: () {},
                  ),
                ),
                const SizedBox(width: 10),
                _buildActionButton(
                  label: "إنهاء",
                  icon: Icons.check_circle,
                  active: !isLock && !hasPending,
                  onTap: () {
                    print("DEBUG: Finish button clicked! Forcing next turn.");
                    engine.forceNextTurn();
                  },
                  color: Colors.greenAccent,
                  size: (math.min(boardWidth, boardHeight) * 0.06).clamp(28, 50).toDouble(),
                ),
              ],
            ),
          SizedBox(height: isSmall ? 6 : 20),
          _buildInternalPlayerStatsBar(gameState, boardWidth),
        ],
      ),
    );
  }

  Widget _buildInternalPlayerStatsBar(GameState state, double boardWidth) {
    final bool isSmall = AppDesign.isSmallScreen(context);
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (!isSmall) {
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
              Colors.purple,
            ][entry.key % 5];
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${p.name}: ${p.money.toInt()}",
                        style: TextStyle(
                          color: isCurrent ? Colors.black87 : Colors.white70,
                          fontSize: isCurrent ? 16 : 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (state.settings.winCriteria != WinCriteria.moneyOnly)
                        Text(
                          "الثروة: ${_calculatePlayerWealth(p, state).toInt()}",
                          style: TextStyle(
                            color: isCurrent
                                ? Colors.blueAccent
                                : Colors.amberAccent.withOpacity(0.7),
                            fontSize: isCurrent ? 13 : 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.monetization_on_rounded, color: Colors.amberAccent, size: isCurrent ? 14 : 11),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showLogsDialog(state.logs, title: "سجل ${p.name}", filterPlayerIndex: entry.key),
                    child: Icon(Icons.list_alt, color: isCurrent ? Colors.black54 : Colors.white38, size: isCurrent ? 18 : 14),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    // For mobile (small screens), stack them vertically as requested
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Using Wrap to handle landscape better even on "small" screens
        Wrap(
          direction: isLandscape ? Axis.horizontal : Axis.vertical,
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: state.players.asMap().entries.map((entry) {
            final isCurrent = state.currentPlayerIndex == entry.key;
            final p = entry.value;
            final color = [
              Colors.red,
              Colors.green,
              Colors.blue,
              Colors.orange,
              Colors.purple,
            ][entry.key % 5];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isCurrent ? Colors.white.withOpacity(0.9) : Colors.white10,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent ? color.withOpacity(0.5) : Colors.white10,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car, color: color, size: 10),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${p.name}: ${p.money.toInt()}",
                        style: TextStyle(
                          color: isCurrent ? Colors.black87 : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                       if (state.settings.winCriteria != WinCriteria.moneyOnly)
                        Text(
                          "الثروة: ${_calculatePlayerWealth(p, state).toInt()}",
                          style: TextStyle(
                            color: isCurrent ? Colors.blueAccent : Colors.amberAccent.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.monetization_on_rounded, color: Colors.amberAccent, size: 10),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _showLogsDialog(state.logs, title: "سجل ${p.name}", filterPlayerIndex: entry.key),
                    child: Icon(Icons.list_alt, color: isCurrent ? Colors.black54 : Colors.white38, size: 14),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStationCell(
    int index,
    Station station,
    double cw,
    double ch,
    int wCount,
    int hCount,
    Offset pos,
    GameState gameState,
  ) {
    if (station.id == null && station.name.isEmpty) {
      return Positioned(
        left: pos.dx,
        top: pos.dy,
        child: Container(
          width: cw,
          height: ch,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white10, width: 0.5),
          ),
          child: Center(
            child: Icon(Icons.blur_on, color: Colors.white.withOpacity(0.05), size: 24),
          ),
        ),
      );
    }

    final bool isSmall = AppDesign.isSmallScreen(context);
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    bool isCorner = index == 0 ||
        index == wCount - 1 ||
        index == wCount + hCount - 2 ||
        index == 2 * wCount + hCount - 3;

    final bool isSpecial = station.type != StationType.property && station.type != StationType.question;
    final baseColor = isCorner
        ? Colors.grey.shade900
        : (isSpecial ? Colors.blueGrey.shade800 : _getCityColor(index));

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (station.id != null) {
              final ownerIndex = gameState.players.indexWhere((p) => p.ownedStationIds.contains(station.id));
              if (ownerIndex != -1 && ownerIndex == gameState.currentPlayerIndex) {
                 _showMyPropertyActionDialog(context, station, gameState, ref.read(gameEngineProvider.notifier));
              }
            }
          },
          child: Container(
            width: cw,
            height: ch,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white24, width: 1.5),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Stack(
                children: [
                Column(
                  children: [
                    Container(
                      height: ch * 0.22,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: baseColor.withOpacity(0.85),
                        border: const Border(bottom: BorderSide(color: Colors.white10, width: 1)),
                      ),
                      child: (station.type == StationType.card)
                          ? Icon(
                              station.cardType == "chance" ? Icons.auto_awesome : Icons.card_giftcard,
                              color: Colors.white,
                              size: (ch * 0.15).clamp(12, 24).toDouble(),
                            )
                          : null,
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                station.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: (isLandscape ? ch * 0.16 : cw * 0.18).clamp(10, 45).toDouble(),
                                  height: 1.1,
                                  fontWeight: FontWeight.bold, // Bold font as requested
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (!isCorner && station.buyPrice > 0)
                              Builder(builder: (context) {
                                final ownerIdx = gameState.players.indexWhere((p) => p.ownedStationIds.contains(station.id));
                                if (ownerIdx != -1) {
                                   double rent = station.baseRent > 0 ? station.baseRent : (station.buyPrice * 0.2);
                                   for (var b in station.buildings) if (b.isPurchased) rent += b.additionalRent;
                                   return Text(
                                     "${rent.toInt()} R",
                                     style: TextStyle(
                                       color: Colors.white.withOpacity(0.6),
                                       fontSize: (cw * 0.12).clamp(8, 14).toDouble(),
                                       fontWeight: FontWeight.bold,
                                     ),
                                   );
                                } else {
                                  return Text(
                                    "${station.buyPrice.toInt()} P",
                                    style: TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: (cw * 0.14).clamp(9, 16).toDouble(),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }
                              }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                _buildOwnerIndicator(station, cw, ch, gameState),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Offset _calculateRectOffset(int index, int w, int h, double boardWidth, double boardHeight) {
    double cw = boardWidth / w;
    double ch = boardHeight / h;
    if (index < w) return Offset(index * cw, 0);
    if (index < w + h - 1) return Offset(boardWidth - cw, (index - w + 1) * ch);
    if (index < 2 * w + h - 2) {
      return Offset(boardWidth - cw - (index - (w + h - 2)) * cw, boardHeight - ch);
    }
    return Offset(0, boardHeight - ch - (index - (2 * w + h - 3)) * ch);
  }

  Widget _buildOwnerIndicator(
    Station station,
    double cw,
    double ch,
    GameState state,
  ) {
    final ownerIndex = state.players.indexWhere((p) => p.ownedStationIds.contains(station.id));
    if (ownerIndex == -1) return const SizedBox.shrink();

    final ownerColor = [
      Colors.redAccent,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
    ][ownerIndex % 5];

    return Positioned(
      bottom: 4,
      left: cw * 0.1,
      right: cw * 0.1,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [
              ownerColor.withOpacity(0.2),
              ownerColor,
              ownerColor.withOpacity(0.2),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: ownerColor.withOpacity(0.6),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Container(
            height: 1,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedPlayerPiece(
    int index,
    GameState state,
    double boardWidth,
    double boardHeight,
    int w,
    int h,
  ) {
    final bool isSmall = AppDesign.isSmallScreen(context);
    final p = state.players[index];
    final pos = _calculateRectOffset(p.currentPosition, w, h, boardWidth, boardHeight);
    double cw = boardWidth / w;
    double ch = boardHeight / h;
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
      duration: const Duration(milliseconds: 300),
      curve: Curves.linear, // Linear is better for step-by-step movement
      left: pos.dx + (cw / 2) - 30 + (r * 10 - 5),
      top: pos.dy + (ch / 2) - 27.5 + (c * 10 - 5),
      child: PlayerPiece(
        scale: isSmall ? 0.38 : 0.85,
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

  // ==================== GAME OVER OVERLAY ====================

  Widget _buildGameOverOverlay(GameState state, GameEngine engine, BuildContext context) {
    if (!state.isGameOver) return const SizedBox.shrink();

    final winnerColor = state.winnerIndex != null
        ? [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple][state.winnerIndex! % 5]
        : Colors.blueAccent;

    return Stack(
      children: [
        // 1. Blur Background
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
        ),

        // 2. Main Content
        Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              constraints: const BoxConstraints(maxWidth: 550),
              decoration: AppDesign.dialogDecoration.copyWith(
                border: Border.all(color: winnerColor.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(color: winnerColor.withOpacity(0.2), blurRadius: 40, spreadRadius: 10),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Trophy with Shine
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 90),
                      ),
                      const SizedBox(
                        width: 150,
                        height: 150,
                        child: ClipOval(child: _ShineAnimation(color: Colors.white24)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    "نهاية المباراة!",
                    style: AppDesign.titleStyle.copyWith(fontSize: 34, letterSpacing: 1),
                  ),
                  const SizedBox(height: 16),

                  // Winner Message
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: winnerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: winnerColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white10)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("ترتيب النتائج", style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider(color: Colors.white10)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sorted Players List by Wealth
                  ...(() {
                    final sortedIndices = List<int>.generate(state.players.length, (i) => i);
                    sortedIndices.sort((a, b) => _calculatePlayerWealth(state.players[b], state).compareTo(_calculatePlayerWealth(state.players[a], state)));

                    return sortedIndices.map((idx) {
                      final p = state.players[idx];
                      final color = [Colors.red, Colors.green, Colors.blue, Colors.orange, Colors.purple][idx % 5];
                      final wealth = _calculatePlayerWealth(p, state);
                      final isWinner = idx == state.winnerIndex;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isWinner ? winnerColor.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isWinner ? winnerColor : Colors.white10, width: isWinner ? 1 : 0.5),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.directions_car_filled, color: color, size: 24),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                p.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isWinner ? FontWeight.w900 : FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Text(
                              "${wealth.toInt()} P",
                              style: TextStyle(
                                color: isWinner ? Colors.amberAccent : Colors.white70,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  })(),

                  const SizedBox(height: 40),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => engine.restartGame(),
                          icon: const Icon(Icons.refresh_rounded, size: 24),
                          label: const Text(
                            "لعبة أخرى",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.logout_rounded, size: 24),
                          label: const Text(
                            "خروج",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24, width: 2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      ],
    );
  }

  // ==================== PREPARATION & RESTART ====================

  Widget _buildPreparationScreen(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppDesign.backgroundWrapper(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(40),
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: AppDesign.glassDecoration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withOpacity(0.1),
                    shape: BoxShape.circle,

                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 64),
                ),
                const SizedBox(height: 32),
                Text(
                  "بنك الحظ: القالب الديني",
                  style: AppDesign.titleStyle.copyWith(fontSize: 26),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "ابدأ اللعب فوراً باستخدام خريطة أورشليم والمدن المقدسة، أو قم بإنشاء مدنك الخاصة من الإعدادات.",
                  style: TextStyle(color: Colors.white60, fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_circle_fill, size: 28),
                    label: const Text(
                      'بدء اللعبة (القالب الديني)',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 10,
                    ),
                    onPressed: () => _restartGamePrompt(context, ref),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white38),
                  label: const Text(
                    'إدارة المحطات والكروت',
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
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
                final db = await DatabaseService.instance.database;
                // 1. Seed the religious data as Template ID 1
                await BankAlHazDefaultData.seed(db, force: true, templateId: 1);
                
                // 2. Force settings to use Template ID 1 (Religious)
                final repo = ref.read(bankAlHazRepositoryProvider);
                var currentSettings = await repo.getSettings();
                currentSettings = currentSettings.copyWith(activeTemplateId: 1);
                await repo.saveSettings(currentSettings);

                await Future.delayed(const Duration(milliseconds: 600));
                
                // 3. Invalidate and re-read providers
                ref.invalidate(gameEngineProvider);
                ref.invalidate(stationsProvider);
                ref.invalidate(cardsProvider);
                ref.invalidate(gameSettingsProvider);
                
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
                
                // 4. Start the game!
                await ref
                    .read(gameEngineProvider.notifier)
                    .initGame(teams.map((t) => t.name).toList(), settings);
              } catch (e) {
                print("Error starting religious template: $e");
              }
            },
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePostPurchaseFlow(Station station, GameEngine engine) async {
    // 1. Building Flow
    if (station.buildings.isNotEmpty) {
      await _showBuildPromptDialog(station, engine);
    }
    
    // Refresh station state from board (it might have been updated by buildings)
    final updatedStation = ref.read(gameEngineProvider).board.firstWhere((s) => s.id == station.id);

    // 2. Tax Flow
    if (updatedStation.allowsTax) {
      await _showTaxSettingDialog(updatedStation, engine);
    }
  }

  Future<void> _showBuildPromptDialog(Station station, GameEngine engine) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final gameState = ref.watch(gameEngineProvider);
          final currentStation = gameState.board.firstWhere((s) => s.id == station.id);
          final currentPlayer = gameState.players[gameState.currentPlayerIndex];
          
          return AlertDialog(
            backgroundColor: AppDesign.slate800,
            title: Text('البناء في ${station.name}', style: AppDesign.titleStyle),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Text('هل تريد شراء مباني لهذه المدينة؟', style: AppDesign.subtitleStyle),
                   const SizedBox(height: 16),
                   // Show current balance
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.05),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         const Icon(Icons.account_balance_wallet, color: Colors.amberAccent, size: 20),
                         const SizedBox(width: 8),
                         Text(
                           "رصيدك الحالي: ${currentPlayer.money.toInt()} P",
                           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 16),
                  ...currentStation.buildings.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final b = entry.value;
                    final canAfford = currentPlayer.money >= b.buyPrice;
                    
                    return ListTile(
                      title: Text(b.name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text('ثمن: ${b.buyPrice} • إيجار إضافي: ${b.additionalRent}', style: const TextStyle(color: Colors.white70)),
                      trailing: b.isPurchased 
                        ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                        : ElevatedButton(
                            onPressed: canAfford ? () async {
                              await engine.buyBuilding(station.id!, idx);
                              setState(() {});
                            } : null,
                            child: const Text('شراء'),
                          ),
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إنهاء البناء'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _showTaxSettingDialog(Station station, GameEngine engine) async {
    final controller = TextEditingController(text: station.taxAmount.toString());
    bool taxEnabled = station.hasTax;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppDesign.slate800,
          title: Text('إعدادات الضرائب - ${station.name}', style: AppDesign.titleStyle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('تفعيل الضرائب', style: TextStyle(color: Colors.white)),
                subtitle: const Text('سيقوم اللاعبون بدفع مبلغ عند المرور بهذه الخانة أو الوقوف عليها', style: TextStyle(color: Colors.white70, fontSize: 12)),
                value: taxEnabled,
                onChanged: (val) {
                  setState(() {
                    taxEnabled = val;
                    if (val && (double.tryParse(controller.text) ?? 0) == 0) {
                      // Set default to maximum limit
                      controller.text = (station.buyPrice * 0.25).toInt().toString();
                    }
                  });
                },
              ),
              if (taxEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'قيمة الضريبة (بحد أقصى ${station.buyPrice * 0.25})',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                  ),
                ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                engine.toggleTax(station.id!, taxEnabled);
                if (taxEnabled) {
                  final amt = double.tryParse(controller.text) ?? 10.0;
                  engine.setTaxAmount(station.id!, amt);
                }
                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
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

  void _showLogsDialog(List<GameLog> logs, {String title = "سجل أحداث اللعبة", int? filterPlayerIndex}) {
    final gameState = ref.read(gameEngineProvider);
    final filteredLogs = filterPlayerIndex == null 
      ? logs 
      : logs.where((l) => l.playerIndex == filterPlayerIndex).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppDesign.slate800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.history, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Text(title, style: AppDesign.titleStyle),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 600,
          child: filteredLogs.isEmpty
            ? const Center(child: Text("لا توجد أحداث بعد", style: TextStyle(color: Colors.white54)))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: filteredLogs.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final log = filteredLogs[filteredLogs.length - 1 - index]; // Newest first
                  final logPlayer = log.playerIndex != null ? gameState.players[log.playerIndex!] : null;
                  
                  return ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getLogColor(log.type).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getLogIcon(log.type), color: _getLogColor(log.type), size: 16),
                    ),
                    title: RichText(
                      text: TextSpan(
                        children: [
                          if (logPlayer != null)
                            TextSpan(
                              text: "${logPlayer.name}: ",
                              style: TextStyle(
                                color: [Colors.red, Colors.green, Colors.blue, Colors.orange][log.playerIndex! % 4].shade300,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          TextSpan(
                            text: log.message,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    subtitle: Text(
                      "${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}", 
                      style: const TextStyle(color: Colors.white24, fontSize: 10)
                    ),
                  );
                },
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إغلاق", style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  IconData _getLogIcon(LogType type) {
    switch (type) {
      case LogType.moneyAdd: return Icons.add_circle;
      case LogType.moneyRemove: return Icons.remove_circle;
      case LogType.purchase: return Icons.shopping_cart;
      case LogType.movement: return Icons.directions_walk;
      case LogType.info: return Icons.info;
    }
  }

  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.moneyAdd: return Colors.greenAccent;
      case LogType.moneyRemove: return Colors.redAccent;
      case LogType.purchase: return Colors.blueAccent;
      case LogType.movement: return Colors.amberAccent;
      case LogType.info: return Colors.white54;
    }
  }

  Widget _buildBalanceDiff(BankAlHazPlayer player, double cost, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("رصيدك الحالي", style: TextStyle(color: Colors.white60, fontSize: 11)),
              Text("${player.money.toInt()} P", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("الرصيد بعد الشراء", style: TextStyle(color: Colors.white60, fontSize: 11)),
              Text(
                "${(player.money - cost).toInt()} P", 
                style: TextStyle(
                  color: active ? Colors.greenAccent : Colors.redAccent, 
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                )
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMyPropertiesDialog(BuildContext context, GameState state) {
    final currentPlayer = state.players[state.currentPlayerIndex];
    final ownedStations = state.board.where((s) => currentPlayer.ownedStationIds.contains(s.id)).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.inventory, color: Colors.greenAccent),
            const SizedBox(width: 10),
            Text("ممتلكات ${currentPlayer.name}", style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ownedStations.isEmpty
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 20),
                    Icon(Icons.info_outline, color: Colors.white24, size: 48),
                    SizedBox(height: 10),
                    Text("لا تملك أي مدن حالياً", style: TextStyle(color: Colors.white60)),
                    SizedBox(height: 20),
                  ],
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: ownedStations.length,
                  itemBuilder: (context, index) {
                    final s = ownedStations[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text("القيمة: ${s.buyPrice.toInt()} P", style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showSellDialog(context, s, state, ref.read(gameEngineProvider.notifier));
                              },
                              icon: const Icon(Icons.sell, size: 16),
                              label: const Text("بيع", style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("إغلاق")
          ),
        ],
      ),
    );
  }

  void _showMyPropertyActionDialog(BuildContext context, Station station, GameState state, GameEngine notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 350,
          decoration: AppDesign.dialogDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: _getCityColor(state.board.indexOf(station)).withOpacity(0.8),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.location_city, color: Colors.white, size: 48),
                    const SizedBox(height: 12),
                    Text(station.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildDialogAction(
                      icon: Icons.add_business,
                      title: "بناء في المدينة",
                      subtitle: "تطوير وتحسين العائد",
                      color: Colors.amberAccent,
                      onTap: () {
                         Navigator.pop(ctx);
                         _showBuildingDialog(context, state, station, notifier);
                      },
                    ),
                    _buildDialogAction(
                      icon: station.hasTax ? Icons.gavel : Icons.gavel_outlined,
                      title: station.hasTax ? "إلغاء تفعيل الضريبة" : "تفعيل الضريبة",
                      subtitle: "تحصيل رسوم من المارين",
                      color: Colors.blueAccent,
                      onTap: () {
                         Navigator.pop(ctx);
                         notifier.toggleTax(station.id!, !station.hasTax);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDialogAction(
                      icon: Icons.sell,
                      title: "بيع العقار",
                      subtitle: "للـبنـــك أو لـلاعب آخـــر",
                      color: Colors.redAccent,
                      onTap: () {
                         Navigator.pop(ctx);
                         _showSellDialog(context, station, state, notifier);
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إغلاق", style: TextStyle(color: Colors.white54))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBuildingDialog(BuildContext context, GameState state, Station station, GameEngine engine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("بناء في ${station.name}", style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: station.buildings.asMap().entries.map((entry) {
              final b = entry.value;
              return ListTile(
                title: Text(b.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text("عائد إضافي: ${b.additionalRent.toInt()} P", style: const TextStyle(color: Colors.white54)),
                trailing: b.isPurchased 
                  ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                  : ElevatedButton(
                      onPressed: state.players[state.currentPlayerIndex].money >= b.buyPrice
                          ? () {
                              engine.addUpgradeToStation(station.id!, b.name);
                              Navigator.pop(ctx);
                            }
                          : null,
                      child: Text("${b.buyPrice.toInt()} P"),
                    ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogAction({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  void _showSellDialog(BuildContext context, Station station, GameState state, GameEngine engine) {
    final otherPlayers = state.players.asMap().entries.where((e) => e.key != state.currentPlayerIndex).toList();
    
    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool sellToBank = true;
        int? selectedBuyerIdx;
        double price = (station.buyPrice * 0.5).floorToDouble(); // Default for bank

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: 400,
              decoration: AppDesign.dialogDecoration,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // Header
                   Container(
                     padding: const EdgeInsets.symmetric(vertical: 20),
                     width: double.infinity,
                     decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.8),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                     ),
                     child: const Column(
                       children: [
                         Icon(Icons.sell, color: Colors.white, size: 40),
                         SizedBox(height: 8),
                         Text("بيع العقار", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                       ],
                     ),
                   ),
                   
                   Padding(
                     padding: const EdgeInsets.all(24),
                     child: Column(
                       children: [
                         Text(station.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 20),
                         
                         // Selection
                         Row(
                           children: [
                             Expanded(
                               child: _sellOptionChip(
                                 label: "للـبنـــك",
                                 icon: Icons.account_balance,
                                 selected: sellToBank,
                                 onTap: () => setDialogState(() {
                                   sellToBank = true;
                                   price = (station.buyPrice * 0.5).floorToDouble();
                                 }),
                               ),
                             ),
                             const SizedBox(width: 12),
                             Expanded(
                               child: _sellOptionChip(
                                 label: "للاعـــب",
                                 icon: Icons.person,
                                 selected: !sellToBank,
                                 onTap: () => setDialogState(() {
                                   sellToBank = false;
                                   price = station.buyPrice;
                                 }),
                               ),
                             ),
                           ],
                         ),
                         
                         const SizedBox(height: 24),
                         
                         if (sellToBank) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                children: [
                                  const Text("سعر البيع للبنك (50%)", style: TextStyle(color: Colors.white60)),
                                  const SizedBox(height: 8),
                                  Text("${price.toInt()} P", style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                         ] else ...[
                            DropdownButtonHideUnderline(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: DropdownButton<int?>(
                                  hint: const Text("اختر المشتري", style: TextStyle(color: Colors.white54)),
                                  dropdownColor: Colors.grey.shade900,
                                  isExpanded: true,
                                  value: selectedBuyerIdx,
                                  items: otherPlayers.map((e) => DropdownMenuItem(
                                    value: e.key, 
                                    child: Text(e.value.name, style: const TextStyle(color: Colors.white))
                                  )).toList(),
                                  onChanged: (val) => setDialogState(() => selectedBuyerIdx = val),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "السعر المطلوب",
                                labelStyle: const TextStyle(color: Colors.white54),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.payments, color: Colors.greenAccent),
                              ),
                              style: const TextStyle(color: Colors.white),
                              onChanged: (val) => price = double.tryParse(val) ?? price,
                            ),
                         ],
                         
                         const SizedBox(height: 32),
                         Row(
                           children: [
                             Expanded(
                               child: TextButton(
                                 onPressed: () => Navigator.pop(dialogCtx),
                                 child: const Text("إلغاء", style: TextStyle(color: Colors.white54)),
                               ),
                             ),
                             Expanded(
                               child: ElevatedButton(
                                 onPressed: (sellToBank || selectedBuyerIdx != null) ? () {
                                   if (sellToBank) {
                                      engine.sellStationToBank(station.id!);
                                   } else {
                                      engine.sellStationToPlayer(station.id!, selectedBuyerIdx!, price);
                                   }
                                   Navigator.pop(dialogCtx);
                                 } : null,
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: Colors.redAccent,
                                   padding: const EdgeInsets.symmetric(vertical: 16),
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                 ),
                                 child: const Text("تأكيد البيع", style: TextStyle(fontWeight: FontWeight.bold)),
                               ),
                             ),
                           ],
                         ),
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
  }

  Widget _sellOptionChip({required String label, required IconData icon, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.redAccent : Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.redAccent : Colors.white24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ShineAnimation extends StatefulWidget {
  final Color color;
  const _ShineAnimation({required this.color});

  @override
  State<_ShineAnimation> createState() => _ShineAnimationState();
}

class _ShineAnimationState extends State<_ShineAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(-200 + (_controller.value * 800), -100),
          child: Transform.rotate(
            angle: 0.5,
            child: Container(
              width: 100,
              height: 400,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


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
    bool isSmall = AppDesign.isSmallScreen(context);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: AppDesign.dialogDecoration,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.quiz_outlined, size: 22, color: Colors.blueAccent),
                        SizedBox(width: 10),
                        Text(
                          'سؤال التحدي',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.blueAccent,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (widget.question.imageData != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        widget.question.imageData!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  Text(
                    widget.question.text,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.5,
                      shadows: [Shadow(color: Colors.blueAccent, blurRadius: 10)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  if (widget.question.type == QuestionType.multipleChoice &&
                      widget.question.options != null &&
                      widget.question.options!.isNotEmpty)
                    ...widget.question.options!.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final opt = entry.value;
                      final isCorrectOpt =
                          widget.question.correctOptionIndices?.contains(idx) ?? false;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _showAnswer && isCorrectOpt
                                ? Colors.greenAccent.withOpacity(0.1)
                                : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _showAnswer && isCorrectOpt
                                  ? Colors.greenAccent
                                  : Colors.white.withOpacity(0.1),
                              width: _showAnswer && isCorrectOpt ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _showAnswer && isCorrectOpt
                                      ? Colors.greenAccent
                                      : Colors.white.withOpacity(0.1),
                                ),
                                child: Center(
                                  child: Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: _showAnswer && isCorrectOpt
                                          ? Colors.black
                                          : Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Text(
                                  opt,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: _showAnswer && isCorrectOpt
                                        ? FontWeight.w900
                                        : FontWeight.w500,
                                    color: _showAnswer && isCorrectOpt
                                        ? Colors.greenAccent
                                        : Colors.white70,
                                  ),
                                ),
                              ),
                              if (_showAnswer && isCorrectOpt)
                                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
                            ],
                          ),
                        ),
                      );
                    }),
                  if (widget.question.type == QuestionType.trueFalse)
                    isSmall 
                      ? Column(
                          children: [
                            SizedBox(width: double.infinity, child: _buildTFChip("صح", true, widget.question.tfValue == true)),
                            const SizedBox(height: 12),
                            SizedBox(width: double.infinity, child: _buildTFChip("خطأ", false, widget.question.tfValue == false)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTFChip("صح", true, widget.question.tfValue == true),
                            const SizedBox(width: 20),
                            _buildTFChip("خطأ", false, widget.question.tfValue == false),
                          ],
                        ),
                  const SizedBox(height: 32),
                  if (_showAnswer) ...[
                    const Divider(color: Colors.white10, height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.amberAccent, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'الإجابة الصحيحة:',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
                      ),
                      child: Text(
                        widget.question.answer,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                  if (!_showAnswer)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _showAnswer = true),
                        icon: const Icon(Icons.visibility),
                        label: const Text(
                          'إظهار الإجابة',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  if (_showAnswer)
                    isSmall
                      ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context, true),
                                icon: const Icon(Icons.check_circle),
                                label: const Text('إجابة صحيحة', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context, false),
                                icon: const Icon(Icons.cancel),
                                label: const Text('إجابة خاطئة', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context, true),
                                icon: const Icon(Icons.check_circle),
                                label: const Text(
                                  'إجابة صحيحة',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context, false),
                                icon: const Icon(Icons.cancel),
                                label: const Text(
                                  'إجابة خاطئة',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: _showAnswer && isCorrect
              ? Colors.greenAccent.withOpacity(0.1)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _showAnswer && isCorrect
                ? Colors.greenAccent
                : Colors.white.withOpacity(0.1),
            width: _showAnswer && isCorrect ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _showAnswer && isCorrect
                    ? Colors.greenAccent
                    : Colors.white70,
              ),
            ),
            if (_showAnswer && isCorrect) ...[
              const SizedBox(width: 12),
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
            ],
          ],
        ),
      ),
    );
  }
}
