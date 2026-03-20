import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/under_pressure_settings_provider.dart';
import 'package:games/core/design/app_design.dart';

class UnderPressureSettingsPage extends ConsumerWidget {
  const UnderPressureSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(underPressureSettingsProvider);

    return settingsAsync.when(
      data: (settings) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSettingCard(
              context,
              title: 'إعدادات تحت الضغط',
              icon: Icons.timer_outlined,
              children: [
                _buildNumberSetting(
                  context,
                  title: 'عدد الأسئلة في الجولة',
                  subtitle: 'يحدد عدد الأسئلة التي تظهر لكل فريق',
                  value: settings['question_count'] ?? 15,
                  min: 5,
                  max: 50,
                  onChanged: (val) => ref.read(underPressureSettingsProvider.notifier).setQuestionCount(val),
                ),
                const Divider(color: Colors.white10),
                _buildNumberSetting(
                  context,
                  title: 'الوقت المتاح للجولة (بالثواني)',
                  subtitle: 'الوقت الذي سيبدأ به العداد لكل فريق',
                  value: settings['timer_duration'] ?? 60,
                  min: 10,
                  max: 300,
                  onChanged: (val) => ref.read(underPressureSettingsProvider.notifier).setTimerDuration(val),
                ),
                const Divider(color: Colors.white10),
                _buildNumberSetting(
                  context,
                  title: 'نقاط كل سؤال',
                  subtitle: 'النقاط التي يحصل عليها الفريق لكل إجابة صحيحة',
                  value: settings['points_per_question'] ?? 1,
                  min: 1,
                  max: 100,
                  onChanged: (val) => ref.read(underPressureSettingsProvider.notifier).setPointsPerQuestion(val),
                ),
                const Divider(color: Colors.white10),
                _buildNumberSetting(
                  context,
                  title: 'نقاط البونص',
                  subtitle: 'النقاط الإضافية للفائز في الجولة',
                  value: settings['bonus_points'] ?? 10,
                  min: 0,
                  max: 500,
                  onChanged: (val) => ref.read(underPressureSettingsProvider.notifier).setBonusPoints(val),
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
      error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
    );
  }

  Widget _buildSettingCard(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 800),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.purpleAccent),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberSetting(BuildContext context, {required String title, required String subtitle, required int value, required int min, required int max, required Function(int) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              InkWell(
                onTap: () {
                  final controller = TextEditingController(text: value.toString());
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                      title: Text(title, style: const TextStyle(color: Colors.white)),
                      content: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: AppDesign.searchInputDecoration('أدخل القيمة'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final val = int.tryParse(controller.text);
                            if (val != null) {
                              onChanged(val.clamp(min, max));
                            }
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                          child: const Text('حفظ'),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.white54),
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
