import 'package:common_gamekit/common_gamekit.dart';
import 'package:flutter/material.dart';
import 'package:hub_app/features/games/widgets/game_cover_card.dart';

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
    return AppPagePadding(
      child: ListView.separated(
        itemCount: gameRegistry.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final module = gameRegistry[index];
          return GameCoverCard(
            key: Key(module.id),
            title: module.name,
            subtitle: module.description,
            coverAsset: module.coverAsset,
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => module.pageBuilder()));
            },
          );
        },
      ),
    );
  }
}
