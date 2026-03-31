import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:games/core/design/app_design.dart';
import 'package:games/core/design/app_themes.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import 'dart:io';

class CustomThemeConfigPage extends ConsumerWidget {
  const CustomThemeConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(generalSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        final primaryColor = Color(settings['custom_primary_color'] ?? 0xFF00BCD4);
        final bgDeep = Color(settings['custom_bg_deep'] ?? 0xFF001F3F);
        final bgSoft = Color(settings['custom_bg_soft'] ?? 0xFF003366);
        final isGradient = settings['custom_is_gradient'] ?? true;
        final bgImage = settings['custom_bg_image'] as String?;
        final musicPath = settings['custom_music_path'] as String?;
        final musicEnabled = settings['custom_music_enabled'] ?? true;
        final icons = settings['custom_icons'] as List<dynamic>? ?? ['58713'];

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('تخصيص الثيم الخاص بك', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: AppDesign.backgroundWrapper(
            theme: AppThemes.getThemeById('custom', customParams: settings),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                children: [
                  _buildSectionTitle('الألوان والنمط'),
                  _buildColorPickerTile(
                    context,
                    ref,
                    'اللون الأساسي',
                    primaryColor,
                    (color) => ref.read(generalSettingsProvider.notifier).setCustomThemeData(primaryColor: color.value),
                  ),
                  _buildGradientToggle(ref, isGradient),
                  if (isGradient) ...[
                    _buildColorPickerTile(
                      context,
                      ref,
                      'لون الخلفية العميق',
                      bgDeep,
                      (color) => ref.read(generalSettingsProvider.notifier).setCustomThemeData(bgDeep: color.value),
                    ),
                    _buildColorPickerTile(
                      context,
                      ref,
                      'لون الخلفية الناعم',
                      bgSoft,
                      (color) => ref.read(generalSettingsProvider.notifier).setCustomThemeData(bgSoft: color.value),
                    ),
                  ],
                  
                  const SizedBox(height: 30),
                  _buildSectionTitle('الخلفية'),
                  _buildFilePickerTile(
                    'صورة الخلفية',
                    bgImage != null ? 'تم اختيار صورة' : 'لا يوجد صورة',
                    Icons.image,
                    () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
                      if (result != null) {
                        ref.read(generalSettingsProvider.notifier).setCustomThemeData(bgImage: result.files.single.path);
                      }
                    },
                    onDelete: bgImage != null ? () => ref.read(generalSettingsProvider.notifier).setCustomThemeData(bgImage: '') : null,
                  ),

                  const SizedBox(height: 30),
                  _buildSectionTitle('الموسيقى'),
                  _buildMusicToggle(ref, musicEnabled),
                  _buildFilePickerTile(
                    'ملف الموسيقى',
                    musicPath != null ? 'تم اختيار ملف' : 'لا يوجد ملف',
                    Icons.music_note,
                    () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
                      if (result != null) {
                        ref.read(generalSettingsProvider.notifier).setCustomThemeData(musicPath: result.files.single.path);
                      }
                    },
                    onDelete: musicPath != null ? () => ref.read(generalSettingsProvider.notifier).setCustomThemeData(musicPath: '') : null,
                  ),

                  const SizedBox(height: 30),
                  _buildSectionTitle('الأشكال والأيقونات'),
                  _buildIconSelection(context, ref, icons),
                  
                  const SizedBox(height: 20),
                  _buildSectionTitle('أيقوناتك الخاصة (صور)'),
                  _buildFilePickerTile(
                    'إضافة أيقونة من ملف',
                    'اختر صوراً (PNG, JPG, etc.)',
                    Icons.add_photo_alternate,
                    () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        allowMultiple: true,
                      );
                      if (result != null) {
                        List<String> currentFiles = List.from(settings['custom_icon_files'] ?? []);
                        currentFiles.addAll(result.files.where((f) => f.path != null).map((f) => f.path!));
                        ref.read(generalSettingsProvider.notifier).setCustomThemeData(iconFiles: currentFiles);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildCustomIconFileList(ref, settings['custom_icon_files'] ?? []),
                  
                  const SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(generalSettingsProvider.notifier).setAppTheme('custom');
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('تطبيق الثيم المخصص', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildColorPickerTile(BuildContext context, WidgetRef ref, String title, Color currentColor, Function(Color) onColorSelected) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      trailing: GestureDetector(
        onTap: () => _showColorPickerDialog(context, onColorSelected),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: currentColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context, Function(Color) onColorSelected) {
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.purple, Colors.orange,
      Colors.teal, Colors.pink, Colors.amber, Colors.cyan, Colors.indigo,
      const Color(0xFF0F172A), const Color(0xFF1E293B), Colors.deepPurple,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('اختر لوناً', style: TextStyle(color: Colors.white)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) => GestureDetector(
            onTap: () {
              onColorSelected(color);
              Navigator.pop(context);
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildGradientToggle(WidgetRef ref, bool isGradient) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('تدرج لوني للخلفية', style: TextStyle(color: Colors.white70)),
      value: isGradient,
      onChanged: (val) => ref.read(generalSettingsProvider.notifier).setCustomThemeData(isGradient: val),
      activeColor: Colors.blueAccent,
    );
  }

  Widget _buildMusicToggle(WidgetRef ref, bool musicEnabled) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('تفعيل الموسيقى', style: TextStyle(color: Colors.white70)),
      value: musicEnabled,
      onChanged: (val) => ref.read(generalSettingsProvider.notifier).setCustomThemeData(musicEnabled: val),
      activeColor: Colors.blueAccent,
    );
  }

  Widget _buildFilePickerTile(String title, String subtitle, IconData icon, VoidCallback onTap, {VoidCallback? onDelete}) {
    return ListTile(
      contentPadding: const EdgeInsets.all(12),
      tileColor: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38)),
      onTap: onTap,
      trailing: onDelete != null ? IconButton(
        icon: const Icon(Icons.delete, color: Colors.redAccent),
        onPressed: onDelete,
      ) : const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
    );
  }

  Widget _buildCustomIconFileList(WidgetRef ref, List<dynamic> files) {
    if (files.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: files.map((path) {
        return Stack(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: FileImage(File(path.toString())),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: Colors.white24),
              ),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: InkWell(
                onTap: () {
                  List<String> current = List.from(files);
                  current.remove(path);
                  ref.read(generalSettingsProvider.notifier).setCustomThemeData(iconFiles: current);
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildIconSelection(BuildContext context, WidgetRef ref, List<dynamic> selectedIcons) {
    final availableIcons = [
      Icons.star, Icons.favorite, Icons.auto_awesome, Icons.ac_unit, 
      Icons.lightbulb, Icons.bolt, Icons.cloud, Icons.wb_sunny,
      Icons.nightlight, Icons.celebration, Icons.music_note, Icons.palette
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: availableIcons.map((icon) {
        final isSelected = selectedIcons.map((e) => e.toString()).contains(icon.codePoint.toString());
        return GestureDetector(
          onTap: () {
            List<String> newIcons = List.from(selectedIcons.map((e) => e.toString()));
            if (isSelected) {
              if (newIcons.length > 1) newIcons.remove(icon.codePoint.toString());
            } else {
              newIcons.add(icon.codePoint.toString());
            }
            ref.read(generalSettingsProvider.notifier).setCustomThemeData(icons: newIcons);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10),
            ),
            child: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.white70),
          ),
        );
      }).toList(),
    );
  }
}
