import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wheel_providers.dart';
import '../../../questions/presentation/providers/question_providers.dart';
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
    final textController = TextEditingController(text: segment?.text ?? '');
    final pointsController = TextEditingController(text: segment?.points.toString() ?? '10');
    bool isQuestion = segment?.isQuestion ?? false;
    int? selectedCategoryId = segment?.categoryId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final categoriesAsync = ref.watch(categoriesProvider);

          return AlertDialog(
            title: Text(segment == null ? 'إضافة قسم جديد' : 'تعديل القسم'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: textController, decoration: const InputDecoration(labelText: 'النص (مثلاً: سؤال سهل)')),
                  TextField(controller: pointsController, decoration: const InputDecoration(labelText: 'النقاط'), keyboardType: TextInputType.number),
                  SwitchListTile(
                    title: const Text('مرتبط بسؤال؟'),
                    value: isQuestion,
                    onChanged: (val) => setState(() => isQuestion = val),
                  ),
                  if (isQuestion)
                    categoriesAsync.when(
                      data: (categories) => DropdownButton<int>(
                        isExpanded: true,
                        value: selectedCategoryId,
                        hint: const Text('اختر النوع'),
                        items: categories
                            .map((c) => DropdownMenuItem<int>(
                                  value: c.id,
                                  child: Text(c.name),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => selectedCategoryId = val),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (err, stack) => Text('خطأ في تحميل الأنواع: $err'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () {
                  final newSegment = WheelSegment(
                    id: segment?.id,
                    text: textController.text,
                    points: int.tryParse(pointsController.text) ?? 10,
                    isQuestion: isQuestion,
                    categoryId: isQuestion ? selectedCategoryId : null,
                  );
                  if (segment == null) {
                    ref.read(wheelSegmentsProvider.notifier).addSegment(newSegment);
                  } else {
                    ref.read(wheelSegmentsProvider.notifier).updateSegment(newSegment);
                  }
                  Navigator.pop(context);
                },
                child: Text(segment == null ? 'إضافة' : 'حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }
}
