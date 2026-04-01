import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/question_providers.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/category.dart';
import 'package:games/core/design/app_design.dart';
import 'package:games/core/design/themed_background.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class QuestionsManagementPage extends ConsumerWidget {
  const QuestionsManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSmall = AppDesign.isSmallScreen(context);

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('إدارة الأسئلة والفئات', style: AppDesign.titleStyle.copyWith(fontSize: isSmall ? 18 : 24)),
          centerTitle: true,
          actions: [
             // Move total count to appbar on small screens to save space
             if (isSmall) 
               Consumer(builder: (context, ref, child) {
                  final questionsAsync = ref.watch(questionsProvider(null));
                  final count = questionsAsync.value?.length ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  );
               }),
          ],
        ),
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 24, vertical: isSmall ? 6 : 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: const TabBar(
                  indicator: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: 'الأنواع / المجموعات'),
                    Tab(text: 'الأسئلة'),
                  ],
                ),
              ),
               if (!isSmall)
                 Consumer(
                   builder: (context, ref, child) {
                     final questionsAsync = ref.watch(questionsProvider(null));
                     final count = questionsAsync.value?.length ?? 0;
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 12),
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         decoration: BoxDecoration(
                           color: Colors.amber.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(10),
                           border: Border.all(color: Colors.amber.withOpacity(0.2)),
                         ),
                         child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             const Icon(Icons.analytics_outlined, color: Colors.amber, size: 20),
                             const SizedBox(width: 10),
                             Text(
                               'إجمالي الأسئلة بكل الفئات: ',
                               style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                             ),
                             Text(
                               '$count',
                               style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 18),
                             ),
                           ],
                         ),
                       ),
                     );
                   },
                 ),
              Expanded(
                child: TabBarView(
                  children: [
                    _CategoriesList(),
                    _QuestionsList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesList extends ConsumerStatefulWidget {
  const _CategoriesList();
  @override
  ConsumerState<_CategoriesList> createState() => _CategoriesListState();
}

class _CategoriesListState extends ConsumerState<_CategoriesList> {
  bool selectionMode = false;
  final Set<int> selectedIds = {};
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final isSmall = AppDesign.isSmallScreen(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    final allCategories = categoriesAsync.value ?? [];
    final filteredCategories = allCategories.where((c) => c.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Search and Bulk Action Bar for Categories
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => searchQuery = val),
                    style: TextStyle(color: Colors.white, fontSize: isSmall ? 14 : 16),
                    decoration: AppDesign.searchInputDecoration(isSmall ? 'بحث...' : 'بحث في الفئات...').copyWith(
                      prefixIcon: Icon(Icons.search, color: Colors.white38, size: isSmall ? 18 : 24),
                      contentPadding: EdgeInsets.symmetric(vertical: isSmall ? 8 : 12, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (selectionMode) ...[
                  IconButton(
                    tooltip: 'اختيار الكل',
                    icon: Icon(
                      selectedIds.length == filteredCategories.length && filteredCategories.isNotEmpty
                          ? Icons.deselect
                          : Icons.select_all,
                      color: Colors.amber,
                    ),
                    onPressed: filteredCategories.isEmpty ? null : () {
                      setState(() {
                        if (selectedIds.length == filteredCategories.length) {
                          selectedIds.clear();
                        } else {
                          selectedIds.addAll(filteredCategories.map((c) => c.id!));
                        }
                      });
                    },
                  ),
                  IconButton(
                    tooltip: 'حذف المختار',
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                    onPressed: selectedIds.isEmpty ? null : () => _confirmBulkDelete(),
                  ),
                  IconButton(
                    tooltip: 'إغلاق',
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => setState(() { selectionMode = false; selectedIds.clear(); }),
                  ),
                ] else
                   IconButton(
                    tooltip: 'تفعيل الاختيار المتعدد',
                    icon: const Icon(Icons.checklist, color: Colors.amber),
                    onPressed: () => setState(() => selectionMode = true),
                  ),
              ],
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              data: (_) {
                final categories = filteredCategories;
                
                if (categories.isEmpty) return const Center(child: Text('لا توجد فئات مطابقة', style: TextStyle(color: Colors.white38)));
                
                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSmall = AppDesign.isSmallScreen(context);
                    final isSelected = selectedIds.contains(category.id);

                    return InkWell(
                      onLongPress: () => setState(() { selectionMode = true; selectedIds.add(category.id!); }),
                      onTap: selectionMode ? () => setState(() {
                        if (isSelected) selectedIds.remove(category.id); else selectedIds.add(category.id!);
                      }) : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: isSelected ? Colors.amber : Colors.white10),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20, vertical: 8),
                          leading: selectionMode ? Checkbox(
                            value: isSelected, 
                            activeColor: Colors.amber,
                            onChanged: (v) => setState(() { if (v!) selectedIds.add(category.id!); else selectedIds.remove(category.id!); })
                          ) : null,
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.name, 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 16 : 18, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                ),
                                child: Text(
                                  '${category.questionsCount}', 
                                  style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          trailing: selectionMode ? null : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_outlined, color: Colors.blueAccent, size: isSmall ? 20 : 24),
                                onPressed: () => _showEditCategoryDialog(context, ref, category),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: isSmall ? 20 : 24),
                                onPressed: () => _confirmSingleDelete(category),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
              error: (err, stack) => Center(child: Text('خطأ: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
      floatingActionButton: selectionMode ? null : FloatingActionButton(
        mini: true,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        onPressed: () => _showAddCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmSingleDelete(Category category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppDesign.slate900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف الفئة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف الفئة "${category.name}"؟\nسيتم حذف الأسئلة المرتبطة بها أيضاً.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(categoriesProvider.notifier).deleteCategory(category.id!);
              Navigator.pop(ctx);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _confirmBulkDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppDesign.slate900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('حذف الفئات المختارة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف ${selectedIds.length} فئة؟\nسيتم حذف الأسئلة المرتبطة حصرياً بهذه الفئات أيضاً.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              final notifier = ref.read(categoriesProvider.notifier);
              for (var id in selectedIds) {
                await notifier.deleteCategory(id);
              }
              if (mounted) {
                setState(() { selectionMode = false; selectedIds.clear(); });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف بنجاح'), backgroundColor: Colors.redAccent));
              }
            },
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
  }
}

void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();
  _showCategoryDialog(context, ref, 'إضافة نوع جديد', controller, () {
    if (controller.text.isNotEmpty) {
      ref.read(categoriesProvider.notifier).addCategory(controller.text);
      Navigator.pop(context);
    }
  });
}

void _showEditCategoryDialog(BuildContext context, WidgetRef ref, Category category) {
  final controller = TextEditingController(text: category.name);
  _showCategoryDialog(context, ref, 'تعديل النوع', controller, () {
    if (controller.text.isNotEmpty) {
      ref.read(categoriesProvider.notifier).updateCategory(category.copyWith(name: controller.text));
      Navigator.pop(context);
    }
  });
}

void _showCategoryDialog(BuildContext context, WidgetRef ref, String title, TextEditingController controller, VoidCallback onSave) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'اسم النوع',
          labelStyle: const TextStyle(color: Colors.white60),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.amber)),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
          onPressed: onSave,
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
}

class _QuestionsList extends ConsumerWidget {
  const _QuestionsList();

  Future<void> _saveOrShareFile({
    required BuildContext context,
    required Uint8List bytes,
    required String fileName,
    required String shareTitle,
    bool isPdf = false,
  }) async {
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ الملف',
          fileName: fileName,
        );

        if (outputFile != null) {
          // Ensure file extension
          if (!outputFile.toLowerCase().endsWith(fileName.substring(fileName.lastIndexOf('.')).toLowerCase())) {
             outputFile += fileName.substring(fileName.lastIndexOf('.'));
          }
          final file = File(outputFile);
          await file.writeAsBytes(bytes);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم حفظ الملف بنجاح'), backgroundColor: Colors.green),
            );
          }
        }
      } else {
        if (isPdf) {
          await Printing.sharePdf(bytes: bytes, filename: fileName);
        } else {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(bytes);
          await Share.shareXFiles(
            [XFile(file.path, name: fileName, mimeType: fileName.endsWith('.csv') ? 'text/csv' : null)], 
            text: shareTitle
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ/المشاركة: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportAllCsv(BuildContext context, WidgetRef ref) async {
    try {
      final questions = await ref.read(questionRepositoryProvider).getQuestions(null);
      final categories = await ref.read(questionRepositoryProvider).getCategories();
      final catMap = {for (var c in categories) c.id: c.name};

      final List<List<dynamic>> rows = [
        ['Text', 'Answer', 'Categories', 'Type', 'Options', 'CorrectIndices', 'TFValue', 'IsMultiple', 'GridRows', 'GridCols', 'GridCorrectCells']
      ];

      for (var q in questions) {
        final catNames = q.categoryIds.map((id) => catMap[id] ?? '').join(';');
        
        List<dynamic> row = [
          q.text,
          q.answer,
          catNames,
          q.type.name,
          q.options?.join('|') ?? '',
          q.correctOptionIndices?.join(',') ?? '',
          q.tfValue?.toString() ?? '',
          q.isMultiple,
          (q.gridData?['rows'] as List?)?.join('|') ?? '',
          (q.gridData?['cols'] as List?)?.join('|') ?? '',
          (q.gridData?['correctCells'] as List?)?.map((c) => "${c[0]},${c[1]}").join(';') ?? '',
        ];
        rows.add(row);
      }

      final csvString = const ListToCsvConverter().convert(rows);
      final bytes = Uint8List.fromList(utf8.encode('\uFEFF$csvString'));
      
      if (context.mounted) {
        await _saveOrShareFile(
          context: context, 
          bytes: bytes, 
          fileName: 'all_questions.csv', 
          shareTitle: 'كل الأسئلة الحالية'
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ التصدير: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _exportAllPdf(BuildContext context, WidgetRef ref) async {
    try {
      final questions = await ref.read(questionRepositoryProvider).getQuestions(null);
      final categories = await ref.read(questionRepositoryProvider).getCategories();
      final catMap = {for (var c in categories) c.id: c.name};

      final pdf = pw.Document();
      // Load fonts from assets for offline support as requested by USER
      final regularFontData = await rootBundle.load("assets/fonts/Amiri-Regular.ttf");
      final boldFontData = await rootBundle.load("assets/fonts/Amiri-Bold.ttf");
      
      final font = pw.Font.ttf(regularFontData);
      final boldFont = pw.Font.ttf(boldFontData);

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (context) => [
            pw.Header(
              level: 0, 
              child: pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('قائمة الأسئلة والفئات', textDirection: pw.TextDirection.rtl)
              )
            ),
            pw.SizedBox(height: 20),
            ...questions.map((q) {
              final qCats = q.categoryIds.map((id) => catMap[id] ?? '').join('، ');
              return pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Container(
                  // Set a reasonable width for the cards so they don't always stretch but take their content or a portion of the page
                  width: 400, 
                  margin: const pw.EdgeInsets.only(bottom: 15),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('السؤال: ${q.text}', textDirection: pw.TextDirection.rtl, style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                      pw.Text('الإجابة: ${q.answer}', textDirection: pw.TextDirection.rtl, style: const pw.TextStyle(color: PdfColors.green), textAlign: pw.TextAlign.right),
                      pw.Text('الفئات: $qCats', textDirection: pw.TextDirection.rtl, style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10), textAlign: pw.TextAlign.right),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );

      final bytes = await pdf.save();
      
      if (context.mounted) {
        await _saveOrShareFile(
          context: context, 
          bytes: bytes, 
          fileName: 'questions.pdf', 
          shareTitle: 'قائمة الأسئلة',
          isPdf: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ PDF: $e\nتأكد من وجود ملفات الخطوط في assets/fonts/'), backgroundColor: Colors.red));
      }
    }
  }

  void _confirmDeleteEverything(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppDesign.slate900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('حذف جميع البيانات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'هل أنت متأكد من حذف جميع الأسئلة والفئات بشكل نهائي؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(color: Colors.white70)
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(categoriesProvider.notifier).deleteAllCategories();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف جميع البيانات بنجاح'), backgroundColor: Colors.redAccent)
                );
              }
            },
            child: const Text('حذف كل شيء'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveDuplicates(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppDesign.slate900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف الأسئلة المكررة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('سيتم البحث عن جميع الأسئلة التي لها نفس النص (تطابق تام) وحذف النسخ الإضافية، مع الإبقاء على نسخة واحدة فقط.', style: TextStyle(color: Colors.white70)),
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
                    content: Text(count > 0 ? 'تم حذف $count سؤال مكرراً بنجاح' : 'لا توجد أسئلة مكررة حالياً'), 
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

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(questionRepositoryProvider);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true);
      if (result == null || (result.files.single.path == null && result.files.single.bytes == null)) return;
      
      late String input;
      if (result.files.single.bytes != null) {
        input = utf8.decode(result.files.single.bytes!, allowMalformed: true);
      } else {
        final file = File(result.files.single.path!);
        input = await file.readAsString();
      }
      
      List<List<dynamic>> fields;
      try {
          fields = const CsvToListConverter().convert(input);
        
        // Auto-detect semicolon if comma fails to find columns
        if (fields.isNotEmpty && fields[0].length < 3) {
           final altFields = const CsvToListConverter(fieldDelimiter: ';').convert(input);
           if (altFields.isNotEmpty && altFields[0].length >= 3) {
             fields = altFields;
           }
        }
      } catch (e) {
        throw 'تنسيق الملف غير صحيح: $e';
      }

      if (fields.isEmpty) throw 'الملف فارغ';
      
      final rows = fields.skip(1).toList();
      final total = rows.length;
      if (total == 0) throw 'لا توجد بيانات أسئلة بعد السطر الأول';

      int count = 0;
      final currentCats = await repo.getCategories();
      final catMap = {for (var c in currentCats) c.name: c.id!};

      // Show Progress Dialog
      final progressController = StreamController<int>();
      _showImportProgress(context, total, progressController.stream);

      try {
        final existingQuestions = await repo.getQuestions(null);
        final existingTexts = existingQuestions.map((q) => q.text.trim().toLowerCase()).toSet();

        for (var row in rows) {
          if (row.length < 3) continue;
          final qText = _get(row, 0);
          if (qText.isEmpty) continue;
          
          // Skip if question text already exists (case-insensitive, trimmed)
          if (existingTexts.contains(qText.trim().toLowerCase())) {
            progressController.add(++count);
            continue; 
          }
          
          final aText = _get(row, 1);
          final catString = _get(row, 2).toString();
          final typeStr = _get(row, 3).toLowerCase();
          QuestionType type = QuestionType.essay;
          if (typeStr.contains('اختيار') || typeStr.contains('mcq')) type = QuestionType.multipleChoice;
          if (typeStr.contains('صح') || typeStr.contains('tf')) type = QuestionType.trueFalse;
          if (typeStr.contains('شبكي') || typeStr.contains('grid')) type = QuestionType.grid;

          List<int> catIds = [];
          final catNames = catString.split(RegExp(r'[,;]')).map((e) => e.trim()).where((e) => e.isNotEmpty);
          for (var name in catNames) {
            int? cid = catMap[name];
            if (cid == null) { 
              cid = await repo.addCategory(name); 
              catMap[name] = cid; 
            }
            catIds.add(cid);
          }

          final optionsStr = _get(row, 4);
          List<String>? options = optionsStr.isNotEmpty ? optionsStr.split('|').map((e) => e.trim()).toList() : null;
          final indicesStr = _get(row, 5);
          List<int>? correctIndices = indicesStr.isNotEmpty ? indicesStr.split(',').map((e) => int.tryParse(e.trim()) ?? 0).toList() : null;
          final tfStr = _get(row, 6).toLowerCase();
          bool? tfValue = tfStr.isEmpty ? null : (tfStr.startsWith('t') || tfStr.contains('صح'));
          final multipleStr = _get(row, 7).toLowerCase();
          bool isMultiple = multipleStr.startsWith('t') || multipleStr.contains('صح') || multipleStr.contains('نعم');

          Map<String, dynamic>? gridData;
          if (type == QuestionType.grid) {
            final rowNames = _get(row, 8).split('|').map((e) => e.trim()).toList();
            final colNames = _get(row, 9).split('|').map((e) => e.trim()).toList();
            final cellsStr = _get(row, 10);
            final correctCells = cellsStr.isNotEmpty ? cellsStr.split(';').map((s) {
              final parts = s.split(',');
              if (parts.length < 2) return [0, 0];
              return [int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0];
            }).toList() : <List<int>>[];
            gridData = {'rows': rowNames.isEmpty ? ['1','2'] : rowNames, 'cols': colNames.isEmpty ? ['1','2'] : colNames, 'correctCells': correctCells};
          }

          await repo.addQuestion(Question(text:qText, answer:aText, type:type, categoryIds:catIds, options:options, correctOptionIndices:correctIndices, tfValue:tfValue, isMultiple:isMultiple, gridData:gridData));
          count++;
          progressController.add(count);
          
          if (count % 20 == 0) await Future.delayed(const Duration(milliseconds: 1));
        }
      } finally {
        progressController.close();
        if (context.mounted) Navigator.pop(context); // Close dialog
      }

      ref.invalidate(categoriesProvider); ref.invalidate(questionsProvider(null));
      if (context.mounted) {
        String msg = 'تم استيراد $count سؤال بنجاح';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الاستيراد: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showImportProgress(BuildContext context, int total, Stream<int> progressStream) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.upload_file, color: Colors.amber),
              SizedBox(width: 10),
              Text('جاري الاستيراد...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: StreamBuilder<int>(
            stream: progressStream,
            builder: (context, snapshot) {
              final current = snapshot.data ?? 0;
              final percent = total > 0 ? (current / total) : 0.0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: percent, 
                    backgroundColor: Colors.white10, 
                    color: Colors.amber,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$current من $total سؤال', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      Text('${(percent * 100).toInt()}%', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              );
            }
          ),
        ),
      ),
    );
  }

  Future<void> _downloadTemplate(BuildContext context) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Text,Answer,Categories,Type,Options,CorrectIndices,TFValue,IsMultiple,GridRows,GridCols,GridCorrectCells');
      buffer.writeln('ما عاصمة مصر؟,القاهرة,معلومات عامة,مقالي,,,,,,,');
      
      final bytes = Uint8List.fromList(utf8.encode('\uFEFF$buffer'));
      
      await _saveOrShareFile(
        context: context, 
        bytes: bytes, 
        fileName: 'questions_template.csv', 
        shareTitle: 'نموذج الأسئلة'
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في القالب: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _get(List<dynamic> row, int index) { if (index >= row.length) return ''; return row[index]?.toString().trim() ?? ''; }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isSmall = AppDesign.isSmallScreen(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24.0, vertical: isSmall ? 8 : 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildActionButton(
                    context, 
                    isSmall ? 'استيراد' : 'استيراد CSV', 
                    Icons.cloud_upload_outlined, 
                    Colors.greenAccent, 
                    () => _importCsv(context, ref)
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton(
                    context, 
                    isSmall ? 'تصدير' : 'تصدير كل الأسئلة (CSV)', 
                    Icons.download_rounded, 
                    Colors.blueAccent, 
                    () => _exportAllCsv(context, ref)
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton(
                    context, 
                    isSmall ? 'PDF' : 'تصدير PDF', 
                    Icons.picture_as_pdf_outlined, 
                    Colors.purpleAccent, 
                    () => _exportAllPdf(context, ref)
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton(
                    context, 
                    isSmall ? 'مكرر' : 'حذف المكرر', 
                    Icons.cleaning_services_rounded, 
                    Colors.orangeAccent, 
                    () => _confirmRemoveDuplicates(context, ref)
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton(
                    context, 
                    isSmall ? 'حذف الكل' : 'حذف كل البيانات', 
                    Icons.delete_forever_rounded, 
                    Colors.redAccent, 
                    () => _confirmDeleteEverything(context, ref)
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () => _downloadTemplate(context),
                    icon: const Icon(Icons.help_outline, color: Colors.white60, size: 16),
                    label: Text(isSmall ? 'نموذج' : 'تحميل نموذج فارغ', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                // Show questions even if categories are empty to allow managing orphaned questions
                return Stack(
                  children: [
                    _QuestionsBySelectedCategory(categories: categories),
                    Positioned(
                      bottom: 24,
                      left: 24,
                      child: FloatingActionButton(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        onPressed: () => _showAddQuestionDialog(context, ref, categories, initialCatId: categories.isNotEmpty ? categories.first.id : null),
                        child: const Icon(Icons.add, size: 30),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
              error: (err, stack) => Center(child: Text('خطأ: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _QuestionsBySelectedCategory extends ConsumerStatefulWidget {
  final List<Category> categories;
  const _QuestionsBySelectedCategory({required this.categories});

  @override
  ConsumerState<_QuestionsBySelectedCategory> createState() => _QuestionsBySelectedCategoryState();
}

class _QuestionsBySelectedCategoryState extends ConsumerState<_QuestionsBySelectedCategory> {
  final List<int> selectedCategoryIds = [];
  bool selectAll = true;
  bool showUncategorized = false;
  String searchQuery = "";
  bool selectionMode = false;
  final Set<int> multiSelectedIds = {};

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsProvider(null));
    final allQuestions = questionsAsync.value ?? [];
    final filteredQuestions = allQuestions.where((q) {
      final validCategoryIds = widget.categories.map((c) => c.id).toSet();
      final hasValidCategory = q.categoryIds.any((id) => validCategoryIds.contains(id));
      
      final matchesCat = selectAll || 
                         q.categoryIds.any((id) => selectedCategoryIds.contains(id)) ||
                         (showUncategorized && !hasValidCategory);
                         
      final matchesSearch = q.text.toLowerCase().contains(searchQuery.toLowerCase()) || 
                          q.answer.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    final isSmall = AppDesign.isSmallScreen(context);

    return Column(
      children: [
        // Search and Actions Bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24, vertical: isSmall ? 4 : 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => searchQuery = val),
                  style: TextStyle(color: Colors.white, fontSize: isSmall ? 14 : 16),
                  decoration: AppDesign.searchInputDecoration(isSmall ? 'بحث...' : 'بحث في الأسئلة...').copyWith(
                    prefixIcon: Icon(Icons.search, color: Colors.white38, size: isSmall ? 18 : 24),
                    contentPadding: EdgeInsets.symmetric(vertical: isSmall ? 8 : 12, horizontal: 16),
                  ),
                ),
              ),
              SizedBox(width: isSmall ? 8 : 12),
              if (selectionMode) ...[
                IconButton(
                  tooltip: 'اختيار الكل',
                  icon: Icon(
                    multiSelectedIds.length == filteredQuestions.length && filteredQuestions.isNotEmpty
                        ? Icons.deselect
                        : Icons.select_all,
                    color: Colors.amber,
                  ),
                  onPressed: filteredQuestions.isEmpty ? null : () {
                    setState(() {
                      if (multiSelectedIds.length == filteredQuestions.length) {
                        multiSelectedIds.clear();
                      } else {
                        multiSelectedIds.addAll(filteredQuestions.map((q) => q.id!));
                      }
                    });
                  },
                ),
                IconButton(
                  tooltip: 'حذف المختار',
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                  onPressed: multiSelectedIds.isEmpty ? null : () => _confirmBulkDelete(),
                ),
                IconButton(
                  tooltip: 'إغلاق',
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => setState(() { selectionMode = false; multiSelectedIds.clear(); }),
                ),
              ] else
                IconButton(
                  tooltip: 'تفعيل الاختيار المتعدد',
                  icon: const Icon(Icons.checklist, color: Colors.amber),
                  onPressed: () => setState(() => selectionMode = true),
                ),
            ],
          ),
        ),

        // Category Filter
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('الكل', style: TextStyle(fontSize: 12)),
                  selected: selectAll,
                  selectedColor: Colors.amber.withOpacity(0.4),
                  padding: isSmall ? EdgeInsets.zero : null,
                  onSelected: (val) => setState(() { 
                    selectAll = true; 
                    selectedCategoryIds.clear(); 
                    showUncategorized = false; 
                  }),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('بدون فئة', style: TextStyle(fontSize: 12, color: Colors.orangeAccent)),
                  selected: !selectAll && showUncategorized,
                  selectedColor: Colors.orangeAccent.withOpacity(0.4),
                  padding: isSmall ? EdgeInsets.zero : null,
                  onSelected: (val) => setState(() {
                    if (val) {
                      selectAll = false;
                      showUncategorized = true;
                    } else {
                      showUncategorized = false;
                      if (selectedCategoryIds.isEmpty) selectAll = true;
                    }
                  }),
                ),
                const SizedBox(width: 8),
                ...widget.categories.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(c.name, style: const TextStyle(fontSize: 12)),
                    selected: !selectAll && selectedCategoryIds.contains(c.id),
                    selectedColor: Colors.blueAccent.withOpacity(0.4),
                    padding: isSmall ? EdgeInsets.zero : null,
                    onSelected: (val) => setState(() {
                      if (val) { selectAll = false; selectedCategoryIds.add(c.id!); }
                      else { selectedCategoryIds.remove(c.id); if (selectedCategoryIds.isEmpty) selectAll = true; }
                    }),
                  ),
                )),
              ],
            ),
          ),
        ),
        Expanded(
          child: questionsAsync.when(
            data: (_) {
              final questions = filteredQuestions;

              final isSmall = AppDesign.isSmallScreen(context);
              return GridView.builder(
                padding: EdgeInsets.all(isSmall ? 12 : 24).copyWith(bottom: 100),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 500, 
                  mainAxisExtent: isSmall ? null : 110, 
                  crossAxisSpacing: 16, 
                  mainAxisSpacing: 12
                ),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final isSelected = multiSelectedIds.contains(q.id);
                  final qCats = widget.categories.where((c) => q.categoryIds.contains(c.id)).map((c) => c.name).join('، ');
                  return InkWell(
                    onLongPress: () => setState(() { selectionMode = true; multiSelectedIds.add(q.id!); }),
                    onTap: selectionMode ? () => setState(() { 
                      if (isSelected) multiSelectedIds.remove(q.id); else multiSelectedIds.add(q.id!); 
                    }) : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.amber.withOpacity(0.2) : Colors.white.withOpacity(0.05), 
                        borderRadius: BorderRadius.circular(15), 
                        border: Border.all(color: isSelected ? Colors.amber : Colors.white10)
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 16, vertical: 8),
                        leading: selectionMode 
                          ? Checkbox(
                              value: isSelected, 
                              activeColor: Colors.amber,
                              onChanged: (v) => setState(() { if (v!) multiSelectedIds.add(q.id!); else multiSelectedIds.remove(q.id!); })
                            )
                          : (q.imageData != null 
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(q.imageData!, width: isSmall ? 40 : 50, height: isSmall ? 40 : 50, fit: BoxFit.cover),
                              )
                            : Container(
                                width: isSmall ? 40 : 50, height: isSmall ? 40 : 50, 
                                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.text_fields_rounded, color: Colors.white24, size: isSmall ? 20 : 24),
                              )),
                        title: Text(q.text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 14 : 16, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('ج: ${q.answer}', style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (!isSmall) Text(qCats, style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        trailing: selectionMode 
                          ? null 
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: Icon(Icons.edit_outlined, color: Colors.blueAccent, size: isSmall ? 18 : 20), onPressed: () => _showEditQuestionDialog(context, ref, widget.categories, q)),
                                IconButton(icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: isSmall ? 18 : 20), onPressed: () => ref.read(questionsProvider(null).notifier).deleteQuestion(q.id!)),
                              ],
                            ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, s) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  void _confirmBulkDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppDesign.slate900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف المتعدد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف ${multiSelectedIds.length} سؤال؟', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final notifier = ref.read(questionsProvider(null).notifier);
              final idsToDelete = List<int>.from(multiSelectedIds);
              for (var id in idsToDelete) {
                await notifier.deleteQuestion(id);
              }
              if (mounted) {
                setState(() {
                  selectionMode = false;
                  multiSelectedIds.clear();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حذف ${idsToDelete.length} سؤال بنجاح'), backgroundColor: Colors.redAccent)
                );
              }
            },
            child: const Text('حذف الكل المختار'),
          ),
        ],
      ),
    );
  }
}

class _TFButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TFButton({required this.label, required this.selected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    bool isSmall = AppDesign.isSmallScreen(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: isSmall ? 24 : 40),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.3) : Colors.white.withOpacity(0.05), 
          borderRadius: BorderRadius.circular(15), 
          border: Border.all(color: selected ? color : Colors.white10, width: 2)
        ),
        child: Text(
          label, 
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70, 
            fontWeight: FontWeight.bold, 
            fontSize: isSmall ? 16 : 20
          )
        ),
      ),
    );
  }
}

class _GridBuilder extends StatelessWidget {
  final List<String> rows; final List<String> cols; final List<List<int>> selectedCells; final Function(int, int) onCellTap;
  const _GridBuilder({required this.rows, required this.cols, required this.selectedCells, required this.onCellTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const FixedColumnWidth(100),
          children: [
            TableRow(children: [const SizedBox(), ...cols.map((name) => Center(child: Padding(padding: const EdgeInsets.all(8), child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amberAccent)))))]),
            ...List.generate(rows.length, (r) => TableRow(children: [
              Center(child: Padding(padding: const EdgeInsets.all(8), child: Text(rows[r], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)))),
              ...List.generate(cols.length, (c) => InkWell(
                onTap: () => onCellTap(r, c),
                child: Container(
                  height: 45, margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: selectedCells.any((cell) => cell[0] == r && cell[1] == c) ? Colors.blueAccent.withOpacity(0.2) : Colors.white.withOpacity(0.03),
                    border: Border.all(color: selectedCells.any((cell) => cell[0] == r && cell[1] == c) ? Colors.blueAccent : Colors.white12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(selectedCells.any((cell) => cell[0] == r && cell[1] == c) ? Icons.check_circle : Icons.circle_outlined, size: 24, color: selectedCells.any((cell) => cell[0] == r && cell[1] == c) ? Colors.blueAccent : Colors.white24),
                ),
              )),
            ])),
          ],
        ),
      ),
    );
  }
}

void _showAddQuestionDialog(BuildContext context, WidgetRef ref, List<Category> categories, {int? initialCatId}) => _showQuestionEditorDialog(context, ref, categories, initialCatId: initialCatId);
void _showEditQuestionDialog(BuildContext context, WidgetRef ref, List<Category> categories, Question question) => _showQuestionEditorDialog(context, ref, categories, question: question);

void _showQuestionEditorDialog(BuildContext context, WidgetRef ref, List<Category> categories, {int? initialCatId, Question? question}) {
  final isEditing = question != null;
  final qController = TextEditingController(text: question?.text ?? '');
  final aController = TextEditingController(text: question?.answer ?? '');
  QuestionType selectedType = question?.type ?? QuestionType.essay;
  String? imagePath = question?.imagePath; Uint8List? imageData = question?.imageData;
  List<int> selectedCatIds = question?.categoryIds ?? (initialCatId != null ? [initialCatId] : []);
  List<TextEditingController> optionControllers = (question?.options ?? ['', '']).map((opt) => TextEditingController(text: opt)).toList();
  List<int> correctOptionIndices = List.from(question?.correctOptionIndices ?? [0]);
  bool tfValue = question?.tfValue ?? true;
  int gridRows = (question?.gridData?['rows'] as List?)?.length ?? 2;
  int gridCols = (question?.gridData?['cols'] as List?)?.length ?? 2;
  List<String> rowNames = (question?.gridData?['rows'] as List?)?.cast<String>() ?? List.generate(2, (i) => '${i + 1}');
  List<String> colNames = (question?.gridData?['cols'] as List?)?.cast<String>() ?? List.generate(2, (i) => '${i + 1}');
  List<List<int>> gridCorrect = (question?.gridData?['correctCells'] as List?)?.map((cell) => List<int>.from(cell)).toList() ?? [];
  bool isMultiple = question?.isMultiple ?? false;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(builder: (context, setState) {
      final isSmallScreen = AppDesign.isSmallScreen(context);
      return AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        insetPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 40, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEditing ? 'تعديل السؤال' : 'إضافة سؤال جديد', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(width: MediaQuery.of(context).size.width * (isSmallScreen ? 0.95 : 0.7), child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<QuestionType>(dropdownColor: const Color(0xFF1E293B), style: const TextStyle(color: Colors.white), value: selectedType, decoration: const InputDecoration(labelText: 'نوع السؤال', labelStyle: TextStyle(color: Colors.white70)), items: const [
            DropdownMenuItem(value: QuestionType.essay, child: Text('مقالي')),
            DropdownMenuItem(value: QuestionType.multipleChoice, child: Text('اختيار من متعدد')),
            DropdownMenuItem(value: QuestionType.trueFalse, child: Text('صح وخطأ')),
            DropdownMenuItem(value: QuestionType.grid, child: Text('سؤال شبكي')),
          ], onChanged: (val) { if (val != null) setState(() => selectedType = val); }),
          const SizedBox(height: 16),
          Row(children: [
            ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.white10), onPressed: () async {
              final result = await FilePicker.platform.pickFiles(type: FileType.image);
              if (result != null && result.files.single.path != null) {
                 final path = result.files.single.path!;
                 final bytes = await File(path).readAsBytes();
                 setState(() { imagePath = path; imageData = bytes; });
              }
            }, icon: const Icon(Icons.image), label: const Text('إرفاق صورة')),
            if (imagePath != null) ...[const SizedBox(width: 8), const Icon(Icons.done, color: Colors.green), IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => setState(() { imagePath = null; imageData = null; }))],
          ]),
          if (imageData != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(imageData!, height: 150, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 16),
          TextField(controller: qController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'نص السؤال', labelStyle: TextStyle(color: Colors.white70))),
          if (selectedType == QuestionType.multipleChoice || selectedType == QuestionType.grid)
            _buildSwitch('اختيارات متعددة؟', isMultiple, (v) => setState(() => isMultiple = v)),
          const Divider(color: Colors.white10, height: 40),
          if (selectedType == QuestionType.essay)
            TextField(controller: aController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'الإجابة الصحيحة', labelStyle: TextStyle(color: Colors.white70)))
          else if (selectedType == QuestionType.multipleChoice) ...[
            const Text('الاختيارات:', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ...List.generate(optionControllers.length, (i) => Row(children: [
              Checkbox(activeColor: Colors.amber, value: correctOptionIndices.contains(i), onChanged: (v) => setState(() { if (v!) { if (!isMultiple) correctOptionIndices.clear(); correctOptionIndices.add(i); } else correctOptionIndices.remove(i); })),
              Expanded(child: TextField(controller: optionControllers[i], style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'الاختيار ${i+1}', hintStyle: const TextStyle(color: Colors.white24)))),
              IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: optionControllers.length > 2 ? () => setState(() { optionControllers.removeAt(i); correctOptionIndices.remove(i); correctOptionIndices = correctOptionIndices.map((idx) => idx > i ? idx - 1 : idx).toList(); }) : null),
            ])),
            TextButton.icon(onPressed: () => setState(() => optionControllers.add(TextEditingController())), icon: const Icon(Icons.add, color: Colors.amber), label: const Text('إضافة اختيار', style: TextStyle(color: Colors.amber))),
          ] else if (selectedType == QuestionType.trueFalse) ...[
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _TFButton(label: 'صح', selected: tfValue == true, color: Colors.green, onTap: () => setState(() => tfValue = true)),
              const SizedBox(width: 20),
              _TFButton(label: 'خطأ', selected: tfValue == false, color: Colors.red, onTap: () => setState(() => tfValue = false)),
            ]),
            const SizedBox(height: 16),
            TextField(controller: aController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'التصويب (اختياري)', labelStyle: TextStyle(color: Colors.white70))),
          ] else if (selectedType == QuestionType.grid) ...[
            Row(children: [
              Expanded(child: TextField(style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'الصفوف'), keyboardType: TextInputType.number, controller: TextEditingController(text: gridRows.toString()), onChanged: (v) {
                final n = int.tryParse(v); if (n != null && n > 0) setState(() { gridRows = n; if (rowNames.length < n) rowNames.addAll(List.generate(n - rowNames.length, (i) => '${rowNames.length + i + 1}')); else rowNames = rowNames.sublist(0, n); gridCorrect.removeWhere((cell) => cell[0] >= n); });
              })),
              const SizedBox(width: 16),
              Expanded(child: TextField(style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'الأعمدة'), keyboardType: TextInputType.number, controller: TextEditingController(text: gridCols.toString()), onChanged: (v) {
                final n = int.tryParse(v); if (n != null && n > 0) setState(() { gridCols = n; if (colNames.length < n) colNames.addAll(List.generate(n - colNames.length, (i) => '${colNames.length + i + 1}')); else colNames = colNames.sublist(0, n); gridCorrect.removeWhere((cell) => cell[1] >= n); });
              })),
            ]),
            const SizedBox(height: 20),
            _GridBuilder(rows: rowNames, cols: colNames, selectedCells: gridCorrect, onCellTap: (r, c) => setState(() {
              if (gridCorrect.any((cell) => cell[0] == r && cell[1] == c)) gridCorrect.removeWhere((cell) => cell[0] == r && cell[1] == c);
              else { if (!isMultiple) gridCorrect.clear(); gridCorrect.add([r, c]); }
            })),
          ],
          const Divider(color: Colors.white10, height: 40),
          const Text('الفئات المرتبطة:', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ...categories.map((cat) => CheckboxListTile(activeColor: Colors.amber, visualDensity: VisualDensity.compact, title: Text(cat.name, style: const TextStyle(color: Colors.white, fontSize: 13)), value: selectedCatIds.contains(cat.id), onChanged: (v) {
            setState(() { if (v == true) selectedCatIds.add(cat.id!); else selectedCatIds.remove(cat.id!); });
          })),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black), onPressed: () async {
            if (qController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال نص السؤال'))); return; }
            String answer = aController.text; List<String>? options; List<int>? mcqCorrect; bool? tf; Map<String, dynamic>? grid;
            if (selectedType == QuestionType.multipleChoice) { options = optionControllers.map((c) => c.text).toList(); mcqCorrect = correctOptionIndices; answer = mcqCorrect.map((i) => options![i]).join('، '); }
            else if (selectedType == QuestionType.trueFalse) tf = tfValue;
            else if (selectedType == QuestionType.grid) { grid = {'rows': rowNames, 'cols': colNames, 'correctCells': gridCorrect}; answer = 'سؤال شبكي'; }
            final newQuestion = Question(id: question?.id, text: qController.text, answer: answer, type: selectedType, isMultiple: isMultiple, imagePath: imagePath, imageData: imageData, categoryIds: selectedCatIds, options: options, correctOptionIndices: mcqCorrect, tfValue: tf, gridData: grid, usedInCategoryIds: question?.usedInCategoryIds ?? []);
            showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
            try {
              if (isEditing) await ref.read(questionsProvider(null).notifier).updateQuestion(newQuestion);
              else await ref.read(questionsProvider(null).notifier).addQuestion(newQuestion);
              if (context.mounted) { Navigator.pop(context); Navigator.pop(context); }
            } catch (e) { if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'))); } }
          }, child: Text(isEditing ? 'حفظ' : 'إضافة')),
        ],
      );
    })
  );
}

Widget _buildSwitch(String label, bool value, Function(bool) onChanged) => SwitchListTile(activeColor: Colors.amber, title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)), value: value, onChanged: onChanged);
