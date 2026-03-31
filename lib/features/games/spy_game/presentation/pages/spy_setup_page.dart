import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/spy_game_provider.dart';
import '../widgets/glass_container.dart';
import 'spy_settings_page.dart';
import 'spy_reveal_page.dart';
import 'spy_game_page.dart';
import 'spy_voting_page.dart';
import 'spy_guess_page.dart';
import 'spy_result_page.dart';
import '../../domain/entities/game_state.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';

class SpySetupPage extends ConsumerStatefulWidget {
  const SpySetupPage({super.key});

  @override
  ConsumerState<SpySetupPage> createState() => _SpySetupPageState();
}

class _SpySetupPageState extends ConsumerState<SpySetupPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spyGameProvider.notifier).syncPlayersWithTeams();
    });
  }

  void _addPlayer() {
    if (_nameController.text.trim().isNotEmpty) {
      ref.read(spyGameProvider.notifier).addPlayer(_nameController.text.trim());
      _nameController.clear();
    }
  }

  void _confirmResetScores(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تصفير النقاط وحذف السجل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من تصفير نقاط كل الفرق وحذف سجل النقاط بالكامل؟', 
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await ref.read(teamsListProvider.notifier).resetScoresAndClearLogs();
              ref.read(spyGameProvider.notifier).resetGame();
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
    final state = ref.watch(spyGameProvider);
    
    ref.listen(teamsListProvider, (previous, next) {
        if (next is AsyncData) {
           ref.read(spyGameProvider.notifier).syncPlayersWithTeams();
        }
    });

    final players = state.players;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          "لعبة الجاسوس",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SpySettingsPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: 'تصفير النقاط',
            onPressed: () => _confirmResetScores(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 12),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "إضافة لاعبين (على الأقل 3)",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: "اسم اللاعب",
                                hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                filled: true,
                                fillColor: Colors.white.withAlpha(10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _addPlayer(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: _addPlayer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blueAccent.withAlpha(50),
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              player.name,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => ref.read(spyGameProvider.notifier).removePlayer(player.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: players.length >= 3
                      ? () => ref.read(spyGameProvider.notifier).startRound()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                  ),
                  child: const Text(
                    "ابدأ اللعبة",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpyGameMainScreen extends ConsumerWidget {
  const SpyGameMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(spyGameProvider);

    return switch (state.status) {
      SpyGameStatus.setup => const SpySetupPage(),
      SpyGameStatus.reveal => const SpyRevealPage(),
      SpyGameStatus.gameplay => const SpyGameplayPage(),
      SpyGameStatus.voting => const SpyVotingPage(),
      SpyGameStatus.spyGuess => const SpyGuessPage(),
      SpyGameStatus.result => const SpyResultPage(),
    };
  }
}
