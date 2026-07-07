import 'package:common_gamekit/common_gamekit.dart';

import 'presentation/ocean_clean_game_page.dart';

GameModule oceanCleanModule(ScoreRepository repo) => GameModule(
      id: 'ocean_clean',
      name: 'Ocean Clean',
      description: 'Limpa o lixo do oceano!',

      coverAsset: 'packages/ocean_clean_game/assets/images/ocean_clean_bg.png',
      pageBuilder: () => OceanCleanPage(scoreRepo: repo),
    );