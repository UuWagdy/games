import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/core/design/app_design.dart';
import 'package:games/core/design/themed_background.dart';
import 'package:games/features/games/quiz_arena/presentation/providers/quiz_arena_provider.dart';
import 'package:games/features/games/quiz_arena/presentation/pages/quiz_arena_game_page.dart';
import 'package:games/features/teams/domain/entities/team.dart';

class QuizArenaWinnerPage extends ConsumerWidget {
  const QuizArenaWinnerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizArenaGameProvider);
    final List<Team> sortedTeams = List<Team>.from(state.teams)..sort((a, b) => b.score.compareTo(a.score));
    final winners = state.winners;

    return Scaffold(
      body: ThemedBackground(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDesign.isSmallScreen(context) ? 16 : 32, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (winners.isNotEmpty)
                  _buildWinnerIcon(winners.first.name, context),
                const SizedBox(height: 32),
                Text(
                  'نهاية التحدي!',
                  style: TextStyle(
                    color: Colors.white60, 
                    fontSize: AppDesign.isSmallScreen(context) ? 18 : 24, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  winners.length > 1 ? 'تعادل!' : 'الفائز هو: ${winners.first.name}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.purpleAccent, 
                    fontSize: AppDesign.isSmallScreen(context) ? 28 : 36, 
                    fontWeight: FontWeight.w900, 
                    shadows: const [Shadow(color: Colors.purpleAccent, blurRadius: 20)]
                  ),
                ),
                const SizedBox(height: 40),
                _buildRankingTable(sortedTeams, context),
                const SizedBox(height: 40),
                _buildActionButtons(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerIcon(String name, BuildContext context) {
    bool isSmall = AppDesign.isSmallScreen(context);
    return Column(
      children: [
        Container(
          width: isSmall ? 100 : 150,
          height: isSmall ? 100 : 150,
          decoration: BoxDecoration(
            color: Colors.purpleAccent.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.purpleAccent, width: isSmall ? 3 : 4),
            boxShadow: [
              BoxShadow(color: Colors.purpleAccent.withOpacity(0.3), blurRadius: 40, spreadRadius: 10),
            ],
          ),
          child: Icon(Icons.emoji_events_rounded, color: Colors.purpleAccent, size: isSmall ? 50 : 80),
        ),
      ],
    );
  }

  Widget _buildRankingTable(List sortedTeams, BuildContext context) {
    bool isSmall = AppDesign.isSmallScreen(context);
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 24),
      decoration: AppDesign.glassDecoration,
      child: Column(
        children: [
          const Text('ترتيب الفرق', style: TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 16),
          for (final entry in sortedTeams.asMap().entries)
            Builder(
              builder: (context) {
                final index = entry.key;
                final team = entry.value;
                final isWinner = index == 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        alignment: Alignment.center,
                        child: Text('${index + 1}',
                            style: TextStyle(
                                color:
                                    isWinner ? Colors.purpleAccent : Colors.white30,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmall ? 16 : 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(team.name,
                            style: TextStyle(
                                color: isWinner ? Colors.white : Colors.white70,
                                fontSize: isSmall ? 16 : 18,
                                fontWeight:
                                    isWinner ? FontWeight.bold : FontWeight.normal)),
                      ),
                      const SizedBox(width: 12),
                      Text('${team.score}',
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: isSmall ? 18 : 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text('نقطة',
                          style: TextStyle(color: Colors.white24, fontSize: isSmall ? 10 : 12)),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    bool isSmall = AppDesign.isSmallScreen(context);
    final buttons = [
      ElevatedButton.icon(
        onPressed: () {
          ref.read(quizArenaGameProvider.notifier).restartGame();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const QuizArenaGamePage()));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purpleAccent.withOpacity(0.2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.purpleAccent)),
        ),
        icon: const Icon(Icons.replay_rounded),
        label: const Text('إعادة اللعبة', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      if (!isSmall) const SizedBox(width: 20) else const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
        ),
        icon: const Icon(Icons.home_rounded),
        label: const Text('القائمة الرئيسية', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ];

    if (isSmall) {
      return Column(
        children: buttons,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: buttons,
    );
  }
}
