import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/penalty_shootout_provider.dart';
import '../widgets/penalty_scoreboard.dart';
import '../../domain/entities/penalty_shootout_state.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'dart:math';

class PenaltyShootoutPage extends ConsumerStatefulWidget {
  const PenaltyShootoutPage({super.key});

  @override
  ConsumerState<PenaltyShootoutPage> createState() => _PenaltyShootoutPageState();
}

class _PenaltyShootoutPageState extends ConsumerState<PenaltyShootoutPage> with TickerProviderStateMixin {
  late AnimationController _goalController;
  late AnimationController _missController;
  late Animation<double> _goalScale;
  late Animation<double> _missScale;

  @override
  void initState() {
    super.initState();
    _goalController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _missController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _goalScale = CurvedAnimation(parent: _goalController, curve: Curves.elasticOut);
    _missScale = CurvedAnimation(parent: _missController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _goalController.dispose();
    _missController.dispose();
    super.dispose();
  }

  void _showFeedback(bool? result) {
    if (result == true) {
      _goalController.forward().then((_) => Future.delayed(const Duration(seconds: 1)).then((_) => _goalController.reverse()));
    } else if (result == false) {
      _missController.forward().then((_) => Future.delayed(const Duration(seconds: 1)).then((_) => _missController.reverse()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(penaltyShootoutProvider);
    final teamsAsync = ref.watch(teamsListProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Grass Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
              ),
            ),
            child: CustomPaint(
              size: MediaQuery.of(context).size,
              painter: FootballFieldPainter(),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: PenaltyScoreboard(gameState: gameState),
                ),
                
                if (gameState.status == PenaltyGameStatus.idle)
                  Expanded(
                    child: Center(
                      child: teamsAsync.when(
                        data: (teams) {
                          if (teams.length < 2) {
                            return const Text('يرجى إضافة فريقين على الأقل للبدء', style: TextStyle(color: Colors.white, fontSize: 24));
                          }
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () {
                              ref.read(penaltyShootoutProvider.notifier).startGame(teams[0], teams[1], null);
                            },
                            child: const Text('بدء الجولة الحاسمة', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (e, s) => Text('Error: $e'),
                      ),
                    ),
                  ),

                if (gameState.status == PenaltyGameStatus.playing || gameState.status == PenaltyGameStatus.feedback)
                  Expanded(
                    child: Center(
                      child: _buildQuestionArea(gameState),
                    ),
                  ),

                if (gameState.status == PenaltyGameStatus.finished)
                  Expanded(
                    child: Center(
                      child: _buildWinnerArea(gameState),
                    ),
                  ),
              ],
            ),
          ),

          // Animations
          Center(
            child: ScaleTransition(
              scale: _goalScale,
              child: _buildResultOverlay('هدف!', Colors.yellow, Colors.green),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _missScale,
              child: _buildResultOverlay('ضاعت!', Colors.white, Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionArea(PenaltyShootoutState state) {
    final currentTeam = state.currentTurn == PenaltyTurn.teamA ? state.teamA : state.teamB;
    final teamColor = state.currentTurn == PenaltyTurn.teamA ? Colors.blue : Colors.red;

    return Container(
      width: min(600, MediaQuery.of(context).size.width * 0.9),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: teamColor, width: 4),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'فريق: ${currentTeam?.name}', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: teamColor)
              ),
              if (state.isSuddenDeath)
                const Text('SUDDEN DEATH', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 18))
              else
                Text('المحاولة: ${state.currentRound} / 5', style: const TextStyle(fontSize: 18)),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          
          if (state.status == PenaltyGameStatus.playing) ...[
            Text(
              state.currentQuestion?.text ?? 'تحميل السؤال...', 
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // Timer
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80, height: 80,
                  child: CircularProgressIndicator(
                    value: state.timer / 10,
                    strokeWidth: 8,
                    color: state.timer < 4 ? Colors.red : Colors.green,
                  ),
                ),
                Text('${state.timer}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
            
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _handleAnswerSelection(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, 
                foregroundColor: Colors.white, 
                minimumSize: const Size(200, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('إجابة صحيحة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => _handleAnswerSelection(false),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('إجابة خاطئة', style: TextStyle(fontSize: 20)),
            ),
          ],

          if (state.status == PenaltyGameStatus.feedback) ...[
            _buildAnswerFeedback(state),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(penaltyShootoutProvider.notifier).nextTurn(null), 
              child: const Text('التالي', style: TextStyle(fontSize: 24)),
            ),
          ],
        ],
      ),
    );
  }

  void _handleAnswerSelection(bool correct) {
    ref.read(penaltyShootoutProvider.notifier).submitAnswer(correct);
    _showFeedback(correct);
  }

  Widget _buildAnswerFeedback(PenaltyShootoutState state) {
    final correct = state.lastResult == true;
    return Column(
      children: [
        Icon(correct ? Icons.check_circle : Icons.cancel, color: correct ? Colors.green : Colors.red, size: 80),
        Text(
          correct ? 'هدف ممتاز!' : 'للأسف ضاعت!', 
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: correct ? Colors.green : Colors.red)
        ),
        const SizedBox(height: 10),
        const Text('الإجابة الصحيحة كانت:', style: TextStyle(fontSize: 18, color: Colors.grey)),
        Text(state.currentQuestion?.answer ?? '-', style: const TextStyle(fontSize: 24, decoration: TextDecoration.underline)),
      ],
    );
  }

  Widget _buildWinnerArea(PenaltyShootoutState state) {
     return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [const BoxShadow(color: Colors.amber, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 120),
          const SizedBox(height: 20),
          const Text('الفائز في الجولة الحاسمة هو:', style: TextStyle(fontSize: 24)),
          Text(state.winner ?? 'تعادل!', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.blue)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => ref.read(penaltyShootoutProvider.notifier).reset(), 
            child: const Text('إعادة اللعب', style: TextStyle(fontSize: 24)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('الخروج من اللعبة', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultOverlay(String text, Color textColor, Color strokeColor) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 120,
        fontWeight: FontWeight.w900,
        color: textColor,
        shadows: [
          Shadow(color: strokeColor, blurRadius: 30, offset: const Offset(5, 5)),
          Shadow(color: strokeColor, blurRadius: 30, offset: const Offset(-5, -5)),
        ],
      ),
    );
  }
}

class FootballFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Outer line
    canvas.drawRect(Rect.fromLTWH(10, 10, size.width - 20, size.height - 20), paint);

    // Center line
    canvas.drawLine(Offset(10, size.height / 2), Offset(size.width - 10, size.height / 2), paint);

    // Center circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 60, paint);

    // Penalty area (Top)
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 100, 10, 200, 80), paint);
    
    // Penalty area (Bottom)
    canvas.drawRect(Rect.fromLTWH(size.width / 2 - 100, size.height - 90, 200, 80), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
