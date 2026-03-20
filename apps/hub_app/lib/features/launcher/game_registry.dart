import 'package:common_gamekit/common_gamekit.dart';
import 'package:eco_sort_game/eco_sort_game.dart';
import 'package:eco_guess_game/eco_guess_game.dart';

import '../../app/di.dart';

List<GameModule> buildGameRegistry() => [
      ecoSortModule(AppDi.scoreRepo),
      ecoGuessModule(AppDi.scoreRepo),
    ];