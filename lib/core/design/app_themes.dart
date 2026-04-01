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
    backgroundImage: 'assets/images/christmas_bg.png',
    icon: Icons.ac_unit,
  );

  static final ThemeConfig holyWeekTheme = ThemeConfig(
    id: 'holy_week',
    name: 'ثيم أسبوع الآلام',
    primaryColor: const Color(0xFF424242), // Charcoal Gray
    backgroundDeep: const Color(0xFF000000), // Pure Black
    backgroundSoft: const Color(0xFF121212), // Deep Charcoal
    orbColors: [
      Colors.black,
      const Color(0xFF212121), // Medium Charcoal
      const Color(0xFF424242), // Light Charcoal
      Colors.black.withOpacity(0.9),
    ],
    icon: Icons.church,
  );

  static final ThemeConfig resurrectionTheme = ThemeConfig(
    id: 'resurrection',
    name: 'ثيم القيامة',
    primaryColor: const Color(0xFFFFD700), // Gold
    backgroundDeep: const Color(0xFF4A3515), // Deep brown/gold
    backgroundSoft: const Color(0xFF8B6B13), // Golden brown
    orbColors: [
      const Color(0xFFFFD700),
      const Color(0xFFFFFACD),
      const Color(0xFFDAA520),
      Colors.white.withOpacity(0.5),
    ],
    icon: Icons.brightness_high,
  );

  static List<ThemeConfig> allThemes = [
    defaultTheme,
    christmasTheme,
    holyWeekTheme,
    resurrectionTheme,
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
