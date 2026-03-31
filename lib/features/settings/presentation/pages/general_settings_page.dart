import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backup_restore_page.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import '../providers/settings_providers.dart';
import 'package:games/features/games/penalty_shootout/presentation/providers/penalty_settings_provider.dart';
import 'package:games/features/games/under_pressure/presentation/providers/under_pressure_settings_provider.dart';
import 'package:games/features/games/snakes_and_ladders/presentation/providers/snakes_ladders_providers.dart';
import 'package:games/features/games/quiz_arena/presentation/providers/quiz_arena_provider.dart';
import 'package:games/features/games/spy_game/presentation/providers/spy_game_provider.dart';
import 'package:games/features/games/ludo_quiz/presentation/providers/ludo_controller.dart';


class GeneralSettingsPage extends ConsumerWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(generalSettingsProvider);
    final penaltySettings = ref.watch(penaltySettingsProvider);
    final underPressureSettings = ref.watch(underPressureSettingsProvider);
    final snakesLaddersGame = ref.watch(snakesLaddersGameProvider);
    final quizArenaSettings = ref.watch(quizArenaSettingsProvider);
    final spyGame = ref.watch(spyGameProvider);
    final ludoGame = ref.watch(ludoControllerProvider);

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
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined, color: Colors.orangeAccent),
                  title: const Text('حذف الأسئلة المكررة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('يقوم بالبحث عنها بالاسم وحذف المكرر منها', style: TextStyle(color: Colors.white60)),
                  onTap: () => _confirmRemoveDuplicates(context, ref),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.category_outlined, color: Colors.amberAccent),
                  title: const Text('حذف الفئات المكررة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('يتم دمج الفئات التي لها نفس الاسم وحذف المكرر', style: TextStyle(color: Colors.white60)),
                  onTap: () => _confirmRemoveDuplicateCategories(context, ref),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                  title: const Text('مسح كافة البيانات (أسئلة وفئات)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('سيتم حذف كافة الأسئلة والفئات بالكامل من قاعدة البيانات', style: TextStyle(color: Colors.white60)),
                  onTap: () => _confirmDeleteAllCategories(context, ref),
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
              ]),
              const SizedBox(height: 32),
              const Text(
                'إعدادات الألعاب',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.amber),
              ),
              const SizedBox(height: 16),
              
              // Penalty Shootout Section
              _buildSectionTitle('ضربات الجزاء', Icons.sports_soccer),
              _buildCard(context, [
                ListTile(
                  title: const Text('نقاط الفوز', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${settings['penalty_win_points'] ?? 25} نقطة', style: const TextStyle(color: Colors.white60)),
                  onTap: () => _showPointsPicker(context, ref, 'نقاط الفوز في ضربات الجزاء', settings['penalty_win_points'] ?? 25, (val) => ref.read(generalSettingsProvider.notifier).setPenaltyWinPoints(val)),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('الوضع التنافسي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('تبادل الأدوار بين الفرق في كل محاولة', style: TextStyle(color: Colors.white60)),
                  value: penaltySettings.value?['competitive_mode'] ?? true,
                  onChanged: (val) => ref.read(penaltySettingsProvider.notifier).setCompetitiveMode(val),
                ),
                const Divider(),
                ListTile(
                  title: const Text('وقت التسديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${penaltySettings.value?['timer_duration'] ?? 10} ثانية', style: const TextStyle(color: Colors.white60)),
                  onTap: () => _showSecondsPicker(context, ref, 'وقت التسديد', penaltySettings.value?['timer_duration'] ?? 10, (val) => ref.read(penaltySettingsProvider.notifier).setTimerDuration(val)),
                ),
              ]),
              const SizedBox(height: 24),

              // Tic Tac Toe Section
              _buildSectionTitle('لعبة XO', Icons.grid_3x3_rounded),
              _buildCard(context, [
                ListTile(
                  title: const Text('نقاط الفوز', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${settings['tic_tac_toe_win_points'] ?? 20} نقطة', style: const TextStyle(color: Colors.white60)),
                  onTap: () => _showPointsPicker(context, ref, 'نقاط الفوز في XO', settings['tic_tac_toe_win_points'] ?? 20, (val) => ref.read(generalSettingsProvider.notifier).setTicTacToeWinPoints(val)),
                ),
              ]),
              const SizedBox(height: 24),

              // Under Pressure Section
              _buildSectionTitle('تحت الضغط', Icons.speed),
              _buildCard(context, [
                ListTile(
                  title: const Text('وقت التحدي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${underPressureSettings.value?['timer_duration'] ?? 60} ثانية', style: const TextStyle(color: Colors.white60)),
                  onTap: () => _showSecondsPicker(context, ref, 'وقت التحدي', underPressureSettings.value?['timer_duration'] ?? 60, (val) => ref.read(underPressureSettingsProvider.notifier).setTimerDuration(val)),
                ),
                const Divider(),
                ListTile(
                  title: const Text('نقاط البونص', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${underPressureSettings.value?['bonus_points'] ?? 10} نقطة', style: const TextStyle(color: Colors.white60)),
                  onTap: () => _showPointsPicker(context, ref, 'نقاط البونص', underPressureSettings.value?['bonus_points'] ?? 10, (val) => ref.read(underPressureSettingsProvider.notifier).setBonusPoints(val)),
                ),
              ]),
              const SizedBox(height: 24),

              // Snakes and Ladders Section
              _buildSectionTitle('السلم والثعبان', Icons.extension),
              _buildCard(context, [
                ListTile(
                  title: const Text('نقاط الفوز', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${snakesLaddersGame.winPoints} نقطة', style: const TextStyle(color: Colors.white60)),
                  onTap: () => _showPointsPicker(context, ref, 'نقاط الفوز في السلم والثعبان', snakesLaddersGame.winPoints, (val) => ref.read(snakesLaddersGameProvider.notifier).setWinPoints(val)),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('تفعيل الأسئلة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('هل يجب الإجابة على سؤال قبل التحرك؟', style: TextStyle(color: Colors.white60)),
                  value: snakesLaddersGame.questionsEnabled,
                  onChanged: (val) => ref.read(snakesLaddersGameProvider.notifier).setQuestionsEnabled(val),
                ),
              ]),
              const SizedBox(height: 24),

              // Bank Al Haz Section
              _buildSectionTitle('بنك الحظ', Icons.monetization_on),
              _buildCard(context, [
                ListTile(
                  title: const Text('نقاط الفوز', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${settings['bank_al_haz_win_points'] ?? 50} نقطة', style: const TextStyle(color: Colors.white60)),
                  onTap: () => _showPointsPicker(context, ref, 'نقاط الفوز في بنك الحظ', settings['bank_al_haz_win_points'] ?? 50, (val) => ref.read(generalSettingsProvider.notifier).setBankAlHazWinPoints(val)),
                ),
              ]),
              const SizedBox(height: 24),

              // Quiz Arena Section
              _buildSectionTitle('ساحة الاختبار (Quiz Arena)', Icons.quiz),
              _buildCard(context, [
                SwitchListTile(
                  title: const Text('تفعيل عداد الوقت', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  value: quizArenaSettings.timerEnabled,
                  onChanged: (val) => ref.read(quizArenaSettingsProvider.notifier).updateSettings(quizArenaSettings.copyWith(timerEnabled: val)),
                ),
                const Divider(),
                ListTile(
                  title: const Text('وقت الإجابة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${quizArenaSettings.timeLimitSeconds} ثانية', style: const TextStyle(color: Colors.white60)),
                  onTap: () => _showSecondsPicker(context, ref, 'وقت الإجابة في ساحة الاختبار', quizArenaSettings.timeLimitSeconds, (val) => ref.read(quizArenaSettingsProvider.notifier).updateSettings(quizArenaSettings.copyWith(timeLimitSeconds: val))),
                ),
                const Divider(),
                ListTile(
                  title: const Text('عدد الجولات', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${quizArenaSettings.rounds} جولات', style: const TextStyle(color: Colors.white60)),
                  onTap: () => _showRoundsPicker(context, ref, 'عدد جولات ساحة الاختبار', quizArenaSettings.rounds, (val) => ref.read(quizArenaSettingsProvider.notifier).updateSettings(quizArenaSettings.copyWith(rounds: val))),
                ),
                const Divider(),
                ListTile(
                  title: const Text('نقاط الفوز (للفائز في نهاية الجولات)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${quizArenaSettings.winPoints} نقطة', style: const TextStyle(color: Colors.white60)),
                  onTap: () => _showPointsPicker(context, ref, 'نقاط الفوز في ساحة الاختبار', quizArenaSettings.winPoints, (val) => ref.read(quizArenaSettingsProvider.notifier).updateSettings(quizArenaSettings.copyWith(winPoints: val))),
                ),
              ]),
              const SizedBox(height: 24),

              // Spy Game Section
              _buildSectionTitle('لعبة الجاسوس (Spy Game)', Icons.visibility_off),
              _buildCard(context, [
                ListTile(
                  title: const Text('نقاط الجاسوس عند الفوز', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${spyGame.settings.spyWinPoints} نقطة', style: const TextStyle(color: Colors.white60)),
                  onTap: () => _showPointsPicker(context, ref, 'نقاط فوز الجاسوس', spyGame.settings.spyWinPoints, (val) => ref.read(spyGameProvider.notifier).updateSettings(spyGame.settings.copyWith(spyWinPoints: val))),
                ),
                const Divider(),
                ListTile(
                  title: const Text('نقاط اللاعبين عند الفوز', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${spyGame.settings.playersWinPoints} نقطة', style: const TextStyle(color: Colors.white60)),
                  onTap: () => _showPointsPicker(context, ref, 'نقاط فوز اللاعبين', spyGame.settings.playersWinPoints, (val) => ref.read(spyGameProvider.notifier).updateSettings(spyGame.settings.copyWith(playersWinPoints: val))),
                ),
              ]),
              const SizedBox(height: 24),

              // Ludo Quiz Section
              _buildSectionTitle('لودو الأسئلة (Ludo Quiz)', Icons.grid_on),
              _buildCard(context, [
                ListTile(
                  title: const Text('نقاط الفوز بلعبة لودو', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: Text('${ludoGame.winPoints} نقطة', style: const TextStyle(color: Colors.white60)),
                  onTap: () => _showPointsPicker(context, ref, 'نقاط الفوز في لودو', ludoGame.winPoints, (val) => ref.read(ludoControllerProvider.notifier).updateSettings(winPoints: val)),
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
              ]),
              const SizedBox(height: 32),
              const Text(
                'البيانات والنظام',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.amber),
              ),
              const SizedBox(height: 16),
              _buildCard(context, [
                ListTile(
                  leading: const Icon(Icons.backup_outlined, color: Colors.blueAccent),
                  title: const Text('النسخ الاحتياطي والاستعادة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('حفظ نسخة من بياناتك أو استعادتها (قاعدة البيانات)', style: TextStyle(color: Colors.white60)),
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const BackupRestorePage())
                  ),
                ),
              ]),
              const SizedBox(height: 64),
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

  void _confirmRemoveDuplicates(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('حذف الأسئلة المكررة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('سيتم البحث عن جميع الأسئلة التي لها نفس النص وحذف النسخ الإضافية.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(ctx);
              final count = await ref.read(questionsProvider(null).notifier).removeDuplicateQuestions();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(count > 0 ? 'تم حذف $count سؤال مكرر بنجاح' : 'لا توجد أسئلة مكررة حالياً'), 
                    backgroundColor: count > 0 ? Colors.green : Colors.blueGrey
                  )
                );
              }
            },
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveDuplicateCategories(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('حذف الفئات المكررة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('سيتم البحث عن الفئات التي لها نفس الاسم ودمجها في فئة واحدة وحذف المكرر.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(ctx);
              final count = await ref.read(categoriesProvider.notifier).removeDuplicateCategories();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(count > 0 ? 'تم حذف ودمج $count فئة مكررة بنجاح' : 'لا توجد فئات مكررة حالياً'), 
                    backgroundColor: count > 0 ? Colors.green : Colors.blueGrey
                  )
                );
              }
            },
            child: const Text('تأكيد الحذف والدمج'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAllCategories(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('مسح كافة البيانات (أسئلة وفئات)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من مسح كافة الأسئلة والفئات بالكامل من قاعدة البيانات؟\nسيتم حذف 4010 سؤال تماماً ولا يمكن استعادة البيانات إلا عبر نسخة احتياطية.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(categoriesProvider.notifier).deleteAllCategories();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم مسح كافة البيانات (الأسئلة والفئات) بنجاح'), 
                    backgroundColor: Colors.redAccent
                  )
                );
              }
            },
            child: const Text('حذف الكل'),
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

  void _showSecondsPicker(BuildContext context, WidgetRef ref, String title, int current, Function(int) onSave) {
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
              Text('$val ثانية', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
              Slider(
                value: val.toDouble(),
                min: 1, max: 60, divisions: 59,
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

  void _showRoundsPicker(BuildContext context, WidgetRef ref, String title, int current, Function(int) onSave) {
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
              Text('$val جولة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
              Slider(
                value: val.toDouble(),
                min: 1, max: 50, divisions: 49,
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
