import 'package:common_gamekit/common_gamekit.dart';

import './presentation/eco_guess_page.dart';

GameModule ecoGuessModule(ScoreRepository repo) => GameModule(
      id: 'eco_guess',
      name: 'Eco Guess',
      description: 'Adivinha a palavra escondida.',
      pageBuilder: () => EcoGuessPage(scoreRepo: repo),
    );