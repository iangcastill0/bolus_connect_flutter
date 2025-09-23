import 'package:flutter/material.dart';

import 'home_page.dart';
import 'logs_page.dart';
import 'bolus_page.dart';
import 'settings_page.dart';

class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key});

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  int _index = 0;
  final ValueNotifier<int> _bolusRefreshTick = ValueNotifier<int>(0);
  final ValueNotifier<int> _logsRefreshTick = ValueNotifier<int>(0);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      LogsPage(refreshTick: _logsRefreshTick),
      BolusPage(refreshTick: _bolusRefreshTick, logRefreshTick: _logsRefreshTick),
      const SettingsPage(),
    ];
  }

  @override
  void dispose() {
    _bolusRefreshTick.dispose();
    _logsRefreshTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 2) {
            _bolusRefreshTick.value++;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Logs'),
          NavigationDestination(icon: Icon(Icons.medical_services_outlined), selectedIcon: Icon(Icons.medical_services), label: 'Bolus'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
