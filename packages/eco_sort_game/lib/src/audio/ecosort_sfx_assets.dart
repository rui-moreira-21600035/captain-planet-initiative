import 'package:common_gamekit/common_gamekit.dart';

abstract final class EcoSortSfxAssets {
  static const correct = SfxAsset(key: 'correct', path: 'packages/eco_sort_game/assets/sfx/correct.wav');
  static const wrong = SfxAsset(key: 'wrong', path: 'packages/eco_sort_game/assets/sfx/wrong.wav');
  static const clockTickTock = SfxAsset(key: 'clock_tick_tock', path: 'packages/eco_sort_game/assets/sfx/clock_tick_tock.wav');

  static const all = [
    correct,
    wrong,
    clockTickTock
  ];
}