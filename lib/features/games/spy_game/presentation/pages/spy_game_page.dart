import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/spy_game_provider.dart';
import '../widgets/glass_container.dart';

class SpyGameplayPage extends ConsumerStatefulWidget {
  const SpyGameplayPage({super.key});

  @override
  ConsumerState<SpyGameplayPage> createState() => _SpyGameplayPageState();
}

class _SpyGameplayPageState extends ConsumerState<SpyGameplayPage> {
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(spyGameProvider).settings;
    _secondsRemaining = settings.roundTimerSeconds;
    if (settings.timerEnabled) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          _onTimerEnd();
        }
      });
    });
  }

  void _onTimerEnd() {
    ref.read(spyGameProvider.notifier).startVoting();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(spyGameProvider);
    final questionerId = state.randomQuestionerId;
    final answererId = state.randomAnswererId;
    
    final questioner = state.players.firstWhere((p) => p.id == questionerId, orElse: () => state.players[0]);
    final answerer = state.players.firstWhere((p) => p.id == answererId, orElse: () => state.players[1]);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("وقت الأسئلة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (state.settings.timerEnabled)
                Center(
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    borderRadius: 30,
                    opacity: 0.1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, color: _secondsRemaining < 30 ? Colors.redAccent : Colors.blueAccent),
                        const SizedBox(width: 12),
                        Text(
                          _formatTime(_secondsRemaining),
                          style: TextStyle(
                            color: _secondsRemaining < 30 ? Colors.redAccent : Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              const Text(
                "حان دور:",
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        questioner.name,
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "اسأل",
                      style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        answerer.name,
                        style: const TextStyle(color: Colors.blueAccent, fontSize: 28, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "وحاول توقعه",
                      style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Progress indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       const Text("تقدم الجولة:", style: TextStyle(color: Colors.white38, fontSize: 11)),
                       Text(
                         "${state.interactionHistory.length} / ${state.players.length * (state.players.length - 1) * state.settings.numberOfRounds}",
                         style: const TextStyle(color: Colors.white38, fontSize: 11),
                       ),
                     ],
                   ),
                   const SizedBox(height: 8),
                   ClipRRect(
                     borderRadius: BorderRadius.circular(10),
                     child: LinearProgressIndicator(
                       value: state.cycleProgress,
                       minHeight: 6,
                       backgroundColor: Colors.white10,
                       valueColor: AlwaysStoppedAnimation<Color>(state.isCycleCompleted ? Colors.greenAccent : Colors.blueAccent),
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 24),
              
              if (state.isCycleCompleted) 
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "اكتملت الجولة! كل لاعب سأل كل لاعب آخر ${state.settings.numberOfRounds} مرّة. يمكنكم الانتقال للتصويت.",
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: state.isCycleCompleted ? null : () => ref.read(spyGameProvider.notifier).nextTurn(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.isCycleCompleted ? Colors.grey.withOpacity(0.2) : Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: state.isCycleCompleted ? 0 : 5,
                  ),
                  child: Text(
                    state.isCycleCompleted ? "انتهت الجولات" : "السؤال التالي", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (state.isCycleCompleted)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => ref.read(spyGameProvider.notifier).startVoting(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 8,
                    ),
                    child: const Text("ابدأ التصويت الآن", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                )
              else
                TextButton(
                  onPressed: () => ref.read(spyGameProvider.notifier).startVoting(),
                  child: const Text(
                    "لم نكتشف الجاسوس؟ ابدأ التصويت الآن",
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ),
            ],
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
