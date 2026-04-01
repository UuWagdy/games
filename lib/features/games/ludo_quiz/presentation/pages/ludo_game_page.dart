import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import '../../domain/entities/ludo_entities.dart';
import '../../domain/models/ludo_state.dart';
import '../providers/ludo_controller.dart';
import '../widgets/ludo_board.dart';
import '../widgets/dice_widget.dart';
import '../widgets/ludo_question_dialog.dart';
import 'ludo_settings_page.dart';
import 'package:games/core/design/themed_background.dart';
import 'package:games/core/design/app_themes.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import 'package:flutter/services.dart';

class LudoGamePage extends ConsumerWidget {
  const LudoGamePage({super.key});

  static const Map<LudoColor, Color> _colorMap = {
    LudoColor.red: Colors.red,
    LudoColor.green: Colors.green,
    LudoColor.yellow: Colors.amber,
    LudoColor.blue: Colors.blue,
  };

  static const Map<LudoColor, String> _nameMap = {
    LudoColor.red: 'أحمر',
    LudoColor.green: 'أخضر',
    LudoColor.yellow: 'أصفر',
    LudoColor.blue: 'أزرق',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LudoState state = ref.watch(ludoControllerProvider);
    final LudoController notifier = ref.read(ludoControllerProvider.notifier);
    final teamsAsync = ref.watch(teamsListProvider);
    final teams = teamsAsync.value ?? [];

    // Listen for question phase
    ref.listen<LudoState>(
      ludoControllerProvider,
      (LudoState? prev, LudoState next) {
        if (next.phase == LudoGameState.answeringQuestion && 
            next.currentQuestionTrigger != null && 
            (prev?.phase != LudoGameState.answeringQuestion)) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext ctx) => LudoQuestionDialog(trigger: next.currentQuestionTrigger!),
          );
        }
      },
    );

    // Auto-initialize if players are empty
    if (state.players.isEmpty && teams.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final Map<LudoColor, String> selection = {};
        for (int i = 0; i < teams.length && i < LudoColor.values.length; i++) {
          selection[LudoColor.values[i]] = teams[i].name;
        }
        notifier.initGame(selection);
      });
    }

    ref.listen(generalSettingsProvider, (prev, next) {
      final prevAi = prev?.value?['global_ai_enabled'] ?? false;
      final nextAi = next.value?['global_ai_enabled'] ?? false;
      if (prevAi != nextAi) {
        notifier.toggleAiPlayer(nextAi);
      }
    });

    final LudoColor currentColor = state.currentPlayer.color;
    final String teamName = state.colorTeamNames[currentColor] ??
        (teams.length > state.currentTurn ? teams[state.currentTurn].name : _nameMap[currentColor]!);

    final themeAsync = ref.watch(currentThemeProvider);
    final theme = themeAsync.value ?? AppThemes.defaultTheme;

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("لودو الأسئلة", style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor, fontSize: 16)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: 40,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.restart_alt, color: Colors.orangeAccent, size: 20),
              tooltip: 'تصفير النقاط',
              onPressed: () => _confirmResetScores(context, ref),
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: theme.primaryColor, size: 20),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LudoSettingsPage())),
            ),
          ],
        ),
        body: SafeArea(
          child: Focus(
            autofocus: true,
            onKey: (node, event) {
              if (event is RawKeyDownEvent && 
                  (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter)) {
                if (state.phase == LudoGameState.idle) {
                  notifier.rollDice();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: Column(
              children: [
                // Compact Score chips
                if (teams.isNotEmpty) _buildScoreChips(teams, state),
                
                // Slim Turn indicator
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _colorMap[currentColor]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _colorMap[currentColor]!.withOpacity(0.5), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _colorMap[currentColor],
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: _colorMap[currentColor]!, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'دور: $teamName',
                        style: TextStyle(color: _colorMap[currentColor], fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
      
                // Board In Themed Frame
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ThemedGameFrame(
                          padding: const EdgeInsets.all(8),
                          child: const LudoBoard(),
                        ),
                      ),
                    ),
                  ),
                ),
      
                // Slim Bottom controls
                _buildBottomBar(state, notifier),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreChips(List<dynamic> teams, LudoState state) {
    // Show only the teams that are actually playing in the current game
    final activeTeams = teams.where((t) => state.colorTeamNames.containsValue(t.name)).toList();
    final displayTeams = activeTeams.isEmpty ? teams : activeTeams;
    
    return Container(
      height: 30,
      margin: const EdgeInsets.only(top: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displayTeams.length,
        itemBuilder: (BuildContext context, int index) {
          final team = displayTeams[index];
          Color c = Colors.grey;
          
          if (activeTeams.isNotEmpty) {
            // Find the chosen color for this team
            final entry = state.colorTeamNames.entries.where((e) => e.value == team.name).firstOrNull;
            if (entry != null) {
              c = _colorMap[entry.key] ?? Colors.white;
            }
          } else {
            // Fallback before any selection
            final colors = [Colors.red, Colors.green, Colors.amber, Colors.blue];
            c = colors[index % colors.length];
          }

          return Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: c.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(team.name, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text('${team.score}', style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w900)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(LudoState state, LudoController notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Vision Mode Button (Conditional)
          if (state.isVisionModeEnabled) 
            _buildMiniButton(
              iconWidget: Image.asset(
                'assets/images/angel.png',
                width: 24,
                height: 24,
                color: _canActivateVision(state) ? Colors.cyanAccent : Colors.white24,
                colorBlendMode: BlendMode.srcIn,
              ),
              label: 'الرؤيا',
              color: _canActivateVision(state) ? Colors.cyanAccent : Colors.white24,
              onTap: _canActivateVision(state) ? () => _handleVision(state, notifier) : null,
            ),

          // Dice (Compact)
          DiceWidget(
            value: state.diceValue,
            isRolling: state.phase == LudoGameState.rolling,
            onTap: state.phase == LudoGameState.idle ? () => notifier.rollDice() : null,
            accentColor: LudoGamePage._colorMap[state.currentPlayer.color] ?? Colors.amber,
          ),

          // Phase indicator
          _buildPhaseIndicator(
            state.phase, 
            LudoGamePage._colorMap[state.currentPlayer.color] ?? Colors.amber,
          ),
        ],
      ),
    );
  }

  bool _canActivateVision(LudoState state) {
    final player = state.currentPlayer;
    
    // Per Player constraints
    if (state.visionModeScope == VisionModeScope.player && player.hasUsedVision) {
      return false;
    }
    
    // Any unlocked token?
    return player.tokens.any((t) => t.isVisionModeUnlocked);
  }

  void _handleVision(LudoState state, LudoController notifier) {
    for (final LudoToken t in state.currentPlayer.tokens) {
      if (t.isVisionModeUnlocked) {
        notifier.activateVisionMode(t);
        break;
      }
    }
  }

  Widget _buildMiniButton({IconData? icon, Widget? iconWidget, required String label, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget ?? Icon(icon, color: color, size: 28),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator(LudoGameState phase, Color playerColor) {
    String label;
    IconData icon;
    Color color;
    switch (phase) {
      case LudoGameState.idle: label = 'ارمِ'; icon = Icons.casino; color = playerColor.withOpacity(0.7); break;
      case LudoGameState.rolling: label = 'رمي'; icon = Icons.refresh; color = Colors.white; break;
      case LudoGameState.result: label = 'النتيجة'; icon = Icons.casino; color = playerColor; break;
      case LudoGameState.choosingToken: label = 'اختر'; icon = Icons.touch_app; color = playerColor; break;
      case LudoGameState.answeringQuestion: label = 'سؤال'; icon = Icons.help; color = Colors.orangeAccent; break;
      case LudoGameState.moving: label = 'تحرك'; icon = Icons.directions_walk; color = Colors.greenAccent; break;
      case LudoGameState.gameOver: label = 'انتهت'; icon = Icons.emoji_events; color = Colors.yellowAccent; break;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _confirmResetScores(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تصفير النقاط وحذف السجل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
            'هل أنت متأكد من تصفير نقاط كل الفرق وحذف سجل النقاط بالكامل؟ سيتم إعادة تشغيل اللعبة أيضاً.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await ref.read(teamsListProvider.notifier).resetScoresAndClearLogs();
              final state = ref.read(ludoControllerProvider);
              ref.read(ludoControllerProvider.notifier).initGame(
                    state.colorTeamNames,
                    isTeamMode: state.isTeamMode,
                    playerTeams: state.playerTeams,
                  );
              Navigator.pop(context);
            },
            child: const Text('تصفير الكل'),
          ),
        ],
      ),
    );
  }
}
