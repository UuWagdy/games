import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../domain/entities/bank_al_haz_entities.dart';
import '../providers/game_engine_provider.dart';
import '../providers/bank_al_haz_providers.dart';
import '../providers/bank_al_haz_template_seeder.dart';
import '../../../../teams/presentation/providers/team_providers.dart';
import '../widgets/three_d_dice.dart';
import '../widgets/player_piece.dart';
import '../../../../questions/domain/entities/question.dart';
import '../../../../teams/presentation/pages/teams_management_page.dart';
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
      extendBodyBehindAppBar: true,
      endDrawer: AppDesign.isSmallScreen(context) ? Drawer(
        backgroundColor: AppDesign.slate900,
        child: _buildMobileDrawer(gameState),
      ) : null,
      body: AppDesign.backgroundWrapper(
        child: SafeArea(
          child: Column(
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
                          station.isUnbuyable
                              ? "غرامة التحدي"
                              : "الإيجار الأساسي",
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
                              onPressed: () =>
                                  Navigator.pop(dialogCtx, _StationAction.buy),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amberAccent,
                                foregroundColor: Colors.black,
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
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogCtx, _StationAction.pass),
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
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogCtx, _StationAction.pass),
                            child: const Text("إغلاق", style: TextStyle(color: Colors.white70)),
                          ),
                        ] else if (isOwned) ...[
                          const Text(
                            "ستدخل تحدي المار لتقليل الإيجار",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(
                                dialogCtx,
                                _StationAction.passerQuestion,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.black,
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
                          if (isSmall)
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: canBuy
                                        ? () => Navigator.pop(dialogCtx, _StationAction.buy)
                                        : null,
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
                                    onPressed: canBuy
                                        ? () => Navigator.pop(
                                            dialogCtx,
                                            _StationAction.buy,
                                          )
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.greenAccent.shade700,
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
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(
                                      dialogCtx,
                                      _StationAction.pass,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      side: const BorderSide(color: Colors.white24),
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
                              padding: EdgeInsets.only(top: 12.0),
                              child: Text(
                                "نقاطك لا تكفي للشراء",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 14,
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
                const SizedBox(width: 16),
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
              if (isSmall)
                Builder(
                  builder: (scaffoldContext) => IconButton(
                    icon: Icon(Icons.menu, color: Colors.white, size: isSmall ? 22 : 28),
                    onPressed: () => Scaffold.of(scaffoldContext).openEndDrawer(),
                    visualDensity: VisualDensity.compact,
                  ),
                )
              else ...[
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

        int total = state.board.length;
        if (total == 0) return const SizedBox.shrink();

        // Calculate grid dimensions
        int pPlus4 = total + 4;
        int sumSides = (pPlus4 / 2).floor();
        int widthCells = (sumSides / 2).ceil();
        int heightCells = sumSides - widthCells;
        if (2 * (widthCells + heightCells) - 4 < total) widthCells++;

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
              IgnorePointer(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (int i = 0; i < total; i++)
                      _buildStationCell(
                        i,
                        state.board[i],
                        finalWidth,
                        finalHeight,
                        widthCells,
                        heightCells,
                        state,
                      ),
                  ],
                ),
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
          if (gameState.message.isNotEmpty)
            IgnorePointer(
              child: Container(
                margin: EdgeInsets.only(bottom: isSmall ? 4 : 10),
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: isSmall ? 3 : 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  gameState.message,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: (math.min(boardWidth, boardHeight) * 0.05).clamp(14, 34).toDouble(),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
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
          IgnorePointer(
            child: _buildInternalPlayerStatsBar(gameState, boardWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildInternalPlayerStatsBar(GameState state, double boardWidth) {
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
                    fontSize: isCurrent ? 14 : 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.monetization_on_rounded, color: Colors.amberAccent, size: isCurrent ? 14 : 11),
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
    double boardWidth,
    double boardHeight,
    int wCount,
    int hCount,
    GameState gameState,
  ) {
    final bool isSmall = AppDesign.isSmallScreen(context);
    final pos = _calculateRectOffset(index, wCount, hCount, boardWidth, boardHeight);
    double cw = boardWidth / wCount;
    double ch = boardHeight / hCount;
    bool isCorner =
        index == 0 ||
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
      child: Container(
        width: cw,
        height: ch,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Column(
            children: [
              // Color Bar
              Container(
                height: ch * 0.22,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.8),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  boxShadow: [BoxShadow(color: baseColor.withOpacity(0.3), blurRadius: 4)],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                station.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmall ? (cw * 0.18).clamp(10, 16) : (cw * 0.25).clamp(14, 35),
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (station.type == StationType.card)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    station.cardType == "chance" 
                                        ? Icons.auto_awesome_rounded 
                                        : Icons.gavel_rounded,
                                    color: station.cardType == "chance" 
                                        ? Colors.amberAccent 
                                        : Colors.blueAccent,
                                    size: cw * 0.25,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (!isCorner && station.buyPrice > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: () {
                            // Check if any player owns this station
                            final isOwned = gameState.players.any(
                              (p) => p.ownedStationIds.contains(station.id),
                            );
                            if (isOwned) {
                              // Show rent
                              final rent = station.baseRent > 0
                                  ? station.baseRent
                                  : (station.buyPrice * 0.2).floorToDouble();
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "إيجار: ${rent.toInt()}",
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: (cw * 0.15).clamp(10, 18),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                );
                              } else {
                                // Show buy price
                                return Text(
                                  "${station.buyPrice.toInt()}",
                                  style: TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: (cw * 0.16).clamp(12, 20),
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }
                            }(),
                          ),
                    ],
                  ),
                ),
              ),
              _buildOwnerIndicator(station, cw, ch, gameState),
            ],
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
                await BankAlHazTemplateSeeder().seedGame();
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
