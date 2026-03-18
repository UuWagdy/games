import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/question_providers.dart';
import '../../domain/entities/question.dart';

class QuestionsManagementPage extends ConsumerWidget {
  const QuestionsManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'الأنواع / المجموعات'),
              Tab(text: 'الأسئلة'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                const _CategoriesList(),
                const _QuestionsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesList extends ConsumerWidget {
  const _CategoriesList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: categoriesAsync.when(
        data: (categories) => ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              title: Text(category.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => ref
                    .read(categoriesProvider.notifier)
                    .deleteCategory(category.id!),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطأ: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => _showAddCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة نوع جديد'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(categoriesProvider.notifier).addCategory(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class _QuestionsList extends ConsumerWidget {
  const _QuestionsList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(child: Text('يرجى إضافة نوع أولاً'));
        }
        return _QuestionsBySelectedCategory(categories: categories);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('خطأ: $err')),
    );
  }
}

class _QuestionsBySelectedCategory extends StatefulWidget {
  final List<dynamic> categories;
  const _QuestionsBySelectedCategory({required this.categories});

  @override
  State<_QuestionsBySelectedCategory> createState() =>
      _QuestionsBySelectedCategoryState();
}

class _QuestionsBySelectedCategoryState
    extends State<_QuestionsBySelectedCategory> {
  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      selectedCategoryId = widget.categories.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButton<int>(
            isExpanded: true,
            value: selectedCategoryId,
            items: widget.categories
                .map((c) => DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(c.name),
                    ))
                .toList(),
            onChanged: (val) => setState(() => selectedCategoryId = val),
          ),
        ),
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final questionsAsync = ref.watch(questionsProvider(selectedCategoryId));
              return questionsAsync.when(
                data: (questions) => Scaffold(
                  body: ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      return ListTile(
                        title: Text(q.text),
                        subtitle: Text('الإجابة: ${q.answer}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => ref
                              .read(questionsProvider(selectedCategoryId).notifier)
                              .deleteQuestion(q.id!),
                        ),
                      );
                    },
                  ),
                  floatingActionButton: FloatingActionButton(
                    mini: true,
                    onPressed: () => _showAddQuestionDialog(
                        context, ref, selectedCategoryId!),
                    child: const Icon(Icons.add),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('خطأ: $err')),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddQuestionDialog(BuildContext context, WidgetRef ref, int catId) {
    final qController = TextEditingController();
    final aController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة سؤال جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: qController, decoration: const InputDecoration(labelText: 'السؤال')),
            TextField(controller: aController, decoration: const InputDecoration(labelText: 'الإجابة')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (qController.text.isNotEmpty && aController.text.isNotEmpty) {
                ref.read(questionsProvider(catId).notifier).addQuestion(Question(
                      text: qController.text,
                      answer: aController.text,
                      categoryId: catId,
                    ));
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}
