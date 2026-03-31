import 'package:flutter/material.dart';

class ThemeConfig {
  final String id;
  final String name;
  final Color primaryColor;
  final Color backgroundDeep;
  final Color backgroundSoft;
  final List<Color> orbColors;
  final String? backgroundImage;
  final IconData icon;

  ThemeConfig({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.backgroundDeep,
    required this.backgroundSoft,
    required this.orbColors,
    this.backgroundImage,
    required this.icon,
  });
}

class AppThemes {
  static final ThemeConfig defaultTheme = ThemeConfig(
    id: 'default',
    name: 'الافتراضي',
    primaryColor: Colors.blueAccent,
    backgroundDeep: const Color(0xFF0F172A),
    backgroundSoft: const Color(0xFF1E293B),
    orbColors: [
      const Color(0xFF1E293B),
      const Color(0xFF334155),
      Colors.blueAccent,
      Colors.purpleAccent,
    ],
    icon: Icons.auto_awesome,
  );

  static final ThemeConfig christmasTheme = ThemeConfig(
    id: 'christmas',
    name: 'ثيم الكريسماس',
    primaryColor: Colors.redAccent,
    backgroundDeep: const Color(0xFF06331A), // Dark forest green
    backgroundSoft: const Color(0xFF0A4D27), // Forest green
    orbColors: [
      Colors.redAccent,
      Colors.amberAccent,
      const Color(0xFF0A4D27),
      Colors.white.withOpacity(0.5),
    ],
    icon: Icons.ac_unit,
  );

  static List<ThemeConfig> allThemes = [
    defaultTheme,
    christmasTheme,
    // The UI will add 'custom' as a virtual theme
  ];

  static ThemeConfig getThemeById(String id, {Map<String, dynamic>? customParams}) {
    if (id == 'custom' && customParams != null) {
      final primaryColor = Color(customParams['custom_primary_color'] ?? 0xFF00BCD4);
      final bgDeep = Color(customParams['custom_bg_deep'] ?? 0xFF001F3F);
      final bgSoft = Color(customParams['custom_bg_soft'] ?? 0xFF003366);
      final isGradient = customParams['custom_is_gradient'] ?? true;
      final bgImage = customParams['custom_bg_image'] as String?;

      return ThemeConfig(
        id: 'custom',
        name: 'ثيم مخصص',
        primaryColor: primaryColor,
        backgroundDeep: isGradient ? bgDeep : primaryColor,
        backgroundSoft: isGradient ? bgSoft : primaryColor,
        orbColors: [
          primaryColor,
          primaryColor.withOpacity(0.5),
          Colors.white24,
          primaryColor.withOpacity(0.2),
        ],
        backgroundImage: bgImage,
        icon: Icons.palette,
      );
    }
    return allThemes.firstWhere((t) => t.id == id, orElse: () => defaultTheme);
  }
}
