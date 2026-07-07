import 'dart:async';

import 'package:eco_sort_game/src/audio/ecosort_sfx_assets.dart';
import 'package:eco_sort_game/src/domain/bin_type_mapper.dart';
import 'package:eco_sort_game/src/domain/wrong_answer_record.dart';
import 'package:eco_sort_game/src/game/components/countdown_ring_component.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../data/catalog/catalog_loader.dart';
import '../domain/bin_type.dart';
import '../domain/waste_item.dart';
import '../domain/ecosort_game_result.dart';
import '../domain/ecosort_feedback.dart';
import 'components/bin_component.dart';
import 'components/waste_item_component.dart';
import 'controllers/round_controller.dart';
import 'controllers/scoring_controller.dart';
import 'components/eco_sort_hud_component.dart';

import 'package:common_gamekit/common_gamekit.dart';

class EcoSortFlameGame extends FlameGame {
  static Vector2 logicalResolution = Vector2(1280, 720);
  late Vector2 _wasteFrameCenter;
  late Vector2 _wasteFrameSize;

  // Asset keys de package
  static const String _pkg = 'packages/eco_sort_game/';

  GameLoadState _state = GameLoadState.booting;

  final _soundEffectPlugin = SfxService.instance;

  final List<WrongAnswerRecord> _wrongAnswers = [];

  late final CatalogLoader _catalogLoader;
  late final ScoringController _scoring;
  late RoundController _rounds;
  static const int maxRoundsPerSession = 10;

  List<WasteItem> _items = const [];
  final Map<BinType, BinComponent> _binComps = {};
  bool _inputLocked = false;
  final Map<BinType, Sprite> _binSprites = {};
  final Map<String, Sprite> _itemSprites = {};

  late WasteItemComponent _waste;

  int _startMs = 0;

  TextComponent? _loadingText;
  TextComponent? _errorText;

  static const double roundSeconds = 10.0;

  int? _lastTickSecond;

  late TimerComponent _roundTimerComp;
  double _timeLeft = roundSeconds;
  double _getTimeLeft() => _timeLeft;

  // Feedback stream
  final StreamController<EcoSortFeedback> _feedbackCtrl =
      StreamController<EcoSortFeedback>.broadcast();
  Stream<EcoSortFeedback> get feedbackStream => _feedbackCtrl.stream;

  final StreamController<EcoSortGameResult> _resultCtrl =
      StreamController<EcoSortGameResult>.broadcast();
  Stream<EcoSortGameResult> get resultStream => _resultCtrl.stream;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Define o prefixo para os assets no Flame Images
    images.prefix = '${_pkg}assets/images/';

    await _soundEffectPlugin.init();

    camera = CameraComponent.withFixedResolution(
      width: logicalResolution.x,
      height: logicalResolution.y,
    );

    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();

    camera.viewfinder.zoom = 1.05; // ~ 1.02–1.10 conforme o dispositivo

    add(camera);

    _scoring = ScoringController();
    _catalogLoader = CatalogLoader();

    _buildBootScene();
    _state = GameLoadState.loading;

    // Não fazer loads pesados aqui dentro.
    Future.microtask(_loadGameData);
  }

  @override
  void onRemove() {
    _roundTimerComp.timer.stop();
    _feedbackCtrl.close();
    _resultCtrl.close();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_state != GameLoadState.ready) return;

    // countdown
    _timeLeft = (_timeLeft - dt).clamp(0.0, roundSeconds);
    _updateWarningTick();
  }

  void _updateWarningTick() {
    if (_state != GameLoadState.ready) return;
    if (_inputLocked) return;

    final seconds = _timeLeft.ceil();
    final shouldTick = seconds >= 1 && seconds <= 3;

    if (!shouldTick) {
      _lastTickSecond = null;
      return;
    }

    if (_lastTickSecond == seconds) return;

    _lastTickSecond = seconds;
    SfxService.instance.play(EcoSortSfxAssets.clockTickTock);

  }

  void _buildBootScene() {
    // Background
    world.add(
      RectangleComponent(
        size: logicalResolution,
        paint: Paint()..color = const Color(0xFF0B1320),
      ),
    );

    _loadingText = TextComponent(
      text: 'A carregar...',
      position: logicalResolution / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 34, color: Colors.white),
      ),
      priority: 1000,
    );

    camera.viewport.add(_loadingText!);
  }

  void _onRoundTimeout() {
    if (_state != GameLoadState.ready) return;
    if (_inputLocked) return;

    _inputLocked = true;

    final current = _waste.item;
    if (current != null) {
      _scoring.registerWrong();

      // Hint do contentor correcto
      _binComps[current.bin]?.playHintCorrect();
      _soundEffectPlugin.play(EcoSortSfxAssets.wrong);

      // feedback para UI
      _feedbackCtrl.add(
        EcoSortFeedback(
          isCorrect: false,
          chosen: current.bin,
          expected: current.bin,
          item: current,
        ),
      );
    }

    add(
      TimerComponent(
        period: 0.65,
        removeOnFinish: true,
        onTick: () {
          _inputLocked = false;
          _nextRound();
        },
      ),
    );
  }

  Future<void> _loadGameData() async {
    try {
      final catalog = await _catalogLoader.load();

      // Items (data -> domínio)
      _items = catalog.items.map((i) {
        return WasteItem(
          id: i.id,
          labelPt: i.labelPt,
          labelEn: i.labelEn,
          bin: BinTypeMapper.fromId(i.bin),
          asset: i.asset,
        );
      }).toList();

      if (_items.isEmpty) throw StateError('Catálogo sem items.');

      _rounds = RoundController(_items);

      // Sprites bins
      for (final b in catalog.bins) {
        final type = BinTypeMapper.fromId(b.id);
        final img = await images.load(b.asset);
        _binSprites[type] = Sprite(img);
      }

      // Sprites items
      for (final item in _items) {
        final img = await images.load(item.asset);
        _itemSprites[item.id] = Sprite(img);
      }

      await _buildScene();

      _startMs = DateTime.now().millisecondsSinceEpoch;
      _state = GameLoadState.ready;

      _loadingText?.removeFromParent();
      _loadingText = null;

      _roundTimerComp = TimerComponent(
        period: roundSeconds,
        repeat: false,
        removeOnFinish: false,
        onTick: _onRoundTimeout,
      );

      add(_roundTimerComp);
      _resetRoundTimer();

      _nextRound();
    } catch (e) {
      _state = GameLoadState.error;
      _loadingText?.removeFromParent();
      _loadingText = null;
      _showError(e);
      rethrow;
    }
  }

  void _showError(Object e) {
    _errorText = TextComponent(
      text: 'Erro a carregar: $e',
      position: logicalResolution / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 24, color: Colors.redAccent),
      ),
      priority: 1000,
    );
    camera.viewport.add(_errorText!);
  }

  Future<void> _buildScene() async {
    world.removeAll(world.children.toList());

    final w = logicalResolution.x;
    final h = logicalResolution.y;
    final leftW = logicalResolution.x * 0.30;

    // Frame lógico para o item no painel esquerdo (centrado, com margens)
    final frameCenter = Vector2(leftW * 0.5, h * 0.52);
    final frameSize = Vector2(leftW * 0.75, h * 0.55);

    _wasteFrameCenter = Vector2(leftW * 0.5, h * 0.52);
    _wasteFrameSize = Vector2(leftW * 0.75, h * 0.55);

    // 1) Background (preenche tudo)
    world.add(
      RectangleComponent(
        position: Vector2.zero(),
        size: Vector2(w, h),
        paint: Paint()
          ..color = const Color.fromARGB(255, 225, 226, 225), // cor do fundo
      ),
    );

    // 2) Painel esquerdo (30%)
    world.add(
      RectangleComponent(
        position: Vector2.zero(),
        size: Vector2(leftW, h),
        paint: Paint()..color = const Color.fromARGB(255, 85, 84, 89),
      ),
    );

    // 2.1) Frame para o lixo (centrado no painel esquerdo), invisível
    // Mantém a referência de layout sem desenhar borda.
    world.add(
      RectangleComponent(
        position: frameCenter,
        size: frameSize,
        anchor: Anchor.center,
        paint: Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0x00000000),
      ),
    );

    // 2.2) Lixo no painel esquerdo (centrado)
    _waste = WasteItemComponent(position: frameCenter)
      ..anchor = Anchor.center
      ..size = frameSize;
    world.add(_waste);

    // 3) Bins em linha horizontal no painel direito
    final rightX = leftW;
    final rightW = w - rightX;

    final bins = <BinType>[
      BinType.blue,
      BinType.green,
      BinType.yellow,
      BinType.brown,
    ];

    // 3.1) Calcula tamanhos dos bins para caberem no painel direito, mantendo proporção e deixando espaço entre eles
    final maxBinHeight =
        h * 0.26; // Altura dos bins
    final gap = rightW * 0.04; // reduz espaço entre bins para caber melhor

    final binSizes = <BinType, Vector2>{};
    double totalWidth = 0;

    for (final type in bins) {
      final sp = _binSprites[type]!;
      final srcW = sp.srcSize.x;
      final srcH = sp.srcSize.y;
      final scale = maxBinHeight / srcH;

      final size = Vector2(srcW * scale, srcH * scale);
      binSizes[type] = size;
      totalWidth += size.x;
    }
    totalWidth += gap * (bins.length - 1);

    // 3.2) Centra o grupo de bins inteiro no painel direito
    final startX = rightX + (rightW - totalWidth) / 2;
    final y = h * 0.50;

    var cursorX = startX;

    for (final type in bins) {
      final size = binSizes[type]!;

      final bin = BinComponent(
        binType: type,
        onChosen: _onBinChosen,
        sprite: _binSprites[type]!,
        position: Vector2(cursorX + size.x / 2, y),
        size: size,
        anchor: Anchor.center,
      );

      _binComps[type] = bin;
      world.add(bin);

      cursorX += size.x + gap;
    }

    // 4) Painel/HUD direito (fundo semitransparente atrás do texto)
    final hudCardPos = Vector2(rightX + 12, 8);
    final hudCardSize = Vector2((w - rightX) - 24, 100);

    camera.viewport.add(
      RectangleComponent(
        position: hudCardPos,
        size: hudCardSize,
        paint: Paint()
          ..color = const Color(0x14FFFFFF), // branco com pouca opacidade
        priority: 900, // atrás do texto (texto está 1000)
      ),
    );

    final hudTop = 24.0;
    final hudPad = 24.0;

    // 4.1) HUD no viewport (fixo no ecrã)
    camera.viewport.add(
      EcoSortHudComponent(
        scoring: _scoring,
        timeLeftSeconds: _getTimeLeft,
        position: Vector2(w - 30, hudTop),
        anchor: Anchor.topRight,
        priority: 1000,
      ),
    );

    // 4.2) Anel de contagem decrescente
    const ringSize = 80.0;

    camera.viewport.add(
      CountdownRingComponent(
        totalSeconds: roundSeconds,
        timeLeftSeconds: _getTimeLeft,
        position: Vector2(
          w - 40 - hudPad - (ringSize / 2),
          hudTop + ringSize / 2,
        ),
        size: Vector2.all(78),
        strokeWidth: 7,
      ),
    );
  }

  void _onBinChosen(BinType chosen) {
    if (_state != GameLoadState.ready) return;
    if (_inputLocked) return;

    final current = _waste.item;
    if (current == null) return;

    _inputLocked = true;

    final expected = current.bin;
    final isCorrect = expected == chosen;

    if (isCorrect) {
      _scoring.registerCorrect();
      _binComps[chosen]?.playCorrect();
      _soundEffectPlugin.play(EcoSortSfxAssets.correct);
    } else {
      _scoring.registerWrong();

      _wrongAnswers.add(
        WrongAnswerRecord(item: current, chosen: chosen, expected: expected),
      );

      _binComps[chosen]?.playWrong();
      _soundEffectPlugin.play(EcoSortSfxAssets.wrong);
      _binComps[expected]?.playHintCorrect(); // mostra o contentor correcto
    }

    // Envia feedback para a UI (snackbar)
    _feedbackCtrl.add(
      EcoSortFeedback(
        isCorrect: isCorrect,
        chosen: chosen,
        expected: expected,
        item: current,
      ),
    );

    // Dá tempo à animação antes de avançar
    add(
      TimerComponent(
        period: 0.65,
        removeOnFinish: true,
        onTick: () {
          _inputLocked = false;
          _nextRound();
        },
      ),
    );
  }

  void _nextRound() {
    if (_state != GameLoadState.ready) return;

    if (_rounds.totalRoundsPlayed >= maxRoundsPerSession) {
      _endGame(EndReason.completed);
      return;
    }

    final next = _rounds.nextOrLoop();

    final sprite = _itemSprites[next.id];
    if (sprite == null) {
      throw StateError('Sprite não encontrado para ${next.id}');
    }

    _waste.setItem(next, sprite);
    
    _waste.position = _wasteFrameCenter; // garante que o item começa centrado
    _fitWasteIntoFrame(_wasteFrameSize);

    _resetRoundTimer();
  }

  void _endGame(EndReason reason) {
    if (_state == GameLoadState.finished) return;

    _state = GameLoadState.finished;
    _inputLocked = true;
    _roundTimerComp.timer.stop();

    final result = buildResult(reason);

    if (!_resultCtrl.isClosed) {
      _resultCtrl.add(result);
    }
  }

  void _resetRoundTimer() {
    _timeLeft = roundSeconds;
    _roundTimerComp.timer.stop();
    _roundTimerComp.timer.start();
  }

  EcoSortGameResult buildResult(EndReason reason) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return EcoSortGameResult(
      score: _scoring.score,
      correct: _scoring.correct,
      wrong: _scoring.wrong,
      streakMax: _scoring.streakMax,
      durationMs: (now - _startMs).clamp(0, 1 << 30),
      totalRoundsPlayed: _rounds.totalRoundsPlayed,
      reason: reason,
      wrongAnswers: List.unmodifiable(_wrongAnswers),
    );
  }

  void _fitWasteIntoFrame(Vector2 frameSize) {
    final sp = _waste.sprite;
    if (sp == null) return;

    final maxW = frameSize.x * 0.90; // deixa margem horizontal
    final maxH = frameSize.y * 0.82; // cap vertical mais conservador

    final srcW = sp.srcSize.x;
    final srcH = sp.srcSize.y;
    if (srcW <= 0 || srcH <= 0) return;

    // Tenta normalizar a altura visual entre itens com rácios diferentes.
    final targetH = frameSize.y * 0.62;
    var scale = targetH / srcH;

    // Se ao normalizar altura exceder largura, reduz para caber.
    final scaledW = srcW * scale;
    if (scaledW > maxW) {
      scale = maxW / srcW;
    }

    // Baliza para nunca passar o limite vertical.
    final scaledH = srcH * scale;
    if (scaledH > maxH) {
      scale = maxH / srcH;
    }

    _waste.size = Vector2(srcW * scale, srcH * scale);

    // garante alinhamento com frame (centrodo, com margem vertical consistente)
    _waste.anchor = Anchor.center;
  }
}