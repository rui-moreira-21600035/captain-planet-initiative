import 'dart:async' as async;
import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart' hide Timer;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../domain/proto_character_data.dart';
import 'components/clickable_character_component.dart';

class EcoProtoGameResult {
  final int correct;
  final int wrong;
  final int score;
  final int durationMs;
  final int totalRoundsPlayed;

  const EcoProtoGameResult({
    required this.correct,
    required this.wrong,
    required this.score,
    required this.durationMs,
    required this.totalRoundsPlayed,
  });
}

class EcoProtoFeedback {
  final bool isCorrect;
  final ProtoCharacterData target;
  final ProtoCharacterData tapped;

  const EcoProtoFeedback({
    required this.isCorrect,
    required this.target,
    required this.tapped,
  });
}

class EcoProtoFlameGame extends FlameGame {
  late final int _startedAtMs;
  final Random _rng = Random();

  // Asset keys de package
  static const String _pkg = 'packages/eco_proto_game/';

  async.Timer? _roundTimeoutTimer;

  int _correctCount = 0;
  int _wrongCount = 0;
  int _score = 0;
  int _roundsPlayed = 0;

  bool _clickedInCurrentRound = false;

  ProtoCharacterData? _currentTarget;
  final List<ProtoCharacterData> _characters = [];

  SpriteComponent? _targetCard;
  TextComponent? _targetTitleText;
  TextComponent? _scoreText;

  final List<ClickableCharacterComponent> _optionComponents = [];

  final _feedbackController = StreamController<EcoProtoFeedback>.broadcast();

  Stream<EcoProtoFeedback> get feedbackStream => _feedbackController.stream;

  final List<ProtoCharacterData> _targetDeck = [];

  ProtoCharacterData? _lastTarget;

  void _resetTargetDeck() {
    _targetDeck
      ..clear()
      ..addAll(_characters)
      ..shuffle(_rng);

    if (_lastTarget != null &&
        _targetDeck.isNotEmpty &&
        _targetDeck.last.id == _lastTarget!.id &&
        _targetDeck.length > 1) {
      final swap = _targetDeck.last;
      _targetDeck[_targetDeck.length - 1] = _targetDeck[0];
      _targetDeck[0] = swap;
    }
  }

  @override
  Future<void> onLoad() async {
    // CRÍTICO:
    // o Images do Flame mete prefix "assets/images/" por defeito.
    // Aqui queremos carregar por asset key completa (packages/.../assets/...)
    images.prefix = '${_pkg}assets/images/'; // <-- desliga prefix automático

    _startedAtMs = DateTime.now().millisecondsSinceEpoch;

    await images.loadAll([
      'captain_planet_cyber.jpg',
      'captain_planet_female.jpg',
      'captain_planet_male.jpg',
      'dummy_cyber.jpg',
      'dummy_female.jpg',
      'dummy_male.jpg',
    ]);

    _characters.addAll([
      const ProtoCharacterData(
        id: 'cyber_captain_planet',
        title: 'Cyber Captain Planet',
        targetImagePath: 'dummy_cyber.jpg',
        optionImagePath: 'captain_planet_cyber.jpg',
      ),
      const ProtoCharacterData(
        id: 'female_captain_planet',
        title: 'Female Captain Planet',
        targetImagePath: 'dummy_female.jpg',
        optionImagePath: 'captain_planet_female.jpg',
      ),
      const ProtoCharacterData(
        id: 'male_captain_planet',
        title: 'Male Captain Planet',
        targetImagePath: 'dummy_male.jpg',
        optionImagePath: 'captain_planet_male.jpg',
      ),
    ]);

    await _buildStaticLayout();
    _prepareNextRound();
  }

  Future<void> _buildStaticLayout() async {
    final leftPanelWidth = size.x * 0.35;
    final rightStartX = leftPanelWidth;
    final rightWidth = size.x - rightStartX;

    final cardWidth = size.x * 0.15;
    final cardHeight = size.y * 0.50;

    // Componente esquerdo (1/3 do ecrã)
    final leftPanel = RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(leftPanelWidth, size.y),
      paint: Paint()..color = const Color.fromARGB(255, 83, 83, 88), // Cinza escuro,
    );
    await add(leftPanel);

    // Componente direito (2/3 do ecrã)
    final rightPanel = RectangleComponent(
      position: Vector2(leftPanelWidth, 0),
      size: Vector2(size.x - leftPanelWidth, size.y),
      paint: Paint()..color = const Color.fromARGB(255, 225, 226, 225), // Bege claro,
    );
    await add(rightPanel);

    _targetCard = SpriteComponent(
      sprite: Sprite(images.fromCache('dummy_female.jpg')),
      position: Vector2(leftPanelWidth * 0.5, size.y / 2),
      size: Vector2(cardWidth, cardHeight),
      anchor: Anchor.center,
    );
    await add(_targetCard!);

    _targetTitleText = TextComponent(
      text: 'Título',
      position: Vector2(rightStartX + rightWidth / 2, size.y * 0.12),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.blue.shade600,
          fontSize: size.y * 0.055,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    await add(_targetTitleText!);

    _scoreText = TextComponent(
      text: 'Certas: 0 | Erradas: 0',
      position: Vector2(size.x - 85, 20),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.blue.shade600,
          fontSize: size.y * 0.04,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    await add(_scoreText!);

    await _buildOptionCards(
      leftPanelWidth: leftPanelWidth,
      rightWidth: rightWidth,
    );
  }

  Future<void> _buildOptionCards({
    required double leftPanelWidth,
    required double rightWidth,
  }) async {

    final cardWidth = size.x * 0.15;
    final cardHeight = size.y * 0.50;
    final gap = rightWidth * 0.03;

    final totalCardsWidth = (cardWidth * 3) + (gap * 2);
    final firstX =
        leftPanelWidth + ((rightWidth - totalCardsWidth) / 2) + (cardWidth / 2);
    final centerY = size.y / 2;
    
    final positions = <Vector2>[
      Vector2(firstX, centerY),
      Vector2(firstX + cardWidth + gap, centerY),
      Vector2(firstX + (cardWidth + gap) * 2, centerY),
    ];

    for (var i = 0; i < _characters.length; i++) {
      final entry = _characters[i];
      final sprite = Sprite(images.fromCache(entry.optionImagePath));

      final component = ClickableCharacterComponent(
        data: entry,
        sprite: sprite,
        position: positions[i],
        size: Vector2(cardWidth, cardHeight),
        onTapCharacter: _onCharacterTapped,
      );

      _optionComponents.add(component);
      await add(component);
    }
  }

  ProtoCharacterData _pickNextTarget() {
    if (_characters.isEmpty) {
      throw StateError('No characters available.');
    }

    if (_targetDeck.isEmpty) {
      _resetTargetDeck();
    }

    final next = _targetDeck.removeLast();
    _lastTarget = next;
    return next;
  }

  void _showTarget(ProtoCharacterData target) {
    _targetTitleText?.text = target.title;
    _targetCard?.sprite = Sprite(images.fromCache(target.targetImagePath));
  }

  void _updateHud() {
    _scoreText?.text = 'Certas: $_correctCount | Erradas: $_wrongCount';
  }

  void _prepareNextRound() {
    _roundsPlayed++;
    _clickedInCurrentRound = false;

    _currentTarget = _pickNextTarget();
    _showTarget(_currentTarget!);
    _updateHud();

    _roundTimeoutTimer?.cancel();
    _roundTimeoutTimer = async.Timer(
      const Duration(seconds: 4),
      _onRoundTimeout,
    );
  }

  void _onCharacterTapped(ProtoCharacterData tapped) {
    if (_clickedInCurrentRound) return;
    _clickedInCurrentRound = true;

    _roundTimeoutTimer?.cancel();

    final isCorrect = _currentTarget != null && tapped.id == _currentTarget!.id;

    if (_currentTarget != null) {
      _feedbackController.add(
        EcoProtoFeedback(
          isCorrect: isCorrect,
          target: _currentTarget!,
          tapped: tapped,
        ),
      );
    }

    if (isCorrect) {
      _correctCount++;
      _score += 100;
    } else {
      _wrongCount++;
    }

    _updateHud();

    async.Future.delayed(const Duration(milliseconds: 500), () {
      _prepareNextRound();
    });
  }

  void _onRoundTimeout() {
    if (_clickedInCurrentRound) return;

    _clickedInCurrentRound = true;
    _wrongCount++;
    _updateHud();

    Future.delayed(const Duration(milliseconds: 500), () {
      _prepareNextRound();
    });
  }

  EcoProtoGameResult buildResult(dynamic endReason) {
    final durationMs = DateTime.now().millisecondsSinceEpoch - _startedAtMs;

    return EcoProtoGameResult(
      correct: _correctCount,
      wrong: _wrongCount,
      score: _score,
      durationMs: durationMs,
      totalRoundsPlayed: _roundsPlayed,
    );
  }

  @override
  void onRemove() {
    _roundTimeoutTimer?.cancel();
    super.onRemove();
  }
}
