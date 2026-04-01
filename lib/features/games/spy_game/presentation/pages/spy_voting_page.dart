import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/spy_game_provider.dart';
import 'package:games/core/design/themed_background.dart';
import 'package:games/core/design/app_themes.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import '../widgets/glass_container.dart';

class SpyVotingPage extends ConsumerStatefulWidget {
  const SpyVotingPage({super.key});

  @override
  ConsumerState<SpyVotingPage> createState() => _SpyVotingPageState();
}

class _SpyVotingPageState extends ConsumerState<SpyVotingPage> {
  int _currentVoterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(spyGameProvider);
    final themeAsync = ref.watch(currentThemeProvider);
    final theme = themeAsync.value ?? AppThemes.defaultTheme;
    if (state.players.isEmpty) return const SizedBox();
    
    final voter = state.players[_currentVoterIndex];

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(        title: const Text("التصويت", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showEndGameDialog(context),
            icon: const Icon(Icons.logout_outlined, color: Colors.redAccent, size: 20),
            tooltip: "إنهاء اللعبة",
          ),
          const SizedBox(width: 8),
        ],
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.how_to_vote, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "دور: ${voter.name}",
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "من هو الجاسوس برأيك؟",
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: state.players.length,
                  itemBuilder: (context, index) {
                    final target = state.players[index];
                    if (target.id == voter.id) return const SizedBox.shrink();
    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: GlassContainer(
                        padding: EdgeInsets.zero,
                        opacity: 0.1,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(
                            target.name,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(Icons.radio_button_off, color: Colors.blueAccent, size: 18),
                          onTap: () {
                             ref.read(spyGameProvider.notifier).castVote(voter.id, target.id);
                             if (_currentVoterIndex < state.players.length - 1) {
                               setState(() {
                                 _currentVoterIndex++;
                               });
                             }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "${_currentVoterIndex + 1} / ${state.players.length}",
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _showEndGameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("إنهاء اللعبة", style: TextStyle(color: Colors.white)),
        content: const Text("هل تريد حقاً إنهاء اللعبة والعودة للرئيسية؟", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
               ref.read(spyGameProvider.notifier).resetGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text("إنهاء"),
          ),
        ],
      ),
    );
  }
}
