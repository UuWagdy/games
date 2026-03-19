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
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'إعدادات الأسئلة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('تكرار الأسئلة'),
              subtitle: const Text('هل يسمح بتكرار ظهور السؤال مرة أخرى؟'),
              value: settings['repeat_questions'],
              onChanged: (val) => ref
                  .read(generalSettingsProvider.notifier)
                  .setRepeatQuestions(val),
            ),
            const Divider(),
            ListTile(
              title: const Text('نظام اختيار الأسئلة'),
              subtitle: const Text(
                'عندما يكون قسم العجلة مرتبطاً بأكثر من فئة واحدة',
              ),
              trailing: DropdownButton<String>(
                value: settings['selection_mode'],
                items: const [
                  DropdownMenuItem(
                    value: 'random',
                    child: Text('عشوائي من الفئات'),
                  ),
                  DropdownMenuItem(
                    value: 'manual',
                    child: Text('يدوي (اختيار الفئة)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(generalSettingsProvider.notifier)
                        .setSelectionMode(val);
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('طريقة تتبع استعمال الأسئلة'),
              subtitle: const Text(
                'هل السؤال يعتبر مستعمل لكل الفئات أم للفئة الحالية فقط؟',
              ),
              trailing: DropdownButton<String>(
                value: settings['usage_tracking_mode'] ?? 'per_category',
                items: const [
                  DropdownMenuItem(
                    value: 'per_category',
                    child: Text('لكل فئة على حدة'),
                  ),
                  DropdownMenuItem(
                    value: 'per_question',
                    child: Text('للسؤال بشكل عام'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(generalSettingsProvider.notifier)
                        .setUsageTrackingMode(val);
                  }
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'عمليات استرجاع',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('إعادة تعيين الأسئلة المستعملة'),
              subtitle: const Text(
                'سيتمكن التطبيق من اختيار الأسئلة التي ظهرت سابقاً مرة أخرى',
              ),
              onTap: () => _confirmResetQuestions(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.score_outlined, color: Colors.orange),
              title: const Text('تصفير كل النقاط'),
              subtitle: const Text(
                'سيتم تصفير نقاط جميع الفرق في جميع الألعاب',
              ),
              onTap: () => _confirmResetScores(context, ref),
            ),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'أخرى',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('وقت لفة العجلة (ثواني)'),
              subtitle: Text('${settings['wheel_spin_duration']} ثانية'),
              trailing: const Icon(Icons.timer_outlined),
              onTap: () => _showSpinDurationPicker(
                context,
                ref,
                settings['wheel_spin_duration'],
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'وقت الإجابة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('تفعيل عداد الوقت'),
              subtitle: const Text('هل يجب إنهاء الإجابة خلال وقت محدد؟'),
              secondary: const Icon(Icons.av_timer_outlined),
              value: settings['enable_question_timer'] ?? false,
              onChanged: (val) => ref
                  .read(generalSettingsProvider.notifier)
                  .setEnableQuestionTimer(val),
            ),
            if (settings['enable_question_timer'] == true)
              ListTile(
                title: const Text('وقت الإجابة للسؤال'),
                subtitle: Text(
                  _formatDuration(settings['question_timer_duration']),
                ),
                trailing: const Icon(Icons.edit_note_outlined),
                onTap: () => _showQuestionDurationPicker(
                  context,
                  ref,
                  settings['question_timer_duration'],
                ),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
      ),
    );
  }

  void _confirmResetQuestions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد'),
        content: const Text(
          'هل أنت متأكد من إعادة تعيين جميع الأسئلة لتكون غير مستعملة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(questionsProvider(null).notifier)
                  .resetAllQuestionsUsed();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمت العملية بنجاح')),
              );
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
        title: const Text('تأكيد'),
        content: const Text('هل أنت متأكد من تصفير جميع نقاط الفرق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(teamsListProvider.notifier).resetScores();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تصفير جميع النقاط')),
              );
            },
            child: const Text('تصفير'),
          ),
        ],
      ),
    );
  }

  void _showSpinDurationPicker(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) {
    int val = current;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مدة لفة العجلة'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$val ثانية'),
              Slider(
                value: val.toDouble(),
                min: 1,
                max: 15,
                divisions: 14,
                onChanged: (newVal) => setState(() => val = newVal.toInt()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(generalSettingsProvider.notifier)
                  .setWheelSpinDuration(val);
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
    if (secs == 0) return '$mins دقيقة';
    return '$mins دقيقة و $secs ثانية';
  }

  void _showQuestionDurationPicker(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) {
    int val = current;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('وقت الإجابة للسؤال'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDuration(val),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Slider(
                value: val.toDouble(),
                min: 5,
                max: 300, // Up to 5 mins
                divisions: 59,
                onChanged: (newVal) => setState(() => val = newVal.toInt()),
              ),
              const Text(
                'بين 5 ثواني و 5 دقائق',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(generalSettingsProvider.notifier)
                  .setQuestionTimerDuration(val);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
