import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../domain/entities/bank_al_haz_entities.dart';
import '../providers/bank_al_haz_providers.dart';
import '../../../../questions/presentation/providers/question_providers.dart';
import 'package:games/core/design/app_design.dart';
import '../../data/sources/bank_al_haz_csv_service.dart';

class StationManagementPage extends ConsumerWidget {
  const StationManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(stationsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppDesign.backgroundWrapper(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text('إدارة محطات بنك الحظ', style: AppDesign.titleStyle.copyWith(fontSize: 22)),
              actions: [
                IconButton(
                  tooltip: 'تنزيل نموذج Excel (CSV)',
                  icon: const Icon(Icons.download, color: Colors.greenAccent),
                  onPressed: () async {
                    final stations = stationsAsync.value ?? [];
                    final cards = await ref.read(cardsProvider.future);
                    final categories = await ref.read(categoriesProvider.future);
                    BankAlHazCsvService.exportTemplate(stations, cards, categories);
                  },
                ),
                IconButton(
                  tooltip: 'استيراد من CSV',
                  icon: const Icon(Icons.upload_file, color: Colors.orangeAccent),
                  onPressed: () => _importCsv(context, ref),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 30),
                  onPressed: () => _showStationDialog(context, ref),
                ),
              ],
            ),
            Expanded(
              child: stationsAsync.when(
                data: (stations) => stations.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: stations.length,
                        itemBuilder: (context, index) {
                          final station = stations[index];
                          final color = _getCityColor(index);
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
                                child: station.imageData != null
                                    ? ClipOval(
                                        child: Image.memory(
                                          station.imageData!,
                                          width: 55, height: 55,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Icon(
                                        station.type == StationType.question
                                            ? Icons.help_center_outlined
                                            : station.type == StationType.card
                                            ? Icons.auto_awesome_motion
                                            : Icons.location_on_outlined,
                                        color: color,
                                        size: 28,
                                      ),
                              ),
                              title: Text(
                                station.name,
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${_getTypeLabel(station.type)} • السعر: ${station.buyPrice.toInt()}',
                                  style: TextStyle(color: Colors.white60, fontSize: 14),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_note, color: Colors.blueAccent),
                                    onPressed: () => _showStationDialog(context, ref, station: station),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _deleteStation(context, ref, station.id!),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCityColor(int index) {
    final colors = [
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.redAccent,
      Colors.cyanAccent,
      Colors.amberAccent,
    ];
    return colors[index % colors.length];
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
    bool allowsTax = station?.allowsTax ?? true;
    Era era = station?.era ?? Era.none;
    List<Building> currentBuildings = station?.buildings != null ? [...station!.buildings] : [];

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
              padding: const EdgeInsets.symmetric(vertical: 10),
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
                  SizedBox(height: AppDesign.isSmallScreen(context) ? 4 : 12),
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
                  SizedBox(height: AppDesign.isSmallScreen(context) ? 8 : 16),
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
                    SizedBox(height: AppDesign.isSmallScreen(context) ? 8 : 16),
                    const Text(
                      'تحديد فئات الأسئلة:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: AppDesign.isSmallScreen(context) ? 4 : 8),
                    _buildCategoryDropdown(
                      context: context,
                      label: 'سؤال المالك (عند الشراء)',
                      icon: Icons.shopping_bag,
                      value: selectedOwnerCategoryId,
                      onChanged: (val) =>
                          setState(() => selectedOwnerCategoryId = val),
                    ),
                    SizedBox(height: AppDesign.isSmallScreen(context) ? 6 : 12),
                    _buildCategoryDropdown(
                      context: context,
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

                  SizedBox(height: AppDesign.isSmallScreen(context) ? 8 : 16),
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

                  SizedBox(height: AppDesign.isSmallScreen(context) ? 8 : 16),
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

                  if ((selectedType == StationType.question || selectedType == StationType.property) && !isUnbuyable) ...[
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text(
                        'تفعيل نظام الضرائب لـ هذه المحطة؟',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'إذا تم الإلغاء، لن يظهر خيار الضريبة لصاحب المكان أثناء اللعبة',
                      ),
                      value: allowsTax,
                      onChanged: (val) => setState(() => allowsTax = val),
                      secondary: const Icon(Icons.money_off, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.business),
                      label: const Text('إدارة مباني هذه المحطة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.withOpacity(0.1),
                        foregroundColor: Colors.blueAccent,
                      ),
                      onPressed: () {
                         _showBuildingListDialog(context, ref, station?.id, currentBuildings, (newList) {
                           setState(() {
                             currentBuildings = newList;
                           });
                         });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Era>(
                      value: era,
                      decoration: const InputDecoration(
                        labelText: 'العهد',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.history_edu),
                      ),
                      items: Era.values.map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e == Era.oldTestament ? 'عهد قديم' : (e == Era.newTestament ? 'عهد جديد' : 'لا يوجد')),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            era = val;
                            // Add default buildings if empty
                            if (currentBuildings.isEmpty) {
                              if (val == Era.newTestament) {
                                currentBuildings = [
                                  const Building(name: "كنيسة", buyPrice: 100, additionalRent: 50),
                                  const Building(name: "كاتدرائية", buyPrice: 150, additionalRent: 75),
                                  const Building(name: "دير", buyPrice: 200, additionalRent: 100),
                                ];
                              } else if (val == Era.oldTestament && nameController.text.contains("أورشليم")) {
                                currentBuildings = [
                                  const Building(name: "الهيكل", buyPrice: 300, additionalRent: 150),
                                  const Building(name: "خيمة الاجتماع", buyPrice: 200, additionalRent: 100),
                                ];
                              }
                            }
                          });
                        }
                      },
                    ),
                  ],

                  SizedBox(height: AppDesign.isSmallScreen(context) ? 4 : 12),
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
                    allowsTax: allowsTax,
                    era: era,
                    buildings: currentBuildings,
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
    required BuildContext context,
    required String label,
    IconData? icon,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return Consumer(
      builder: (context, ref, _) {
        final catsAsync = ref.watch(categoriesProvider);
        return catsAsync.when(
          data: (cats) {
            String currentName = value == null ? 'جميع الفئات' : (cats.any((c) => c.id == value) ? cats.firstWhere((c) => c.id == value).name : 'فئة غير معروفة');

            return InkWell(
              onTap: () => _showSearchableCategoryPicker(context, cats, value, onChanged),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(icon ?? Icons.help, color: Colors.blueAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          Text(currentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('خطأ في تحميل الفئات'),
        );
      },
    );
  }

  void _showSearchableCategoryPicker(BuildContext context, List categories, int? currentValue, ValueChanged<int?> onSelected) {
    showDialog(
      context: context,
      builder: (context) => _SearchableCategoryDialog(
        categories: categories,
        initialValue: currentValue,
        onSelected: onSelected,
      ),
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

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    try {
      final categories = await ref.read(categoriesProvider.future);
      final result = await BankAlHazCsvService.importFromCsv(categories);
      
      if (result.stations.isEmpty && result.cards.isEmpty) return;

      int stationCount = 0;
      int cardCount = 0;
      final repo = ref.read(bankAlHazRepositoryProvider);
      
      for (var s in result.stations) {
        await repo.addStation(s);
        stationCount++;
      }
      for (var c in result.cards) {
        await repo.saveCard(c);
        cardCount++;
      }
      
      ref.invalidate(stationsProvider);
      ref.invalidate(cardsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم استيراد ${stationCount + cardCount} عنصر بنجاح')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الاستيراد: $e')),
        );
      }
    }
  }

  void _showBuildingListDialog(BuildContext context, WidgetRef ref, int? stationId, List<Building> buildings, Function(List<Building>) onUpdate) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إدارة المباني'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: Column(
              children: [
                Expanded(
                  child: buildings.isEmpty
                      ? const Center(child: Text('لا توجد مباني مضافة'))
                      : ListView.builder(
                          itemCount: buildings.length,
                          itemBuilder: (context, index) {
                            final b = buildings[index];
                            return ListTile(
                              title: Text(b.name),
                              subtitle: Text('ثمن: ${b.buyPrice} • إيجار: ${b.additionalRent}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showEditBuildingDialog(context, b, (newB) {
                                      final newList = [...buildings];
                                      newList[index] = newB;
                                      onUpdate(newList);
                                      setState(() {
                                        buildings = newList;
                                      });
                                    }),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      final newList = [...buildings];
                                      newList.removeAt(index);
                                      onUpdate(newList);
                                      setState(() {
                                        buildings = newList;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const Divider(),
                ElevatedButton.icon(
                  onPressed: () => _showEditBuildingDialog(context, null, (newB) {
                    final newList = [...buildings, newB];
                    onUpdate(newList);
                    setState(() {
                      buildings = newList;
                    });
                  }),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة مبنى جديد'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBuildingDialog(BuildContext context, Building? building, Function(Building) onSave) {
    final nameController = TextEditingController(text: building?.name ?? '');
    final priceController = TextEditingController(text: building?.buyPrice.toString() ?? '100');
    final rentController = TextEditingController(text: building?.additionalRent.toString() ?? '50');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(building == null ? 'إضافة مبنى' : 'تعديل مبنى'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم المبنى')),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: 'ثمن الشراء'), keyboardType: TextInputType.number),
            TextField(controller: rentController, decoration: const InputDecoration(labelText: 'قيمة الإيجار الإضافي'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              onSave(Building(
                name: nameController.text,
                buyPrice: double.tryParse(priceController.text) ?? 100,
                additionalRent: double.tryParse(rentController.text) ?? 50,
              ));
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _SearchableCategoryDialog extends StatefulWidget {
  final List categories;
  final int? initialValue;
  final ValueChanged<int?> onSelected;

  const _SearchableCategoryDialog({
    required this.categories,
    this.initialValue,
    required this.onSelected,
  });

  @override
  State<_SearchableCategoryDialog> createState() => _SearchableCategoryDialogState();
}

class _SearchableCategoryDialogState extends State<_SearchableCategoryDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = [
      null, // For "All Categories"
      ...widget.categories.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())),
    ];

    return AlertDialog(
      title: const Text('اختر الفئة', textAlign: TextAlign.right),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'بحث...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final cat = filtered[index];
                  final bool isAll = cat == null;
                  return ListTile(
                    title: Text(isAll ? 'جميع الفئات' : cat.name),
                    selected: isAll ? widget.initialValue == null : widget.initialValue == cat.id,
                    onTap: () {
                      widget.onSelected(isAll ? null : cat.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
