import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/features/questions/presentation/providers/question_providers.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import '../providers/hazer_fazer_providers.dart';
import '../../domain/entities/saint_picture.dart';
import '../../domain/entities/hazer_fazer_state.dart';

class HazerFazerSettingsDialog extends ConsumerWidget {
  const HazerFazerSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.settings, color: Colors.amberAccent),
          SizedBox(width: 10),
          Text(
            'إعدادات حزر فزر',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: const SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: HazerFazerSettingsContent(),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amberAccent,
            foregroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('تم وحفظ', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class HazerFazerSettingsContent extends ConsumerStatefulWidget {
  const HazerFazerSettingsContent({super.key});

  @override
  ConsumerState<HazerFazerSettingsContent> createState() => _HazerFazerSettingsContentState();
}

class _HazerFazerSettingsContentState extends ConsumerState<HazerFazerSettingsContent> {
  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(generalSettingsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final hazerState = ref.watch(hazerFazerControllerProvider);

    return settingsAsync.when(
      data: (settings) {
        final currentTileCount = (settings['hazer_fazer_tile_count'] as int?) ?? 9;
        final currentWinPoints = (settings['hazer_fazer_win_points'] as int?) ?? 15;
        final selectedCatIds = (settings['hazer_fazer_category_ids'] as List<int>?) ?? [];
        final isPerTeam = hazerState.gameMode == HazerFazerGameMode.perTeam;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Game Mode: Shared vs Per-Team Image
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.dashboard_customize_rounded, color: Colors.amberAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'نظام الصور والتحدي في اللعبة',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RadioListTile<HazerFazerGameMode>(
                    value: HazerFazerGameMode.shared,
                    groupValue: hazerState.gameMode,
                    activeColor: Colors.amberAccent,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'صورة واحدة مشتركة لجميع الفرق (تنافسية)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: const Text(
                      'الفرق تتناوب على فتح نفس الصورة وأول من يخمن يفوز',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(hazerFazerControllerProvider.notifier).setGameMode(mode);
                      }
                    },
                  ),
                  RadioListTile<HazerFazerGameMode>(
                    value: HazerFazerGameMode.perTeam,
                    groupValue: hazerState.gameMode,
                    activeColor: Colors.amberAccent,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'صورة مستقلة لكل فريق (تحدي فك الشفرة الخاص)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: const Text(
                      'كل فريق له صورته الخاصة به التي يفتح مربعاتها ويفك شفرتها عند دوره',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    onChanged: (mode) {
                      if (mode != null) {
                        ref.read(hazerFazerControllerProvider.notifier).setGameMode(mode);
                      }
                    },
                  ),
                  if (hazerState.gameMode == HazerFazerGameMode.perTeam) ...[
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.only(right: 12, left: 4, top: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.view_carousel_rounded, color: Colors.amberAccent, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'طريقة عرض صور الفرق على الشاشة:',
                                style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          RadioListTile<HazerFazerPerTeamView>(
                            value: HazerFazerPerTeamView.all,
                            groupValue: hazerState.perTeamView,
                            activeColor: Colors.amberAccent,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text(
                              'عرض صور كل الفرق معاً جنباً إلى جنب (وصورة الفريق صاحب الدور فقط التي تتأثر)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            subtitle: const Text(
                              'تظهر جميع اللوحات في الشاشة معاً ويتم تمييز وتفعيل لوحة الفريق الذي عليه الدور فقط',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            onChanged: (view) {
                              if (view != null) {
                                ref.read(hazerFazerControllerProvider.notifier).setPerTeamView(view);
                              }
                            },
                          ),
                          RadioListTile<HazerFazerPerTeamView>(
                            value: HazerFazerPerTeamView.single,
                            groupValue: hazerState.perTeamView,
                            activeColor: Colors.amberAccent,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: const Text(
                              'عرض صورة الفريق صاحب الدور فقط',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            subtitle: const Text(
                              'تظهر لوحة واحدة كبيرة في المنتصف وتتغير تلقائياً بحسب الفريق الذي عليه الدور',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            onChanged: (view) {
                              if (view != null) {
                                ref.read(hazerFazerControllerProvider.notifier).setPerTeamView(view);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Number of Squares / Tiles
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.grid_on_rounded, color: Colors.amberAccent),
              title: const Text(
                'عدد المربعات المغطية للصورة',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Text(
                'الافتراضي 9 مربعات (3×3) — الحالي: $currentTileCount',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              trailing: DropdownButton<int>(
                value: currentTileCount,
                dropdownColor: const Color(0xFF1E293B),
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: 4, child: Text('4 مربعات (2×2)')),
                  DropdownMenuItem(value: 6, child: Text('6 مربعات (3×2)')),
                  DropdownMenuItem(value: 9, child: Text('9 مربعات (3×3) [افتراضي]')),
                  DropdownMenuItem(value: 12, child: Text('12 مربعاً (4×3)')),
                  DropdownMenuItem(value: 16, child: Text('16 مربعاً (4×4)')),
                  DropdownMenuItem(value: 20, child: Text('20 مربعاً (5×4)')),
                  DropdownMenuItem(value: 25, child: Text('25 مربعاً (5×5)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(hazerFazerControllerProvider.notifier).setTileCount(val);
                  }
                },
              ),
            ),
            const Divider(color: Colors.white12),

            // 3. Win Points
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.stars_rounded, color: Colors.cyanAccent),
              title: const Text(
                'نقاط الفوز بالتخمين',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Text(
                'الافتراضي 15 نقطة — الحالي: $currentWinPoints نقطة',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      if (currentWinPoints > 5) {
                        ref.read(hazerFazerControllerProvider.notifier).setWinPoints(currentWinPoints - 5);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                  ),
                  Text(
                    '$currentWinPoints',
                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(hazerFazerControllerProvider.notifier).setWinPoints(currentWinPoints + 5);
                    },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),

            // 4. Question Categories Link
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.category_rounded, color: Colors.purpleAccent),
              title: const Text(
                'ربط فئة الأسئلة باللعبة',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: const Text(
                'اختر فئة أو فئات الأسئلة التي تظهر عند فتح المربعات',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              trailing: ElevatedButton(
                onPressed: () => categoriesAsync.whenData(
                  (cats) => _showCategoryPickerDialog(context, ref, cats, selectedCatIds),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent.withValues(alpha: 0.2),
                  foregroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('اختيار الفئات'),
              ),
            ),

            if (selectedCatIds.isNotEmpty)
              categoriesAsync.maybeWhen(
                data: (cats) {
                  final names = cats.where((c) => selectedCatIds.contains(c.id)).map((c) => c.name).toList();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: names.map((name) => Chip(
                        label: Text(name, style: const TextStyle(fontSize: 11, color: Colors.white)),
                        backgroundColor: Colors.purpleAccent.withValues(alpha: 0.2),
                        deleteIconColor: Colors.purpleAccent,
                        visualDensity: VisualDensity.compact,
                        onDeleted: () {
                          final cat = cats.firstWhere((c) => c.name == name);
                          final newIds = List<int>.from(selectedCatIds)..remove(cat.id);
                          ref.read(generalSettingsProvider.notifier).setHazerFazerCategoryIds(newIds);
                        },
                      )).toList(),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'لم يتم تحديد فئة (سيتم استخدام جميع الفئات المتاحة تلقائياً)',
                  style: TextStyle(color: Colors.amber, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),

            const Divider(color: Colors.white12),

            // 5. Image Management: Add, Edit, Change pictures
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.photo_library_rounded, color: Colors.greenAccent, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'إدارة وتعديل صور اللعبة',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => ref.read(hazerFazerControllerProvider.notifier).resetSaintsToDefault(),
                      icon: const Icon(Icons.restore, size: 16, color: Colors.white60),
                      label: const Text('استعادة الأصل', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showAddSaintDialog(context),
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                      label: const Text('إضافة صورة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent.withValues(alpha: 0.2),
                        foregroundColor: Colors.greenAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Pictures List Cards
            ...hazerState.allSaints.map((saint) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: saint.buildImage(fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            saint.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (saint.title.isNotEmpty)
                            Text(
                              saint.title,
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.cyanAccent, size: 20),
                      tooltip: 'تعديل أو تغيير الصورة',
                      onPressed: () => _showEditSaintDialog(context, saint),
                    ),
                    if (hazerState.allSaints.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        tooltip: 'حذف الصورة',
                        onPressed: () => ref.read(hazerFazerControllerProvider.notifier).deleteSaint(saint.id),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
    );
  }

  void _showAddSaintDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    String? selectedFilePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('إضافة صورة قديس/شخصية جديدة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'اسم صاحب الصورة (مطلوب)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'اللقب أو الوصف (اختياري)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () async {
                    final res = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['png', 'jpg', 'jpeg'],
                    );
                    if (res != null && res.files.single.path != null) {
                      setStateDialog(() {
                        selectedFilePath = res.files.single.path;
                      });
                    }
                  },
                  icon: const Icon(Icons.folder_open_rounded, color: Colors.amberAccent),
                  label: Text(
                    selectedFilePath != null ? 'تم اختيار الصورة ✅' : 'اختر ملف الصورة من جهازك',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: selectedFilePath != null ? Colors.greenAccent : Colors.white30),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty || selectedFilePath == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى كتابة الاسم واختيار ملف الصورة')),
                  );
                  return;
                }
                final newSaint = SaintPicture(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  title: titleCtrl.text.trim(),
                  filePath: selectedFilePath,
                  isCustom: true,
                );
                ref.read(hazerFazerControllerProvider.notifier).addOrUpdateSaint(newSaint);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
              child: const Text('حفظ وإضافة', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSaintDialog(BuildContext context, SaintPicture saint) {
    final nameCtrl = TextEditingController(text: saint.name);
    final titleCtrl = TextEditingController(text: saint.title);
    String? updatedFilePath = saint.filePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('تعديل "${saint.name}"', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'اللقب',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () async {
                    final res = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['png', 'jpg', 'jpeg'],
                    );
                    if (res != null && res.files.single.path != null) {
                      setStateDialog(() {
                        updatedFilePath = res.files.single.path;
                      });
                    }
                  },
                  icon: const Icon(Icons.image_rounded, color: Colors.cyanAccent),
                  label: Text(
                    updatedFilePath != null && updatedFilePath != saint.filePath
                        ? 'تم اختيار صورة بديلة ✅'
                        : 'تغيير أو استبدال ملف الصورة',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                final updated = saint.copyWith(
                  name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : saint.name,
                  title: titleCtrl.text.trim(),
                  filePath: updatedFilePath,
                );
                ref.read(hazerFazerControllerProvider.notifier).addOrUpdateSaint(updated);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
              child: const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPickerDialog(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> allCategories,
    List<int> currentIds,
  ) {
    List<int> selected = List<int>.from(currentIds);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('اختر فئات الأسئلة', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 400,
              child: allCategories.isEmpty
                  ? const Text('لا توجد فئات حالياً، أضف فئات من إدارة الأسئلة', style: TextStyle(color: Colors.white60))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: allCategories.length,
                      itemBuilder: (context, index) {
                        final cat = allCategories[index];
                        final isChecked = selected.contains(cat.id);
                        return CheckboxListTile(
                          title: Text(cat.name, style: const TextStyle(color: Colors.white)),
                          value: isChecked,
                          activeColor: Colors.purpleAccent,
                          checkColor: Colors.white,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selected.add(cat.id);
                              } else {
                                selected.remove(cat.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(generalSettingsProvider.notifier).setHazerFazerCategoryIds(selected);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            child: const Text('حفظ الفئات', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
