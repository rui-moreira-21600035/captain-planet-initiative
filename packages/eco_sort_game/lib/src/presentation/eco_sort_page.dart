import 'dart:async';
import 'dart:convert';

import 'package:common_gamekit/common_gamekit.dart';
import 'package:eco_sort_game/src/domain/bin_type.dart';
import 'package:eco_sort_game/src/domain/ecosort_difficulty_config.dart';
import 'package:eco_sort_game/src/domain/ecosort_game_result.dart';
import 'package:eco_sort_game/src/domain/ecosort_feedback.dart';
import 'package:eco_sort_game/src/game/components/eco_sort_result_dialog.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/eco_sort_flame_game.dart';

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
  final GameDifficulty initialDifficulty;

  const EcoSortPage({
    super.key,
    required this.scoreRepo,
    this.initialDifficulty = GameDifficulty.easy});

  @override
  State<EcoSortPage> createState() => _EcoSortPageState();
}

class _EcoSortPageState extends State<EcoSortPage> with WidgetsBindingObserver {
  bool _started = false;
  GameDifficulty? _selectedDifficulty;
  EcoSortFlameGame? _game;
  
  StreamSubscription<EcoSortFeedback>? _feedbackSub;
  StreamSubscription<EcoSortGameResult>? _resultSub;

  bool _saved = false;

  @override
  void initState() {
    super.initState();

    // Fullscreen (esconde status + nav bars)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    WidgetsBinding.instance.addObserver(this);
    _lockLandscape();

    _selectedDifficulty = widget.initialDifficulty;

    WidgetsBinding.instance.addPostFrameCallback((_) async{
      if (_started) return;
      _started = true;
      
      final started = await _startNewGameWithDifficultyPicker();
      if (!mounted) return;

      if (!started){
        Navigator.of(context).pop();
      }
    });

    // _createNewGame(_selectedDifficulty);
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
      _createNewGame();
    });
    return true;
  }

  void _createNewGame() {
    _feedbackSub?.cancel();
    _resultSub?.cancel();

    _saved = false;

    final difficulty = _selectedDifficulty ?? widget.initialDifficulty;

    final game = EcoSortFlameGame(difficulty: difficulty);

    _game = game;

    _feedbackSub = game.feedbackStream.listen((fb) {
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

    _resultSub = game.resultStream.listen((result) async {
      if (!mounted) return;

      await _trySave(EndReason.completed);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => EcoSortResultDialog(result: result),
      );

      if (!mounted) return;

      while(mounted){
        final action = await showGameMenuDialog<GameMenuAction>(
          context: context,
          title: 'ECO SORT - MENU',
          headerBadge: DifficultyBadge(
            difficulty: _selectedDifficulty ?? GameDifficulty.easy,
          ),
          items: const [
            //GameMenuItem(label: 'Retomar Jogo', value: GameMenuAction.resume, icon: Icon(Icons.play_arrow)),
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
          case GameMenuAction.restart:
            final restarted = await _startNewGameWithDifficultyPicker();

            if(!mounted) return;

            if (restarted){
              // User seleccionou dificuldade e clicou no botão começar
              return;
            }

            // Cancelou reinicio -> volta ao menu
            continue;

          case GameMenuAction.exit:
          case null:
            final confirmed = await showConfirmExitDialog(context);
            if (!mounted) return;

            if (confirmed) {
              await _trySave(EndReason.backToHub);
              if (mounted){
                Navigator.of(context).pop(result);
              }
              return;
            }

            // Cancelou saída: volta ao menu de fim de jogo.
            continue;
            
          case GameMenuAction.resume:
            continue;
        }
      }
    });
  }

  Future<void> _openMenu({bool pauseGame = true, bool gameFinished = false}) async {
    final game = _game;
    if(game == null) return;

    if (pauseGame && !gameFinished){
      game.pauseEngine();
    }

    while (mounted) {
      final action = await showGameMenuDialog<GameMenuAction>(
        context: context,
        title: 'ECO SORT - MENU',
        icon: const Icon(
          Icons.delete_outline,
          size: 42,
          color: Color.fromARGB(255, 128, 174, 121),
        ),
        items: const [
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
          if(!mounted) return;

          if (restarted){
            // User seleccionou dificuldade e clicou no botão começar
            return;
          }

        case GameMenuAction.exit:
          final confirmed = await showConfirmExitDialog(context);
          if (!mounted) return;

          if (confirmed) {
            //await _trySave(EndReason.backToHub);
            Navigator.of(context).pop();
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

  // --- AQUI está a lógica de persistência ---
  Future<void> _trySave(EndReason reason) async {
    if (_saved) return;

    final game = _game;
    if (game == null) return;

    _saved = true;

    final result = game.buildResult(reason);

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
      'difficulty': _selectedDifficulty?.name,
      'roundDurationSeconds': _selectedDifficulty?.roundDurationSeconds,
      'configuredTotalRounds': _selectedDifficulty?.totalRounds,
      'endReason': reason.name,
      'correct': result.correct,
      'wrong': result.wrong,
      'streakMax': result.streakMax,
      'durationMs': result.durationMs,
      'roundsPlayed': result.totalRoundsPlayed,
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
        syncedAt: null,
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
            if (_game == null)
              const Center(child: CircularProgressIndicator(),
              )
            else
              GameWidget(game: _game!),

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
