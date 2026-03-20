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

import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import 'package:games/features/teams/presentation/pages/teams_management_page.dart';
import 'package:games/features/settings/presentation/pages/settings_page.dart';
import 'package:games/core/design/app_design.dart';

class WheelGamePage extends ConsumerStatefulWidget {
  const WheelGamePage({super.key});

  @override
  ConsumerState<WheelGamePage> createState() => _WheelGamePageState();
}

class _WheelGamePageState extends ConsumerState<WheelGamePage> with TickerProviderStateMixin {
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

    if (segment.isSwitch) {
      _showSwitchDialog(currentTeam, teams);
      return;
    }

    if (segment.isJoker) {
      _showJokerDialog(currentTeam, teams);
      return;
    }

    if (!segment.isQuestion || segment.categoryIds.isEmpty) {
      // Direct points
      await ref.read(teamsListProvider.notifier).updateScore(currentTeam.id!, segment.points, reason: segment.text);
      _showPointsDialog(currentTeam.name, segment.points, teams.length);
    } else {
      // Linked to question
      _showQuestionDialog(segment, currentTeam, teams.length);
    }
  }

  void _showSwitchDialog(dynamic currentTeam, List<dynamic> allTeams) {
    final otherTeam = allTeams.length == 2 ? allTeams.firstWhere((t) => t.id != currentTeam.id) : null;
    final title = allTeams.length == 2 
        ? 'الفريق ${otherTeam.name} يختار للفريق ${currentTeam.name}'
        : 'منسق اللعبة يختار السؤال لفريق ${currentTeam.name}';
    
    _showSelectionDialog(title, currentTeam, allTeams.length);
  }

  void _showJokerDialog(dynamic currentTeam, List<dynamic> allTeams) {
    final title = 'فريق ${currentTeam.name} يختار القسم لنفسه';
    _showSelectionDialog(title, currentTeam, allTeams.length);
  }

  void _showSelectionDialog(String title, dynamic currentTeam, int totalTeams) {
    final segments = ref.read(wheelSegmentsProvider).value ?? [];
    final choices = segments.where((s) => !s.isSwitch && !s.isJoker).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        content: SizedBox(
          width: 500,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: choices.length,
            itemBuilder: (context, index) {
              final s = choices[index];
              return ListTile(
                title: Text(s.text, style: const TextStyle(color: Colors.white)),
                subtitle: Text(s.isQuestion ? 'سؤال (${s.points})' : 'نقاط مباشرة (${s.points})', style: const TextStyle(color: Colors.white60)),
                onTap: () {
                  Navigator.pop(context);
                  _handleResult(s);
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showPointsDialog(String teamName, int points, int teamsTotal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(points >= 0 ? 'مبروك!' : 'حاول مرة أخرى', style: const TextStyle(color: Colors.white)),
        content: Text('حصل فريق $teamName على $points نقطة', style: const TextStyle(color: Colors.white70)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
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
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('اختر الفئة', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 500,
          child: linkedCategories.isEmpty
              ? const Text('لا توجد فئات مرتبطة بهذا القطاع', style: TextStyle(color: Colors.white70))
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
                              color: Colors.white.withOpacity(0.05),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: ListTile(
                                title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                subtitle: Text('الأسئلة ${canRepeat ? "المتاحة" : "غير المستعملة"}: $displayCount', style: const TextStyle(color: Colors.white60)),
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
                          error: (e, s) => Text('خطأ: $e', style: const TextStyle(color: Colors.red)),
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
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('سجل نقاط فريق ${team.name}', style: const TextStyle(color: Colors.white)),
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
                          child: Text('${log.points > 0 ? "+" : ""}${log.points}', style: TextStyle(color: log.points >= 0 ? Colors.greenAccent : Colors.redAccent)),
                        ),
                        title: Row(
                          children: [
                            Text(log.reason ?? 'تعديل', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if (log.gameName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  log.gameName!,
                                  style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.w300),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(timeStr, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, s) => Text('خطأ: $err', style: const TextStyle(color: Colors.red)),
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrent ? Colors.amberAccent.withOpacity(0.5) : Colors.white10,
          width: 2,
        ),
        boxShadow: isCurrent ? [BoxShadow(color: Colors.amberAccent.withOpacity(0.1), blurRadius: 15, spreadRadius: 1)] : [],
      ),
      child: ListTile(
        onTap: () => _showScoreLogsDialog(team),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        title: Text(
          team.name,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: isCurrent ? Colors.amberAccent : Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        subtitle: Text(
          '${team.score}',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: isCurrent ? Colors.white : Colors.white54,
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
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تصفير النقاط وحذف السجل', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من تصفير نقاط كل الفرق وحذف سجل النقاط بالكامل؟', style: TextStyle(color: Colors.white70)),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('عجلة الحظ', style: AppDesign.titleStyle),
        centerTitle: true,
        actions: [
          if (!AppDesign.isSmallScreen(context)) ...[
            IconButton(
              icon: const Icon(Icons.group_add, color: Colors.white70),
              tooltip: 'إدارة الفرق',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TeamsManagementPage()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              tooltip: 'إعدادات العجلة',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage(initialIndex: 3)),
              ),
            ),
            IconButton(icon: const Icon(Icons.restart_alt, color: Colors.redAccent), onPressed: _confirmResetScores),
          ],
          if (AppDesign.isSmallScreen(context))
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.leaderboard_rounded, color: Colors.amberAccent),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          const SizedBox(width: 10),
        ],
      ),
      endDrawer: AppDesign.isSmallScreen(context) ? _buildMobileDrawer(teamsAsync, currentIndex) : null,
      body: AppDesign.backgroundWrapper(
        child: teamsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.amberAccent)),
          error: (err, stack) => Center(child: Text('خطأ: $err', style: const TextStyle(color: Colors.redAccent))),
          data: (teams) {
            if (teams.isEmpty) return const Center(child: Text('يرجى إضافة فرق للبدء', style: TextStyle(color: Colors.white, fontSize: 24)));
            final currentTeam = (currentIndex < teams.length) ? teams[currentIndex] : teams.first;
            
            return Stack(
              children: [
                if (AppDesign.isSmallScreen(context))
                  SafeArea(
                    child: Column(
                      children: [
                        _buildCurrentTeamCard(currentTeam),
                        Expanded(child: _buildWheel(segmentsAsync)),
                        const SizedBox(height: 20),
                        _buildSpinButton(context),
                        const SizedBox(height: 40),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        flex: 8,
                        child: SafeArea(
                          child: Column(
                            children: [
                              _buildCurrentTeamCard(currentTeam),
                              Expanded(child: _buildWheel(segmentsAsync)),
                              const SizedBox(height: 20),
                              _buildSpinButton(context),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 350,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          border: const Border(left: BorderSide(color: Colors.white10)),
                        ),
                        child: _buildSidebar(teamsAsync, currentIndex),
                      ),
                    ],
                  ),
                // Removed global Positioned spin button to move it inside columns for better centering
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpinButton(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _spinBtnController, curve: Curves.easeInOut),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: ElevatedButton(
              onPressed: () {
                _spinBtnController.forward().then((_) => _spinBtnController.reverse());
                _wheelKey.currentState?.spin();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                backgroundColor: Colors.white.withOpacity(0.05),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 28, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Text(
                    'لف العجلة',
                    style: TextStyle(
                      fontSize: AppDesign.isSmallScreen(context) ? 20 : 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTeamCard(dynamic currentTeam) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: EdgeInsets.symmetric(horizontal: AppDesign.isSmallScreen(context) ? 20 : 40, vertical: 16),
      decoration: AppDesign.glassDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('الدور على فريق:', style: AppDesign.subtitleStyle),
          const SizedBox(height: 8),
          Text(
            currentTeam.name,
            style: TextStyle(
              fontSize: AppDesign.isSmallScreen(context) ? 32 : 42, 
              fontWeight: FontWeight.w900, 
              color: Colors.amberAccent, 
              shadows: const [Shadow(color: Colors.amberAccent, blurRadius: 15)]
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel(AsyncValue<List<WheelSegment>> segmentsAsync) {
    return segmentsAsync.when(
      data: (segments) => Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 50, spreadRadius: 10)],
              ),
              child: SpinningWheelWidget(
                key: _wheelKey,
                segments: segments,
                onResult: _handleResult,
              ),
            ),
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.amberAccent)),
      error: (e, s) => Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
    );
  }

  Widget _buildMobileDrawer(AsyncValue<List<dynamic>> teamsAsync, int currentIndex) {
    return Drawer(
      backgroundColor: AppDesign.slate900,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.amber.shade900),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 48),
                SizedBox(height: 12),
                Text('عجلة الحظ', style: AppDesign.titleStyle),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.group_add, color: Colors.blueAccent),
            title: const Text('إدارة الفرق', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamsManagementPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white70),
            title: const Text('إعدادات العجلة', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage(initialIndex: 3)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.redAccent),
            title: const Text('تصفير النقاط', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _confirmResetScores();
            },
          ),
          const Divider(color: Colors.white10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Text('النتائج والترتيب', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          ),
          Expanded(child: _buildSidebar(teamsAsync, currentIndex, showTitle: false)),
        ],
      ),
    );
  }

  Widget _buildSidebar(AsyncValue<List<dynamic>> teamsAsync, int currentIndex, {bool showTitle = true}) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SafeArea(
          child: Column(
            children: [
              if (showTitle)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('الفرق والنتائج', style: AppDesign.titleStyle),
                ),
              Expanded(
                child: teamsAsync.when(
                  data: (teams) => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: teams.length,
                    itemBuilder: (context, index) => _buildTeamScoreItem(teams[index], index == currentIndex),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.8),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.amber.withOpacity(0.3), width: 2),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text('سؤال لفريق ${widget.teamName}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const SizedBox(height: 30),
                  if (widget.question.imageData != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        widget.question.imageData!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                  Text(
                    widget.question.text, 
                    style: TextStyle(fontSize: AppDesign.isSmallScreen(context) ? 24 : 35, fontWeight: FontWeight.bold, color: Colors.white, height: 1.4), 
                    textAlign: TextAlign.center
                  ),
                  const SizedBox(height: 30),
                  if (_showAnswer) ...[
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 20),
                    const Text('الإجابة الصحيحة:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text(
                      widget.question.answer, 
                      style: TextStyle(color: Colors.greenAccent, fontSize: AppDesign.isSmallScreen(context) ? 22 : 32, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                  ],
                  Builder(
                    builder: (context) {
                      bool isSmall = AppDesign.isSmallScreen(context);
                      return isSmall 
                        ? Column(
                            children: [
                              if (!_showAnswer) 
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber, 
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    ),
                                    onPressed: () => setState(() => _showAnswer = true), 
                                    child: const Text('إظهار الإجابة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
                                  ),
                                ),
                              if (_showAnswer) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.greenAccent, 
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    ), 
                                    onPressed: () { widget.onResult(true); Navigator.pop(context); }, 
                                    child: const Text('إجابة صحيحة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent, 
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    ), 
                                    onPressed: () { widget.onResult(false); Navigator.pop(context); }, 
                                    child: const Text('إجابة خاطئة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
                                  ),
                                ),
                              ]
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!_showAnswer) 
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber, 
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                  onPressed: () => setState(() => _showAnswer = true), 
                                  child: const Text('إظهار الإجابة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
                                ),
                              if (_showAnswer) ...[
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent, 
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ), 
                                  onPressed: () { widget.onResult(true); Navigator.pop(context); }, 
                                  child: const Text('إجابة صحيحة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
                                ),
                                const SizedBox(width: 20),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent, 
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ), 
                                  onPressed: () { widget.onResult(false); Navigator.pop(context); }, 
                                  child: const Text('إجابة خاطئة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
                                ),
                              ]
                            ],
                          );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
