import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games/features/teams/presentation/pages/teams_management_page.dart';
import 'package:games/features/questions/presentation/pages/questions_management_page.dart';
import 'package:games/features/games/wheel/presentation/pages/wheel_settings_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإعدادات'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.group), text: 'الفرق'),
              Tab(icon: Icon(Icons.help_center), text: 'الأسئلة والأنواع'),
              Tab(icon: Icon(Icons.settings_suggest), text: 'عجلة الحظ'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TeamsManagementPage(),
            QuestionsManagementPage(),
            WheelSettingsPage(),
          ],
        ),
      ),
    );
  }
}
