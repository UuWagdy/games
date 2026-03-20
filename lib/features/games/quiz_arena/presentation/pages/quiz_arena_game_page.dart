import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/core/design/app_design.dart';
import 'package:games/features/games/quiz_arena/presentation/providers/quiz_arena_provider.dart';
import 'package:games/features/games/quiz_arena/domain/models/quiz_arena_game_state.dart';
import 'package:games/features/teams/domain/entities/team.dart';
import 'package:games/features/questions/domain/entities/question.dart';
import 'package:games/features/games/quiz_arena/presentation/pages/quiz_arena_winner_page.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:games/features/teams/presentation/pages/teams_management_page.dart';
import 'package:games/features/settings/presentation/pages/settings_page.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';

class QuizArenaGamePage extends ConsumerWidget {
  const QuizArenaGamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizArenaGameProvider);
    final currentQuestion = state.currentQuestion;

    // Listen to game over state to navigate
    ref.listen(quizArenaGameProvider.select((s) => s.isGameOver), (prev, next) {
      if (next) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QuizArenaWinnerPage()),
        );
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: AppDesign.isSmallScreen(context) ? 20 : 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'ساحة التحدي', 
            style: TextStyle(
              color: Colors.white,
              fontSize: AppDesign.isSmallScreen(context) ? 18 : 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        centerTitle: true,
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.group_add, color: Colors.white70, size: AppDesign.isSmallScreen(context) ? 18 : 24),
            tooltip: 'إدارة الفرق',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeamsManagementPage()),
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white70, size: AppDesign.isSmallScreen(context) ? 18 : 24),
            tooltip: 'إعدادات الجلسة',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage(initialIndex: 4)),
            ),
          ),
          IconButton(
            icon: Icon(Icons.restart_alt, color: Colors.redAccent, size: AppDesign.isSmallScreen(context) ? 18 : 24),
            tooltip: 'تصفير النقاط',
            onPressed: () => _confirmResetScores(context, ref),
          ),
          if (AppDesign.isSmallScreen(context))
            IconButton(
              icon: const Icon(Icons.leaderboard_rounded, color: Colors.amberAccent, size: 18),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          SizedBox(width: AppDesign.isSmallScreen(context) ? 4 : 10),
        ],
      ),
      endDrawer: AppDesign.isSmallScreen(context) ? Drawer(
        backgroundColor: AppDesign.slate900,
        child: _buildTeamsSidebar(context, ref, state),
      ) : null,
      body: AppDesign.backgroundWrapper(
        child: state.isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.purpleAccent),
                    SizedBox(height: 20),
                    Text('جاري التحميل...', style: TextStyle(color: Colors.white70, fontSize: 18)),
                  ],
                ),
              )
            : Row(
                children: [
                  // Main Game Area
                  Expanded(
                    flex: 8,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: AppDesign.isSmallScreen(context) ? 90 : 120),
                          _buildTournamentBanner(state, context),
                          SizedBox(height: AppDesign.isSmallScreen(context) ? 10 : 20),
                          _buildTurnIndicator(state, context),
                          SizedBox(height: AppDesign.isSmallScreen(context) ? 10 : 20),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: AppDesign.isSmallScreen(context) ? 12 : 24),
                            child: currentQuestion == null
                                ? const Center(child: CircularProgressIndicator())
                                : _buildQuestionCard(context, ref, state, currentQuestion),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: AppDesign.isSmallScreen(context) ? 15 : 40),
                            child: _buildActiveButton(ref, state, context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Teams Sidebar
                  if (!AppDesign.isSmallScreen(context))
                    _buildTeamsSidebar(context, ref, state),
                ],
              ),
      ),
    );
  }

  Widget _buildTournamentBanner(QuizArenaGameState state, BuildContext context) {
    bool isSmall = AppDesign.isSmallScreen(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 32, vertical: isSmall ? 8 : 12),
      decoration: AppDesign.glassDecoration.copyWith(
        borderRadius: BorderRadius.circular(30),
        color: Colors.purpleAccent.withOpacity(0.1),
      ),
      child: Text(
        'الجولة ${state.currentRound}',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isSmall ? 18 : 24),
      ),
    );
  }

  Widget _buildTurnIndicator(QuizArenaGameState state, BuildContext context) {
    if (state.teams.isEmpty) return const SizedBox.shrink();
    final currentTeam = state.teams[state.currentTeamIndex];
    bool isSmall = AppDesign.isSmallScreen(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24, vertical: isSmall ? 6 : 10),
      margin: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amberAccent.withOpacity(0.2), Colors.amberAccent.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.amberAccent.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.amberAccent.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 20),
          const SizedBox(width: 8),
          Text(
            'دور فريق: ${currentTeam.name}',
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.w900, 
              fontSize: isSmall ? 18 : 22,
              shadows: [Shadow(color: Colors.amberAccent.withOpacity(0.5), blurRadius: 8)],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsSidebar(BuildContext context, WidgetRef ref, QuizArenaGameState state) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: const Border(left: BorderSide(color: Colors.white10)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الفرق والنتائج',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_moderator_rounded, color: Colors.greenAccent),
                        tooltip: 'تعديل نقاط يدوي',
                        onPressed: () => _showManualAdjustmentDialog(context, ref, state),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.teams.length,
                    itemBuilder: (context, index) {
                      final team = state.teams[index];
                      final isCurrent = index == state.currentTeamIndex;
                      return _buildTeamScoreItem(context, ref, team, isCurrent);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamScoreItem(BuildContext context, WidgetRef ref, Team team, bool isCurrent) {
    return GestureDetector(
      onTap: () => _showScoreLogsDialog(context, ref, team),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrent ? Colors.purpleAccent.withOpacity(0.15) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCurrent ? Colors.purpleAccent : Colors.white10,
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: isCurrent ? [BoxShadow(color: Colors.purpleAccent.withOpacity(0.1), blurRadius: 10)] : [],
        ),
        child: Column(
          children: [
            Text(
              team.name,
              style: TextStyle(
                color: isCurrent ? Colors.white : Colors.white70,
                fontSize: 18,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '${team.score}',
              style: TextStyle(
                color: isCurrent ? Colors.amberAccent : Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScoreLogsDialog(BuildContext context, WidgetRef ref, Team team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('سجل نقاط فريق ${team.name}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: Consumer(
            builder: (context, ref, child) {
              final logsAsync = ref.watch(scoreLogsProvider(team.id!));
              return logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) return const Center(child: Text('لا يوجد سجل نقاط حتى الآن', style: TextStyle(color: Colors.white60)));
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final timeStr = DateFormat('hh:mm a').format(log.timestamp);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: log.points >= 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          child: Text('${log.points > 0 ? "+" : ""}${log.points}', style: TextStyle(color: log.points >= 0 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(log.reason ?? (log.points >= 0 ? 'إضافة نقاط' : 'خصم نقاط'), style: const TextStyle(color: Colors.white, fontSize: 16)),
                        subtitle: Text(timeStr, style: const TextStyle(color: Colors.white38)),
                        trailing: Text(log.gameName ?? '', style: const TextStyle(color: Colors.purpleAccent, fontSize: 10)),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
                error: (err, s) => Text('خطأ: $err', style: const TextStyle(color: Colors.redAccent)),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق', style: TextStyle(color: Colors.white60))),
        ],
      ),
    );
  }

  void _showManualAdjustmentDialog(BuildContext context, WidgetRef ref, QuizArenaGameState state) {
    List<int> selectedTeamIds = [];
    final ptsController = TextEditingController();
    final reasonController = TextEditingController(text: 'تعديل يدوي');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('تعديل النقاط يدوياً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('اختر الفريق / الفرق:', style: TextStyle(color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.teams.map((team) {
                    final isSelected = selectedTeamIds.contains(team.id);
                    return FilterChip(
                      label: Text(team.name),
                      selected: isSelected,
                      onSelected: (val) {
                        setDialogState(() {
                          if (val) selectedTeamIds.add(team.id!);
                          else selectedTeamIds.remove(team.id);
                        });
                      },
                      selectedColor: Colors.purpleAccent.withOpacity(0.3),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: ptsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'النقاط القيمة (مثال: 50 أو -50)',
                    labelStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'السبب (اختياري)',
                    labelStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () async {
                final pts = int.tryParse(ptsController.text) ?? 0;
                if (selectedTeamIds.isNotEmpty && pts != 0) {
                  for (final id in selectedTeamIds) {
                    await ref.read(teamsListProvider.notifier).updateScore(
                      id, 
                      pts, 
                      reason: reasonController.text,
                      gameName: 'Quiz Arena',
                    );
                  }
                  // Synchronize local game state with database
                  await ref.read(quizArenaGameProvider.notifier).syncLocalScoresWithGlobal(state.teams.map((t) => t.id!).toList());
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('تطبيق التعديلات', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResetScores(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('تصفير النقاط وحذف السجل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من تصفير نقاط كل الفرق وحذف سجل النقاط بالكامل؟ سيتم إعادة تشغيل اللعبة أيضاً.', 
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await ref.read(teamsListProvider.notifier).resetScoresAndClearLogs();
              ref.read(quizArenaGameProvider.notifier).restartGame();
              Navigator.pop(context);
            },
            child: const Text('تصفير الكل'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, WidgetRef ref, QuizArenaGameState state, Question question) {
    bool isSmall = AppDesign.isSmallScreen(context);
    return Center(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmall ? 16 : 32),
        decoration: AppDesign.glassDecoration.copyWith(
          color: Colors.white.withOpacity(0.03),
          boxShadow: [
            BoxShadow(color: Colors.purpleAccent.withOpacity(0.1), blurRadius: 40, spreadRadius: -10),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ref.read(quizArenaSettingsProvider).timerEnabled)
              _buildTimer(state.remainingTime, ref.read(quizArenaSettingsProvider).timeLimitSeconds, context),
            SizedBox(height: isSmall ? 10 : 20),
            if (question.imageData != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  question.imageData!,
                  height: isSmall ? 150 : 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              question.text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: isSmall ? 18 : 24, fontWeight: FontWeight.bold, height: 1.5),
            ),
            SizedBox(height: isSmall ? 12 : 40),
              if (question.type == QuestionType.multipleChoice && question.options != null)
                Column(
                  children: [
                    if (question.options != null)
                      for (final option in question.options!)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: state.showAnswer && option == question.answer
                                ? Colors.greenAccent.withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  state.showAnswer && option == question.answer
                                      ? Colors.greenAccent
                                      : Colors.white10,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              color:
                                  state.showAnswer && option == question.answer
                                      ? Colors.greenAccent
                                      : Colors.white70,
                              fontSize: 16,
                              fontWeight:
                                  state.showAnswer && option == question.answer
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                  ],
                ),
              if (state.showAnswer)
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text('الإجابة الصحيحة:', style: TextStyle(color: Colors.white60, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        question.answer,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer(int remaining, int total, BuildContext context) {
    bool isSmall = AppDesign.isSmallScreen(context);
    final progress = remaining / total;
    final color = remaining < 10 ? Colors.redAccent : Colors.purpleAccent;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: isSmall ? 60 : 80,
              height: isSmall ? 60 : 80,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: isSmall ? 6 : 8,
                backgroundColor: Colors.white12,
                color: color,
              ),
            ),
            Text(
              '$remaining',
              style: TextStyle(color: color, fontSize: isSmall ? 20 : 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildActiveButton(WidgetRef ref, QuizArenaGameState state, BuildContext context) {
    final notifier = ref.read(quizArenaGameProvider.notifier);
    bool isSmall = AppDesign.isSmallScreen(context);

    if (!state.showAnswer) {
      // Step 1: Just show "Show Answer"
      return FloatingActionButton.extended(
        onPressed: () => notifier.showAnswer(),
        label: Text('إظهار الإجابة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 16 : 18)),
        icon: const Icon(Icons.visibility_rounded),
        backgroundColor: Colors.blueAccent,
      );
    } else if (!state.hasVerdict) {
      // Step 2: Show verdict buttons
      return Wrap(
        spacing: 20,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          _ActionButton(
            label: 'إجابة صحيحة',
            icon: Icons.check_circle_outline,
            color: Colors.greenAccent,
            onPressed: () => notifier.answerCorrectly(),
            isSmall: isSmall,
          ),
          _ActionButton(
            label: 'إجابة خاطئة',
            icon: Icons.highlight_off_rounded,
            color: Colors.redAccent,
            onPressed: () => notifier.answerWrong(),
            isSmall: isSmall,
          ),
        ],
      );
    } else {
      // Step 3: Next Team
      // ONLY show if timer is enabled. If not, we auto-advance turn anyway.
      final timerEnabled = ref.read(quizArenaSettingsProvider).timerEnabled;
      if (!timerEnabled) return const SizedBox.shrink();

      return FloatingActionButton.extended(
        onPressed: () => notifier.nextTurn(),
        label: Text('الفريق التالي',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 16 : 18)),
        icon: const Icon(Icons.navigate_next_rounded),
        backgroundColor: Colors.purpleAccent,
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isSmall;

  const _ActionButton({
    required this.label, 
    required this.icon, 
    required this.color, 
    required this.onPressed,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24, vertical: isSmall ? 12 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: color.withOpacity(0.4), width: 2)),
        elevation: 0,
      ),
      icon: Icon(icon, size: isSmall ? 20 : 28),
      label: Text(label, style: TextStyle(fontSize: isSmall ? 14 : 18, fontWeight: FontWeight.bold)),
    );
  }
}
