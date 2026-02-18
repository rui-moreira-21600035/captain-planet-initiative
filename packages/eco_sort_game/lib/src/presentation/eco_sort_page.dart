import 'dart:async';
import 'dart:convert';

import 'package:common_gamekit/common_gamekit.dart';
import 'package:eco_sort_game/src/domain/bin_type.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/eco_sort_flame_game.dart';

extension BinTypeLabels on BinType {
  String labelPt() {
    switch (this) {
      case BinType.blue: return 'azul';
      case BinType.green: return 'verde';
      case BinType.yellow: return 'amarelo';
      case BinType.brown: return 'castanho';
    }
  }
}

class EcoSortPage extends StatefulWidget {
  final ScoreRepository scoreRepo;

  const EcoSortPage({
    super.key,
    required this.scoreRepo,
  });

  @override
  State<EcoSortPage> createState() => _EcoSortPageState();
}

class _EcoSortPageState extends State<EcoSortPage> with WidgetsBindingObserver {
  late final EcoSortFlameGame _game;

  bool _saved = false;

  StreamSubscription<EcoSortFeedback>? _feedbackSub;

  String _binNamePt(BinType t) {
  switch (t) {
    case BinType.blue:
      return 'azul';
    case BinType.green:
      return 'verde';
    case BinType.yellow:
      return 'amarelo';
    case BinType.brown:
      return 'castanho';
  }
}

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _lockLandscape();

    _game = EcoSortFlameGame(); // já sem onGameOver

    _feedbackSub = _game.feedbackStream.listen((fb) {
      if (!mounted) return;

      final msg = fb.isCorrect
          ? '✅ Certo!'
          : '❌ Errado: o contentor correcto é o ${fb.expected.labelPt()}.';

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(milliseconds: 900),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black87,
            margin: const EdgeInsets.only(bottom: 24, left: 250, right: 250),
          ),
        );
    });
  }

  // --- LIFECYCLE: quando a app vai para background / detached ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _trySave(EndReason.appPaused);
    } else if (state == AppLifecycleState.detached) {
      _trySave(EndReason.appDetached);
    }
  }

  // --- GARANTIA: ao destruir a página, tenta guardar (fallback) ---
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trySave(EndReason.backToHub); // fallback (se não apanhou PopScope/paused)
    _restoreOrientation();
    _feedbackSub?.cancel();
    super.dispose();
  }

  Future<void> _lockLandscape() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restoreOrientation() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  // --- AQUI está a lógica de persistência ---
  Future<void> _trySave(EndReason reason) async {
    if (_saved) return;
    _saved = true;

    final result = _game.buildResult(reason);

    // Não guardar sessões “vazias”
    // (ajustar conforme necessário)
    final bool tooShort = result.durationMs < 5000; // < 5s
    final bool tooFewRounds = result.totalRoundsPlayed < 3;
    final bool noAction = (result.correct + result.wrong) == 0;

    if ((tooShort && tooFewRounds) || noAction) {
      return;
    }

    final metricsJson = jsonEncode({
      'gameId': 'eco_sort',
      'endReason': reason.name,
      'correct': result.correct,
      'wrong': result.wrong,
      'streakMax': result.streakMax,
      'durationMs': result.durationMs,
      'roundsPlayed': result.totalRoundsPlayed,
      // espaço para futuro:
      // 'difficulty': 'normal',
      // 'device': ...,
      // etc.
    });

    // Criar entrada (idealmente via helper do repo local)
    final repo = widget.scoreRepo;

    if (repo is LocalScoreRepositorySqflite) {
      final entry = repo.newEntry(
        gameId: 'eco_sort',
        score: result.score,
        durationMs: result.durationMs,
        metricsJson: metricsJson,
      );
      await repo.save(entry);
    } else {
      // fallback genérico (pior, mas compila)
      final entry = ScoreEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        gameId: 'eco_sort',
        score: result.score,
        durationMs: result.durationMs,
        metricsJson: metricsJson,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
        synced: false,
      );
      await repo.save(entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // O utilizador voltou ao hub (ou tentou)
        _trySave(EndReason.backToHub);
      },
      child: Scaffold(
        body: GameWidget(
          game: _game,
        ),
      ),
    );
  }
}