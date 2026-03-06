import 'package:flutter/material.dart';

import 'app_tab.dart';

class MainNavigationBar extends StatelessWidget {
  const MainNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: AppTabs.all
          .map(
            (tab) => NavigationDestination(
              icon: Icon(tab.icon),
              label: tab.label,
            ),
          )
          .toList(),
    );
  }
}
