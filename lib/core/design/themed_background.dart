import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'app_design.dart';
import 'app_themes.dart';
import 'christmas_widgets.dart';
import 'custom_widgets.dart';
import '../../features/settings/presentation/providers/settings_providers.dart';

class ThemedBackground extends ConsumerWidget {
  final Widget child;
  final ThemeConfig? forceTheme;

  const ThemedBackground({
    super.key,
    required this.child,
    this.forceTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (forceTheme != null) {
      return AppDesign.backgroundWrapper(child: child, theme: forceTheme);
    }

    final settingsAsync = ref.watch(generalSettingsProvider);
    final themeId = settingsAsync.when(
      data: (s) => s['app_theme'] as String? ?? 'default',
      loading: () => 'default',
      error: (_, __) => 'default',
    );
    final settingsForTheme = settingsAsync.maybeWhen(data: (s) => s, orElse: () => null);
    final theme = AppThemes.getThemeById(themeId, customParams: settingsForTheme);

    return AppDesign.backgroundWrapper(
      theme: theme,
      child: Stack(
        children: [
          if (themeId == 'christmas') const ChristmasDecorations(),
          if (themeId == 'custom') CustomDecorations(settings: settingsForTheme ?? {}),
          child,
        ],
      ),
    );
  }
}
