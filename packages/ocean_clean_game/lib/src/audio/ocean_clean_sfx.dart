import 'package:common_gamekit/common_gamekit.dart';

final class OceanCleanSfx {
  static const trashCollected = SfxAsset(
    key: 'ocean_clean_trash_collected',
    path: 'packages/ocean_clean_game/assets/sfx/trash_collected.wav',
  );

  static const fishHit = SfxAsset(
    key: 'ocean_clean_fish_hit',
    path: 'packages/ocean_clean_game/assets/sfx/fish_hit.wav',
  );

  static const all = [
    trashCollected,
    fishHit,
  ];

  const OceanCleanSfx._();
}