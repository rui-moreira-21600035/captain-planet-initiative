import 'dart:async';
import 'dart:convert';

import 'package:common_gamekit/common_gamekit.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:eco_proto_game/src/game/eco_proto_flame_game.dart';

enum GameLoadState { booting, loading, ready, error }

enum EndReason { backToHub, appPaused, appDetached }

enum EcoProtoMenuAction { resume, restart, exit }

class EcoProtoPage extends StatefulWidget {
  final ScoreRepository scoreRepo;

  const EcoProtoPage({super.key, required this.scoreRepo});

  @override
  State<EcoProtoPage> createState() => _EcoProtoPageState();
}

class _EcoProtoPageState extends State<EcoProtoPage>
    with WidgetsBindingObserver {
  late EcoProtoFlameGame _game;
  bool _saved = false;

  StreamSubscription<EcoProtoFeedback>? _feedbackSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockLandscape();
    _createNewGame();
  }

  void _createNewGame() {
    _feedbackSub?.cancel();

    _game = EcoProtoFlameGame();

    _feedbackSub = _game.feedbackStream.listen((fb) {
      if (!mounted) return;

      final msg = fb.isCorrect
          ? '✓ Acertaste!'
          : '✗ Errado! Era ${fb.target.title}.';

      final bgColor = fb.isCorrect ? Colors.green.shade700 : Colors.red.shade700;

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(milliseconds: 900),
            behavior: SnackBarBehavior.floating,
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: const EdgeInsets.only(
              left: 220,
              right: 220,
              bottom: 24,
            ),
          ),
        );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _trySave(EndReason.appPaused);
    } else if (state == AppLifecycleState.detached) {
      _trySave(EndReason.appDetached);
    }
  }

  @override
  void dispose() {
    _feedbackSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _trySave(EndReason.backToHub);
    _restoreOrientation();
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

  Future<void> _openMenu() async {
    _game.pauseEngine();

    while (mounted) {
      final action = await showGameMenuDialog<EcoProtoMenuAction>(
        context: context,
        title: 'ECO PROTO - MENU',
        icon: const Icon(Icons.science, size: 42),
        items: const [
          GameMenuItem(
            label: 'RETOMAR JOGO',
            value: EcoProtoMenuAction.resume,
            icon: Icon(Icons.play_arrow),
          ),
          GameMenuItem(
            label: 'REINICIAR JOGO',
            value: EcoProtoMenuAction.restart,
            icon: Icon(Icons.refresh),
          ),
          GameMenuItem(
            label: 'SAIR DO JOGO',
            value: EcoProtoMenuAction.exit,
            isDestructive: true,
            icon: Icon(Icons.logout),
          ),
        ],
      );

      if (!mounted) return;

      switch (action) {
        case null:
        case EcoProtoMenuAction.resume:
          _game.resumeEngine();
          return;

        case EcoProtoMenuAction.restart:
          setState(() {
            _saved = false;
            _createNewGame();
          });
          return;

        case EcoProtoMenuAction.exit:
          final confirmed = await showConfirmExitDialog(context);
          if (!mounted) return;

          if (confirmed) {
            await _trySave(EndReason.backToHub);
            if (mounted) Navigator.of(context).pop();
            return;
          }

          continue;
      }
    }
  }

  Future<void> _trySave(EndReason reason) async {
    if (_saved) return;
    _saved = true;

    final result = _game.buildResult(reason);

    final noAction = (result.correct + result.wrong) == 0;
    if (noAction) return;

    final metricsJson = jsonEncode({
      'gameId': 'eco_proto',
      'endReason': reason.name,
      'correct': result.correct,
      'wrong': result.wrong,
      'durationMs': result.durationMs,
      'roundsPlayed': result.totalRoundsPlayed,
    });

    final repo = widget.scoreRepo;
    final entry = ScoreEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      gameId: 'eco_proto',
      score: result.score,
      durationMs: result.durationMs,
      metricsJson: metricsJson,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      synced: false,
    );

    await repo.save(entry);
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
