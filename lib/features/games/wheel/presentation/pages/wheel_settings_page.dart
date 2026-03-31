import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wheel_providers.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import '../../domain/entities/wheel_segment.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';

class WheelSettingsPage extends ConsumerWidget {
  const WheelSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentsAsync = ref.watch(wheelSegmentsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: segmentsAsync.when(
        data: (segments) => Theme(
          data: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Colors.transparent,
            cardColor: Colors.white.withOpacity(0.05),
          ),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildGeneralWheelSettings(context, ref),
              const SizedBox(height: 24),
              const Text('إدارة أقسام العجلة', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...segments.map((segment) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(segment.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        segment.isSwitch ? 'سويتش (تبديل اختيار)' : 
                        segment.isJoker ? 'جوكر (اختيار حر)' :
                        'النقاط: ${segment.points} | ${segment.isQuestion ? "سؤال" : "بدون سؤال"}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => ref.read(wheelSegmentsProvider.notifier).deleteSegment(segment.id!),
                    ),
                    onTap: () => _showAddEditSegmentDialog(context, ref, segment: segment),
                  ),
                ),
              )).toList(),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (err, stack) => Center(child: Text('خطأ: $err', style: const TextStyle(color: Colors.red))),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        onPressed: () => _showAddEditSegmentDialog(context, ref),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  Widget _buildGeneralWheelSettings(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(generalSettingsProvider);
    return settingsAsync.maybeWhen(
      data: (settings) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إعدادات اللعبة العامة', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('تفعيل عداد وقت السؤال', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              secondary: const Icon(Icons.av_timer_outlined, color: Colors.cyanAccent),
              value: settings['enable_question_timer'] ?? false,
              onChanged: (val) => ref.read(generalSettingsProvider.notifier).setEnableQuestionTimer(val),
              contentPadding: EdgeInsets.zero,
            ),
            if (settings['enable_question_timer'] == true) ...[
              const Divider(color: Colors.white10),
              ListTile(
                title: const Text('مدة وقت السؤال', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text('${settings['question_timer_duration']} ثانية', style: const TextStyle(color: Colors.white60)),
                trailing: const Icon(Icons.edit_note_outlined, color: Colors.white70),
                contentPadding: EdgeInsets.zero,
                onTap: () => _showDurationPicker(context, ref, settings['question_timer_duration']),
              ),
              const Divider(color: Colors.white10),
              SwitchListTile(
                title: const Text('إظهار الإجابة والتحقق تلقائياً', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                secondary: const Icon(Icons.visibility_outlined, color: Colors.amberAccent, size: 20),
                value: settings['auto_show_answer'] ?? false,
                onChanged: (val) => ref.read(generalSettingsProvider.notifier).setAutoShowAnswer(val),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }

  void _showDurationPicker(BuildContext context, WidgetRef ref, int current) {
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
              Text('$val ثانية', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white)),
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

  void _showAddEditSegmentDialog(BuildContext context, WidgetRef ref, {WheelSegment? segment}) {
    showDialog(
      context: context,
      builder: (context) => _SegmentDialog(segment: segment),
    );
  }
}

class _SegmentDialog extends ConsumerStatefulWidget {
  final WheelSegment? segment;
  const _SegmentDialog({this.segment});

  @override
  ConsumerState<_SegmentDialog> createState() => _SegmentDialogState();
}

class _SegmentDialogState extends ConsumerState<_SegmentDialog> {
  late TextEditingController _textController;
  late TextEditingController _pointsController;
  late bool _isQuestion;
  late bool _isSwitch;
  late bool _isJoker;
  List<int> _selectedCategoryIds = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.segment?.text ?? '');
    _pointsController = TextEditingController(text: widget.segment?.points.toString() ?? '10');
    _isQuestion = widget.segment?.isQuestion ?? false;
    _isSwitch = widget.segment?.isSwitch ?? false;
    _isJoker = widget.segment?.isJoker ?? false;
    _selectedCategoryIds = List.from(widget.segment?.categoryIds ?? []);
  }

  @override
  void dispose() {
    _textController.dispose();
    _pointsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.segment == null ? 'إضافة قسم جديد' : 'تعديل القسم', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'النص المعروض',
                  labelStyle: const TextStyle(color: Colors.white60),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.amber)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _pointsController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'النقاط',
                  labelStyle: const TextStyle(color: Colors.white60),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.amber)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _buildSwitch('مرتبط بسؤال؟', _isQuestion, (v) => setState(() => _isQuestion = v)),
              _buildSwitch('قسم سويتش؟', _isSwitch, (v) => setState(() => _isSwitch = v)),
              _buildSwitch('قسم جوكر؟', _isJoker, (v) => setState(() => _isJoker = v)),
              
              if (_isQuestion) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: Colors.white10),
                ),
                const Text('اختر أنواع الأسئلة المرتبطة:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'البحث عن فئة...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    prefixIcon: const Icon(Icons.search, color: Colors.amber, size: 20),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 10),
                categoriesAsync.when(
                  data: (categories) {
                    if (categories.isEmpty) return const Text('لا توجد أنواع أسئلة مضافة', style: TextStyle(color: Colors.redAccent));
                    final filtered = categories.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                    if (filtered.isEmpty) return const Padding(padding: EdgeInsets.all(8.0), child: Text('لا توجد نتائج', style: TextStyle(color: Colors.white24)));
                    return Column(
                      children: filtered.map((category) {
                        return CheckboxListTile(
                          title: Text(category.name, style: const TextStyle(color: Colors.white)),
                          activeColor: Colors.amber,
                          checkColor: Colors.black,
                          value: _selectedCategoryIds.contains(category.id),
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) _selectedCategoryIds.add(category.id!);
                              else _selectedCategoryIds.remove(category.id);
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('خطأ: $err', style: const TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
          onPressed: () {
            final newSegment = WheelSegment(
              id: widget.segment?.id,
              text: _textController.text,
              points: int.tryParse(_pointsController.text) ?? 10,
              isQuestion: _isQuestion,
              isSwitch: _isSwitch,
              isJoker: _isJoker,
              categoryIds: _isQuestion ? _selectedCategoryIds : [],
            );
            if (widget.segment == null) {
              ref.read(wheelSegmentsProvider.notifier).addSegment(newSegment);
            } else {
              ref.read(wheelSegmentsProvider.notifier).updateSegment(newSegment);
            }
            Navigator.pop(context);
          },
          child: Text(widget.segment == null ? 'إضافة' : 'حفظ'),
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      value: value,
      activeColor: Colors.amber,
      onChanged: onChanged,
    );
  }
}
