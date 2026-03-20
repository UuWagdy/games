import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_providers.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';

class GeneralSettingsPage extends ConsumerWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(generalSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: settingsAsync.when(
        data: (settings) => Theme(
          data: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.transparent,
            cardColor: Colors.white.withOpacity(0.05),
            dividerColor: Colors.white10,
          ),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'إعدادات الأسئلة',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.amber),
              ),
              const SizedBox(height: 16),
              _buildCard(context, [
                SwitchListTile(
                  title: const Text('تكرار الأسئلة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('هل يسمح بتكرار ظهور السؤال مرة أخرى؟', style: TextStyle(color: Colors.white60)),
                  value: settings['repeat_questions'],
                  onChanged: (val) => ref.read(generalSettingsProvider.notifier).setRepeatQuestions(val),
                ),
                const Divider(),
                ListTile(
                  title: const Text('نظام اختيار الأسئلة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('عندما يكون قسم العجلة مرتبطاً بأكثر من فئة واحدة', style: TextStyle(color: Colors.white60)),
                  trailing: DropdownButton<String>(
                    dropdownColor: const Color(0xFF1E293B),
                    underline: const SizedBox(),
                    value: settings['selection_mode'],
                    items: const [
                      DropdownMenuItem(value: 'random', child: Text('عشوائي', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'manual', child: Text('يدوي', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) ref.read(generalSettingsProvider.notifier).setSelectionMode(val);
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  title: const Text('تتبع استعمال الأسئلة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('هل السؤال يعتبر مستعمل لكل الفئات أم للفئة الحالية فقط؟', style: TextStyle(color: Colors.white60)),
                  trailing: DropdownButton<String>(
                    dropdownColor: const Color(0xFF1E293B),
                    underline: const SizedBox(),
                    value: settings['usage_tracking_mode'] ?? 'per_category',
                    items: const [
                      DropdownMenuItem(value: 'per_category', child: Text('لكل فئة', style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(value: 'per_question', child: Text('للسؤال عامة', style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) {
                      if (val != null) ref.read(generalSettingsProvider.notifier).setUsageTrackingMode(val);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 32),
              const Text(
                'عمليات استرجاع وتصفير',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.amber),
              ),
              const SizedBox(height: 16),
              _buildCard(context, [
                ListTile(
                  leading: const Icon(Icons.history_outlined, color: Colors.blueAccent),
                  title: const Text('إعادة تعيين الأسئلة المستعملة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  onTap: () => _confirmResetQuestions(context, ref),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.score_outlined, color: Colors.redAccent),
                  title: const Text('تصفير كل النقاط', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  onTap: () => _confirmResetScores(context, ref),
                ),
              ]),
              const SizedBox(height: 32),
              const Text(
                'إعدادات الوقت',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.amber),
              ),
              const SizedBox(height: 16),
              _buildCard(context, [
                ListTile(
                  title: const Text('وقت لفة العجلة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${settings['wheel_spin_duration']} ثانية', style: const TextStyle(color: Colors.white60)),
                  trailing: const Icon(Icons.timer_outlined, color: Colors.amberAccent),
                  onTap: () => _showSpinDurationPicker(context, ref, settings['wheel_spin_duration']),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('تفعيل عداد وقت السؤال', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  secondary: const Icon(Icons.av_timer_outlined, color: Colors.cyanAccent),
                  value: settings['enable_question_timer'] ?? false,
                  onChanged: (val) => ref.read(generalSettingsProvider.notifier).setEnableQuestionTimer(val),
                ),
                if (settings['enable_question_timer'] == true)
                  ListTile(
                    title: const Text('مدة وقت السؤال', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(_formatDuration(settings['question_timer_duration']), style: const TextStyle(color: Colors.white60)),
                    trailing: const Icon(Icons.edit_note_outlined, color: Colors.white70),
                    onTap: () => _showQuestionDurationPicker(context, ref, settings['question_timer_duration']),
                  ),
              ]),
              const SizedBox(height: 32),
              const Text(
                'النقاط والمزامنة',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.amber),
              ),
              const SizedBox(height: 16),
              _buildCard(context, [
                SwitchListTile(
                  title: const Text('مزامنة النقاط بين الألعاب', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('عند التفعيل، النقاط تزيد في جميع الألعاب للفريق', style: TextStyle(color: Colors.white60)),
                  value: settings['sync_scores'] ?? false,
                  onChanged: (val) => ref.read(generalSettingsProvider.notifier).setSyncScores(val),
                ),
                const Divider(),
                ListTile(
                  title: const Text('نقاط الفوز في ضربات الجزاء', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${settings['penalty_win_points'] ?? 25} نقطة', style: const TextStyle(color: Colors.white60)),
                  onTap: () => _showPointsPicker(context, ref, 'نقاط الفوز في ضربات الجزاء', settings['penalty_win_points'] ?? 25, (val) => ref.read(generalSettingsProvider.notifier).setPenaltyWinPoints(val)),
                ),
                const Divider(),
                ListTile(
                  title: const Text('نقاط الفوز في بنك الحظ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${settings['bank_al_haz_win_points'] ?? 50} نقطة', style: const TextStyle(color: Colors.white60)),
                  onTap: () => _showPointsPicker(context, ref, 'نقاط الفوز في بنك الحظ', settings['bank_al_haz_win_points'] ?? 50, (val) => ref.read(generalSettingsProvider.notifier).setBankAlHazWinPoints(val)),
                ),
              ]),
              const SizedBox(height: 40),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (err, stack) => Center(child: Text('خطأ: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(children: children),
    );
  }

  void _confirmResetQuestions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('إعادة تعيين الأسئلة', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من جعل جميع الأسئلة غير مستعملة؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              ref.read(questionsProvider(null).notifier).resetAllQuestionsUsed();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت العملية بنجاح')));
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _confirmResetScores(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تصفير النقاط', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من تصفير نقاط كل الفرق؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(teamsListProvider.notifier).resetScores();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تصفير النقاط')));
            },
            child: const Text('تصفير الكل'),
          ),
        ],
      ),
    );
  }

  void _showSpinDurationPicker(BuildContext context, WidgetRef ref, int current) {
    int val = current;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('مدة لفة العجلة', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$val ثانية', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Slider(
                value: val.toDouble(),
                min: 1, max: 15, divisions: 14,
                onChanged: (newVal) => setState(() => val = newVal.toInt()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              ref.read(generalSettingsProvider.notifier).setWheelSpinDuration(val);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds ثانية';
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return secs == 0 ? '$mins دقيقة' : '$mins دقيقة و $secs ثانية';
  }

  void _showQuestionDurationPicker(BuildContext context, WidgetRef ref, int current) {
    int val = current;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('وقت الإجابة', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_formatDuration(val), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
              const SizedBox(height: 10),
              Slider(
                value: val.toDouble(),
                min: 5, max: 300, divisions: 59,
                onChanged: (newVal) => setState(() => val = newVal.toInt()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              ref.read(generalSettingsProvider.notifier).setQuestionTimerDuration(val);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showPointsPicker(BuildContext context, WidgetRef ref, String title, int current, Function(int) onSave) {
    int val = current;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$val نقطة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
              Slider(
                value: val.toDouble(),
                min: 0, max: 500, divisions: 50,
                activeColor: Colors.amber,
                onChanged: (newVal) => setState(() => val = newVal.toInt()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              onSave(val);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
