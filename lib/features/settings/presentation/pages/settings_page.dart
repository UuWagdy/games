import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/features/teams/presentation/pages/teams_management_page.dart';
import 'package:games/features/questions/presentation/pages/questions_management_page.dart';
import 'package:games/features/games/wheel/presentation/pages/wheel_settings_page.dart';

import 'package:games/features/settings/presentation/pages/general_settings_page.dart';

import 'package:games/features/settings/presentation/pages/about_page.dart';

class SettingsPage extends ConsumerWidget {
  final int initialIndex;
  const SettingsPage({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', height: 40),
              const SizedBox(width: 8),
              const Text('GAMES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
            ],
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.settings), text: 'عام'),
              Tab(icon: Icon(Icons.group), text: 'الفرق'),
              Tab(icon: Icon(Icons.help_center), text: 'الأسئلة والأنواع'),
              Tab(icon: Icon(Icons.settings_suggest), text: 'عجلة الحظ'),
              Tab(icon: Icon(Icons.info_outline), text: 'عن البرنامج'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            GeneralSettingsPage(),
            TeamsManagementPage(),
            QuestionsManagementPage(),
            WheelSettingsPage(),
            AboutPage(),
          ],
        ),
      ),
    );
  }
}
