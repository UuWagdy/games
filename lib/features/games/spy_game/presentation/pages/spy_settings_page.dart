import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/spy_game_provider.dart';
import '../widgets/glass_container.dart';
import 'package:games/core/design/themed_background.dart';
import '../../domain/repositories/word_repository.dart';

class SpySettingsPage extends ConsumerStatefulWidget {
  final bool isView;
  const SpySettingsPage({super.key, this.isView = false});

  @override
  ConsumerState<SpySettingsPage> createState() => _SpySettingsPageState();
}

class _SpySettingsPageState extends ConsumerState<SpySettingsPage> {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  String? _selectedCategoryToManage;

  @override
  void dispose() {
    _categoryController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  void _addCategory() {
    if (_categoryController.text.trim().isNotEmpty) {
      setState(() {
        SpyWordRepository.addCategory(_categoryController.text.trim());
        _categoryController.clear();
      });
    }
  }

  void _addItem() {
    if (_selectedCategoryToManage != null && _itemController.text.trim().isNotEmpty) {
      setState(() {
        SpyWordRepository.addItem(_selectedCategoryToManage!, _itemController.text.trim());
        _itemController.clear();
      });
    }
  }

  void _deleteCategory(String category) {
    setState(() {
      SpyWordRepository.deleteCategory(category);
      if (_selectedCategoryToManage == category) _selectedCategoryToManage = null;
    });
  }

  void _editCategory(String category) {
    final editController = TextEditingController(text: category);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("تعديل اسم الصنف", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "الاسم الجديد"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                SpyWordRepository.editCategory(category, editController.text.trim());
                if (_selectedCategoryToManage == category) {
                   _selectedCategoryToManage = editController.text.trim();
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  void _editItem(String category, String item) {
    final editController = TextEditingController(text: item);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("تعديل الشيء", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "الاسم الجديد"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                SpyWordRepository.editItem(category, item, editController.text.trim());
              });
              Navigator.pop(ctx);
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  void _deleteItem(String category, String item) {
    setState(() {
      SpyWordRepository.deleteItem(category, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(spyGameProvider);
    final settings = state.settings;
    final notifier = ref.read(spyGameProvider.notifier);
    final allCategories = SpyWordRepository.getAllCategories();

    final content = SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSection(
              title: "خيارات الفوز",
              child: Column(
                children: [
                   _buildPointsConfig("فوز الجاسوس", settings.spyWinPoints, Colors.redAccent, (v) => notifier.updateSettings(settings.copyWith(spyWinPoints: v))),
                   const SizedBox(height: 16),
                   _buildPointsConfig("فوز اللاعبين", settings.playersWinPoints, Colors.greenAccent, (v) => notifier.updateSettings(settings.copyWith(playersWinPoints: v))),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: "خيارات الجولة",
              child: Column(
                children: [
                   _buildSliderConfig("عدد الجواسيس", settings.numberOfSpies, 1, 5, 4, Colors.redAccent, (v) => notifier.updateSettings(settings.copyWith(numberOfSpies: v))),
                   const SizedBox(height: 16),
                   _buildSwitchConfig("تفعيل الموقت", settings.timerEnabled, Colors.blueAccent, (v) => notifier.updateSettings(settings.copyWith(timerEnabled: v))),
                   if (settings.timerEnabled) ...[
                     const SizedBox(height: 16),
                     _buildSliderConfig("وقت الجولة (ثانية)", settings.roundTimerSeconds, 30, 900, 29, Colors.blueAccent, (v) => notifier.updateSettings(settings.copyWith(roundTimerSeconds: v))),
                   ],
                   const SizedBox(height: 16),
                   _buildSliderConfig("عدد جولات الأسئلة", settings.numberOfRounds, 1, 10, 9, Colors.amberAccent, (v) => notifier.updateSettings(settings.copyWith(numberOfRounds: v))),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              title: "إدارة الأصناف (المجموعات)",
              child: Column(
                children: [
                   TextField(
                     controller: _categoryController,
                     style: const TextStyle(color: Colors.white, fontSize: 13),
                     decoration: InputDecoration(
                       hintText: "أضف صنفاً جديداً (مثلاً: فواكه)...",
                       hintStyle: const TextStyle(color: Colors.white24),
                       filled: true,
                       fillColor: Colors.white.withAlpha(10),
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                       suffixIcon: IconButton(icon: const Icon(Icons.add, color: Colors.blueAccent), onPressed: _addCategory),
                     ),
                   ),
                   const SizedBox(height: 16),
                   // Category List
                   Container(
                     constraints: const BoxConstraints(maxHeight: 200),
                     child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: allCategories.length,
                        separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (context, index) {
                          final cat = allCategories[index];
                          final isSelected = _selectedCategoryToManage == cat;
                          return ListTile(
                            onTap: () => setState(() => _selectedCategoryToManage = cat),
                            dense: true,
                            title: Text(cat, style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, size: 16, color: Colors.white38), onPressed: () => _editCategory(cat)),
                                IconButton(icon: Icon(Icons.delete, size: 16, color: Colors.redAccent.withAlpha(150)), onPressed: () => _deleteCategory(cat)),
                              ],
                            ),
                          );
                        },
                     ),
                   ),
                ],
              ),
            ),
            if (_selectedCategoryToManage != null) ...[
              const SizedBox(height: 24),
              _buildSection(
                title: "إدارة الكلمات في صنف: $_selectedCategoryToManage",
                child: Column(
                  children: [
                     TextField(
                       controller: _itemController,
                       style: const TextStyle(color: Colors.white, fontSize: 13),
                       decoration: InputDecoration(
                         hintText: "أضف كلمة جديدة لهذا الصنف...",
                         hintStyle: const TextStyle(color: Colors.white24),
                         filled: true,
                         fillColor: Colors.white.withAlpha(10),
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                         suffixIcon: IconButton(icon: const Icon(Icons.add, color: Colors.greenAccent), onPressed: _addItem),
                       ),
                     ),
                     const SizedBox(height: 16),
                     Wrap(
                       spacing: 8, runSpacing: 8,
                       children: SpyWordRepository.getItemsByCategory(_selectedCategoryToManage!).map((item) => Container(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                         decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                         child: Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Text(item, style: const TextStyle(color: Colors.white, fontSize: 12)),
                             const SizedBox(width: 6),
                             InkWell(onTap: () => _editItem(_selectedCategoryToManage!, item), child: const Icon(Icons.edit, size: 12, color: Colors.white38)),
                             const SizedBox(width: 4),
                             InkWell(onTap: () => _deleteItem(_selectedCategoryToManage!, item), child: const Icon(Icons.close, size: 12, color: Colors.redAccent)),
                           ],
                         ),
                       )).toList(),
                     ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            _buildSection(
              title: "الأصناف المفعلة للجولة",
              child: Wrap(
                spacing: 8,
                children: allCategories.map((cat) {
                  final isSelected = settings.selectedCategories.contains(cat);
                  return FilterChip(
                    label: Text(cat, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (val) {
                      final list = List<String>.from(settings.selectedCategories);
                      if (val) list.add(cat); else if (list.length > 1) list.remove(cat);
                      notifier.updateSettings(settings.copyWith(selectedCategories: list));
                    },
                    selectedColor: Colors.blueAccent.withAlpha(150),
                    backgroundColor: Colors.white10,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );

    if (widget.isView) return content;

    return ThemedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("إعدادات الجلسة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: content,
      ),
    );
  }

  Widget _buildSwitchConfig(String title, bool value, Color color, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color,
        ),
      ],
    );
  }

  Widget _buildSliderConfig(String title, int value, double min, double max, int divisions, Color color, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white60, fontSize: 13)),
            Text("$value", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min, max: max, divisions: divisions,
          activeColor: color,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }

  Widget _buildPointsConfig(String title, int value, Color color, Function(int) onChanged) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white60, fontSize: 13))),
        Text("$value", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 5, max: 100, divisions: 19,
            activeColor: color,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GlassContainer(borderRadius: 20, opacity: 0.05, child: child),
      ],
    );
  }
}
