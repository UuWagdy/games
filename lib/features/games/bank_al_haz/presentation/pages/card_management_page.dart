import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../domain/entities/bank_al_haz_entities.dart';
import '../providers/bank_al_haz_providers.dart';

class CardManagementPage extends ConsumerWidget {
  const CardManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الكروت'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCardDialog(context, ref),
          ),
        ],
      ),
      body: cardsAsync.when(
        data: (cards) => ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    radius: 25,
                    child: card.imageData != null
                        ? ClipOval(
                            child: Image.memory(
                              card.imageData!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.style, color: Colors.blue.shade800),
                  ),
                  title: Text(
                    card.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(card.description),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getEffectLabel(card.effectType),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showCardDialog(context, ref, card: card),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCard(context, ref, card.id!),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
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
}
