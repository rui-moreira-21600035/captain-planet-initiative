import 'package:flutter/material.dart';

import '../launcher/games_page.dart';
import '../scores/scores_page.dart';
import '../settings/settings_page.dart';

class AppTabConfig {
  const AppTabConfig({
    required this.label,
    required this.icon,
    required this.title,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final String title;
  final WidgetBuilder builder;
}

sealed class AppTabs {
  static const games = AppTabConfig(
    label: 'Jogos',
    icon: Icons.sports_esports_outlined,
    title: 'Jogos',
    builder: _buildGamesPage,
  );

  static const scores = AppTabConfig(
    label: 'Pontuações',
    icon: Icons.emoji_events_outlined,
    title: 'Pontuações',
    builder: _buildScoresPage,
  );

  static const settings = AppTabConfig(
    label: 'Definições',
    icon: Icons.settings_outlined,
    title: 'Definições',
    builder: _buildSettingsPage,
  );

  static const all = [games, scores, settings];

  static Widget _buildGamesPage(BuildContext context) => const GamesPage();
  static Widget _buildScoresPage(BuildContext context) => const ScoresPage();
  static Widget _buildSettingsPage(BuildContext context) => const SettingsPage();
}
