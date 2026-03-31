import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/bank_al_haz_providers.dart';
import '../providers/game_engine_provider.dart';
import '../../domain/entities/bank_al_haz_entities.dart';
import 'package:games/core/design/app_design.dart';
import '../../../../questions/presentation/providers/question_providers.dart';

class TemplateEditorPage extends ConsumerStatefulWidget {
  final BankAlHazTemplate template;

  const TemplateEditorPage({super.key, required this.template});

  @override
  ConsumerState<TemplateEditorPage> createState() => _TemplateEditorPageState();
}

class _TemplateEditorPageState extends ConsumerState<TemplateEditorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _currentTemplateName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentTemplateName = widget.template.name;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: InkWell(
          onTap: _showRenameDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تعديل $_currentTemplateName', style: AppDesign.titleStyle),
              const SizedBox(width: 8),
              const Icon(Icons.edit, size: 18, color: Colors.white60),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
             icon: const Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 30),
             tooltip: 'تفعيل وبدء اللعبة الآن',
             onPressed: () => _activateAndPlay(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(icon: Icon(Icons.location_city), text: 'المدن والمحطات'),
            Tab(icon: Icon(Icons.auto_awesome_motion), text: 'الكروت والمكافآت'),
          ],
        ),
      ),
      body: AppDesign.backgroundWrapper(
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _StationsEditor(templateId: widget.template.id!),
              _CardsEditor(templateId: widget.template.id!),
            ],
          ),
        ),
      ),
    );
  }

  void _activateAndPlay() async {
    final repository = ref.read(bankAlHazRepositoryProvider);
    final engine = ref.read(gameEngineProvider.notifier);
    final settings = await repository.getSettings();
    await repository.saveSettings(settings.copyWith(activeTemplateId: widget.template.id));
    
    ref.invalidate(gameSettingsProvider);
    ref.invalidate(stationsProvider);
    ref.invalidate(cardsByTemplateProvider(widget.template.id ?? 1));
    ref.invalidate(stationsByTemplateProvider(widget.template.id ?? 1));
    ref.invalidate(cardsProvider);
    
    engine.clearSavedGame();
    
    if (mounted) {
       Navigator.pushNamedAndRemoveUntil(context, '/bank_al_haz_board', (route) => route.isFirst);
    }
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: _currentTemplateName);
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
                await repo.saveTemplate(widget.template.copyWith(name: controller.text));
                setState(() => _currentTemplateName = controller.text);
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

class _StationsEditor extends ConsumerWidget {
  final int templateId;
  const _StationsEditor({required this.templateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(stationsByTemplateProvider(templateId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
               backgroundColor: Colors.blueAccent,
               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            icon: const Icon(Icons.add_location),
            label: const Text('إضافة محطة جديدة للقالب'),
            onPressed: () => _showStationDialog(context, ref),
          ),
        ),
        Expanded(
          child: stationsAsync.when(
            data: (stations) => stations.isEmpty
                ? _buildEmptyState('لا توجد محطات في هذا القالب')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: stations.length,
                    itemBuilder: (context, index) {
                      final station = stations[index];
                      final color = _getCityColor(index);
                      return _buildStationItem(context, ref, station, color);
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, s) => Center(child: Text('خطأ: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildStationItem(BuildContext context, WidgetRef ref, Station station, Color color) {
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
              ? ClipOval(child: Image.memory(station.imageData!, width: 55, height: 55, fit: BoxFit.cover))
              : Icon(
                  station.type == StationType.question ? Icons.help_center_outlined : Icons.location_on_outlined,
                  color: color, size: 28,
                ),
        ),
        title: Text(station.name, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${_getTypeLabel(station.type)} • السعر: ${station.buyPrice.toInt()}',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
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
  }

  void _showStationDialog(BuildContext context, WidgetRef ref, {Station? station}) {
    final nameController = TextEditingController(text: station?.name ?? '');
    final buyPriceController = TextEditingController(text: station?.buyPrice.toString() ?? '100');
    final rentController = TextEditingController(text: station?.baseRent.toString() ?? '10');

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Row(
            children: [
              Icon(station == null ? Icons.add_location : Icons.edit_location, color: Colors.blue),
              const SizedBox(width: 10),
              Text(station == null ? 'إضافة محطة للقالب' : 'تعديل محطة'),
            ],
          ),
          content: Consumer(
            builder: (context, ref, child) {
              final cats = ref.watch(categoriesProvider).value ?? [];
              
              if (selectedType != StationType.card && nameController.text.isNotEmpty) {
                 final normalizedName = nameController.text.trim();
                 if (selectedOwnerCategoryId == null || !cats.any((c) => c.id == selectedOwnerCategoryId)) {
                    final ownerCat = cats.cast<dynamic>().where((c) => c.name.trim() == "$normalizedName - مالك" || c.name.trim() == "مالك - $normalizedName").firstOrNull;
                    if (ownerCat != null) selectedOwnerCategoryId = ownerCat.id;
                 }
                 if (selectedPasserCategoryId == null || !cats.any((c) => c.id == selectedPasserCategoryId)) {
                    final passerCat = cats.cast<dynamic>().where((c) => c.name.trim() == "$normalizedName - عابر" || c.name.trim() == "عابر - $normalizedName").firstOrNull;
                    if (passerCat != null) selectedPasserCategoryId = passerCat.id;
                 }
              }
              
              return SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedType != StationType.card)
                        SwitchListTile(
                          title: const Text('مرتبطة بأسئلة؟', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('إذا تم الإلغاء ستعمل كاللعبة الأصلية'),
                          value: requiresQuestion,
                          onChanged: (val) => setState(() => requiresQuestion = val),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        onChanged: (val) {
                          if (requiresQuestion && selectedType != StationType.card) {
                            final cats = ref.read(categoriesProvider).value ?? [];
                            for (var cat in cats) {
                              final catName = cat.name.trim();
                              final normalizedName = val.trim();
                              if (catName == "$normalizedName - مالك" || catName == "مالك - $normalizedName") {
                                setState(() => selectedOwnerCategoryId = cat.id);
                              } else if (catName == "$normalizedName - عابر" || catName == "عابر - $normalizedName") {
                                setState(() => selectedPasserCategoryId = cat.id);
                              }
                            }
                          }
                        },
                        decoration: InputDecoration(
                          labelText: selectedType == StationType.card ? 'اسم مجموعة الكروت' : 'اسم المحطة',
                          prefixIcon: Icon(selectedType == StationType.card ? Icons.style : Icons.location_city),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<StationType>(
                        value: selectedType,
                        decoration: InputDecoration(
                          labelText: 'نوع المحطة',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: StationType.values.map((t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(t == StationType.question ? Icons.help : (t == StationType.card ? Icons.style : Icons.star_outline), size: 20),
                              const SizedBox(width: 10),
                              Text(_getTypeLabel(t)),
                            ],
                          ),
                        )).toList(),
                        onChanged: (val) => setState(() => selectedType = val!),
                      ),
                      if (requiresQuestion && selectedType != StationType.card) ...[
                        const SizedBox(height: 16),
                        const Text('تحديد فئات الأسئلة:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(height: 8),
                        _buildCategoryDropdown(context: context, label: 'سؤال المالك', icon: Icons.shopping_bag, value: selectedOwnerCategoryId, onChanged: (v) => setState(() => selectedOwnerCategoryId = v)),
                        const SizedBox(height: 12),
                        _buildCategoryDropdown(context: context, label: 'سؤال المار', icon: Icons.directions_walk, value: selectedPasserCategoryId, onChanged: (v) => setState(() => selectedPasserCategoryId = v)),
                      ],
                      const SizedBox(height: 16),
                      _buildImagePicker(setState, pickedImageData, (data) => pickedImageData = data),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: buyPriceController, decoration: const InputDecoration(labelText: 'ثمن الشراء'), keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: rentController, decoration: const InputDecoration(labelText: 'إيجار المكان'), keyboardType: TextInputType.number)),
                        ],
                      ),
                      if ((selectedType == StationType.question || selectedType == StationType.property) && !isUnbuyable) ...[
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('نظام الضرائب؟', style: TextStyle(fontWeight: FontWeight.bold)),
                          value: allowsTax,
                          onChanged: (val) => setState(() => allowsTax = val),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final newStation = Station(
                  id: station?.id,
                  name: nameController.text,
                  type: selectedType,
                  ownerCategoryId: selectedOwnerCategoryId,
                  passerCategoryId: selectedPasserCategoryId,
                  requiresQuestion: requiresQuestion,
                  cardType: selectedCardType,
                  imageData: pickedImageData,
                  buyPrice: double.tryParse(buyPriceController.text) ?? 100,
                  baseRent: double.tryParse(rentController.text) ?? 10,
                  isUnbuyable: isUnbuyable,
                  allowsTax: allowsTax,
                  era: era,
                  buildings: currentBuildings,
                );
                await ref.read(bankAlHazRepositoryProvider).saveStation(newStation, templateId: templateId);
                ref.invalidate(stationsByTemplateProvider(templateId));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteStation(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف محطة'),
        content: const Text('هل أنت متأكد من حذف هذه المحطة من القالب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              await ref.read(bankAlHazRepositoryProvider).deleteStation(id);
              ref.invalidate(stationsByTemplateProvider(templateId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getCityColor(int index) {
     final colors = [Colors.blueAccent, Colors.purpleAccent, Colors.greenAccent, Colors.orangeAccent, Colors.redAccent, Colors.cyanAccent, Colors.amberAccent];
     return colors[index % colors.length];
  }

  String _getTypeLabel(StationType type) {
    switch (type) {
      case StationType.property: return 'مدينة';
      case StationType.question: return 'مدينة (أسئلة)';
      case StationType.card: return 'كروت';
      default: return 'عادية';
    }
  }

  Widget _buildEmptyState(String msg) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.layers_clear, size: 60, color: Colors.white24), const SizedBox(height: 12), Text(msg, style: TextStyle(color: Colors.white60))]));
  }
}

class _CardsEditor extends ConsumerWidget {
  final int templateId;
  const _CardsEditor({required this.templateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(cardsByTemplateProvider(templateId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.add_circle),
            label: const Text('إضافة كرت جديد للقالب'),
            onPressed: () => _showCardDialog(context, ref),
          ),
        ),
        Expanded(
          child: cardsAsync.when(
            data: (cards) => cards.isEmpty
                ? Center(child: Text('لا توجد كروت في هذا القالب', style: TextStyle(color: Colors.white60)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final isChance = card.type == 'chance';
                      final color = isChance ? Colors.amberAccent : Colors.blueAccent;
                      return _buildCardItem(context, ref, card, color);
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, s) => Center(child: Text('خطأ: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(BuildContext context, WidgetRef ref, BankAlHazCard card, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppDesign.glassDecorationWithColor(color),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          width: 55, height: 55,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.3), width: 2)),
          child: card.imageData != null
              ? ClipOval(child: Image.memory(card.imageData!, width: 55, height: 55, fit: BoxFit.cover))
              : Icon(card.type == 'chance' ? Icons.auto_awesome : Icons.gavel, color: color, size: 28),
        ),
        title: Text(card.title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          Text(card.description, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
             decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
             child: Text(_getEffectLabel(card.effectType), style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ),
        ]),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit_note, color: Colors.white70), onPressed: () => _showCardDialog(context, ref, card: card)),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteCard(context, ref, card.id!)),
          ],
        ),
      ),
    );
  }

  void _showCardDialog(BuildContext context, WidgetRef ref, {BankAlHazCard? card}) {
    final titleController = TextEditingController(text: card?.title ?? '');
    final descController = TextEditingController(text: card?.description ?? '');
    final valueController = TextEditingController(text: card?.effectValue.toString() ?? '0');
    CardEffectType selectedType = card?.effectType ?? CardEffectType.addMoney;
    String? targetStation = card?.targetStationName;
    Uint8List? pickedImageData = card?.imageData;
    String selectedCardType = card?.type ?? 'chance';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text(card == null ? 'إضافة كرت للقالب' : 'تعديل كرت'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'عنوان الكارت')),
                  const SizedBox(height: 16),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'البند / الشرح'), maxLines: 2),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CardEffectType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'نوع التأثير'),
                    items: CardEffectType.values.map((t) => DropdownMenuItem(value: t, child: Text(_getEffectLabel(t)))).toList(),
                    onChanged: (val) => setState(() => selectedType = val!),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: valueController, decoration: const InputDecoration(labelText: 'قيمة التأثير'), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCardType,
                    decoration: const InputDecoration(labelText: 'جهة الإضافة'),
                    items: const [DropdownMenuItem(value: 'chance', child: Text('حظك اليوم')), DropdownMenuItem(value: 'chest', child: Text('المحكمة'))],
                    onChanged: (val) => setState(() => selectedCardType = val!),
                  ),
                  const SizedBox(height: 16),
                  _buildImagePicker(setState, pickedImageData, (data) => pickedImageData = data),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
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
                await ref.read(bankAlHazRepositoryProvider).saveCard(newCard, templateId: templateId);
                ref.invalidate(cardsByTemplateProvider(templateId));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCard(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف كرت'),
        content: const Text('هل أنت متأكد من حذف هذا الكرت من القالب؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              await ref.read(bankAlHazRepositoryProvider).deleteCard(id);
              ref.invalidate(cardsByTemplateProvider(templateId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getEffectLabel(CardEffectType type) {
    switch (type) {
      case CardEffectType.addMoney: return 'زيادة الفلوس';
      case CardEffectType.removeMoney: return 'نقص الفلوس';
      case CardEffectType.moveSteps: return 'تحرك خطوات';
      case CardEffectType.moveToStation: return 'اذهب لمكان معين';
      case CardEffectType.skipTurn: return 'تخطي دور المالك';
      default: return 'تأثير غير معروف';
    }
  }
}

// Global helpers used in both editors
Widget _buildCategoryDropdown({required BuildContext context, required String label, IconData? icon, required int? value, required ValueChanged<int?> onChanged}) {
  return Consumer(builder: (context, ref, _) {
    final catsAsync = ref.watch(categoriesProvider);
    return catsAsync.when(
      data: (cats) {
            String currentName = 'جميع الفئات';
            if (value != null) {
              final cat = cats.cast<dynamic>().where((c) => c.id == value).firstOrNull;
              if (cat != null) {
                currentName = cat.name;
              } else {
                // If not found in current list, try to find by name
                currentName = 'فئة غير معروفة (ID: $value)';
              }
            }
        return InkWell(
          onTap: () => _showSearchableCategoryPicker(context, cats, value, onChanged),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [Icon(icon ?? Icons.help, color: Colors.blueAccent), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)), Text(currentName, style: const TextStyle(fontWeight: FontWeight.bold))])), const Icon(Icons.arrow_drop_down)]),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('خطأ'),
    );
  });
}

void _showSearchableCategoryPicker(BuildContext context, List categories, int? currentValue, ValueChanged<int?> onSelected) {
  showDialog(context: context, builder: (context) => _SearchableCategoryDialog(categories: categories, initialValue: currentValue, onSelected: onSelected));
}

class _SearchableCategoryDialog extends StatefulWidget {
  final List categories;
  final int? initialValue;
  final ValueChanged<int?> onSelected;
  const _SearchableCategoryDialog({required this.categories, this.initialValue, required this.onSelected});
  @override
  State<_SearchableCategoryDialog> createState() => _SearchableCategoryDialogState();
}

class _SearchableCategoryDialogState extends State<_SearchableCategoryDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  @override
  Widget build(BuildContext context) {
    final filtered = [null, ...widget.categories.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))];
    return AlertDialog(
      title: const Text('اختر الفئة', textAlign: TextAlign.right),
      content: SizedBox(width: 400, height: 500, child: Column(children: [TextField(controller: _searchController, onChanged: (v) => setState(() => _searchQuery = v), decoration: InputDecoration(hintText: 'بحث...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), const SizedBox(height: 12), Expanded(child: ListView.builder(itemCount: filtered.length, itemBuilder: (context, index) { final cat = filtered[index]; final bool isAll = cat == null; return ListTile(title: Text(isAll ? 'جميع الفئات' : cat.name), selected: isAll ? widget.initialValue == null : widget.initialValue == cat.id, onTap: () { widget.onSelected(isAll ? null : cat.id); Navigator.pop(context); }); }))])),
    );
  }
}

Widget _buildImagePicker(void Function(void Function()) setState, Uint8List? pickedImageData, Function(Uint8List?) onPicked) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
    child: Column(children: [
      if (pickedImageData != null) ...[ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(pickedImageData, height: 100, width: double.infinity, fit: BoxFit.cover)), const SizedBox(height: 8)],
      ElevatedButton.icon(
        onPressed: () async {
          final result = await FilePicker.platform.pickFiles(type: FileType.image);
          if (result != null) {
            Uint8List? bytes = result.files.single.bytes;
            if (bytes == null && result.files.single.path != null) bytes = await File(result.files.single.path!).readAsBytes();
            if (bytes != null) setState(() => onPicked(bytes));
          }
        },
        icon: const Icon(Icons.image),
        label: const Text('اختر صورة'),
      ),
    ]),
  );
}
