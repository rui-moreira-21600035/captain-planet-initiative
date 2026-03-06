import 'package:flutter/material.dart';

import 'app_tab.dart';
import 'main_navigation_bar.dart';

class LauncherShell extends StatefulWidget {
  const LauncherShell({super.key});

  @override
  State<LauncherShell> createState() => _LauncherShellState();
}

class _LauncherShellState extends State<LauncherShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentTab = AppTabs.all[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentTab.title),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: AppTabs.all
            .map(
              (tab) => KeyedSubtree(
                key: ValueKey(tab.label),
                child: tab.builder(context),
              ),
            )
            .toList(),
      ),
      bottomNavigationBar: MainNavigationBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
