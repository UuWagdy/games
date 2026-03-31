import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/core/database/database_service.dart';
import 'package:games/features/games/bank_al_haz/data/sources/bank_al_haz_default_data.dart';
import '../providers/bank_al_haz_providers.dart';
import '../providers/game_engine_provider.dart';
import '../../domain/entities/bank_al_haz_entities.dart';
import 'template_editor_page.dart';
import 'package:games/core/design/app_design.dart';
import '../../data/sources/bank_al_haz_csv_service.dart';
import '../../../../teams/presentation/providers/team_providers.dart';
import '../../../../questions/presentation/providers/question_providers.dart';
import 'bank_al_haz_board_page.dart';

final databaseServiceProvider = Provider((ref) => DatabaseService.instance);

class TemplatesManagementPage extends ConsumerWidget {
  const TemplatesManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);
    final repository = ref.read(bankAlHazRepositoryProvider);
    final engine = ref.read(gameEngineProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('إدارة القوالب', style: AppDesign.titleStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orangeAccent),
            tooltip: 'إعادة ضبط القالب الديني الأساسي',
            onPressed: () => _confirmResetReligiousTemplate(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'إنشاء قالب جديد',
            onPressed: () => _showCreateTemplateDialog(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTemplateDialog(context, ref),
        label: const Text('قالب جديد'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigoAccent,
      ),
      body: AppDesign.backgroundWrapper(
        child: SafeArea(
          child: templatesAsync.when(
            data: (templates) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _TemplateItem(
                  template: template,
                  onActivate: () async {
                    final settings = await repository.getSettings();
                    await repository.saveSettings(settings.copyWith(activeTemplateId: template.id));
                    
                    // 1. Invalidate providers to force reload from DB for the new template
                    ref.invalidate(gameSettingsProvider);
                    ref.invalidate(stationsProvider);
                    ref.invalidate(cardsByTemplateProvider(template.id ?? 1));
                    ref.invalidate(stationsByTemplateProvider(template.id ?? 1));
                    ref.invalidate(cardsProvider);
                    
                    // 2. Clear saved game
                    await engine.clearSavedGame();
                    ref.invalidate(savedGameExistsProvider);
                    
                    // 3. Get teams and settings to start the game
                    final teams = await ref.read(teamsListProvider.future);
                    final actualSettings = await ref.read(gameSettingsProvider.future);
                    
                    if (teams.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى إضافة فرق أولاً من القائمة الرئيسية')),
                        );
                      }
                      return;
                    }
                    
                    // 4. Initialize the game board
                    await engine.initGame(teams.map((t) => t.name).toList(), actualSettings);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم تفعيل قالب: ${template.name} وبدء اللعبة بنجاح!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Navigate to board immediately - now it will find board is NOT empty
                      Navigator.pushAndRemoveUntil(
                        context, 
                        MaterialPageRoute(builder: (_) => const BankAlHazBoardPage()), 
                        (route) => route.isFirst
                      );
                    }
                  },
                  onDelete: template.id == 1 ? null : () async {
                     await repository.deleteTemplate(template.id!);
                     ref.invalidate(templatesProvider);
                  },
                  onDuplicate: () async {
                     await repository.duplicateTemplate(template.id!, "${template.name} (نسخة)");
                     ref.invalidate(templatesProvider);
                  },
                   onEdit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TemplateEditorPage(template: template)),
                      );
                   },
                   onRename: () => _showRenameTemplateDialog(context, ref, template),
                 );
               },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, s) => Center(child: Text('خطأ: $err')),
          ),
        ),
      ),
    );
  }

  void _confirmResetReligiousTemplate(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('إعادة ضبط القالب الديني', style: TextStyle(color: Colors.white)),
        content: const Text(
          'هل أنت متأكد من إعادة ضبط القالب الديني الأساسي؟ سيؤدي هذا لمسح أي تعديلات يدوية أجريتها على مدن القالب الديني وتحميل التقسيم الجديد (مالك/عابر).',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final db = await ref.read(databaseServiceProvider).database;
              await BankAlHazDefaultData.seed(db, force: true, templateId: 1);
              ref.invalidate(templatesProvider);
              ref.invalidate(stationsProvider);
              ref.invalidate(cardsProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت إعادة ضبط القالب الديني بنجاح'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('إعادة ضبط الآن'),
          ),
        ],
      ),
    );
  }

  void _showCreateTemplateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    int creationMode = 0; // 0: Manual, 1: CSV

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('قالب جديد', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'اسم القالب',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 20),
              const Text('طريقة الإنشاء:', style: TextStyle(color: Colors.white70, fontSize: 14)),
              RadioListTile<int>(
                title: const Text('بناء يدوي (فارغ)', style: TextStyle(color: Colors.white, fontSize: 14)),
                value: 0,
                groupValue: creationMode,
                onChanged: (v) => setState(() => creationMode = v!),
              ),
              RadioListTile<int>(
                title: const Text('استيراد من ملف CSV / Excel', style: TextStyle(color: Colors.white, fontSize: 14)),
                value: 1,
                groupValue: creationMode,
                onChanged: (v) => setState(() => creationMode = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  final repo = ref.read(bankAlHazRepositoryProvider);
                  final newTemplateId = await repo.saveTemplate(BankAlHazTemplate(name: controller.text));
                  
                  if (creationMode == 1) {
                    // CSV Import logic for the specific template
                    try {
                      final categories = await ref.read(categoriesProvider.future);
                      final result = await BankAlHazCsvService.importFromCsv(categories);
                      
                      for (var s in result.stations) {
                        await repo.addStation(s, templateId: newTemplateId);
                      }
                      for (var c in result.cards) {
                        await repo.saveCard(c, templateId: newTemplateId);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الاستيراد: $e')));
                      }
                    }
                  }

                  ref.invalidate(templatesProvider);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameTemplateDialog(BuildContext context, WidgetRef ref, BankAlHazTemplate template) {
    final controller = TextEditingController(text: template.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تغيير اسم القالب', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'اسم القالب الجديد',
            labelStyle: TextStyle(color: Colors.white60),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final repo = ref.read(bankAlHazRepositoryProvider);
                await repo.saveTemplate(template.copyWith(name: controller.text));
                ref.invalidate(templatesProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _TemplateItem extends StatelessWidget {
  final BankAlHazTemplate template;
  final VoidCallback onActivate;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onRename;
  final VoidCallback? onDelete;

  const _TemplateItem({
    required this.template,
    required this.onActivate,
    required this.onEdit,
    required this.onDuplicate,
    required this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDesign.glassDecoration,
      child: ListTile(
        title: Text(template.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(template.id == 1 ? 'القالب الافتراضي' : 'قالب مخصص', style: const TextStyle(color: Colors.white60)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent),
              tooltip: 'تفعيل وبدء اللعبة',
              onPressed: onActivate,
            ),
            IconButton(
              icon: const Icon(Icons.drive_file_rename_outline, color: Colors.blueAccent),
              tooltip: 'تغيير الاسم',
              onPressed: onRename,
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.amberAccent),
              tooltip: 'تعديل المدن والكروت',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white70),
              tooltip: 'نسخ القالب',
              onPressed: onDuplicate,
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                tooltip: 'حذف',
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
