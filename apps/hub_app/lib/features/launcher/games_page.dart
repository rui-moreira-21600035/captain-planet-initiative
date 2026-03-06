import 'package:flutter/material.dart';

import 'game_registry.dart';

/// Displays the list of registered games.  This is effectively the previous
/// body of `LauncherPage` before the bottom navigation bar was introduced.
///
/// Keeping it in a separate widget makes it easy to switch between tabs and
/// keep the stateful navigation logic in the page that owns the
/// [BottomNavigationBar].
class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gameRegistry = buildGameRegistry();
    return ListView.separated(
      itemCount: gameRegistry.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final module = gameRegistry[index];
        return ListTile(
          key: Key(module.id),
          title: Text(module.name),
          subtitle: Text(module.description),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => module.pageBuilder()),
            );
          },
        );
      },
    );
  }
}
