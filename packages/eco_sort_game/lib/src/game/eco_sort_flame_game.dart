import 'dart:async';
import 'dart:math' as math;

import 'package:eco_sort_game/src/domain/bin_type_mapper.dart';
import 'package:eco_sort_game/src/game/components/countdown_ring_component.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../data/catalog/catalog_loader.dart';
import '../domain/bin_type.dart';
import '../domain/waste_item.dart';
import 'components/bin_component.dart';
import 'components/waste_item_component.dart';
import 'controllers/round_controller.dart';
import 'controllers/scoring_controller.dart';
import 'components/eco_sort_hud_component.dart';

enum GameLoadState { booting, loading, ready, error }

enum EndReason { backToHub, appPaused, appDetached }

class EcoSortGameResult {
  final int score;
  final int correct;
  final int wrong;
  final int streakMax;
  final int durationMs;
  final int totalRoundsPlayed;
  final EndReason reason;

  const EcoSortGameResult({
    required this.score,
    required this.correct,
    required this.wrong,
    required this.streakMax,
    required this.durationMs,
    required this.totalRoundsPlayed,
    required this.reason,
  });
}

/// Evento para a UI Flutter mostrar toast/snackbar
class EcoSortFeedback {
  final bool isCorrect;
  final BinType chosen;
  final BinType expected;
  final WasteItem item;

  const EcoSortFeedback({
    required this.isCorrect,
    required this.chosen,
    required this.expected,
    required this.item,
  });
}

class EcoSortFlameGame extends FlameGame {
  static Vector2 logicalResolution = Vector2(1280, 720);
  late Vector2 _wasteFrameCenter;
  late Vector2 _wasteFrameSize;

  // Asset keys de package
  static const String _pkg = 'packages/eco_sort_game/';

  GameLoadState _state = GameLoadState.booting;

  late final CatalogLoader _catalogLoader;
  late final ScoringController _scoring;
  late RoundController _rounds;

  List<WasteItem> _items = const [];
  final Map<BinType, BinComponent> _binComps = {};
  bool _inputLocked = false;
  final Map<BinType, Sprite> _binSprites = {};
  final Map<String, Sprite> _itemSprites = {};

  late WasteItemComponent _waste;
  final _rng = math.Random();
  WasteItem? _lastItem;

  int _startMs = 0;

  TextComponent? _loadingText;
  TextComponent? _errorText;

  static const double roundSeconds = 10.0;

  late TimerComponent _roundTimerComp;
  double _timeLeft = roundSeconds;
  double _getTimeLeft() => _timeLeft;
  TextComponent? _timerText;

  // Feedback stream
  final StreamController<EcoSortFeedback> _feedbackCtrl = StreamController<EcoSortFeedback>.broadcast();
  Stream<EcoSortFeedback> get feedbackStream => _feedbackCtrl.stream;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // CRÍTICO:
    // o Images do Flame mete prefix "assets/images/" por defeito.
    // Aqui queremos carregar por asset key completa (packages/.../assets/...)
    images.prefix = '${_pkg}assets/images/'; // <-- desliga prefix automático

    // Define o prefixo para os assets no Flame Images
    //images.prefix = _pkg + images.prefix;

    camera = CameraComponent.withFixedResolution(
      width: logicalResolution.x,
      height: logicalResolution.y,
    );

    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();

    camera.viewfinder.zoom = 1.05; // ajusta entre 1.02–1.10 conforme o device

    add(camera);

    _scoring = ScoringController();
    _catalogLoader = CatalogLoader();

    _buildBootScene();
    _state = GameLoadState.loading;

    // Importante: NÃO FAZER loads pesado aqui dentro.
    Future.microtask(_loadGameData);
  }

  @override
  void onRemove() {
    _feedbackCtrl.close();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_state != GameLoadState.ready) return;

    // countdown
    _timeLeft = (_timeLeft - dt).clamp(0.0, roundSeconds);
    _timerText?.text = 'Tempo: ${_timeLeft.ceil()}';
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

    // _timerText = TextComponent(
    //   text: 'Tempo: 10',
    //   position: Vector2(logicalResolution.x * 0.30 + 30, 20), // começa no painel direito
    //   anchor: Anchor.topLeft,
    //   textRenderer: TextPaint(
    //     style: const TextStyle(fontSize: 28, color: Color(0xFF1E63C5)),
    //   ),
    //   priority: 1000,
    // );
    // camera.viewport.add(_timerText!);

    // Coloca no viewport para ficar estático
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

        // feedback para UI
        _feedbackCtrl.add(EcoSortFeedback(
          isCorrect: false,
          chosen: current.bin,     // ou um valor “dummy”
          expected: current.bin,
          item: current,
        ));
      }

      add(TimerComponent(
        period: 0.65,
        removeOnFinish: true,
        onTick: () {
          _inputLocked = false;
          _nextRound();
        },
      ));
    }

  Future<void> _loadGameData() async {
    try {
      final catalog = await _catalogLoader.load();

      // Items (data -> domínio)
      _items = catalog.items.map((i) {
        return WasteItem(
          id: i.id,
          label: i.label,
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

    // TODO: Criar uma progress bar até ao final da ronda (Progressbar/ Ronda X de Y)

    final w = logicalResolution.x;
    final h = logicalResolution.y;
    final leftW = logicalResolution.x * 0.30;

    // Frame lógico para o item no painel esquerdo (centrado, com margens)
    final frameCenter = Vector2(leftW * 0.5, h * 0.52);
    final frameSize   = Vector2(leftW * 0.75, h * 0.55);

    _wasteFrameCenter = Vector2(leftW * 0.5, h * 0.52);
    _wasteFrameSize   = Vector2(leftW * 0.75, h * 0.55);


    // 1) Background (preenche tudo)
    world.add(
      RectangleComponent(
        position: Vector2.zero(),
        size: Vector2(w, h),
        paint: Paint()..color = const Color.fromARGB(255, 225, 226, 225), // cor do fundo
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

    // 3) Frame para o lixo (centrado no painel esquerdo), invisível
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

    // 3) Lixo no painel esquerdo (centrado)
    _waste = WasteItemComponent(
      position: frameCenter,
    )
      ..anchor = Anchor.center
      ..size = frameSize;
    world.add(_waste);

    // 4) Bins em linha horizontal no painel direito
    final rightX = leftW;
    final rightW = w - rightX;

    final bins = <BinType>[
      BinType.blue,
      BinType.green,
      BinType.yellow,
      BinType.brown
    ];

    // Calcula tamanhos dos bins para caberem no painel direito, mantendo proporção e deixando espaço entre eles
    final maxBinHeight = h * 0.26; // aumenta se quiseres bins maiores (0.22–0.28)
    final gap = rightW * 0.04;     // reduz espaço (0.03–0.06)

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

    // Centra o grupo de bins inteiro no painel direito
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

    // 5) Painel/HUD direito (fundo semitransparente atrás do texto)
    final hudCardPos = Vector2(rightX + 12, 8);
    final hudCardSize = Vector2((w - rightX) - 24, 100);

    camera.viewport.add(
      RectangleComponent(
        position: hudCardPos,
        size: hudCardSize,
        paint: Paint()..color = const Color(0x14FFFFFF), // branco com pouca opacidade
        priority: 900, // atrás do texto (texto está 1000)
      ),
    );

    final hudTop = 24.0;
    final hudPad = 24.0;

    // 5.1) HUD no viewport (fixo no ecrã)
    camera.viewport.add(
      EcoSortHudComponent(
        scoring: _scoring,
        timeLeftSeconds: _getTimeLeft,
        position: Vector2(w - 30, hudTop),
        anchor: Anchor.topRight,
        priority: 1000,
      ),
    );

    // 5.2) Anel de contagem decrescente
    const ringSize = 80.0;

    camera.viewport.add(
      CountdownRingComponent(
        totalSeconds: roundSeconds,
        timeLeftSeconds: _getTimeLeft,
        position: Vector2(w - 40 -  hudPad - (ringSize / 2), hudTop + ringSize / 2),
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
    } else {
      _scoring.registerWrong();
      _binComps[chosen]?.playWrong();
      _binComps[expected]?.playHintCorrect(); // 👈 mostra o correcto
    }

    // Envia feedback para a UI (snackbar)
    _feedbackCtrl.add(EcoSortFeedback(
      isCorrect: isCorrect,
      chosen: chosen,
      expected: expected,
      item: current,
    ));

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

    WasteItem next;
    if (_items.length == 1) {
      next = _items.first;
    } else {
      do {
        next = _items[_rng.nextInt(_items.length)];
      } while (_lastItem != null && next.id == _lastItem!.id);
    }

    _lastItem = next;

    final sprite = _itemSprites[next.id];
    if (sprite == null) throw StateError('Sprite não encontrado para ${next.id}');

    _waste.setItem(next, sprite);
    _fitWasteIntoFrame(_wasteFrameSize);

    // (Opcional) se queres que também reinicie aqui:
    _resetRoundTimer();
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
    );
  }

  void restart() {
    if (_state != GameLoadState.ready) return;
    _scoring.reset();
    _rounds.reset();
    _startMs = DateTime.now().millisecondsSinceEpoch;
    _nextRound();
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

    // Guardrail final para nunca passar o limite vertical.
    final scaledH = srcH * scale;
    if (scaledH > maxH) {
      scale = maxH / srcH;
    }

    _waste.size = Vector2(srcW * scale, srcH * scale);

    // garante alinhamento com frame
    _waste.anchor = Anchor.center;
    // IMPORTANTÍSSIMO: não mexer aqui na posição — mantém o frameCenter
  }
}
