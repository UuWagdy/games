import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../widgets/spinning_wheel_widget.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/features/questions/domain/entities/question.dart';
import 'package:games/features/games/wheel/presentation/providers/wheel_providers.dart';
import 'package:games/features/games/wheel/domain/entities/wheel_segment.dart';
import 'dart:math';
import 'dart:ui';
import 'dart:async';

import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import 'package:games/features/teams/presentation/pages/teams_management_page.dart';

import 'package:games/features/settings/presentation/pages/settings_page.dart';

class WheelGamePage extends ConsumerStatefulWidget {
  const WheelGamePage({super.key});

  @override
  ConsumerState<WheelGamePage> createState() => _WheelGamePageState();
}

class _WheelGamePageState extends ConsumerState<WheelGamePage> with SingleTickerProviderStateMixin {
  final GlobalKey<SpinningWheelWidgetState> _wheelKey = GlobalKey<SpinningWheelWidgetState>();
  late AnimationController _spinBtnController;

  @override
  void initState() {
    super.initState();
    _spinBtnController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _spinBtnController.dispose();
    super.dispose();
  }

  void _handleResult(WheelSegment segment) async {
    final teamsAsync = ref.read(teamsListProvider);
    final teams = teamsAsync.value ?? [];
    if (teams.isEmpty) {
      _showError('يرجى إضافة فرق أولاً من الإعدادات');
      return;
    }

    final currentIndex = ref.read(currentTeamIndexProvider);
    final currentTeam = teams[currentIndex];

    if (!segment.isQuestion || segment.categoryIds.isEmpty) {
      // Direct points
      await ref.read(teamsListProvider.notifier).updateScore(currentTeam.id!, segment.points, reason: segment.text);
      _showPointsDialog(currentTeam.name, segment.points, teams.length);
    } else {
      // Linked to question
      _showQuestionDialog(segment, currentTeam, teams.length);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showPointsDialog(String teamName, int points, int teamsTotal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(points >= 0 ? 'مبروك!' : 'حاول مرة أخرى'),
        content: Text('حصل فريق $teamName على $points نقطة'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(currentTeamIndexProvider.notifier).nextTeam(teamsTotal);
              Navigator.pop(context);
            }, 
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  void _showQuestionDialog(WheelSegment segment, dynamic currentTeam, int totalTeams) async {
    final settings = ref.read(generalSettingsProvider).value;
    final canRepeat = settings?['repeat_questions'] ?? true;
    final selectionMode = settings?['selection_mode'] ?? 'random';

    final categories = await ref.read(categoriesProvider.future);

    if (selectionMode == 'manual' && segment.categoryIds.length > 1) {
      _showCategorySelectionDialog(segment, currentTeam, canRepeat, categories, totalTeams);
      return;
    }

    List<Question> availableQuestions = [];
    final usageMode = settings?['usage_tracking_mode'] ?? 'per_category';
    
    for (var catId in segment.categoryIds) {
      final questionsResult = await ref.read(questionsProvider(catId).future);
      if (canRepeat) {
        availableQuestions.addAll(questionsResult);
      } else {
        availableQuestions.addAll(questionsResult.where((q) => !q.isUsedIn(catId)));
      }
    }

    _pickAndShowQuestion(availableQuestions, segment.points, currentTeam, canRepeat, usageMode, totalTeams);
  }

  void _showCategorySelectionDialog(WheelSegment segment, dynamic currentTeam, bool canRepeat, List<dynamic> categories, int totalTeams) {
    final linkedCategories = categories.where((c) => segment.categoryIds.contains(c.id)).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر الفئة'),
        content: SizedBox(
          width: double.maxFinite,
          child: linkedCategories.isEmpty
              ? const Text('لا توجد فئات مرتبطة بهذا القطاع')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: linkedCategories.length,
                  itemBuilder: (context, index) {
                    final cat = linkedCategories[index];
                    return Consumer(
                      builder: (context, ref, child) {
                        final questionsAsync = ref.watch(questionsProvider(cat.id));
                        return questionsAsync.when(
                          data: (questions) {
                            final unusedCount = questions.where((q) => !q.isUsedIn(cat.id!)).length;
                            final totalCount = questions.length;
                            final displayCount = canRepeat ? totalCount : unusedCount;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: 0,
                              color: Colors.blue.withOpacity(0.05),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: ListTile(
                                title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('الأسئلة ${canRepeat ? "المتاحة" : "غير المستعملة"}: $displayCount'),
                                enabled: displayCount > 0,
                                onTap: () {
                                  Navigator.pop(context);
                                  final selectable = canRepeat ? questions : questions.where((q) => !q.isUsedIn(cat.id!)).toList();
                                  final settings = ref.read(generalSettingsProvider).value;
                                  final usageMode = settings?['usage_tracking_mode'] ?? 'per_category';
                                  _pickAndShowQuestion(selectable, segment.points, currentTeam, canRepeat, usageMode, totalTeams, forcedCategoryId: cat.id);
                                },
                              ),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (e, s) => Text('خطأ: $e'),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ],
      ),
    );
  }

  void _pickAndShowQuestion(List<Question> availableQuestions, int points, dynamic currentTeam, bool canRepeat, String usageMode, int totalTeams, {int? forcedCategoryId}) {
    if (availableQuestions.isEmpty) {
      _showError('لا توجد أسئلة متاحة في الفئة/الفئات المختارة');
      return;
    }

    final randomQuestion = availableQuestions[Random().nextInt(availableQuestions.length)];

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _QuestionDialog(
        question: randomQuestion,
        points: points,
        teamName: currentTeam.name,
        onResult: (isCorrect) async {
          ref.read(currentTeamIndexProvider.notifier).nextTeam(totalTeams);
          if (isCorrect) {
            await ref.read(teamsListProvider.notifier).updateScore(
              currentTeam.id!,
              points,
              reason: 'إجابة صحيحة',
              gameName: 'عجلة الحظ',
              question: randomQuestion.text,
              answer: randomQuestion.answer,
            );
          } else {
            await ref.read(teamsListProvider.notifier).updateScore(
              currentTeam.id!,
              0,
              reason: 'إجابة خاطئة',
              gameName: 'عجلة الحظ',
              question: randomQuestion.text,
              answer: randomQuestion.answer,
            );
          }
          if (!canRepeat) {
            final catId = usageMode == 'per_category' ? (forcedCategoryId ?? randomQuestion.categoryIds.first) : null;
            await ref.read(questionsProvider(catId).notifier).setQuestionUsed(randomQuestion.id!, true, categoryId: catId);
          }
        },
      ),
    );
  }

  void _showScoreLogsDialog(dynamic team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('سجل نقاط فريق ${team.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer(
            builder: (context, ref, child) {
              final logsAsync = ref.watch(scoreLogsProvider(team.id!));
              return logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) return const Center(child: Text('لا يوجد سجل نقاط حتى الآن'));
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final timeStr = DateFormat('hh:mm a').format(log.timestamp);
                      return ListTile(
                        leading: CircleAvatar(child: Text('${log.points > 0 ? "+" : ""}${log.points}')),
                        title: Text(log.reason ?? 'تعديل'),
                        subtitle: Text(timeStr),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, s) => Text('خطأ: $err'),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  Widget _buildTeamScoreItem(dynamic team, bool isCurrent) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.white : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? const Color(0xFF003F5C) : Colors.transparent,
          width: 3,
        ),
        boxShadow: isCurrent ? [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))] : [],
      ),
      child: ListTile(
        onTap: () => _showScoreLogsDialog(team),
        title: Text(
          team.name,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: isCurrent ? const Color(0xFF003F5C) : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        subtitle: Text(
          '${team.score}',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: isCurrent ? const Color(0xFF003F5C) : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _confirmResetScores() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفير النقاط وحذف السجل'),
        content: const Text('هل أنت متأكد من تصفير نقاط كل الفرق وحذف سجل النقاط بالكامل؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await ref.read(teamsListProvider.notifier).resetScoresAndClearLogs();
              Navigator.pop(context);
            },
            child: const Text('تصفير الكل'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsListProvider);
    final currentIndex = ref.watch(currentTeamIndexProvider);
    final segmentsAsync = ref.watch(wheelSegmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('عجلة الحظ', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add, color: Colors.blueAccent),
            tooltip: 'إدارة الفرق',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TeamsManagementPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blueGrey),
            tooltip: 'إعدادات العجلة',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage(initialIndex: 3)),
            ),
          ),
          IconButton(icon: const Icon(Icons.restart_alt, color: Colors.red), onPressed: _confirmResetScores),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3)],
          ),
        ),
        child: teamsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('خطأ: $err')),
          data: (teams) {
            if (teams.isEmpty) return const Center(child: Text('يرجى إضافة فرق للبدء'));
            final currentTeam = (currentIndex < teams.length) ? teams[currentIndex] : teams.first;
            
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('الدور على:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                            Text(
                              currentTeam.name,
                              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF003F5C)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: segmentsAsync.when(
                          data: (segments) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: SpinningWheelWidget(
                                  key: _wheelKey,
                                  segments: segments,
                                  onResult: _handleResult,
                                ),
                              ),
                            ),
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, s) => Text('Error: $e'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30, right: 40),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: ScaleTransition(
                            scale: Tween(begin: 1.0, end: 0.9).animate(CurvedAnimation(parent: _spinBtnController, curve: Curves.easeInOut)),
                            child: ElevatedButton(
                              onPressed: () {
                                _spinBtnController.forward().then((_) => _spinBtnController.reverse());
                                _wheelKey.currentState?.spin();
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                                backgroundColor: const Color(0xFF003f5c),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 8,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 20),
                                  SizedBox(width: 8),
                                  Text('لف العجلة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 250,
                  color: Colors.white12,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('الفرق والنتائج', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: teams.length,
                          itemBuilder: (context, index) => _buildTeamScoreItem(teams[index], index == currentIndex),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuestionDialog extends ConsumerStatefulWidget {
  final Question question;
  final int points;
  final String teamName;
  final Function(bool) onResult;

  const _QuestionDialog({
    required this.question,
    required this.points,
    required this.teamName,
    required this.onResult,
  });

  @override
  ConsumerState<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends ConsumerState<_QuestionDialog> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('سؤال لفريق ${widget.teamName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.question.text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (_showAnswer) ...[
              const Divider(),
              const Text('الإجابة الصحيحة:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.question.answer, style: const TextStyle(color: Colors.green, fontSize: 22, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
      actions: [
        if (!_showAnswer) ElevatedButton(onPressed: () => setState(() => _showAnswer = true), child: const Text('إظهار الإجابة')),
        if (_showAnswer) ...[
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: () { widget.onResult(true); Navigator.pop(context); }, child: const Text('إجابة صحيحة')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () { widget.onResult(false); Navigator.pop(context); }, child: const Text('إجابة خاطئة')),
        ]
      ],
    );
  }
}
