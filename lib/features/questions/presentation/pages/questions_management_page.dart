import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../providers/question_providers.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/category.dart';

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
              children: [const _CategoriesList(), const _QuestionsList()],
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () =>
                        _showEditCategoryDialog(context, ref, category),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => ref
                        .read(categoriesProvider.notifier)
                        .deleteCategory(category.id!),
                  ),
                ],
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
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(categoriesProvider.notifier)
                    .addCategory(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) {
    final controller = TextEditingController(text: category.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل اسم النوع'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(categoriesProvider.notifier)
                    .updateCategory(category.copyWith(name: controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _QuestionsList extends ConsumerWidget {
  const _QuestionsList();

  Future<void> _downloadTemplate(BuildContext context) async {
    try {
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ نموذج الأسئلة الشامل',
        fileName: 'questions_full_template.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputFile == null) return;

      // Header: Text,Answer,Categories,Type,Options (pipe separated),CorrectIndices (comma separated),TFValue (T/F),IsMultiple (T/F),GridRows (pipe separated),GridCols (pipe separated),GridCorrectCells (row,col;row,col)
      final buffer = StringBuffer();
      buffer.writeln(
        'Text,Answer,Categories,Type,Options,CorrectIndices,TFValue,IsMultiple,GridRows,GridCols,GridCorrectCells',
      );

      // Essay Example
      buffer.writeln('ما عاصمة مصر؟,القاهرة,معلومات عامة,مقالي,,,,,,,');

      // MCQ Example
      buffer.writeln(
        'أي من هؤلاء لاعب كرة قدم؟,ميسي,"رياضة, مشاهير",اختيار,"ميسي|رونالدو|صلاح|فان دايك","0,1,2",T,,,,,',
      );

      // True/False Example
      buffer.writeln('الأرض كروية؟,صح,حقائق,صح/خطأ,,,T,F,,,,,');

      // Grid Example
      buffer.writeln(
        'وصل كل بلد بعاصمته؟,,ثقافة,شبكي,,,,F,"مصر|فرنسا","القاهرة|باريس","0,0;1,1"',
      );

      final file = File(outputFile);
      await file.writeAsString('\uFEFF$buffer', encoding: utf8);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحميل النموذج الشامل بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ النموذج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(questionRepositoryProvider);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      String input;
      try {
        input = utf8.decode(bytes);
      } catch (_) {
        input = latin1.decode(bytes);
      }

      final fields = const CsvToListConverter().convert(input);
      if (fields.isEmpty) return;

      int count = 0;
      final currentCats = await repo.getCategories();
      final catMap = {for (var c in currentCats) c.name: c.id!};

      for (var row in fields.skip(1)) {
        // Skip header
        if (row.length < 3) continue;

        // 1. Core Data
        final qText = _get(row, 0);
        final aText = _get(row, 1);
        final catString = _get(row, 2);
        if (qText.isEmpty) continue;

        // 2. Type Mapping
        final typeStr = _get(row, 3).toLowerCase();
        QuestionType type = QuestionType.essay;
        if (typeStr.contains('اختيار') || typeStr.contains('mcq'))
          type = QuestionType.multipleChoice;
        if (typeStr.contains('صح') || typeStr.contains('tf'))
          type = QuestionType.trueFalse;
        if (typeStr.contains('شبكي') || typeStr.contains('grid'))
          type = QuestionType.grid;

        // 3. Category Mapping
        List<int> catIds = [];
        final catNames = catString
            .split(RegExp(r'[,;]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty);
        for (var name in catNames) {
          int? cid = catMap[name];
          if (cid == null) {
            cid = await repo.addCategory(name);
            catMap[name] = cid;
          }
          catIds.add(cid);
        }
        if (catIds.isEmpty) continue;

        // 4. Advanced Fields
        // Options: op1|op2|op3
        final optionsStr = _get(row, 4);
        List<String>? options = optionsStr.isNotEmpty
            ? optionsStr.split('|').map((e) => e.trim()).toList()
            : null;

        // CorrectIndices: 0,1
        final indicesStr = _get(row, 5);
        List<int>? correctIndices = indicesStr.isNotEmpty
            ? indicesStr
                  .split(',')
                  .map((e) => int.tryParse(e.trim()) ?? 0)
                  .toList()
            : null;

        // TFValue: T/F or صح/خطأ
        final tfStr = _get(row, 6).toLowerCase();
        bool? tfValue = tfStr.isEmpty
            ? null
            : (tfStr.startsWith('t') || tfStr.contains('صح'));

        // IsMultiple: T/F
        final multipleStr = _get(row, 7).toLowerCase();
        bool isMultiple =
            multipleStr.startsWith('t') ||
            multipleStr.contains('صح') ||
            multipleStr.contains('نعم');

        // Grid Data: Rows|Cols|Correct (row,col;row,col)
        Map<String, dynamic>? gridData;
        if (type == QuestionType.grid) {
          final rowNames = _get(
            row,
            8,
          ).split('|').map((e) => e.trim()).toList();
          final colNames = _get(
            row,
            9,
          ).split('|').map((e) => e.trim()).toList();
          final cellsStr = _get(row, 10);
          final correctCells = cellsStr.isNotEmpty
              ? cellsStr.split(';').map((s) {
                  final parts = s.split(',');
                  return [
                    int.tryParse(parts[0]) ?? 0,
                    int.tryParse(parts[1]) ?? 0,
                  ];
                }).toList()
              : <List<int>>[];

          gridData = {
            'rows': rowNames.isEmpty ? ['1', '2'] : rowNames,
            'cols': colNames.isEmpty ? ['1', '2'] : colNames,
            'correctCells': correctCells,
          };
        }

        await repo.addQuestion(
          Question(
            text: qText,
            answer: aText,
            type: type,
            categoryIds: catIds,
            options: options,
            correctOptionIndices: correctIndices,
            tfValue: tfValue,
            isMultiple: isMultiple,
            gridData: gridData,
          ),
        );
        count++;
      }

      ref.invalidate(categoriesProvider);
      ref.invalidate(questionsProvider(null));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم استيراد $count سؤال بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاستيراد: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _get(List<dynamic> row, int index) {
    if (index >= row.length) return '';
    return row[index]?.toString().trim() ?? '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              InkWell(
                onTap: () => _importCsv(context, ref),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade500, Colors.green.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'استيراد الأسئلة من ملف Excel',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'المطلوب: ملف CSV يدعم كافة الأنواع (مقالي، خيارات، صح وخطأ، شبكات)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _downloadTemplate(context),
                icon: const Icon(Icons.download_rounded, color: Colors.green),
                label: const Text(
                  'تحميل نموذج فارغ للإكسل',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return const Center(child: Text('يرجى إضافة نوع أولاً'));
              }
              return Stack(
                children: [
                  _QuestionsBySelectedCategory(categories: categories),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: FloatingActionButton(
                      onPressed: () => _showAddQuestionDialog(
                        context,
                        ref,
                        categories,
                        initialCatId: categories.first.id!,
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('خطأ: $err')),
          ),
        ),
      ],
    );
  }
}

class _QuestionsBySelectedCategory extends ConsumerStatefulWidget {
  final List<Category> categories;
  const _QuestionsBySelectedCategory({required this.categories});

  @override
  ConsumerState<_QuestionsBySelectedCategory> createState() =>
      _QuestionsBySelectedCategoryState();
}

class _QuestionsBySelectedCategoryState
    extends ConsumerState<_QuestionsBySelectedCategory> {
  final List<int> selectedCategoryIds = [];
  bool selectAll = true;

  @override
  void initState() {
    super.initState();
    selectAll = true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'تصفية حسب الفئة:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      size: 20,
                      color: Colors.blue,
                    ),
                    onPressed: () => ref.invalidate(questionsProvider),
                    tooltip: 'تحديث القائمة',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('الكل'),
                      selected: selectAll,
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onSelected: (val) {
                        setState(() {
                          selectAll = true;
                          selectedCategoryIds.clear();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    ...widget.categories.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(c.name),
                          selected:
                              !selectAll && selectedCategoryIds.contains(c.id),
                          selectedColor: Colors.blue.shade100,
                          checkmarkColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                selectAll = false;
                                selectedCategoryIds.add(c.id!);
                              } else {
                                selectedCategoryIds.remove(c.id);
                                if (selectedCategoryIds.isEmpty)
                                  selectAll = true;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final questionsAsync = ref.watch(questionsProvider(null));
              return questionsAsync.when(
                data: (allQuestions) {
                  final questions = selectAll
                      ? allQuestions
                      : allQuestions
                            .where(
                              (q) => q.categoryIds.any(
                                (id) => selectedCategoryIds.contains(id),
                              ),
                            )
                            .toList();

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;
                      return GridView.builder(
                        padding: const EdgeInsets.all(
                          16.0,
                        ).copyWith(bottom: 80), // Space for FAB
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isWide
                              ? 400
                              : 800, // Two columns on desktop, one on mobile
                          mainAxisExtent: 110,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final q = questions[index];
                          final qCats = widget.categories
                              .where((c) => q.categoryIds.contains(c.id))
                              .map((c) => c.name)
                              .join(', ');
                          return Card(
                            margin: EdgeInsets.zero,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.grey.withOpacity(0.1),
                              ),
                            ),
                            child: Center(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                title: Text(
                                  q.text,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الإجابة: ${q.answer}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'الفئات: $qCats',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blue,
                                        size: 18,
                                      ),
                                      onPressed: () => _showEditQuestionDialog(
                                        context,
                                        ref,
                                        widget.categories,
                                        q,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      onPressed: () => ref
                                          .read(
                                            questionsProvider(null).notifier,
                                          )
                                          .deleteQuestion(q.id!),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('خطأ: $err')),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TFButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TFButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color.withOpacity(0.5) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _GridBuilder extends StatelessWidget {
  final List<String> rows;
  final List<String> cols;
  final List<List<int>> selectedCells;
  final Function(int, int) onCellTap;

  const _GridBuilder({
    required this.rows,
    required this.cols,
    required this.selectedCells,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const FixedColumnWidth(80),
          border: TableBorder.symmetric(
            inside: BorderSide(color: Colors.grey.shade200),
          ),
          children: [
            // Header Row
            TableRow(
              children: [
                const SizedBox(), // Spacer for row names
                ...cols.map(
                  (name) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Data Rows
            ...List.generate(
              rows.length,
              (r) => TableRow(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        rows[r],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  ...List.generate(
                    cols.length,
                    (c) => InkWell(
                      onTap: () => onCellTap(r, c),
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              selectedCells.any(
                                (cell) => cell[0] == r && cell[1] == c,
                              )
                              ? Colors.blue.withOpacity(0.2)
                              : null,
                          border: Border.all(
                            color:
                                selectedCells.any(
                                  (cell) => cell[0] == r && cell[1] == c,
                                )
                                ? Colors.blue
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          selectedCells.any(
                                (cell) => cell[0] == r && cell[1] == c,
                              )
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 20,
                          color:
                              selectedCells.any(
                                (cell) => cell[0] == r && cell[1] == c,
                              )
                              ? Colors.blue
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showAddQuestionDialog(
  BuildContext context,
  WidgetRef ref,
  List<Category> categories, {
  int? initialCatId,
}) {
  _showQuestionEditorDialog(
    context,
    ref,
    categories,
    initialCatId: initialCatId,
  );
}

void _showEditQuestionDialog(
  BuildContext context,
  WidgetRef ref,
  List<Category> categories,
  Question question,
) {
  _showQuestionEditorDialog(context, ref, categories, question: question);
}

void _showQuestionEditorDialog(
  BuildContext context,
  WidgetRef ref,
  List<Category> categories, {
  int? initialCatId,
  Question? question,
}) {
  final isEditing = question != null;
  final qController = TextEditingController(text: question?.text ?? '');
  final aController = TextEditingController(text: question?.answer ?? '');

  QuestionType selectedType = question?.type ?? QuestionType.essay;
  String? imagePath = question?.imagePath;
  Uint8List? imageData = question?.imageData;
  List<int> selectedCatIds =
      question?.categoryIds ?? (initialCatId != null ? [initialCatId] : []);

  // MCQ Data
  List<TextEditingController> optionControllers =
      (question?.options ?? ['', ''])
          .map((opt) => TextEditingController(text: opt))
          .toList();
  List<int> correctOptionIndices = List.from(
    question?.correctOptionIndices ?? [0],
  );

  // True/False Data
  bool tfValue = question?.tfValue ?? true;

  // Grid Data
  int gridRows = (question?.gridData?['rows'] as List?)?.length ?? 2;
  int gridCols = (question?.gridData?['cols'] as List?)?.length ?? 2;
  List<String> rowNames =
      (question?.gridData?['rows'] as List?)?.cast<String>() ??
      List.generate(2, (i) => '${i + 1}');
  List<String> colNames =
      (question?.gridData?['cols'] as List?)?.cast<String>() ??
      List.generate(2, (i) => '${i + 1}');
  List<List<int>> gridCorrect =
      (question?.gridData?['correctCells'] as List?)
          ?.map((cell) => List<int>.from(cell))
          .toList() ??
      [];
  bool isMultiple = question?.isMultiple ?? false;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(isEditing ? 'تعديل السؤال' : 'إضافة سؤال جديد'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Type Selector
                  DropdownButtonFormField<QuestionType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'نوع السؤال'),
                    items: const [
                      DropdownMenuItem(
                        value: QuestionType.essay,
                        child: Text('مقالي'),
                      ),
                      DropdownMenuItem(
                        value: QuestionType.multipleChoice,
                        child: Text('اختيار من متعدد'),
                      ),
                      DropdownMenuItem(
                        value: QuestionType.trueFalse,
                        child: Text('صح وخطأ'),
                      ),
                      DropdownMenuItem(
                        value: QuestionType.grid,
                        child: Text('سؤال شبكي'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Image Picker
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                          );
                          if (result != null) {
                            final path = result.files.single.path;
                            if (path != null) {
                              final bytes = await File(path).readAsBytes();
                              setState(() {
                                imagePath = path;
                                imageData = bytes;
                              });
                            }
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: const Text('إرفاق صورة'),
                      ),
                      if (imagePath != null || imageData != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            imagePath?.split(Platform.pathSeparator).last ??
                                'صورة مخزنة',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() {
                            imagePath = null;
                            imageData = null;
                          }),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: qController,
                    decoration: const InputDecoration(labelText: 'السؤال'),
                  ),
                  const SizedBox(height: 10),

                  // Type Specific Content
                  if (selectedType == QuestionType.multipleChoice ||
                      selectedType == QuestionType.grid)
                    SwitchListTile(
                      title: const Text('اختيارات متعددة؟'),
                      subtitle: Text(
                        isMultiple
                            ? 'يمكن اختيار أكثر من إجابة'
                            : 'اختيار إجابة واحدة فقط',
                      ),
                      value: isMultiple,
                      onChanged: (val) => setState(() => isMultiple = val),
                    ),
                  const Divider(),

                  if (selectedType == QuestionType.essay) ...[
                    TextField(
                      controller: aController,
                      decoration: const InputDecoration(
                        labelText: 'الإجابة النموذجية',
                      ),
                    ),
                  ] else if (selectedType == QuestionType.multipleChoice) ...[
                    const Text(
                      'الاختيارات (حدد الصحيح منها):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...List.generate(
                      optionControllers.length,
                      (index) => Row(
                        children: [
                          Checkbox(
                            value: correctOptionIndices.contains(index),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  if (!isMultiple)
                                    correctOptionIndices
                                        .clear(); // Clear if single selection
                                  correctOptionIndices.add(index);
                                } else {
                                  correctOptionIndices.remove(index);
                                }
                              });
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: optionControllers[index],
                              decoration: InputDecoration(
                                hintText: 'الاختيار ${index + 1}',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: optionControllers.length > 2
                                ? () => setState(() {
                                    optionControllers.removeAt(index);
                                    correctOptionIndices.remove(index);
                                    // Updates indices of remaining
                                    correctOptionIndices = correctOptionIndices
                                        .map((i) => i > index ? i - 1 : i)
                                        .toList();
                                  })
                                : null,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(
                        () => optionControllers.add(TextEditingController()),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة اختيار'),
                    ),
                  ] else if (selectedType == QuestionType.trueFalse) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TFButton(
                          label: 'صح',
                          selected: tfValue == true,
                          color: Colors.green,
                          onTap: () => setState(() => tfValue = true),
                        ),
                        const SizedBox(width: 20),
                        _TFButton(
                          label: 'خطأ',
                          selected: tfValue == false,
                          color: Colors.red,
                          onTap: () => setState(() => tfValue = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: aController,
                      decoration: const InputDecoration(
                        labelText: 'التصويب (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ] else if (selectedType == QuestionType.grid) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'عدد الصفوف',
                            ),
                            keyboardType: TextInputType.number,
                            controller:
                                TextEditingController(text: gridRows.toString())
                                  ..selection = TextSelection.collapsed(
                                    offset: gridRows.toString().length,
                                  ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null && n > 0) {
                                setState(() {
                                  gridRows = n;
                                  if (rowNames.length < n) {
                                    rowNames.addAll(
                                      List.generate(
                                        n - rowNames.length,
                                        (i) => '${rowNames.length + i + 1}',
                                      ),
                                    );
                                  } else {
                                    rowNames = rowNames.sublist(0, n);
                                  }
                                  gridCorrect.removeWhere(
                                    (cell) => cell[0] >= n,
                                  ); // Remove out-of-bounds cells
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'عدد الأعمدة',
                            ),
                            keyboardType: TextInputType.number,
                            controller:
                                TextEditingController(text: gridCols.toString())
                                  ..selection = TextSelection.collapsed(
                                    offset: gridCols.toString().length,
                                  ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null && n > 0) {
                                setState(() {
                                  gridCols = n;
                                  if (colNames.length < n) {
                                    colNames.addAll(
                                      List.generate(
                                        n - colNames.length,
                                        (i) => '${colNames.length + i + 1}',
                                      ),
                                    );
                                  } else {
                                    colNames = colNames.sublist(0, n);
                                  }
                                  gridCorrect.removeWhere(
                                    (cell) => cell[1] >= n,
                                  ); // Remove out-of-bounds cells
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'أسماء الصفوف:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Wrap(
                      spacing: 8,
                      children: List.generate(
                        gridRows,
                        (i) => SizedBox(
                          width: 80,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'صف ${i + 1}',
                              isDense: true,
                            ),
                            onChanged: (v) => rowNames[i] = v,
                            controller: TextEditingController(text: rowNames[i])
                              ..selection = TextSelection.collapsed(
                                offset: rowNames[i].length,
                              ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'أسماء الأعمدة:',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Wrap(
                      spacing: 8,
                      children: List.generate(
                        gridCols,
                        (i) => SizedBox(
                          width: 80,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'عمود ${i + 1}',
                              isDense: true,
                            ),
                            onChanged: (v) => colNames[i] = v,
                            controller: TextEditingController(text: colNames[i])
                              ..selection = TextSelection.collapsed(
                                offset: colNames[i].length,
                              ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'حدد الخلايا الصحيحة:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _GridBuilder(
                      rows: rowNames,
                      cols: colNames,
                      selectedCells: gridCorrect,
                      onCellTap: (r, c) => setState(() {
                        if (gridCorrect.any(
                          (cell) => cell[0] == r && cell[1] == c,
                        )) {
                          gridCorrect.removeWhere(
                            (cell) => cell[0] == r && cell[1] == c,
                          );
                        } else {
                          if (!isMultiple) gridCorrect.clear();
                          gridCorrect.add([r, c]);
                        }
                      }),
                    ),
                  ],

                  const Divider(height: 30),
                  const Text(
                    'الفئات المرتبطة:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...categories.map(
                    (cat) => CheckboxListTile(
                      visualDensity: VisualDensity.compact,
                      title: Text(cat.name),
                      value: selectedCatIds.contains(cat.id),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedCatIds.add(cat.id!);
                          } else if (selectedCatIds.length > 1) {
                            selectedCatIds.remove(cat.id!);
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (qController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('برجى إدخال نص السؤال')),
                  );
                  return;
                }
                if (selectedCatIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى اختيار فئة واحدة على الأقل'),
                    ),
                  );
                  return;
                }

                // Prepare data based on type
                String answer = aController.text;
                List<String>? options;
                List<int>? mcqCorrect;
                bool? tf;
                Map<String, dynamic>? grid;

                if (selectedType == QuestionType.multipleChoice) {
                  options = optionControllers.map((c) => c.text).toList();
                  mcqCorrect = correctOptionIndices;
                  answer = mcqCorrect.map((i) => options![i]).join('، ');
                } else if (selectedType == QuestionType.trueFalse) {
                  tf = tfValue;
                } else if (selectedType == QuestionType.grid) {
                  grid = {
                    'rows': rowNames,
                    'cols': colNames,
                    'correctCells': gridCorrect,
                  };
                  answer = 'سؤال شبكي';
                }

                final newQuestion = Question(
                  id: question?.id,
                  text: qController.text,
                  answer: answer,
                  type: selectedType,
                  isMultiple: isMultiple,
                  imagePath: imagePath,
                  imageData: imageData,
                  categoryIds: selectedCatIds,
                  options: options,
                  correctOptionIndices: mcqCorrect,
                  tfValue: tf,
                  gridData: grid,
                  usedInCategoryIds: question?.usedInCategoryIds ?? [],
                );

                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  if (isEditing) {
                    await ref
                        .read(questionsProvider(null).notifier)
                        .updateQuestion(newQuestion);
                  } else {
                    await ref
                        .read(questionsProvider(null).notifier)
                        .addQuestion(newQuestion);
                  }
                  if (context.mounted) {
                    Navigator.pop(context); // Pop loading
                    Navigator.pop(context); // Pop editor
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Pop loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'حفظ' : 'إضافة'),
            ),
          ],
        );
      },
    ),
  );
}
