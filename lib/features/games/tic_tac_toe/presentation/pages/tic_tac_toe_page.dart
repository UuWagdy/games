import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import 'package:games/core/design/app_design.dart';
import '../providers/tic_tac_toe_providers.dart';
import '../../domain/entities/tic_tac_toe_state.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/features/questions/domain/entities/question.dart';

import '../widgets/xo_board_widget.dart';
import '../widgets/xo_settings_dialog.dart';

class TicTacToePage extends ConsumerStatefulWidget {
  const TicTacToePage({super.key});

  @override
  ConsumerState<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends ConsumerState<TicTacToePage> {
  int? _pendingMove;
  bool _isProcessingMove = false;

  void _handleBoardTap(int index) async {
    final gameState = ref.read(ticTacToeControllerProvider);
    final settingsAsync = ref.read(generalSettingsProvider);
    final settings = settingsAsync.value;
    
    // Safety checks
    if (gameState.board[index] != null || gameState.winner != null || gameState.isDraw || _isProcessingMove) return;
    // Block tap if computer is supposed to move
    if (gameState.vsComputer && gameState.currentPlayer == TicTacToePlayer.o) return;

    final questionsEnabled = settings?['tic_tac_toe_questions_enabled'] ?? false;
    
    if (questionsEnabled) {
      _pendingMove = index;
      _showQuestionFlow();
    } else {
      ref.read(ticTacToeControllerProvider.notifier).makeMove(index);
    }
  }




  void _showQuestionFlow() async {
    final settingsAsync = ref.read(generalSettingsProvider);
    final selectedCategoryIds = settingsAsync.value?['tic_tac_toe_category_ids'] as List<int>? ?? [];
    
    List<Question> availableQuestions = [];
    if (selectedCategoryIds.isEmpty) {
      final allCats = await ref.read(categoriesProvider.future);
      final listQs = await Future.wait(allCats.map((cat) => ref.read(questionsProvider(cat.id).future)));
      for (var qs in listQs) {
        availableQuestions.addAll(qs);
      }
    } else {
        final listQs = await Future.wait(selectedCategoryIds.map((id) => ref.read(questionsProvider(id).future)));
        for (var qs in listQs) {
          availableQuestions.addAll(qs);
        }
    }

    if (!mounted) return;
    if (availableQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد أسئلة متاحة!')));
      if (_pendingMove != null) {
        ref.read(ticTacToeControllerProvider.notifier).makeMove(_pendingMove!);
        _pendingMove = null;
      }
      return;
    }

    final randomQuestion = availableQuestions[math.Random().nextInt(availableQuestions.length)];
    final teams = ref.read(teamsListProvider).value ?? [];
    final settings = ref.read(generalSettingsProvider).value;
    
    final isXTurn = ref.read(ticTacToeControllerProvider).currentPlayer == TicTacToePlayer.x;
    int? teamId;
    if (isXTurn) {
      teamId = settings?['tic_tac_toe_team_x_id'] as int?;
    } else {
      teamId = settings?['tic_tac_toe_team_o_id'] as int?;
    }

    dynamic activeTeam;
    if (teams.where((t) => t.id == teamId).isNotEmpty) {
      activeTeam = teams.firstWhere((t) => t.id == teamId);
    } else if (isXTurn && teams.isNotEmpty) {
      activeTeam = teams.first;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _QuestionDialog(
        question: randomQuestion,
        teamName: activeTeam?.name ?? (isXTurn ? 'اللاعب X' : 'اللاعب O'),
        onResult: (isCorrect) {
          if (isCorrect) {
            if (_pendingMove != null) {
              ref.read(ticTacToeControllerProvider.notifier).makeMove(_pendingMove!);
            }
          } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('إجابة خاطئة! ضاع دورك')));
             ref.read(ticTacToeControllerProvider.notifier).skipTurn(); 
          }
          _pendingMove = null;
        },
        isReadOnly: false,
      ),
    );
  }

  void _handleGameEnd(TicTacToeState next) async {
      final teams = ref.read(teamsListProvider).value ?? [];
      final settings = ref.read(generalSettingsProvider).value;
      final syncScores = settings?['sync_scores'] ?? false;
      final winPoints = settings?['tic_tac_toe_win_points'] ?? 20;

      if (next.winner != null && teams.isNotEmpty) {
        final winPlayer = next.winner!;
        int? teamId;
        if (winPlayer == TicTacToePlayer.x) {
          teamId = settings?['tic_tac_toe_team_x_id'] as int?;
        } else {
          teamId = settings?['tic_tac_toe_team_o_id'] as int?;
        }
        bool isComputerWinner = (winPlayer == TicTacToePlayer.o && next.vsComputer);
        
        dynamic winningTeam;
        if (isComputerWinner) {
           // Do not award any points to the AI, as requested by the user.
        } else {
           if (teams.where((t) => t.id == teamId).isNotEmpty) {
              winningTeam = teams.firstWhere((t) => t.id == teamId);
           } else if (winPlayer == TicTacToePlayer.x && teams.isNotEmpty) {
              winningTeam = teams.first;
           }
           if (winningTeam != null && syncScores) {
               await ref.read(teamsListProvider.notifier).updateScore(
                  winningTeam.id!, 
                  winPoints, 
                  reason: 'فوز في لعبة XO',
                  gameName: 'لعبة XO'
                );
           }
        }
        
        String winMsg = isComputerWinner ? 'الذكاء الاصطناعي بنجاح' : (winningTeam != null ? 'فريق ${winningTeam.name} بـ $winPoints نقطة' : 'اللاعب ${winPlayer == TicTacToePlayer.x ? "X" : "O"}');
        _showGameOverDialog('مبروك! $winMsg', isWin: true);
      } else if (next.isDraw) {
        _showGameOverDialog('التعادل سيد الموقف!', isWin: false);
      }
  }

  void _showGameOverDialog(String message, {required bool isWin}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          padding: const EdgeInsets.all(32),
          decoration: AppDesign.glassDecoration.copyWith(
            color: isWin ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9)
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isWin ? Icons.emoji_events : Icons.sentiment_very_dissatisfied, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              Text(message, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(ticTacToeControllerProvider.notifier).resetGame();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('لعب مرة أخرى', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(ticTacToeControllerProvider);
    final teamsAsync = ref.watch(teamsListProvider);
    // Removed unused theme variable

    ref.listen(generalSettingsProvider, (prev, next) {
      final bool prevGlobalAi = prev?.value?['global_ai_enabled'] == true;
      final bool prevLocalAi = prev?.value?['tic_tac_toe_vs_computer'] == true;
      final bool nextGlobalAi = next.value?['global_ai_enabled'] == true;
      final bool nextLocalAi = next.value?['tic_tac_toe_vs_computer'] == true;
      
      final bool prevEffective = prevGlobalAi || prevLocalAi;
      final bool nextEffective = nextGlobalAi || nextLocalAi;

      if (prevEffective != nextEffective) {
        ref.read(ticTacToeControllerProvider.notifier).toggleVsComputer(nextEffective);
      }
    });

    ref.listen(ticTacToeControllerProvider, (previous, next) {
      // Game end detection
      if (previous is TicTacToeState) {
        if ((next.winner != null || next.isDraw) && (previous.winner == null && previous.isDraw == false)) {
          _handleGameEnd(next);
        }
      }
    });

    final currentTheme = ref.watch(currentThemeProvider);
    
    return AppDesign.backgroundWrapper(
      theme: currentTheme.value,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('لعبة XO', style: AppDesign.titleStyle),
          centerTitle: true,
          actions: [

            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => showDialog(context: context, builder: (_) => const XOSettingsDialog()),
            ),
            IconButton(
              icon: const Icon(Icons.restart_alt, color: Colors.white),
              onPressed: () => ref.read(ticTacToeControllerProvider.notifier).resetGame(),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildTurnInfo(gameState),
              const SizedBox(height: 10),
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxHeight: 500,
                      maxWidth: 500,
                    ),
                    margin: const EdgeInsets.all(24),
                    decoration: AppDesign.glassDecoration.copyWith(
                      border: Border.all(color: Colors.white10),
                    ),
                    child: XOBoardWidget(
                      gameState: gameState,
                      onCellTap: _handleBoardTap,
                    ),
                  ),
                ),
              ),
              if (teamsAsync.value?.isNotEmpty ?? false)
                _buildScoreInfo(teamsAsync.value!, ref.read(generalSettingsProvider).value),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTurnInfo(TicTacToeState gameState) {
      final isXTurn = gameState.currentPlayer == TicTacToePlayer.x;
      final vsComputer = gameState.vsComputer;
      
      final teams = ref.watch(teamsListProvider).value ?? [];
      final settings = ref.watch(generalSettingsProvider).value;
      final teamXId = settings?['tic_tac_toe_team_x_id'];
      final teamOId = settings?['tic_tac_toe_team_o_id'];
      final teamX = teams.where((t) => t.id == teamXId).isNotEmpty ? teams.firstWhere((t) => t.id == teamXId) : null;
      final teamO = teams.where((t) => t.id == teamOId).isNotEmpty ? teams.firstWhere((t) => t.id == teamOId) : null;

      String label;
      if (vsComputer) {
          label = isXTurn ? (teamX?.name != null ? 'دور فريق ${teamX!.name}' : 'دورك (X)') : 'دور الكمبيوتر (O)';
      } else {
          if (isXTurn) {
            label = teamX?.name != null ? 'دور فريق ${teamX!.name}' : 'دور اللاعب الأول (X)';
          } else {
            label = teamO?.name != null ? 'دور فريق ${teamO!.name}' : 'دور اللاعب الثاني (O)';
          }
      }

      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: AppDesign.glassDecoration,
          child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    isXTurn ? Icons.person : (vsComputer ? Icons.computer : Icons.person_outline), 
                    color: isXTurn ? Colors.blueAccent : Colors.redAccent,
                    size: 24
                ),
                const SizedBox(width: 12),
                Text(
                    label,
                    style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: isXTurn ? Colors.blueAccent : Colors.redAccent
                    ),
                ),
              ],
          ),
      );
  }

  Widget _buildScoreInfo(List<dynamic> teams, Map<String, dynamic>? settings) {
      final teamXId = settings?['tic_tac_toe_team_x_id'];
      final teamOId = settings?['tic_tac_toe_team_o_id'];
      final teamX = teams.where((t) => t.id == teamXId).isNotEmpty ? teams.firstWhere((t) => t.id == teamXId) : null;
      final teamO = teams.where((t) => t.id == teamOId).isNotEmpty ? teams.firstWhere((t) => t.id == teamOId) : null;
      
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               if (teamX != null)
                 Text(
                    'فريق ${teamX.name}: ${teamX.score}',
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold),
                 ),
               if (teamO != null && !(settings?['tic_tac_toe_vs_computer'] ?? true))
                 Text(
                    'فريق ${teamO.name}: ${teamO.score}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
                 ),
                if (teamX == null && (teams.isNotEmpty))
                  Text(
                    'نقاط ${teams.first.name}: ${teams.first.score}',
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
            ],
          ),
      );
  }
}

class _QuestionDialog extends StatefulWidget {
  final Question question;
  final String teamName;
  final Function(bool) onResult;
  final bool isReadOnly;

  const _QuestionDialog({
    required this.question,
    required this.teamName,
    required this.onResult,
    this.isReadOnly = false,
  });

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    if (widget.isReadOnly) {
       Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
             setState(() => _showAnswer = true);
          }
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSmall = MediaQuery.of(context).size.width < 600;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          decoration: AppDesign.glassDecoration.copyWith(
            color: const Color(0xFF1E293B).withOpacity(0.9),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('سؤال للاعب: ${widget.teamName}', style: const TextStyle(fontSize: 16, color: Colors.blueAccent)),
              const SizedBox(height: 20),
              if (widget.question.imageData != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(widget.question.imageData!, height: 180, fit: BoxFit.contain),
                ),
                const SizedBox(height: 20),
              ],
              Text(widget.question.text, style: TextStyle(fontSize: isSmall ? 20 : 26, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 30),
              if (_showAnswer) ...[
                const Text('الإجابة الصحيحة:', style: TextStyle(color: Colors.amberAccent, fontSize: 14)),
                Text(widget.question.answer, style: const TextStyle(fontSize: 22, color: Colors.greenAccent, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 30),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_showAnswer && !widget.isReadOnly)
                    ElevatedButton(
                      onPressed: () => setState(() => _showAnswer = true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                      child: const Text('إظهار الإجابة'),
                    )
                  else if (!widget.isReadOnly) ...[
                    ElevatedButton(
                      onPressed: () { widget.onResult(true); Navigator.pop(context); },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('إجابة صحيحة'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () { widget.onResult(false); Navigator.pop(context); },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      child: const Text('إجابة خاطئة'),
                    ),
                  ] else if (widget.isReadOnly && _showAnswer)
                     const Text('الكمبيوتر يفكر في الإجابة...', style: TextStyle(color: Colors.amberAccent, fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
