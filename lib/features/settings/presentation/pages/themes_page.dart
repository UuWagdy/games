import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/core/design/app_design.dart';
import 'package:games/core/design/themed_background.dart';
import 'package:games/core/design/app_themes.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import 'package:games/features/settings/presentation/pages/custom_theme_config_page.dart';

class ThemesPage extends ConsumerWidget {
  const ThemesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(generalSettingsProvider);
    
    return settingsAsync.when(
      data: (settings) {
        final currentThemeId = settings['app_theme'] as String? ?? 'default';
        final currentTheme = AppThemes.getThemeById(currentThemeId);
        
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'الأثواب (الثيمات)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ThemedBackground(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'اختر الثيم المفضل لديك لتغيير مظهر التطبيق',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (currentThemeId == 'christmas')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Container(
                        decoration: AppDesign.glassDecoration.copyWith(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SwitchListTile(
                          title: const Text('موسيقى الكريسماس', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: const Text('We Wish You a Merry Christmas', style: TextStyle(color: Colors.white60)),
                          secondary: const Icon(Icons.music_note, color: Colors.amberAccent),
                          value: settings['christmas_music_enabled'] ?? true,
                          activeColor: Colors.amberAccent,
                          onChanged: (val) => ref.read(generalSettingsProvider.notifier).setChristmasMusicEnabled(val),
                        ),
                      ),
                    ),
                  if (currentThemeId == 'holy_week')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Container(
                        decoration: AppDesign.glassDecoration.copyWith(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SwitchListTile(
                          title: const Text('موسيقى أسبوع الآلام', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: const Text('holy_week_music.mp3', style: TextStyle(color: Colors.white60)),
                          secondary: const Icon(Icons.music_note, color: Colors.purpleAccent),
                          value: settings['holy_week_music_enabled'] ?? true,
                          activeColor: Colors.purpleAccent,
                          onChanged: (val) => ref.read(generalSettingsProvider.notifier).setHolyWeekMusicEnabled(val),
                        ),
                      ),
                    ),
                  if (currentThemeId == 'resurrection')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Container(
                        decoration: AppDesign.glassDecoration.copyWith(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SwitchListTile(
                          title: const Text('موسيقى القيامة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: const Text('resurrection_music.mp3', style: TextStyle(color: Colors.white60)),
                          secondary: const Icon(Icons.music_note, color: Colors.amberAccent),
                          value: settings['resurrection_music_enabled'] ?? true,
                          activeColor: Colors.amberAccent,
                          onChanged: (val) => ref.read(generalSettingsProvider.notifier).setResurrectionMusicEnabled(val),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: AppThemes.allThemes.length + 1,
                      itemBuilder: (context, index) {
                        if (index < AppThemes.allThemes.length) {
                          final theme = AppThemes.allThemes[index];
                          final isSelected = theme.id == currentThemeId;
                          return _buildThemeCard(context, ref, theme, isSelected);
                        } else {
                          // Custom Theme
                          final customTheme = AppThemes.getThemeById('custom', customParams: settings);
                          final isSelected = currentThemeId == 'custom';
                          return Stack(
                            children: [
                              _buildThemeCard(context, ref, customTheme, isSelected),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: IconButton(
                                  icon: const Icon(Icons.settings, color: Colors.white70),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CustomThemeConfigPage()),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildThemeCard(BuildContext context, WidgetRef ref, ThemeConfig theme, bool isSelected) {
    return GestureDetector(
      onTap: () async {
        await ref.read(generalSettingsProvider.notifier).setAppTheme(theme.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isSelected ? 0.15 : 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                theme.icon,
                color: theme.primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildColorDot(theme.backgroundDeep),
                      _buildColorDot(theme.backgroundSoft),
                      _buildColorDot(theme.primaryColor),
                      ...theme.orbColors.take(2).map((c) => _buildColorDot(c)),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
    );
  }
}
