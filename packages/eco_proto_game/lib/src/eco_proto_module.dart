import 'package:common_gamekit/common_gamekit.dart';

import 'presentation/eco_proto_page.dart';

GameModule ecoProtoModule(ScoreRepository repo) => GameModule(
      id: 'eco_proto',
      name: 'Eco Proto',
      description: 'Mini-jogo secreto experimental.',
      coverAsset: 'packages/eco_proto_game/assets/images/eco_proto_cover.png',
      pageBuilder: () => EcoProtoPage(scoreRepo: repo),
    );