import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/penalty_settings_provider.dart';

class PenaltySettingsPage extends ConsumerWidget {
  const PenaltySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(penaltySettingsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: settingsAsync.when(
        data: (settings) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إعدادات ضربات الجزاء',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amberAccent,
                ),
              ),
              const SizedBox(height: 24),

              _buildCard(
                context,
                title: 'الميزة التنافسية',
                subtitle:
                    'تفعيل المنافسة على السؤال للبقاء للأسرع، بدلاً من نظام الأدوار المعتاد.',
                child: SwitchListTile(
                  title: const Text(
                    'أول من يضغط يُجيب',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  value: settings['competitive_mode'] ?? false,
                  activeThumbColor: Colors.amber,
                  onChanged: (val) => ref
                      .read(penaltySettingsProvider.notifier)
                      .setCompetitiveMode(val),
                ),
              ),

              if (settings['competitive_mode'] == true) ...[
                const SizedBox(height: 24),
                _buildCard(
                  context,
                  title: 'أزرار الفريقين (بالأحرف الإنجليزية)',
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildKeySelection(
                          context,
                          title: 'الفريق أ (يمين)',
                          currentKey: settings['team_a_key'],
                          onChanged: (val) => ref
                              .read(penaltySettingsProvider.notifier)
                              .setTeamAKey(val),
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildKeySelection(
                          context,
                          title: 'الفريق ب (يسار)',
                          currentKey: settings['team_b_key'],
                          onChanged: (val) => ref
                              .read(penaltySettingsProvider.notifier)
                              .setTeamBKey(val),
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              _buildCard(
                context,
                title: 'وقت الإجابة (بالثواني)',
                subtitle: 'حدد عدد الثواني المتاحة للإجابة على كل سؤال.',
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.amber, size: 30),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Slider(
                        value: (settings['timer_duration'] ?? 10).toDouble(),
                        min: 3,
                        max: 30,
                        divisions: 27,
                        activeColor: Colors.amber,
                        onChanged: (val) => ref
                            .read(penaltySettingsProvider.notifier)
                            .setTimerDuration(val.round()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${settings['timer_duration'] ?? 10} ث',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (err, stack) => Center(
          child: Text('خطأ: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildKeySelection(
    BuildContext context, {
    required String title,
    required String currentKey,
    required Function(String) onChanged,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 80,
          child: TextField(
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            maxLength: 1,
            decoration: InputDecoration(
              counterText: "",
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: color.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: color, width: 2),
              ),
              filled: true,
              fillColor: color.withOpacity(0.1),
            ),
            controller: TextEditingController(text: currentKey),
            onChanged: (val) {
              if (val.isNotEmpty) onChanged(val[0]);
            },
          ),
        ),
      ],
    );
  }
}
