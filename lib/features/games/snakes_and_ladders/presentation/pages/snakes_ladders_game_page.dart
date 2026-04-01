import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:games/core/design/app_design.dart';
import 'package:games/features/games/snakes_and_ladders/presentation/providers/snakes_ladders_providers.dart';
import 'package:games/features/games/snakes_and_ladders/domain/entities/snakes_ladders_entities.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/features/questions/domain/entities/question.dart';
import 'package:games/features/games/snakes_and_ladders/presentation/widgets/game_board_widget.dart';
import 'package:games/features/games/snakes_and_ladders/presentation/widgets/dice_widget.dart';
import 'package:games/features/games/snakes_and_ladders/presentation/widgets/snakes_ladders_settings_dialog.dart';
import 'package:games/core/providers/sound_effects_provider.dart';
import 'package:games/core/design/app_themes.dart';
import '../../../../settings/presentation/providers/settings_providers.dart';
import 'package:games/core/design/themed_background.dart';


class SnakesLaddersGamePage extends ConsumerStatefulWidget {
  const SnakesLaddersGamePage({super.key});

  @override
  ConsumerState<SnakesLaddersGamePage> createState() => _SnakesLaddersGamePageState();
}

class _SnakesLaddersGamePageState extends ConsumerState<SnakesLaddersGamePage> {
  bool _isRolling = false;
  bool _isMoving = false;
  bool _isHandlingTurn = false;

  void _handleRoll() async {
    final gameState = ref.read(snakesLaddersGameProvider);
    if (gameState.status == SnakesLaddersStatus.finished || _isRolling || _isMoving || _isHandlingTurn) return;

    setState(() {
      _isRolling = true;
      _isHandlingTurn = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final diceVal = math.Random().nextInt(6) + 1;
    ref.read(snakesLaddersGameProvider.notifier).setDiceValue(diceVal);
    
    if (mounted) setState(() => _isRolling = false);

    if (gameState.questionsEnabled) {
      _showQuestionFlow(diceVal);
    } else {
      _executeMove(diceVal);
    }
  }

  void _showQuestionFlow(int diceVal) async {
    final gameState = ref.read(snakesLaddersGameProvider);
    final categoryIds = gameState.categoryIds;
    
    List<Question> availableQuestions = [];
    if (categoryIds.isEmpty) {
      final allCats = await ref.read(categoriesProvider.future);
      for (var cat in allCats) {
        final qs = await ref.read(questionsProvider(cat.id).future);
        availableQuestions.addAll(qs);
      }
    } else {
      for (var catId in categoryIds) {
        final qs = await ref.read(questionsProvider(catId).future);
        availableQuestions.addAll(qs);
      }
    }

    if (!mounted) return;
    if (availableQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد أسئلة متاحة!')));
      _executeMove(diceVal);
      return;
    }

    final randomQuestion = availableQuestions[math.Random().nextInt(availableQuestions.length)];
    final teams = ref.read(teamsListProvider).value ?? [];
    if (teams.isEmpty) {
      if (mounted) setState(() => _isHandlingTurn = false);
      return;
    }
    final currentTeam = teams[gameState.currentPlayerIndex % teams.length];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _QuestionDialog(
        question: randomQuestion,
        teamName: currentTeam.name,
        onResult: (isCorrect) {
          if (isCorrect) {
            _executeMove(diceVal);
          } else {
            final penalty = ref.read(snakesLaddersGameProvider).wrongAnswerPenalty;
            if (penalty == WrongAnswerPenalty.skip) {
              ref.read(snakesLaddersGameProvider.notifier).skipTurn();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('إجابة خاطئة! ضاع دورك')));
            } else {
              final steps = diceVal ~/ 2;
              if (steps > 0) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('إجابة خاطئة! ستتحرك $steps خطوات فقط (نصف المسافة)')));
                _executeMove(steps);
              } else {
                ref.read(snakesLaddersGameProvider.notifier).skipTurn();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('إجابة خاطئة! المسافة صفر، ضاع دورك')));
              }
            }
          }
          if (mounted) setState(() => _isHandlingTurn = false);
        },
      ),
    );
  }

  void _executeMove(int steps) async {
    setState(() {
      _isMoving = true;
      _isHandlingTurn = true;
    });
    try {
      await ref.read(snakesLaddersGameProvider.notifier).moveCurrentPlayer(steps);
    } finally {
      if (mounted) {
        setState(() {
          _isMoving = false;
          _isHandlingTurn = false;
        });
      }
    }
  }

  void _showWinnerDialog(String winnerName) {
    bool isSmall = AppDesign.isSmallScreen(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          width: isSmall ? double.infinity : 600,
          padding: EdgeInsets.all(isSmall ? 24 : 40),
          decoration: AppDesign.glassDecoration.copyWith(color: Colors.amber.withOpacity(0.9)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, size: isSmall ? 64 : 100, color: Colors.white),
              const SizedBox(height: 20),
              Text('مبرووووك!', style: TextStyle(fontSize: isSmall ? 32 : 40, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 10),
              Text('الفائز هو فريق $winnerName', style: TextStyle(fontSize: isSmall ? 18 : 24, color: Colors.white70)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(snakesLaddersGameProvider.notifier).resetPositions();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.amber.shade900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('لعب مرة أخرى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _confirmResetScores(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تصفير النقاط وحذف السجل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من تصفير نقاط كل الفرق وحذف سجل النقاط بالكامل؟ سيتم إعادة تشغيل اللعبة أيضاً.', 
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await ref.read(teamsListProvider.notifier).resetScoresAndClearLogs();
              ref.read(snakesLaddersGameProvider.notifier).resetPositions();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('تصفير الكل'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(snakesLaddersGameProvider);
    final teamsAsync = ref.watch(teamsListProvider);
    final themeAsync = ref.watch(currentThemeProvider);
    final theme = themeAsync.value ?? AppThemes.defaultTheme;

    ref.listen(snakesLaddersGameProvider, (previous, next) {
      if (next.status == SnakesLaddersStatus.finished && previous?.status == SnakesLaddersStatus.playing) {
        final teams = teamsAsync.value ?? [];
        if (teams.isNotEmpty) {
           final winnerIndex = (next.currentPlayerIndex - 1) % teams.length;
           final winner = teams[winnerIndex < 0 ? teams.length - 1 : winnerIndex];
           _showWinnerDialog(winner.name);
        }
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('السلم والثعبان', style: TextStyle(fontSize: AppDesign.isSmallScreen(context) ? 18 : 22, fontWeight: FontWeight.w900, color: theme.primaryColor, shadows: [Shadow(color: theme.primaryColor.withOpacity(0.5), blurRadius: 10)])),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: theme.primaryColor),
            onPressed: () => showDialog(context: context, builder: (_) => const SnakesLaddersSettingsDialog()),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.white), 
            tooltip: 'إعادة تعيين الخانات',
            onPressed: () => ref.read(snakesLaddersGameProvider.notifier).resetPositions()
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: 'تصفير النقاط',
            onPressed: () => _confirmResetScores(context, ref),
          ),
          if (AppDesign.isSmallScreen(context))
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.leaderboard_rounded, color: Colors.amberAccent),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          const SizedBox(width: 10),
        ],
      ),
      endDrawer: AppDesign.isSmallScreen(context) ? Drawer(
        backgroundColor: AppDesign.slate900,
        child: _buildSidebar(teamsAsync, gameState),
      ) : null,
      body: ThemedBackground(
        child: Focus(
          autofocus: true,
          onKey: (node, event) {
            if (event is RawKeyDownEvent && 
                (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter)) {
              if (!_isRolling && !_isMoving && gameState.status != SnakesLaddersStatus.finished) {
                _handleRoll();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: teamsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
            error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
            data: (teams) {
              if (teams.isEmpty) return const Center(child: Text('يرجى إضافة فرق للبدء', style: TextStyle(color: Colors.white, fontSize: 24)));
              
              final currentTeam = teams[gameState.currentPlayerIndex % teams.length];
    
              if (AppDesign.isSmallScreen(context)) {
                return _buildBoardArea(gameState, teams, currentTeam);
              }
    
              return Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: _buildBoardArea(gameState, teams, currentTeam),
                  ),
                  Container(
                    width: 320,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      border: const Border(left: BorderSide(color: Colors.white10)),
                    ),
                    child: _buildSidebar(teamsAsync, gameState),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBoardArea(SnakesLaddersState gameState, List<dynamic> teams, dynamic currentTeam) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(8),
                child: ThemedGameFrame(
                  child: GameBoardWidget(
                    boardSize: gameState.boardSize,
                    elements: gameState.elements,
                    playerPositions: gameState.playerPositions,
                    teams: teams,
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: AppDesign.isSmallScreen(context) ? 120 : 150,
            padding: EdgeInsets.symmetric(horizontal: AppDesign.isSmallScreen(context) ? 20 : 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الدور على فريق:', style: AppDesign.subtitleStyle),
                      Text(
                        currentTeam.name,
                        style: TextStyle(
                          fontSize: AppDesign.isSmallScreen(context) ? 24 : 32, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.amberAccent
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                DiceWidget(
                  value: gameState.lastDiceValue,
                  isRolling: _isRolling,
                  onTap: (_isRolling || _isMoving) ? () {} : _handleRoll,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(AsyncValue<List<dynamic>> teamsAsync, SnakesLaddersState gameState) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('ترتيب اللاعبين', style: AppDesign.titleStyle),
              ),
              Expanded(
                child: teamsAsync.when(
                  data: (teams) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      final pos = gameState.playerPositions[team.id!] ?? 1;
                      final isCurrent = index == (gameState.currentPlayerIndex % teams.length);
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isCurrent ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: isCurrent ? Colors.amber : Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getTeamColor(index),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: _getTeamColor(index).withOpacity(0.4), blurRadius: 8, spreadRadius: 1)],
                                border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                              ),
                              child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(team.name, style: TextStyle(color: isCurrent ? Colors.white : Colors.white70, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
                                  Text('النقاط: ${team.score}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                              child: Text('خانة $pos', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTeamColor(int index) {
    const colors = [Colors.redAccent, Colors.blueAccent, Colors.greenAccent, Colors.orangeAccent, Colors.purpleAccent, Colors.cyanAccent];
    return colors[index % colors.length];
  }
}

class _QuestionDialog extends ConsumerStatefulWidget {
  final Question question;
  final String teamName;
  final Function(bool) onResult;

  const _QuestionDialog({
    required this.question,
    required this.teamName,
    required this.onResult,
  });

  @override
  ConsumerState<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends ConsumerState<_QuestionDialog> {
  bool _showAnswer = false;
  double? _localFontSize;

  double _getEffectiveFontSize(Map<String, dynamic> settings) {
    return _localFontSize ?? (settings['question_font_size'] ?? 24.0);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isSmall = AppDesign.isSmallScreen(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 40, vertical: 24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: EdgeInsets.all(isSmall ? 20 : 40),
          decoration: AppDesign.glassDecoration.copyWith(
            color: const Color(0xFF1E293B).withOpacity(0.85),
            border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('سؤال لفريق: ${widget.teamName}', style: const TextStyle(fontSize: 18, color: Colors.amberAccent)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                final settings = ref.read(generalSettingsProvider).value ?? {};
                                setState(() {
                                  _localFontSize = (_getEffectiveFontSize(settings) - 2).clamp(12, 100);
                                });
                              },
                              icon: const Icon(Icons.zoom_out, color: Colors.amberAccent),
                            ),
                            Text(
                              _getEffectiveFontSize(ref.read(generalSettingsProvider).value ?? {}).toInt().toString(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () {
                                final settings = ref.read(generalSettingsProvider).value ?? {};
                                setState(() {
                                  _localFontSize = _getEffectiveFontSize(settings) + 2;
                                });
                              },
                              icon: const Icon(Icons.zoom_in, color: Colors.amberAccent),
                            ),
                          ],
                        ),
                      ],
                    ),
                const SizedBox(height: 24),
                if (widget.question.imageData != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      widget.question.imageData!,
                      height: isSmall ? 150 : 200,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  widget.question.text, 
                  style: TextStyle(
                    fontSize: _getEffectiveFontSize(ref.watch(generalSettingsProvider).value ?? {}),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ), 
                  textAlign: TextAlign.center
                ),
                const SizedBox(height: 40),
                if (_showAnswer) ...[
                  const Text('الإجابة الصحيحة:', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                  Text(
                    widget.question.answer, 
                    style: TextStyle(
                      fontSize: _getEffectiveFontSize(ref.watch(generalSettingsProvider).value ?? {}) * 0.85,
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                ],
                if (isSmall)
                  Column(
                    children: [
                      if (!_showAnswer)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber, 
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => setState(() => _showAnswer = true),
                            child: const Text('إظهار الإجابة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        )
                      else ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent, 
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () { 
                              SoundEffectsManager.playCorrect();
                              widget.onResult(true); 
                              Navigator.pop(context); 
                            },
                            child: const Text('إجابة صحيحة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent, 
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () { 
                              SoundEffectsManager.playIncorrect();
                              widget.onResult(false); 
                              Navigator.pop(context); 
                            },
                            child: const Text('إجابة خاطئة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                      ]
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_showAnswer)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber, 
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => setState(() => _showAnswer = true),
                          child: const Text('إظهار الإجابة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        )
                      else ...[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent, 
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () { 
                            SoundEffectsManager.playCorrect();
                            widget.onResult(true); 
                            Navigator.pop(context); 
                          },
                          child: const Text('إجابة صحيحة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent, 
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () { 
                            SoundEffectsManager.playIncorrect();
                            widget.onResult(false); 
                            Navigator.pop(context); 
                          },
                          child: const Text('إجابة خاطئة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ]
                    ],
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
