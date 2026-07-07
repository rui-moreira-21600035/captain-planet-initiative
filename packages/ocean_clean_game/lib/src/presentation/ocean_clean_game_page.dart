import 'dart:async';
import 'dart:convert';

import 'package:common_gamekit/common_gamekit.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_game_config.dart';

import 'package:ocean_clean_game/src/domain/ocean_clean_game_result.dart';
import 'package:ocean_clean_game/src/game/ocean_clean_flame_game.dart';
import 'package:ocean_clean_game/src/presentation/ocean_clean_game_over_dialog.dart';

class OceanCleanPage extends StatefulWidget {
  final ScoreRepository scoreRepo;
  final GameDifficulty initialDifficulty;


  const OceanCleanPage({
    super.key,
    required this.scoreRepo,
    this.initialDifficulty = GameDifficulty.easy,
  });

  @override
  State<OceanCleanPage> createState() => _OceanCleanPageState();
}

class _OceanCleanPageState extends State<OceanCleanPage> with WidgetsBindingObserver {
  bool _started = false;
  late GameDifficulty? _selectedDifficulty;
  OceanCleanFlameGame? _game;
  StreamSubscription<OceanCleanGameResult>? _resultSub;


  bool _saved = false;

  @override
  void initState() {
    super.initState();

     // Fullscreen (esconde status + nav bars)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    WidgetsBinding.instance.addObserver(this);
    _lockLandscape();

    _selectedDifficulty = widget.initialDifficulty;
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_started) return;
      _started = true;
      
      final started = await _startNewGameWithDifficultyPicker();
      if (!mounted) return;

      if (!started){
        Navigator.of(context).pop();
      }
    });

    //_createNewGame();
  }

  Future<bool> _startNewGameWithDifficultyPicker() async {
    final choice = await showDifficultyDialog(
      context,
      initial: _selectedDifficulty,
    );
    if (!mounted) return false;

    if (choice == null) {
      return false;
    }

    _selectedDifficulty = choice;

    setState(() {
      _selectedDifficulty = choice;
      _createNewGame();
    });
    return true;
  }

  void _createNewGame() {
    _resultSub?.cancel();

    _saved = false;

    final difficulty = _selectedDifficulty ?? widget.initialDifficulty;

    final game = OceanCleanFlameGame(
      config: OceanCleanGameConfig.defaultConfig(
        difficulty: difficulty,
      ),
    );

    _game = game;
    _resultSub = game.resultStream.listen(_handleGameResult);
  }

  Future<void> _handleGameResult(OceanCleanGameResult result) async {
    if (!mounted) return;

    await _saveResult(result, EndReason.completed);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => OceanCleanGameOverDialog(
        result: result,
        onContinue: () {
          Navigator.of(context).pop();
          _openMenu(gameFinished: true, pauseGame: false);
        },
      ),
    );
  }

  Future<void> _openMenu({bool pauseGame = true, bool gameFinished = false}) async {
    final game = _game;

    if (game == null) return;

    if (pauseGame && !gameFinished){
      game.pauseEngine();
    }
    while(mounted){
      final action = await showGameMenuDialog<GameMenuAction>(
        context: context,
        title: 'OCEAN CLEAN - MENU',
        icon: const Icon(
          Icons.water,
          size: 42,
          color: Color.fromARGB(255, 96, 131, 173),
        ),
        items: [
          if(!gameFinished)
            GameMenuItem(
              label: 'Retomar Jogo',
              value: GameMenuAction.resume,
              icon: Icon(Icons.play_arrow),
            ),
          GameMenuItem(
            label: 'Reiniciar Jogo',
            value: GameMenuAction.restart,
            icon: Icon(Icons.refresh),
          ),
          GameMenuItem(
            label: 'Sair do Jogo',
            value: GameMenuAction.exit,
            isDestructive: true,
            icon: Icon(Icons.exit_to_app),
          ),
        ],
      );

      if (!mounted) return;

      switch (action) {
        case null:
        case GameMenuAction.resume:
          if(!gameFinished){
            game.resumeEngine();
          }
          return;

        case GameMenuAction.restart:
          final restarted = await _startNewGameWithDifficultyPicker();
          if (!mounted) return;

          if (restarted) {
            return;
          }

        case GameMenuAction.exit:
          final confirmed = await showConfirmExitDialog(context);
          if (!mounted) return;

          if (confirmed) {
            // await _trySaveFromCurrentGame(EndReason.backToHub);
            Navigator.of(context).pop();
            return;
          } else {
            //_openMenu(gameFinished: true, pauseGame: false);
          }
          continue;
      }
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _trySaveFromCurrentGame(EndReason.appPaused);
    }

    if (state == AppLifecycleState.detached) {
      _trySaveFromCurrentGame(EndReason.appDetached);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _trySaveFromCurrentGame(EndReason.backToHub);
    _restoreOrientation();

    _resultSub?.cancel();

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

  Future<void> _trySaveFromCurrentGame(EndReason reason) async {
    final game = _game;
    
    if (game == null) return;

    if (_saved) return;

    final result = game.buildResult(reason);
    await _saveResult(result, reason);
  }

  Future<void> _saveResult(
    OceanCleanGameResult result,
    EndReason reason,
  ) async {
    if (_saved) return;
    _saved = true;

    final tooShort = result.duration < const Duration(seconds: 5);
    final noAction = result.trashCollected == 0 && result.fishLost == 0;

    if (tooShort && noAction) return;

    final metricsJson = jsonEncode({
      'gameId': 'ocean_clean',
      'endReason': reason.name,
      'trashCollected': result.trashCollected,
      'fishInitialCount': result.fishInitialCount,
      'fishRemaining': result.fishRemaining,
      'fishLost': result.fishLost,
      'durationMs': result.duration.inMilliseconds,
      'outcome': result.outcome.name,
      'reason': result.reason.name,
      'difficulty': _selectedDifficulty.toString(),
    });

    final repo = widget.scoreRepo;

    final entry = repo is LocalScoreRepositorySqflite
        ? repo.newEntry(
            gameId: 'ocean_clean',
            score: result.score,
            durationMs: result.duration.inMilliseconds,
            metricsJson: metricsJson,
          )
        : ScoreEntry(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            gameId: 'ocean_clean',
            score: result.score,
            durationMs: result.duration.inMilliseconds,
            metricsJson: metricsJson,
            createdAtMs: DateTime.now().millisecondsSinceEpoch,
            syncedAt: null,
          );

    await repo.save(entry);
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;

    if (game == null){
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _openMenu();
      },
      child: Scaffold(
        body: Stack(
          children: [
            GameWidget(game: game),
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