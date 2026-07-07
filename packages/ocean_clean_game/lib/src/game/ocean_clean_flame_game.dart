import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
//import 'package:flame/collisions.dart';

import 'package:common_gamekit/common_gamekit.dart';
import 'package:flutter/widgets.dart';
import 'package:ocean_clean_game/src/audio/ocean_clean_sfx.dart';
import 'package:ocean_clean_game/src/components/fish_component.dart';
import 'package:ocean_clean_game/src/components/net_component.dart';
import 'package:ocean_clean_game/src/components/ocean_clean_hud.dart';
import 'package:ocean_clean_game/src/components/trash_component.dart';
import 'package:ocean_clean_game/src/data/ocean_fact_catalog.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_difficulty_config.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_game_config.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_game_outcome.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_game_result.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_gameover_reason.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_layers.dart';
import 'package:ocean_clean_game/src/game/controllers/scoring_controller.dart';
import 'package:ocean_clean_game/src/game/controllers/trash_spawn_controller.dart';

class OceanCleanFlameGame extends FlameGame with HasCollisionDetection {
  // Asset keys de package
  static const String _pkg = 'packages/ocean_clean_game/';

  final OceanCleanGameConfig config;

  OceanCleanFlameGame({
    OceanCleanGameConfig? config,
  }) : config = config ?? OceanCleanGameConfig.defaultConfig();

  GameLoadState _state = GameLoadState.booting;

  late final OceanCleanScoringController _scoring = OceanCleanScoringController();

  final StreamController<OceanCleanGameResult> _resultCtrl =
      StreamController<OceanCleanGameResult>.broadcast();
  Stream<OceanCleanGameResult> get resultStream => _resultCtrl.stream;

  final _random = Random();

  double _elapsedSeconds = 0;

  // Fishes

  late final List<Sprite> _fishSprites;

  Future<void> _loadFishSprites() async {
    _fishSprites = await Future.wait([
      loadSprite('fishes/fish_1.png'),
      loadSprite('fishes/fish_2.png'),
      loadSprite('fishes/fish_3.png'),
      loadSprite('fishes/fish_4.png'),
      loadSprite('fishes/fish_5.png'),
      loadSprite('fishes/fish_6.png'),
      loadSprite('fishes/fish_7.png'),
      loadSprite('fishes/fish_8.png'),
      loadSprite('fishes/fish_9.png'),
      loadSprite('fishes/fish_10.png'),
      loadSprite('fishes/fish_11.png'),
      loadSprite('fishes/fish_12.png'),
      
    ]);
  }

  // Trash

  TrashSpawnController? _trashSpawnController;
  late final List<Sprite> _trashSprites;

  Future<void> _loadTrashSprites() async {
    _trashSprites = await Future.wait([
      loadSprite('trash/trash_1.png'),
      loadSprite('trash/trash_2.png'),
      loadSprite('trash/trash_3.png'),
      loadSprite('trash/trash_4.png'),
      loadSprite('trash/trash_5.png'),
      loadSprite('trash/trash_6.png'),
      loadSprite('trash/trash_7.png'),
      loadSprite('trash/trash_8.png'),
      loadSprite('trash/trash_9.png'),
      loadSprite('trash/trash_10.png'),
      loadSprite('trash/trash_11.png'),
      loadSprite('trash/trash_12.png'),
      loadSprite('trash/trash_13.png'),
      loadSprite('trash/trash_14.png'),
      loadSprite('trash/trash_15.png'),
    ]);
  }

  int get activeTrash => world.children.whereType<TrashComponent>().length;

  // Net

  late final Sprite _netSprite;
  late final NetComponent _net;

  Future<void> _loadNetSprite() async {
    _netSprite = await loadSprite('nets/net_1.png');
  }

  // Hud

  late final OceanCleanHud _hud;
  
  bool _gameFinished = false;
  late int _fishAlive;

  late final OceanFactCatalog _factCatalog;


  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Define o prefix no flame para assets de imagens do package
    images.prefix = '${_pkg}assets/images/';

    camera = CameraComponent.withFixedResolution(
      width: config.logicalResolution.x,
      height: config.logicalResolution.y,
    );

    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();

    camera.viewfinder.zoom = 1.05; // ~ 1.02–1.10 conforme o dispositivo

    add(camera);

    _state = GameLoadState.loading;

    Future.microtask(_loadGameData);
    
  }

  @override
  void onRemove() {
    _resultCtrl.close();
    super.onRemove();
  }

  Future<void> _loadGameData() async {
    final background = await Sprite.load('ocean_clean_bg.png');
    _fishAlive = OceanCleanDifficultyConfig(config.difficulty).initialFishCount;

    world.add(
      SpriteComponent()
        ..sprite = background
        ..size = config.logicalResolution
        ..anchor = Anchor.topLeft
        ..position = Vector2.zero()
        ..priority = 0,
    );

    _hud = OceanCleanHud(
      resolution: config.logicalResolution,
      gameDifficulty: config.difficulty,
    );

    camera.viewport.add(_hud);

    _hud.updateAll(
      score: _scoring.score,
      remaining: OceanCleanDifficultyConfig(config.difficulty).gameDuration,
      fishAlive: _fishAlive,
      fishTotal: OceanCleanDifficultyConfig(config.difficulty).initialFishCount,
    );

    await _loadFishSprites();
    await _loadTrashSprites();
    await _loadNetSprite();
    await SfxService.instance.loadAll(OceanCleanSfx.all);

    _trashSpawnController = TrashSpawnController(
      game: this,
      random: _random,
    );

    spawnFish();
    spawnNet();

    _factCatalog = await OceanFactCatalog.load();

    _state = GameLoadState.ready;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_state != GameLoadState.ready || _gameFinished) {
      return;
    }

    _elapsedSeconds += dt;

    _trashSpawnController?.update(dt);
    _hud.updateTime(remainingTime);

    if(remainingTime.inMilliseconds <= 0) {
      finishGame(
        outcome: _fishAlive > 0
          ? OceanCleanGameOutcome.victory
          : OceanCleanGameOutcome.defeat,
        reason: OceanCleanGameOverReason.timeExpired,
      );
    }
  }

  OceanCleanGameResult buildResult(EndReason reason) {
    //final now = DateTime.now().millisecondsSinceEpoch;
    return OceanCleanGameResult(
      score: _scoring.score,
      trashCollected: _scoring.trashCollected,
      fishInitialCount: _scoring.trashCollected, // This might need to be adjusted based on actual game logic
      fishRemaining: _scoring.trashCollected - _scoring.fishLost, // This might need to be adjusted based on actual game logic
      fishLost: _scoring.fishLost,
      duration: Duration(seconds: 30),//_rounds.duration,
      outcome: OceanCleanGameOutcome.quit, //_scoring.outcome,
      reason: OceanCleanGameOverReason.playerQuit, //_scoring.reason
      oceanFact: _factCatalog.random(_random),
      difficulty: config.difficulty,
    );
  }

  void spawnFish() {
    final zone = config.fishSafeZone;
    final verticalSpacing = zone.height / (OceanCleanDifficultyConfig(config.difficulty).initialFishCount - 1);

    _fishAlive = OceanCleanDifficultyConfig(config.difficulty).initialFishCount;

    final sprites = List<Sprite>.from(_fishSprites)
      ..shuffle(_random);

    for (var i = 0; i < OceanCleanDifficultyConfig(config.difficulty).initialFishCount; i++) {
      final sprite = sprites[i];

      final y = zone.top + verticalSpacing * i + (_random.nextDouble() * 16 - 8);
      final x = zone.left + _random.nextDouble() * zone.width;

      final fish = FishComponent(
        sprite: sprite,
        position: Vector2(x, y),
        size: Vector2(72, 48),
        baseY: y,
        minX: zone.left,
        maxX: zone.right,
        amplitude: 12 + _random.nextDouble() * 8,
        frequency: 0.8 + _random.nextDouble() * 0.5,
        horizontalSpeed: 20 + _random.nextDouble() * 10,
      )..priority = OceanCleanLayers.fish;

      world.add(fish);
    }
  }

  void spawnNet() {
    _net = NetComponent(
      sprite: _netSprite,
      position: Vector2(
        config.logicalResolution.x * 0.55,
        config.logicalResolution.y * 0.50,
      ),
      size: Vector2(96, 96),
    );

    world.add(_net);
  }

  void collectTrash(TrashComponent trash) {
    if (trash.isRemoving) {
      return;
    }

    trash.removeFromParent();

    _scoring.collectTrash();
    _hud.updateScore(_scoring.score);

    SfxService.instance.play(OceanCleanSfx.trashCollected);

    // _feedbackCtrl.add(
    //   OceanCleanFeedback.trashCollected(10),
    // );
  }

  int get activeTrashCount =>
    world.children.whereType<TrashComponent>().length;

  Sprite randomTrashSprite() {
    return _trashSprites[_random.nextInt(_trashSprites.length)];
  }

  double randomTrashY() {
    final zone = config.fishSafeZone;
    return zone.top + _random.nextDouble() * zone.height;
  }

  double get progress {
    final total = OceanCleanDifficultyConfig(config.difficulty).gameDuration.inSeconds;
    return (_elapsedSeconds / total).clamp(0.0, 1.0);
  }

  double get currentSpawnInterval {
    return OceanCleanDifficultyConfig(config.difficulty).spawnStart + (OceanCleanDifficultyConfig(config.difficulty).spawnEnd - OceanCleanDifficultyConfig(config.difficulty).spawnStart) * progress;
  }

  double get currentTrashSpeed {
    return OceanCleanDifficultyConfig(config.difficulty).speedStart + (OceanCleanDifficultyConfig(config.difficulty).speedEnd - OceanCleanDifficultyConfig(config.difficulty).speedStart) * progress;
  }

  Duration get remainingTime {
    final remainingMs = OceanCleanDifficultyConfig(config.difficulty).gameDuration.inMilliseconds - (_elapsedSeconds * 1000).round();
    return Duration(milliseconds: remainingMs.clamp(0, OceanCleanDifficultyConfig(config.difficulty).gameDuration.inMilliseconds));
  }

  void hitFish({required FishComponent fish, required TrashComponent trash}) {
    if (_gameFinished) return;
    if (fish.isRemoving || trash.isRemoving) return;

    fish.removeFromParent();
    trash.removeFromParent();

    _fishAlive = (_fishAlive - 1).clamp(0, OceanCleanDifficultyConfig(config.difficulty).initialFishCount);

    _scoring.loseFish();

    _hud.updateAll(
      score: _scoring.score,
      remaining: remainingTime,
      fishAlive: _fishAlive,
      fishTotal: OceanCleanDifficultyConfig(config.difficulty).initialFishCount,
    );

    SfxService.instance.play(OceanCleanSfx.fishHit);

    if (_fishAlive == 0) {
      finishGame(
        outcome: OceanCleanGameOutcome.defeat,
        reason: OceanCleanGameOverReason.allFishLost,
      );
    }
  }

  void finishGame({
    required OceanCleanGameOutcome outcome,
    required OceanCleanGameOverReason reason,
  }) {
    if (_gameFinished) return;

    _gameFinished = true;
    pauseEngine();

    if (outcome == OceanCleanGameOutcome.victory || outcome == OceanCleanGameOutcome.defeat) {
      _scoring.addSurvivalBonus(_fishAlive);
      _scoring.addTimeBonus(remainingTime.inSeconds);
    }

    final result = OceanCleanGameResult(
      score: _scoring.score,
      trashCollected: _scoring.trashCollected,
      fishInitialCount: OceanCleanDifficultyConfig(config.difficulty).initialFishCount,
      fishRemaining: _fishAlive,
      fishLost: OceanCleanDifficultyConfig(config.difficulty).initialFishCount - _fishAlive,
      duration: Duration(seconds: _elapsedSeconds.round()),
      outcome: outcome,
      reason: reason,
      oceanFact: _factCatalog.random(_random),
      difficulty: config.difficulty,
    );

    _resultCtrl.add(result);
  }

  @visibleForTesting
  void debugSetElapsedSeconds(double value) {
    _elapsedSeconds = value;
  }

  @visibleForTesting
  void debugSetFishAlive(int fishAlive) {
    _fishAlive = fishAlive;
  }
}