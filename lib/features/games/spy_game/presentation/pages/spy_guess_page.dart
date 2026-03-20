import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/spy_game_provider.dart';
import '../widgets/glass_container.dart';
import '../../domain/repositories/word_repository.dart';

class SpyGuessPage extends ConsumerWidget {
  const SpyGuessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(spyGameProvider);
    final category = state.currentWord?.category ?? "";
    final allWordsInCategory = SpyWordRepository.getItemsByCategory(category);
    final spies = state.players.where((p) => p.isSpy).map((p) => p.name).join(' و ');

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("تخمين الكلمة السرية", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showEndGameDialog(context, ref),
            icon: const Icon(Icons.logout_outlined, color: Colors.redAccent, size: 20),
            tooltip: "إنهاء اللعبة",
          ),
          const SizedBox(width: 8),
        ],
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.psychology_outlined, color: Colors.orangeAccent, size: 56),
              const SizedBox(height: 16),
              Text(
                "الجاسوس هو: $spies",
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "تخمين الكلمة من صنف: $category",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 600 ? 5 : 3;
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: allWordsInCategory.length,
                      itemBuilder: (context, index) {
                        final wordText = allWordsInCategory[index];
                        return GlassContainer(
                          padding: EdgeInsets.zero,
                          opacity: 0.1,
                          borderRadius: 12,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                               ref.read(spyGameProvider.notifier).handleSpyGuess(wordText);
                            },
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(
                                  wordText,
                                  style: const TextStyle(
                                    color: Colors.white, 
                                    fontSize: 14, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                ),
              ),
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
