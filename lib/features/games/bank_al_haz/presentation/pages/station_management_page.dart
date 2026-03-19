import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../domain/entities/bank_al_haz_entities.dart';
import '../providers/bank_al_haz_providers.dart';
import '../../../../questions/presentation/providers/question_providers.dart';

class StationManagementPage extends ConsumerWidget {
  const StationManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(stationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة محطات بنك الحظ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showStationDialog(context, ref),
          ),
        ],
      ),
      body: stationsAsync.when(
        data: (stations) => stations.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: stations.length,
                itemBuilder: (context, index) {
                  final station = stations[index];
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
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          radius: 25,
                          child: station.imageData != null
                              ? ClipOval(
                                  child: Image.memory(
                                    station.imageData!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  station.type == StationType.question
                                      ? Icons.help_outline
                                      : station.type == StationType.card
                                      ? Icons.style
                                      : Icons.location_city,
                                  color: Colors.blue.shade800,
                                ),
                        ),
                        title: Text(
                          station.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${_getTypeLabel(station.type)} - السعر: ${station.buyPrice}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showStationDialog(
                                context,
                                ref,
                                station: station,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deleteStation(context, ref, station.id!),
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

  String _getTypeLabel(StationType type) {
    switch (type) {
      case StationType.property:
        return 'مدينة';
      case StationType.card:
        return 'كروت (حظ/محكمة)';
      case StationType.tax:
        return 'ضرائب/رسوم';
      case StationType.none:
        return 'عادية';
      case StationType.question:
        return 'مدينة (أسئلة)';
    }
  }

  void _showStationDialog(
    BuildContext context,
    WidgetRef ref, {
    Station? station,
  }) {
    final nameController = TextEditingController(text: station?.name ?? '');
    final buyPriceController = TextEditingController(
      text: station?.buyPrice.toString() ?? '100',
    );
    final rentController = TextEditingController(
      text: station?.baseRent.toString() ?? '10',
    );

    StationType selectedType = station?.type ?? StationType.question;
    int? selectedOwnerCategoryId = station?.ownerCategoryId;
    int? selectedPasserCategoryId = station?.passerCategoryId;
    bool requiresQuestion = station?.requiresQuestion ?? true;
    String? selectedCardType = station?.cardType;
    Uint8List? pickedImageData = station?.imageData;
    bool isUnbuyable = station?.isUnbuyable ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: Row(
            children: [
              Icon(
                station == null ? Icons.add_location : Icons.edit_location,
                color: Colors.blue,
              ),
              const SizedBox(width: 10),
              Text(station == null ? 'إضافة محطة جديدة' : 'تعديل محطة'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedType != StationType.card)
                    SwitchListTile(
                      title: const Text(
                        'مرتبطة بأسئلة؟',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'إذا تم الإلغاء ستعمل كاللعبة الأصلية',
                      ),
                      value: requiresQuestion,
                      onChanged: (val) =>
                          setState(() => requiresQuestion = val),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: selectedType == StationType.card
                          ? 'اسم مجموعة الكروت'
                          : 'اسم المحطة (مثلاً: أورشليم)',
                      prefixIcon: Icon(
                        selectedType == StationType.card
                            ? Icons.style
                            : Icons.location_city,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<StationType>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      labelText: 'نوع المحطة',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: StationType.values.map((t) {
                      return DropdownMenuItem<StationType>(
                        value: t,
                        child: Row(
                          children: [
                            Icon(
                              t == StationType.question
                                  ? Icons.help
                                  : (t == StationType.card
                                        ? Icons.style
                                        : (t == StationType.none
                                              ? Icons.star_outline
                                              : Icons.location_city)),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(_getTypeLabel(t)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedType = val!),
                  ),

                  if (requiresQuestion && selectedType != StationType.card) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'تحديد فئات الأسئلة:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCategoryDropdown(
                      label: 'سؤال المالك (عند الشراء)',
                      icon: Icons.shopping_bag,
                      value: selectedOwnerCategoryId,
                      onChanged: (val) =>
                          setState(() => selectedOwnerCategoryId = val),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryDropdown(
                      label: 'سؤال المار (عند العبور)',
                      icon: Icons.directions_walk,
                      value: selectedPasserCategoryId,
                      onChanged: (val) =>
                          setState(() => selectedPasserCategoryId = val),
                    ),
                  ],

                  if (selectedType == StationType.card) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCardType,
                      decoration: InputDecoration(
                        labelText: 'نوع الكارت',
                        prefixIcon: const Icon(Icons.style),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'chance',
                          child: Text('كارت حظ (Chance)'),
                        ),
                        DropdownMenuItem(
                          value: 'chest',
                          child: Text('كارت محكمة (Community Chest)'),
                        ),
                        DropdownMenuItem(
                          value: 'start',
                          child: Text('بداية / مرور (Go)'),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => selectedCardType = val),
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
                          label: const Text('اختر صورة للمدينة'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: buyPriceController,
                          decoration: InputDecoration(
                            labelText: 'ثمن الشراء',
                            prefixIcon: const Icon(Icons.shopping_cart),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: rentController,
                          decoration: InputDecoration(
                            labelText: 'إيجار المكان',
                            prefixIcon: const Icon(Icons.payments),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text(
                      'غير قابلة للشراء (شخصية)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'الصح يربح ثمنها، الخطأ يدفع إيجارها. لا يمكن امتلاكها.',
                    ),
                    value: isUnbuyable,
                    onChanged: (val) => setState(() => isUnbuyable = val),
                    secondary: const Icon(
                      Icons.person_pin_circle,
                      color: Colors.deepPurple,
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('برجاء إدخال اسم المحطة')),
                  );
                  return;
                }

                try {
                  final newStation = Station(
                    id: station?.id,
                    name: nameController.text,
                    type: selectedType,
                    ownerCategoryId: selectedOwnerCategoryId,
                    passerCategoryId: selectedPasserCategoryId,
                    requiresQuestion: requiresQuestion,
                    cardType: selectedCardType,
                    imageData: pickedImageData,
                    buyPrice: double.tryParse(buyPriceController.text) ?? 100.0,
                    baseRent: double.tryParse(rentController.text) ?? 10.0,
                    isUnbuyable: isUnbuyable,
                  );
                  await ref
                      .read(bankAlHazRepositoryProvider)
                      .saveStation(newStation);
                  ref.invalidate(stationsProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown({
    required String label,
    IconData? icon,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return Consumer(
      builder: (context, ref, _) {
        final catsAsync = ref.watch(categoriesProvider);
        return catsAsync.when(
          data: (cats) => DropdownButtonFormField<int?>(
            initialValue: value,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon ?? Icons.help),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('جميع الفئات')),
              ...cats.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: onChanged,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text('خطأ في تحميل الفئات'),
        );
      },
    );
  }

  void _deleteStation(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف محطة'),
        content: const Text('هل أنت متأكد من حذف هذه المحطة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(bankAlHazRepositoryProvider).deleteStation(id);
              ref.invalidate(stationsProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'لا توجد محطات مضافة حالياً',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('اضغط على + لإضافة أول مدينة في اللعبة'),
        ],
      ),
    );
  }
}
