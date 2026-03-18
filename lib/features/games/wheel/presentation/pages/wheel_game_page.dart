import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/spinning_wheel_widget.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/features/questions/domain/entities/question.dart';
import 'package:games/features/games/wheel/presentation/providers/wheel_providers.dart';
import 'package:games/features/games/wheel/domain/entities/wheel_segment.dart';
import 'dart:math';

class WheelGamePage extends ConsumerStatefulWidget {
  const WheelGamePage({super.key});

  @override
  ConsumerState<WheelGamePage> createState() => _WheelGamePageState();
}

class _WheelGamePageState extends ConsumerState<WheelGamePage> {
  void _handleResult(WheelSegment segment) async {
    final teamsAsync = ref.read(teamsListProvider);
    final teams = teamsAsync.value ?? [];
    if (teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إضافة فرق أولاً من الإعدادات')),
      );
      return;
    }

    final currentIndex = ref.read(currentTeamIndexProvider);
    final currentTeam = teams[currentIndex];

    if (!segment.isQuestion || segment.categoryId == null) {
      // Direct points
      await ref.read(teamsListProvider.notifier).updateScore(currentTeam.id!, segment.points);
      _showPointsDialog(currentTeam.name, segment.points);
      ref.read(currentTeamIndexProvider.notifier).nextTeam(teams.length);
    } else {
      // Linked to question
      _showQuestionDialog(segment, currentTeam);
    }
  }

  void _showPointsDialog(String teamName, int points) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(points >= 0 ? 'مبروك!' : 'حاول مرة أخرى'),
        content: Text('حصل فريق $teamName على $points نقطة'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسنًا')),
        ],
      ),
    );
  }

  void _showQuestionDialog(WheelSegment segment, dynamic currentTeam) async {
    final questionsResult = await ref.read(questionsProvider(segment.categoryId).future);
    if (questionsResult.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد أسئلة في هذا القسم')),
      );
      return;
    }

    final randomQuestion = questionsResult[Random().nextInt(questionsResult.length)];

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _QuestionDialog(
        question: randomQuestion,
        points: segment.points,
        teamName: currentTeam.name,
        onResult: (isCorrect) async {
          if (isCorrect) {
            await ref.read(teamsListProvider.notifier).updateScore(currentTeam.id!, segment.points);
          }
          final teams = ref.read(teamsListProvider).value ?? [];
          ref.read(currentTeamIndexProvider.notifier).nextTeam(teams.length);
          if (context.mounted) Navigator.pop(context);
        },
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
        title: const Text('عجلة الحظ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(wheelSegmentsProvider),
          ),
        ],
      ),
      body: teamsAsync.when(
        data: (teams) {
          if (teams.isEmpty) {
            return const Center(child: Text('يرجى إضافة فرق من صفحة الإعدادات للبدء'));
          }
          final currentTeam = teams[currentIndex];
          return Column(
            children: [
              // Scores Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: teams.map((t) {
                    final isCurrent = teams.indexOf(t) == currentIndex;
                    return Column(
                      children: [
                        Text(
                          t.name,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            fontSize: isCurrent ? 20 : 16,
                            color: isCurrent ? Colors.blue : Colors.black,
                          ),
                        ),
                        Text('${t.score}', style: const TextStyle(fontSize: 18)),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('الدور على:', style: TextStyle(fontSize: 18)),
              ),
              Text(
                currentTeam.name,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'لف العجلة لتحديد النقاط أو السؤال القادم!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: segmentsAsync.when(
                  data: (segments) => SpinningWheelWidget(
                    segments: segments,
                    onResult: _handleResult,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('خطأ في تحميل الأقسام: $err')),
                ),
              ),
              const SizedBox(height: 50),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
      ),
    );
  }
}

class _QuestionDialog extends StatefulWidget {
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
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('سؤال لـ ${widget.teamName} (${widget.points} نقطة)'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.question.text,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Divider(height: 40),
            if (_showAnswer) ...[
              const Text('الإجابة:', style: TextStyle(color: Colors.grey)),
              Text(
                widget.question.answer,
                style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ] else
              ElevatedButton(
                onPressed: () => setState(() => _showAnswer = true),
                child: const Text('كشف الإجابة'),
              ),
          ],
        ),
      ),
      actions: [
        if (_showAnswer) ...[
          TextButton(
            onPressed: () => widget.onResult(false),
            child: const Text('إجابة خاطئة', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => widget.onResult(true),
            child: const Text('إجابة صحيحة', style: TextStyle(color: Colors.green)),
          ),
        ],
      ],
    );
  }
}
