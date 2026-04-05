import 'dart:async';
import 'dart:convert';

import 'package:common_gamekit/common_gamekit.dart';
import 'package:eco_sort_game/src/domain/bin_type.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/eco_sort_flame_game.dart';

enum EcoSortMenuAction { resume, restart, exit }

extension BinTypeLabels on BinType {
  String labelPt() {
    switch (this) {
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
}

class EcoSortPage extends StatefulWidget {
  final ScoreRepository scoreRepo;

  const EcoSortPage({super.key, required this.scoreRepo});

  @override
  State<EcoSortPage> createState() => _EcoSortPageState();
}

class _EcoSortPageState extends State<EcoSortPage> with WidgetsBindingObserver {
  late EcoSortFlameGame _game;

  bool _saved = false;

  StreamSubscription<EcoSortFeedback>? _feedbackSub;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _lockLandscape();

    _createNewGame();
  }

  void _createNewGame() {
    _feedbackSub?.cancel();

    _game = EcoSortFlameGame();

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

  Future<void> _openMenu() async {
    _game.pauseEngine();

    while (mounted) {
      final action = await showGameMenuDialog<EcoSortMenuAction>(
        context: context,
        title: 'ECO SORT - MENU',
        icon: const Icon(
          Icons.delete_outline,
          size: 42,
          color: Color.fromARGB(255, 128, 174, 121),
        ),
        items: const [
          GameMenuItem(label: 'Retomar Jogo', value: EcoSortMenuAction.resume , icon: Icon(Icons.play_arrow)),
          GameMenuItem(
            label: 'Reiniciar Jogo',
            value: EcoSortMenuAction.restart,
            icon: Icon(Icons.refresh),
          ),
          GameMenuItem(
            label: 'Sair do Jogo',
            value: EcoSortMenuAction.exit,
            isDestructive: true,
            icon: Icon(Icons.exit_to_app),

          ),
        ],
      );

      if (!mounted) return;

      switch (action) {
        case null:
        case EcoSortMenuAction.resume:
          _game.resumeEngine();
          return;

        case EcoSortMenuAction.restart:
          setState(() {
            _saved = false;
            _createNewGame();
          });
          return;

        case EcoSortMenuAction.exit:
          final confirmed = await showConfirmExitDialog(context);
          if (!mounted) return;

          if (confirmed) {
            await _trySave(EndReason.backToHub);
            if (mounted) Navigator.of(context).pop();
            return;
          }

          // Cancelou saída -> volta ao menu
          continue;
      }
    }
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
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _openMenu();
      },
      child: Scaffold(
        body: Stack(
          children: [
            GameWidget(game: _game),

            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: IconButton(
                    iconSize: 28,
                    icon: const Icon(Icons.pause, color: Colors.white),
                    onPressed: _openMenu,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
