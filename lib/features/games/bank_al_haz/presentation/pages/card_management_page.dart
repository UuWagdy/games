import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../domain/entities/bank_al_haz_entities.dart';
import '../providers/bank_al_haz_providers.dart';
import 'package:games/core/design/app_design.dart';

class CardManagementPage extends ConsumerWidget {
  const CardManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppDesign.backgroundWrapper(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text('إدارة الكروت', style: AppDesign.titleStyle.copyWith(fontSize: 22)),
              actions: [
                IconButton(
                  tooltip: 'حفظ كمجموعة (قالب)',
                  icon: const Icon(Icons.save_as, color: Colors.cyanAccent),
                  onPressed: () => _showSaveAsTemplateDialog(context, ref),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.amberAccent, size: 30),
                  onPressed: () => _showCardDialog(context, ref),
                ),
              ],
            ),
            Expanded(
              child: cardsAsync.when(
                data: (cards) => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    final isChance = card.type == 'chance';
                    final color = isChance ? Colors.amberAccent : Colors.blueAccent;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: AppDesign.glassDecorationWithColor(color),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Container(
                          width: 55, height: 55,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: color.withOpacity(0.3), width: 2),
                          ),
                          child: card.imageData != null
                              ? ClipOval(
                                  child: Image.memory(
                                    card.imageData!,
                                    width: 55, height: 55,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(isChance ? Icons.auto_awesome : Icons.gavel, color: color, size: 28),
                        ),
                        title: Text(
                          card.title,
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(card.description, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: color.withOpacity(0.3)),
                              ),
                              child: Text(
                                _getEffectLabel(card.effectType),
                                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_note, color: Colors.white70),
                              onPressed: () => _showCardDialog(context, ref, card: card),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _deleteCard(context, ref, card.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.amberAccent)),
                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardDialog(
    BuildContext context,
    WidgetRef ref, {
    BankAlHazCard? card,
  }) {
    final titleController = TextEditingController(text: card?.title ?? '');
    final descController = TextEditingController(text: card?.description ?? '');
    final valueController = TextEditingController(
      text: card?.effectValue.toString() ?? '0',
    );

    CardEffectType selectedType = card?.effectType ?? CardEffectType.addMoney;
    String? targetStation = card?.targetStationName;
    Uint8List? pickedImageData = card?.imageData;
    String selectedCardType = card?.type ?? 'chance';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: Text(
            card == null ? 'إضافة كارت جديد' : 'تعديل كارت',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'عنوان الكارت',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'البند / الشرح',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CardEffectType>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      labelText: 'نوع التأثير',
                      prefixIcon: const Icon(Icons.bolt),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: CardEffectType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(_getEffectLabel(t)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => selectedType = val!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valueController,
                    decoration: InputDecoration(
                      labelText: 'قيمة التأثير (رقم)',
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (selectedType == CardEffectType.moveToStation) ...[
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, child) {
                        final stationsAsync = ref.watch(stationsProvider);
                        return stationsAsync.when(
                          data: (stations) {
                            if (stations.isEmpty) {
                              return const Text(
                                "لا توجد محطات مضافة حالياً. برجاء إضافة مدن أولاً.",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              );
                            }
                            // Filter out duplicates and ensure trim
                            final uniqueNames = stations
                                .map((s) => s.name.trim())
                                .toSet()
                                .toList();

                            return DropdownButtonFormField<String>(
                              initialValue:
                                  (targetStation != null &&
                                      uniqueNames.contains(
                                        targetStation!.trim(),
                                      ))
                                  ? targetStation!.trim()
                                  : (uniqueNames.contains("أنطاكية")
                                        ? "أنطاكية"
                                        : (uniqueNames.isNotEmpty
                                              ? uniqueNames.first
                                              : null)),
                              decoration: InputDecoration(
                                labelText: 'اختر المحطة المستهدفة',
                                prefixIcon: const Icon(Icons.location_on),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: uniqueNames
                                  .map(
                                    (name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => targetStation = val),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const Text("خطأ في تحميل المحطات"),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCardType,
                    decoration: InputDecoration(
                      labelText: 'جهة الإضافة (المكان)',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                       DropdownMenuItem(value: 'chance', child: Text('حظك اليوم')),
                       DropdownMenuItem(value: 'chest', child: Text('المحكمة')),
                    ],

                    onChanged: (val) {
                       setState(() => selectedCardType = val!);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Image Picker Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        if (pickedImageData != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              pickedImageData!,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );
                            if (result != null) {
                              Uint8List? bytes = result.files.single.bytes;
                              if (bytes == null &&
                                  result.files.single.path != null) {
                                bytes = await File(
                                  result.files.single.path!,
                                ).readAsBytes();
                              }
                              if (bytes != null) {
                                setState(() => pickedImageData = bytes);
                              }
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('اختر صورة للكارت'),
                        ),
                      ],
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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final newCard = BankAlHazCard(
                  id: card?.id,
                  title: titleController.text,
                  description: descController.text,
                  type: selectedCardType,
                  effectType: selectedType,
                  effectValue: int.tryParse(valueController.text) ?? 0,
                  targetStationName: targetStation,
                  imageData: pickedImageData,
                );
                await ref.read(bankAlHazRepositoryProvider).saveCard(newCard);
                ref.invalidate(cardsProvider);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],

        ),
      ),
    );
  }

  String _getEffectLabel(CardEffectType type) {
    switch (type) {
      case CardEffectType.addMoney:
        return 'زيادة الفلوس';
      case CardEffectType.removeMoney:
        return 'نقص الفلوس';
      case CardEffectType.moveSteps:
        return 'تحرك خطوات';
      case CardEffectType.moveToStation:
        return 'اذهب لمكان معين';
      case CardEffectType.diceMultiplier:
        return 'مضاعفة النرد القادم';
      case CardEffectType.skipTurn:
        return 'ميلعبش الدور الجاي';
    }
  }

  void _deleteCard(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف كارت'),
        content: const Text('هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(bankAlHazRepositoryProvider).deleteCard(id);
              ref.invalidate(cardsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSaveAsTemplateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('حفظ كمجموعة (قالب) جديد', style: TextStyle(color: Colors.white)),
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
                final settings = await ref.read(gameSettingsProvider.future);
                final currentId = settings.activeTemplateId ?? 1;
                
                final newId = await repo.duplicateTemplate(currentId, controller.text);
                ref.invalidate(templatesProvider);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  _showSwitchPrompt(context, ref, controller.text, newId);
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showSwitchPrompt(BuildContext context, WidgetRef ref, String name, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تم الحفظ بنجاح', style: TextStyle(color: Colors.white)),
        content: Text('تم حفظ القالب "$name". هل تريد تفعيله الآن ليكون هو القالب النشط في اللعبة؟', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('لاحقاً')),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(bankAlHazRepositoryProvider);
              final settings = await repo.getSettings();
              await repo.saveSettings(settings.copyWith(activeTemplateId: id));
              ref.invalidate(gameSettingsProvider);
              ref.invalidate(stationsProvider);
              ref.invalidate(cardsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('تفعيل الآن'),
          ),
        ],
      ),
    );
  }
}
