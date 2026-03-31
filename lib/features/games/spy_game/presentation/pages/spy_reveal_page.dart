import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/spy_game_provider.dart';
import '../widgets/glass_container.dart';

class SpyRevealPage extends ConsumerWidget {
  const SpyRevealPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(spyGameProvider);
    final player = state.players[state.currentPlayerRevealIndex];
    final isLastPlayer = state.currentPlayerRevealIndex == state.players.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text("الجولة ${state.currentRound}", style: const TextStyle(color: Colors.white24, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => _showEndGameDialog(context, ref),
            icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
            label: const Text("إنهاء اللعبة", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
        automaticallyImplyLeading: false,
      ),
           body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Progress Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${state.currentPlayerRevealIndex + 1} / ${state.players.length}",
                      style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // Pass phone info
              if (!state.isWordRevealed) ...[
                const Icon(Icons.phonelink_ring_outlined, color: Colors.blueAccent, size: 60),
                const SizedBox(height: 24),
                const Text(
                  "مرر الهاتف إلى:",
                  style: TextStyle(color: Colors.white60, fontSize: 18),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    player.name,
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => ref.read(spyGameProvider.notifier).revealWord(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("اضغط للكشف", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
    
              // Revealed info
              if (state.isWordRevealed) ...[
                AnimatedOpacity(
                  opacity: state.isWordRevealed ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                        const SizedBox(height: 20),
                        if (player.isSpy) ...[
                          const Icon(Icons.person_search, color: Colors.redAccent, size: 70),
                          const SizedBox(height: 16),
                          const Text(
                            "أنت الجاسوس!",
                            style: TextStyle(color: Colors.redAccent, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (state.players.where((p) => p.isSpy).length > 1) ...[
                             const Text(
                               "الجواسيس الآخرون هم:",
                               style: TextStyle(color: Colors.white60, fontSize: 13),
                             ),
                             const SizedBox(height: 4),
                             Wrap(
                               spacing: 8,
                               children: state.players
                                 .where((p) => p.isSpy && p.id != player.id)
                                 .map((p) => Chip(
                                   label: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 11)),
                                   backgroundColor: Colors.redAccent.withOpacity(0.2),
                                   padding: EdgeInsets.zero,
                                   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                 ))
                                 .toList(),
                             ),
                             const SizedBox(height: 12),
                          ],
                          const Text(
                            "حاول أن لا يتم كشفك وتعرف على الكلمة السرية",
                            style: TextStyle(color: Colors.white38, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ] else ...[
                          const Text(
                            "الكلمة السرية هي:",
                            style: TextStyle(color: Colors.white60, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.currentWord?.text ?? "",
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "الفئة: ${state.currentWord?.category}",
                            style: const TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => ref.read(spyGameProvider.notifier).hideWord(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white60,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text("إخفاء"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => ref.read(spyGameProvider.notifier).nextPlayerReveal(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(20),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(
                      isLastPlayer ? "بدء اللعبة" : "تم، اللاعب التالي",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEndGameDialog(BuildContext context, WidgetRef ref) {
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
