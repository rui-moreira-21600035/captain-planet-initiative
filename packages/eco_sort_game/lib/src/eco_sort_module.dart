import 'package:common_gamekit/common_gamekit.dart';

import './presentation/eco_sort_page.dart';

GameModule ecoSortModule(ScoreRepository repo) => GameModule(
      id: 'eco_sort',
      name: 'Eco Sort',
      description: 'Clica no contentor certo para cada item.',
      pageBuilder: () => EcoSortPage(scoreRepo: repo),
    );