import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'app_design.dart';
import 'app_themes.dart';
import 'christmas_widgets.dart';
import 'holy_week_widgets.dart';
import 'resurrection_widgets.dart';
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
        fit: StackFit.expand,
        children: [
          if (themeId == 'christmas') const ChristmasDecorations(),
          if (themeId == 'holy_week') const HolyWeekDecorations(),
          if (themeId == 'resurrection') const ResurrectionDecorations(),
          if (themeId == 'custom') CustomDecorations(settings: settingsForTheme ?? {}),
          child,
        ],
      ),
    );
  }
}

class ThemedGameFrame extends ConsumerWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const ThemedGameFrame({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(currentThemeProvider);
    final theme = themeAsync.value ?? AppThemes.defaultTheme;

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.6),
          width: 3.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: child,
      ),
    );
  }
}
