import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/features/teams/presentation/pages/teams_management_page.dart';
import 'package:games/features/questions/presentation/pages/questions_management_page.dart';
import 'package:games/features/games/wheel/presentation/pages/wheel_settings_page.dart';
import 'package:games/features/games/penalty_shootout/presentation/pages/penalty_settings_page.dart';
import 'package:games/features/games/under_pressure/presentation/pages/under_pressure_settings_page.dart';
import 'package:games/features/games/quiz_arena/presentation/pages/quiz_arena_settings_page.dart';
import 'package:games/features/games/snakes_and_ladders/presentation/widgets/snakes_ladders_settings_dialog.dart';
import 'package:games/features/games/bank_al_haz/presentation/pages/bank_al_haz_settings_page.dart';
import 'package:games/features/games/ludo_quiz/presentation/pages/ludo_settings_page.dart';
import 'package:games/features/games/spy_game/presentation/pages/spy_settings_page.dart';
import 'package:games/features/settings/presentation/pages/general_settings_page.dart';
import 'package:games/features/settings/presentation/pages/themes_page.dart';
import 'package:games/features/settings/presentation/pages/about_page.dart';
import 'package:games/core/design/app_design.dart';
import 'package:games/core/design/themed_background.dart';
import 'package:games/core/design/app_themes.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';
import 'dart:ui';

class SettingsPage extends ConsumerWidget {
  final int initialIndex;
  const SettingsPage({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(generalSettingsProvider);
    final themeId = settingsAsync.when(
      data: (s) => s['app_theme'] as String? ?? 'default',
      loading: () => 'default',
      error: (_, __) => 'default',
    );
    final theme = AppThemes.getThemeById(themeId);

    return DefaultTabController(
      length: 13,
      initialIndex: initialIndex,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Builder(
            builder: (context) {
              final isSmall = AppDesign.isSmallScreen(context);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/logo.png', height: isSmall ? 24 : 40),
                  const SizedBox(width: 12),
                  Text(
                    'الإعدادات', 
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: isSmall ? 18 : 24, 
                      color: Colors.white
                    )
                  ),
                ],
              );
            }
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: theme.primaryColor,
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.settings), text: 'عام'),
              Tab(icon: Icon(Icons.group), text: 'الفرق'),
              Tab(icon: Icon(Icons.help_center), text: 'الأسئلة والأنواع'),
              Tab(icon: Icon(Icons.settings_suggest), text: 'عجلة الحظ'),
              Tab(icon: Icon(Icons.sports_soccer), text: 'ضربات الجزاء'),
              Tab(icon: Icon(Icons.timer), text: 'تحت الضغط'),
              Tab(icon: Icon(Icons.psychology), text: 'ساحة التحدي'),
              Tab(icon: Icon(Icons.grid_4x4), text: 'السلم والثعبان'),
              Tab(icon: Icon(Icons.account_balance), text: 'بنك الحظ'),
              Tab(icon: Icon(Icons.casino), text: 'لودو الأسئلة'),
              Tab(icon: Icon(Icons.visibility_off), text: 'لعبة الجاسوس'),
              Tab(icon: Icon(Icons.color_lens), text: 'الأثواب'),
              Tab(icon: Icon(Icons.info_outline), text: 'عن البرنامج'),
            ],
          ),
        ),
        body: ThemedBackground(
          child: SafeArea(
            child: TabBarView(
              children: [
                GeneralSettingsPage(),
                TeamsManagementPage(),
                QuestionsManagementPage(),
                WheelSettingsPage(),
                PenaltySettingsPage(),
                UnderPressureSettingsPage(),
                QuizArenaSettingsPage(isView: true),
                SnakesLaddersSettingsView(),
                BankAlHazSettingsPage(isView: true),
                LudoSettingsPage(isView: true),
                SpySettingsPage(isView: true),
                ThemesPage(),
                AboutPage(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SnakesLaddersSettingsView extends ConsumerWidget {
  const SnakesLaddersSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: SnakesLaddersSettingsDialogContent(),
        ),
      ),
    );
  }
}

