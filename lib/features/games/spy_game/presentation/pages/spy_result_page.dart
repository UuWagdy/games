import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/spy_game_provider.dart';
import 'package:games/core/design/themed_background.dart';
import 'package:games/core/design/app_themes.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import '../widgets/glass_container.dart';

class SpyResultPage extends ConsumerWidget {
  const SpyResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(spyGameProvider);
    final sortedPlayers = [...state.players]..sort((a, b) => b.score.compareTo(a.score));
    final isSpyWinner = state.winnerTeam == 1;
    final spies = state.players.where((p) => p.isSpy).map((p) => p.name).join(' و ');

    final themeAsync = ref.watch(currentThemeProvider);
    final theme = themeAsync.value ?? AppThemes.defaultTheme;

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("النتائج النهائية", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                     Icon(
                       isSpyWinner ? Icons.security_outlined : Icons.group_outlined,
                       color: isSpyWinner ? Colors.redAccent : Colors.greenAccent,
                       size: 70,
                     ),
                     const SizedBox(height: 16),
                     Text(
                       isSpyWinner ? "فاز الجاسوس!" : "فاز اللاعبون!",
                       style: TextStyle(
                         color: isSpyWinner ? Colors.redAccent : Colors.greenAccent,
                         fontSize: 28,
                         fontWeight: FontWeight.bold,
                       ),
                       textAlign: TextAlign.center,
                     ),
                     const SizedBox(height: 10),
                     Text(
                       "الجاسوس كان: $spies",
                       style: const TextStyle(color: Colors.white70, fontSize: 16),
                       textAlign: TextAlign.center,
                     ),
                     const SizedBox(height: 8),
                     Text(
                       "الكلمة السرية كانت: ${state.currentWord?.text}",
                       style: const TextStyle(color: Colors.white38, fontSize: 14),
                       textAlign: TextAlign.center,
                     ),
                     const SizedBox(height: 24),
                     const Text(
                       "جدول النقاط",
                       style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                     ),
                     const SizedBox(height: 16),
                     ListView.builder(
                       shrinkWrap: true,
                       physics: const NeverScrollableScrollPhysics(),
                       itemCount: sortedPlayers.length,
                       itemBuilder: (context, index) {
                         final p = sortedPlayers[index];
                         return Container(
                           margin: const EdgeInsets.only(bottom: 10),
                           child: GlassContainer(
                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                             opacity: 0.1,
                             child: Row(
                               children: [
                                 Text(
                                   p.name,
                                   style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                 ),
                                 if (p.isSpy)
                                   const Padding(
                                     padding: EdgeInsets.symmetric(horizontal: 8.0),
                                     child: Icon(Icons.person_search, color: Colors.redAccent, size: 14),
                                   ),
                                 const Spacer(),
                                 Text(
                                   p.score.toString(),
                                   style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold),
                                 ),
                               ],
                             ),
                           ),
                         );
                       },
                     ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => ref.read(spyGameProvider.notifier).resetGame(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("نهاية اللعبة"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                           ref.read(spyGameProvider.notifier).nextRound();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("الجولة التالية"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
