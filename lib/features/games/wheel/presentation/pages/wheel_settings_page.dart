import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wheel_providers.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import '../../domain/entities/wheel_segment.dart';

class WheelSettingsPage extends ConsumerWidget {
  const WheelSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segmentsAsync = ref.watch(wheelSegmentsProvider);

    return Scaffold(
      body: segmentsAsync.when(
        data: (segments) => ListView.builder(
          itemCount: segments.length,
          itemBuilder: (context, index) {
            final segment = segments[index];
            return ListTile(
              title: Text(segment.text),
              subtitle: Text('النقاط: ${segment.points} | ${segment.isQuestion ? "سؤال" : "بدون سؤال"}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => ref
                    .read(wheelSegmentsProvider.notifier)
                    .deleteSegment(segment.id!),
              ),
              onTap: () => _showAddEditSegmentDialog(context, ref, segment: segment),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditSegmentDialog(context, ref),
        child: const Icon(Icons.add),
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
  List<int> _selectedCategoryIds = [];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.segment?.text ?? '');
    _pointsController = TextEditingController(text: widget.segment?.points.toString() ?? '10');
    _isQuestion = widget.segment?.isQuestion ?? false;
    _selectedCategoryIds = List.from(widget.segment?.categoryIds ?? []);
  }

  @override
  void dispose() {
    _textController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return AlertDialog(
      title: Text(widget.segment == null ? 'إضافة قسم جديد' : 'تعديل القسم'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                decoration: const InputDecoration(labelText: 'النص (مثلاً: سؤال سهل)'),
              ),
              TextField(
                controller: _pointsController,
                decoration: const InputDecoration(labelText: 'النقاط'),
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                title: const Text('مرتبط بسؤال؟'),
                value: _isQuestion,
                onChanged: (val) => setState(() => _isQuestion = val),
              ),
              if (_isQuestion) ...[
                const Divider(),
                const Text('اختر الأنواع (للتحكم في الأسئلة العشوائية):', style: TextStyle(fontWeight: FontWeight.bold)),
                categoriesAsync.when(
                  data: (categories) {
                    if (categories.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('لا توجد أنواع أسئلة. يرجى إضافتها من التبويب الثاني.', style: TextStyle(color: Colors.red)),
                      );
                    }
                    return Column(
                      children: categories.map((category) {
                        return CheckboxListTile(
                          title: Text(category.name),
                          value: _selectedCategoryIds.contains(category.id),
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedCategoryIds.add(category.id!);
                              } else {
                                _selectedCategoryIds.remove(category.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )),
                  error: (err, stack) => Text('خطأ في تحميل الأنواع: $err'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () {
            final newSegment = WheelSegment(
              id: widget.segment?.id,
              text: _textController.text,
              points: int.tryParse(_pointsController.text) ?? 10,
              isQuestion: _isQuestion,
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
}
