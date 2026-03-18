import 'package:flutter/material.dart';
import '../../../../features/games/wheel/presentation/pages/wheel_game_page.dart';
import '../../../../features/settings/presentation/pages/settings_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const WheelGamePage(),
    const Center(child: Text('قريبًا: لعبة جديدة')),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.refresh),
            label: 'عجلة الحظ',
          ),
          NavigationDestination(
            icon: Icon(Icons.games),
            label: 'ألعاب أخرى',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}
