import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/core/design/app_design.dart';
import 'package:games/core/design/app_themes.dart';
import 'package:games/core/design/themed_background.dart';
import 'package:games/core/providers/sound_effects_provider.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import 'package:games/features/teams/domain/entities/team.dart';
import '../../domain/entities/saint_picture.dart';
import '../../domain/entities/hazer_fazer_state.dart';
import '../providers/hazer_fazer_providers.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/hazer_fazer_board.dart';
import '../widgets/hazer_fazer_guess_dialog.dart';
import '../widgets/hazer_fazer_question_dialog.dart';
import '../widgets/hazer_fazer_settings_dialog.dart';

class HazerFazerPage extends ConsumerStatefulWidget {
  const HazerFazerPage({super.key});

  @override
  ConsumerState<HazerFazerPage> createState() => _HazerFazerPageState();
}

class _HazerFazerPageState extends ConsumerState<HazerFazerPage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Team? _getActiveTeam(List<Team> teams, int teamIndex) {
    if (teams.isEmpty) return null;
    return teams[teamIndex % teams.length];
  }

  void _handleTileTap(int index) {
    final state = ref.read(hazerFazerControllerProvider);
    final teams = ref.read(teamsListProvider).value ?? [];
    final activeTeam = _getActiveTeam(teams, state.currentTeamIndex);
    final activeRevealed = state.getActiveRevealedTiles(activeTeam?.id);

    if (state.isWon || activeRevealed.contains(index)) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => HazerFazerQuestionDialog(
        tileIndex: index,
        onResult: (isCorrect) {
          if (isCorrect) {
            ref.read(hazerFazerControllerProvider.notifier).revealTile(index, activeTeamId: activeTeam?.id);
          }
          // Advance turn to next team
          if (teams.length > 1) {
            ref.read(hazerFazerControllerProvider.notifier).nextTeamTurn();
          }
        },
      ),
    );
  }

  void _openGuessDialog() {
    final state = ref.read(hazerFazerControllerProvider);
    final teams = ref.read(teamsListProvider).value ?? [];
    final activeTeam = _getActiveTeam(teams, state.currentTeamIndex);
    final activeSaint = state.getActiveSaint(activeTeam?.id);

    final settings = ref.read(generalSettingsProvider).value ?? {};
    final defaultPoints = (settings['hazer_fazer_win_points'] as int?) ?? state.winPoints;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => HazerFazerGuessDialog(
        correctSaint: activeSaint,
        defaultPoints: defaultPoints,
        initialTeamId: activeTeam?.id,
        onGuessResult: ({
          required bool isCorrect,
          required int? teamId,
          required String? teamName,
          required int points,
        }) async {
          if (isCorrect) {
            await ref.read(hazerFazerControllerProvider.notifier).submitGuess(
                  isCorrect: true,
                  teamId: teamId,
                  teamName: teamName,
                  customPoints: points,
                );

            if (!mounted) return;
            _showCelebrationDialog(
              saint: activeSaint,
              winningTeamName: teamName,
              winPoints: points,
            );
          } else {
            SoundEffectsManager.playIncorrect();
            if (teams.length > 1) {
              ref.read(hazerFazerControllerProvider.notifier).nextTeamTurn();
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تخمين غير صحيح! تحول الدور للفريق التالي 👏'),
                  backgroundColor: Colors.redAccent,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showCelebrationDialog({
    required SaintPicture saint,
    required String? winningTeamName,
    required int winPoints,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CelebrationDialog(
        saint: saint,
        winningTeamName: winningTeamName,
        winPoints: winPoints,
        onNewRound: () {
          ref.read(hazerFazerControllerProvider.notifier).startNewRound();
        },
        onBackToHub: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hazerFazerControllerProvider);
    final teamsAsync = ref.watch(teamsListProvider);
    final teams = teamsAsync.value ?? [];
    final activeTeam = _getActiveTeam(teams, state.currentTeamIndex);
    final activeSaint = state.getActiveSaint(activeTeam?.id);
    final activeRevealed = state.getActiveRevealedTiles(activeTeam?.id);

    final themeAsync = ref.watch(currentThemeProvider);
    final theme = themeAsync.value ?? AppThemes.defaultTheme;
    final isSmall = AppDesign.isSmallScreen(context);

    final isMultiBoardMode = state.gameMode == HazerFazerGameMode.perTeam &&
        state.perTeamView == HazerFazerPerTeamView.all &&
        teams.length > 1;

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'رجوع للرئيسية',
          ),
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.extension_rounded, color: Colors.amberAccent, size: 22),
              ),
              const SizedBox(width: 10),
              const Text(
                'حزر فزر',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          actions: [
            // Quick toggle between Multi-Board and Single-Board when in per-team mode
            if (state.gameMode == HazerFazerGameMode.perTeam && teams.length > 1)
              IconButton(
                icon: Icon(
                  state.perTeamView == HazerFazerPerTeamView.all
                      ? Icons.view_sidebar_rounded
                      : Icons.grid_view_rounded,
                  color: Colors.cyanAccent,
                ),
                tooltip: state.perTeamView == HazerFazerPerTeamView.all
                    ? 'تبديل: عرض لوحة الفريق الحالي فقط'
                    : 'تبديل: عرض جميع لوحات الفرق معاً',
                onPressed: () {
                  final nextView = state.perTeamView == HazerFazerPerTeamView.all
                      ? HazerFazerPerTeamView.single
                      : HazerFazerPerTeamView.all;
                  ref.read(hazerFazerControllerProvider.notifier).setPerTeamView(nextView);
                },
              ),
            IconButton(
              icon: const Icon(Icons.replay_rounded, color: Colors.white70),
              tooltip: 'إعادة الدور الحالي',
              onPressed: () => ref.read(hazerFazerControllerProvider.notifier).restartCurrentRound(),
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, color: Colors.amberAccent),
              tooltip: 'دور جديد',
              onPressed: () => ref.read(hazerFazerControllerProvider.notifier).startNewRound(),
            ),
            IconButton(
              icon: Icon(Icons.settings_rounded, color: theme.primaryColor),
              tooltip: 'إعدادات اللعبة',
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const HazerFazerSettingsDialog(),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Team Leaderboard / Header Bar with Turn Highlight
              if (teams.isNotEmpty)
                _buildTeamScoreboard(teams, state.currentTeamIndex, isSmall)
              else
                const SizedBox(height: 8),

              // Active Turn & Round Info Banner
              _buildTurnAndRoundBanner(state, activeTeam, activeRevealed.length, isMultiBoardMode, isSmall),

              const SizedBox(height: 8),

              // Boards Area: Either Multi-Board (All Teams Side-by-Side) or Single Focused Board
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: isMultiBoardMode
                      ? _buildMultiTeamBoards(state, teams, activeTeam, isSmall)
                      : HazerFazerBoard(
                          saint: activeSaint,
                          tileCount: state.tileCount,
                          revealedTiles: activeRevealed,
                          isWon: state.isWon,
                          teamNameLabel: (state.gameMode == HazerFazerGameMode.perTeam && activeTeam != null)
                              ? 'صورة فريق ${activeTeam.name}'
                              : null,
                          teamColor: activeTeam != null
                              ? _getTeamColor(teams.indexOf(activeTeam))
                              : Colors.amberAccent,
                          onTileTap: _handleTileTap,
                        ),
                ),
              ),

              const SizedBox(height: 10),

              // Bottom Actions: Guess Button / Win Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _buildBottomControls(state, activeTeam, activeRevealed.isNotEmpty, isSmall),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiTeamBoards(
    HazerFazerState state,
    List<Team> teams,
    Team? activeTeam,
    bool isSmall,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(teams.length, (idx) {
        final team = teams[idx];
        final isCurrentTeamTurn = (team.id == activeTeam?.id);
        final teamSaint = state.teamProgress[team.id]?.saint ?? state.currentSaint;
        final teamRevealed = state.teamProgress[team.id]?.revealedTiles ?? const {};
        final teamWon = state.teamProgress[team.id]?.isWon ?? false;
        final color = _getTeamColor(idx);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: HazerFazerBoard(
              saint: teamSaint,
              tileCount: state.tileCount,
              revealedTiles: teamRevealed,
              isWon: teamWon,
              isInteractive: isCurrentTeamTurn,
              isActiveTeam: isCurrentTeamTurn,
              teamNameLabel: 'لوحة فريق ${team.name}',
              teamColor: color,
              onTileTap: (tileIdx) {
                if (isCurrentTeamTurn) {
                  _handleTileTap(tileIdx);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('هذا ليس دور فريق ${team.name}! الدور الآن على فريق ${activeTeam?.name ?? ""} 🎯'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: Colors.amber[900],
                    ),
                  );
                }
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTeamScoreboard(List<Team> teams, int activeIndex, bool isSmall) {
    return Container(
      height: isSmall ? 48 : 58,
      margin: const EdgeInsets.only(top: 2, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                final isActive = (index == activeIndex % teams.length);
                final color = _getTeamColor(index);

                return InkWell(
                  onTap: () => ref.read(hazerFazerControllerProvider.notifier).setTeamTurn(index),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.amberAccent.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isActive ? Colors.amberAccent : color.withValues(alpha: 0.35),
                        width: isActive ? 2.2 : 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: Colors.amberAccent.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isActive) ...[
                          const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 16),
                          const SizedBox(width: 4),
                        ] else ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          team.name,
                          style: TextStyle(
                            color: isActive ? Colors.amberAccent : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: isActive ? 14 : 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${team.score}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: isActive ? 18 : 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (teams.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: IconButton.filledTonal(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                tooltip: 'نقل الدور للفريق التالي',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.amberAccent,
                ),
                onPressed: () => ref.read(hazerFazerControllerProvider.notifier).nextTeamTurn(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTurnAndRoundBanner(
    HazerFazerState state,
    Team? activeTeam,
    int openedCount,
    bool isMultiBoard,
    bool isSmall,
  ) {
    final total = state.tileCount;
    final isPerTeam = state.gameMode == HazerFazerGameMode.perTeam;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Active Team Turn Badge
          if (activeTeam != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag_rounded, size: 16, color: Colors.black87),
                  const SizedBox(width: 6),
                  Text(
                    isPerTeam
                        ? (isMultiBoard
                            ? 'الدور على فريق: ${activeTeam.name} (لوحته مفعّلة فقط)'
                            : 'دور فريق: ${activeTeam.name} (صورته)')
                        : 'الدور الآن: ${activeTeam.name}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                'الدور ${state.roundNumber}',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),

          // Tiles Progress Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amberAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
            ),
            child: Text(
              'المربعات المفتوحة: $openedCount من $total',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(
    HazerFazerState state,
    Team? activeTeam,
    bool hasRevealedTiles,
    bool isSmall,
  ) {
    if (state.isWon) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => ref.read(hazerFazerControllerProvider.notifier).startNewRound(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('دور جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              foregroundColor: const Color(0xFF1E1B4B),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(width: 14),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home_rounded),
            label: const Text('رجوع للواجهة التي بها جميع الألعاب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      );
    }

    final bool canGuess = state.canGuess || hasRevealedTiles;

    if (!canGuess) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, color: Colors.amberAccent, size: 20),
            SizedBox(width: 10),
            Text(
              'اختر أحد المربعات للإجابة على سؤاله وكشف جزء من الصورة',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    // Glowing Animated Guess Button
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowAlpha = 0.3 + (_pulseController.value * 0.4);
        final teamSuffix = (state.gameMode == HazerFazerGameMode.perTeam && activeTeam != null)
            ? ' (لفريق ${activeTeam.name})'
            : '';

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withValues(alpha: glowAlpha),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _openGuessDialog,
            icon: const Icon(Icons.auto_awesome_rounded, size: 22),
            label: Text(
              '🔮 تخمين صاحب الصورة الآن$teamSuffix',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.amberAccent, width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getTeamColor(int index) {
    final colors = [
      Colors.redAccent,
      Colors.greenAccent,
      Colors.cyanAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.amberAccent,
    ];
    return colors[index % colors.length];
  }
}
