import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/features/teams/presentation/providers/team_providers.dart';
import 'package:games/features/teams/domain/entities/team.dart';

class XOSettingsDialog extends ConsumerWidget {
  const XOSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(generalSettingsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final teamsAsync = ref.watch(teamsListProvider);

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('إعدادات لعبة XO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: settingsAsync.when(
        data: (settings) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('اللعب ضد الكمبيوتر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('إذا تم إيقافه، تلعب ضد شخص آخر بالتناوب', style: TextStyle(color: Colors.white60)),
              value: settings['tic_tac_toe_vs_computer'] ?? true,
              onChanged: (val) => ref.read(generalSettingsProvider.notifier).setTicTacToeVsComputer(val),
              activeColor: Colors.blueAccent,
            ),
            SwitchListTile(
              title: const Text('عكس الدور', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('تبديل X و O بين الفريقين كل دور', style: TextStyle(color: Colors.white60)),
              value: settings['tic_tac_toe_swap_roles'] ?? false,
              onChanged: (val) => ref.read(generalSettingsProvider.notifier).setTicTacToeSwapRoles(val),
              activeColor: Colors.purpleAccent,
            ),
            const Divider(color: Colors.white10),
            SwitchListTile(
              title: const Text('وضع الأسئلة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('المطالبة بالإجابة قبل وضع الـ X', style: TextStyle(color: Colors.white60)),
              value: settings['tic_tac_toe_questions_enabled'] ?? false,
              onChanged: (val) => ref.read(generalSettingsProvider.notifier).setTicTacToeQuestionsEnabled(val),
              activeColor: Colors.amberAccent,
            ),
            const Divider(color: Colors.white10),
            ListTile(
              title: const Text('الفئات المختارة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('من أين تأتي الأسئلة؟', style: TextStyle(color: Colors.white60)),
               onTap: () => categoriesAsync.whenData((cats) => _showMultiCategoryPicker(context, ref, cats, settings['tic_tac_toe_category_ids'] as List<int>? ?? [])),
            ),
            if ((settings['tic_tac_toe_category_ids'] as List<int>? ?? []).isNotEmpty)
              categoriesAsync.maybeWhen(
                data: (cats) {
                  final selectedIds = settings['tic_tac_toe_category_ids'] as List<int>;
                  final selectedNames = cats.where((c) => selectedIds.contains(c.id)).map((c) => c.name).toList();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: selectedNames.map((name) => Chip(
                        label: Text(name, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                        backgroundColor: Colors.white10,
                        visualDensity: VisualDensity.compact,
                        onDeleted: () {
                          final newIds = List<int>.from(selectedIds)..remove(cats.firstWhere((c) => c.name == name).id);
                          ref.read(generalSettingsProvider.notifier).setTicTacToeCategoryIds(newIds);
                        },
                      )).toList(),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            const Divider(color: Colors.white10),
            ListTile(
              visualDensity: VisualDensity.compact,
              title: const Text('فريق X', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              trailing: teamsAsync.when(
                data: (teams) => _buildTeamDropdown(ref, teams, settings['tic_tac_toe_team_x_id'], (val) => ref.read(generalSettingsProvider.notifier).setTicTacToeTeamXId(val)),
                loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const Icon(Icons.error, color: Colors.red),
              ),
            ),
            ListTile(
              visualDensity: VisualDensity.compact,
              title: const Text('فريق O', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              enabled: !(settings['tic_tac_toe_vs_computer'] ?? true),
              trailing: teamsAsync.when(
                data: (teams) => _buildTeamDropdown(ref, teams, settings['tic_tac_toe_team_o_id'], (val) => ref.read(generalSettingsProvider.notifier).setTicTacToeTeamOId(val)),
                loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const Icon(Icons.error, color: Colors.red),
              ),
            ),
            const Divider(color: Colors.white10),
            ListTile(
               title: const Text('نقاط الفوز', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
               subtitle: Text('${settings['tic_tac_toe_win_points'] ?? 20} نقطة', style: const TextStyle(color: Colors.white60)),
               onTap: () => _showPointsPicker(context, ref, settings['tic_tac_toe_win_points'] ?? 20),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Text('Error: $e'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
      ],
    );
  }

  Widget _buildTeamDropdown(WidgetRef ref, List<Team> allTeams, int? currentId, Function(int?) onChanged) {
    final settings = ref.read(generalSettingsProvider).value;
    final bool globalAiEnabled = settings?['global_ai_enabled'] ?? false;
    final teams = globalAiEnabled ? allTeams : allTeams.where((t) => t.name != 'AI' && t.name != 'الآلي' && t.name != 'COMPUTER').toList();

    return DropdownButton<int?>(
      value: currentId,
      dropdownColor: const Color(0xFF1E293B),
      underline: const SizedBox(),
      style: const TextStyle(color: Colors.white),
      hint: const Text('اختر الفريق', style: TextStyle(color: Colors.white38, fontSize: 12)),
      items: [
        const DropdownMenuItem(value: null, child: Text('بدون فريق', style: TextStyle(fontSize: 12))),
        ...teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name, style: const TextStyle(fontSize: 12)))),
      ],
      onChanged: onChanged,
    );
  }

  void _showMultiCategoryPicker(BuildContext context, WidgetRef ref, List<dynamic> allCats, List<int> currentIds) {
    List<int> selectedIds = List<int>.from(currentIds);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('اختر الفئات', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allCats.length,
              itemBuilder: (context, index) {
                final cat = allCats[index];
                final isSelected = selectedIds.contains(cat.id);
                return CheckboxListTile(
                   title: Text(cat.name, style: const TextStyle(color: Colors.white)),
                   value: isSelected,
                   activeColor: Colors.amberAccent,
                   onChanged: (val) {
                      setState(() {
                         if (val == true) {
                           selectedIds.add(cat.id);
                         } else {
                           selectedIds.remove(cat.id);
                         }
                      });
                   },
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              ref.read(generalSettingsProvider.notifier).setTicTacToeCategoryIds(selectedIds);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showPointsPicker(BuildContext context, WidgetRef ref, int current) {
    int val = current;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تحديد نقاط الفوز', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$val نقطة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.amberAccent)),
              Slider(
                value: val.toDouble(),
                min: 0, max: 200, divisions: 20,
                onChanged: (newVal) => setState(() => val = newVal.toInt()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              ref.read(generalSettingsProvider.notifier).setTicTacToeWinPoints(val);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
