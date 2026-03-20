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
import 'package:games/features/settings/presentation/pages/general_settings_page.dart';
import 'package:games/features/settings/presentation/pages/about_page.dart';
import 'package:games/core/design/app_design.dart';
import 'dart:ui';

class SettingsPage extends ConsumerWidget {
  final int initialIndex;
  const SettingsPage({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 10,
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
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
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
              Tab(icon: Icon(Icons.info_outline), text: 'عن البرنامج'),
            ],
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withOpacity(0.05))),
              ),
              Positioned(
                bottom: -50,
                left: -100,
                child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent.withOpacity(0.05))),
              ),
              const SafeArea(
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
                    AboutPage(),
                  ],
                ),
              ),
            ],
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
      body: SnakesLaddersSettingsDialogContent(),
    );
  }
}
