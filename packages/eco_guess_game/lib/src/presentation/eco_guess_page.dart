import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eco_guess_game/src/application/state/eco_guess_session_state.dart';
import 'package:eco_guess_game/src/domain/models/round_status.dart';
import 'package:eco_guess_game/src/presentation/widgets/eco_lives_bar.dart';
import 'package:eco_guess_game/src/application/providers/providers.dart';
import 'package:eco_guess_game/src/domain/models/difficulty.dart';
import 'package:eco_guess_game/src/domain/services/masked_word.dart';
import 'package:eco_guess_game/src/presentation/widgets/round_progress_bar.dart';

import 'package:common_gamekit/common_gamekit.dart';

enum EcoGuessMenuAction { resume, restart, exit }

class EcoGuessPage extends ConsumerStatefulWidget {
  final ScoreRepository scoreRepo;
  final GameDifficulty? difficulty;

  const EcoGuessPage({super.key, required this.scoreRepo, this.difficulty});

  @override
  ConsumerState<EcoGuessPage> createState() => _EcoGuessPageState();
}

class _EcoGuessPageState extends ConsumerState<EcoGuessPage> {
  var _started = false;
  GameDifficulty _selectedDifficulty = GameDifficulty.easy;

  @override
  void initState() {
    super.initState();

    // Fullscreen (esconde status + nav bars)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_started) return;
      _started = true;

      final started = await _pickDifficultyAndStart();
      if (!mounted) return;

      if (!started) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<bool> _pickDifficultyAndStart() async {
    final choice = await showDifficultyDialog(
      context,
      initial: _selectedDifficulty,
    );
    if (!mounted) return false;

    if (choice == null) {
      return false;
    }

    _selectedDifficulty = choice;

    await ref
        .read(ecoGuessControllerProvider.notifier)
        .startGame(_selectedDifficulty);

    return true;
  }

  @override
  void dispose() {
    // Repõe UI do sistema para o resto do hub
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Repõe orientações normais (ou as que o hub quer)
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _openMenu() async {
    ref.read(ecoGuessControllerProvider.notifier).pauseRoundTimer();

    while (mounted) {
      final action = await showGameMenuDialog<EcoGuessMenuAction>(
        context: context,
        title: 'ECO GUESS - MENU',
        headerBadge: DifficultyBadge(
          difficulty: _selectedDifficulty,
        ),
        items: const [
          GameMenuItem(label: 'Retomar Jogo', value: EcoGuessMenuAction.resume, icon: Icon(Icons.play_arrow)),
          GameMenuItem(
            label: 'Reiniciar Jogo',
            value: EcoGuessMenuAction.restart,
            icon: Icon(Icons.refresh),

          ),
          GameMenuItem(
            label: 'Sair do Jogo',
            value: EcoGuessMenuAction.exit,
            isDestructive: true,
            icon: Icon(Icons.exit_to_app),

          ),
        ],
      );

      if (!mounted) return;

      switch (action) {
        case null:
        case EcoGuessMenuAction.resume:
          ref.read(ecoGuessControllerProvider.notifier).resumeRoundTimer();
          return;

        case EcoGuessMenuAction.restart:
          final restarted = await _pickDifficultyAndStart();
          if (!mounted) return;

          if (restarted) {
            return;
          }

          // cancelou a escolha de dificuldade -> volta ao menu
          continue;

        case EcoGuessMenuAction.exit:
          final confirmed = await showConfirmExitDialog(context);
          if (!mounted) return;

          if (confirmed) {
            Navigator.of(context).pop(); // volta ao hub
            return;
          }

          // CANCELADO -> volta ao while e reabre o menu
          continue;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lê o estado atual do jogo
    final session = ref.watch(ecoGuessControllerProvider);
    final controller = ref.read(ecoGuessControllerProvider.notifier);
    final round = session.round;

    if (round == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final masked = buildMaskedWord(
      originalWord: round.challenge.word,
      guessedBase: round.guessedLettersBase,
    );

    final isRoundEnd = session.status == EcoGuessSessionStatus.roundEnd;
    final isGameOver = session.status == EcoGuessSessionStatus.gameOver;
    final isPlaying = session.status == EcoGuessSessionStatus.playing;
    final breakdown = session.lastRoundScore;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            'packages/eco_guess_game/assets/images/eco_guess_bg.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: PopScope(
        canPop: false, // impede pop automático; nós decidimos
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _openMenu();
        },
        child: Scaffold(
          backgroundColor: Color.fromARGB(40, 255, 255, 255),
          body: Stack(
            children: [
              // Wallpaper
              Positioned.fill(
                child: Image.asset(
                  'packages/eco_guess_game/assets/images/eco_guess_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 75, 16, 30),
                  child: Row(
                    // Layout principal: duas colunas (info + eco-meter + pista | palavra + teclado/painel)
                    children: [
                      Expanded(
                        // Coluna Esquerda: Info da ronda, eco-meter, e pista
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withAlpha(230),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.grey.withAlpha(40),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ronda ${session.roundIndex + 1} de ${session.totalRounds}',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tentativas: ${round.attemptsLeft}   •   Score: ${session.score}',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              EcoMeter(
                                attemptsLeft: round.attemptsLeft,
                                maxAttempts: round.difficulty.maxAttempts,
                              ),
                              const SizedBox(height: 8),
                              if (isPlaying) ...[
                                RoundProgressBar(
                                  startedAtMs: round.startedAtMs,
                                  targetSeconds: round.difficulty.targetSeconds,
                                  pausedAccumulatedMs: round.pausedAccumulatedMs,
                                  pausedAtMs: round.pausedAtMs,
                                ),
                                const SizedBox(height: 8),
                              ],
                              Text(
                                "Descrição:", 
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                round.challenge.description,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Coluna Direita: Palavra mascarada e teclado / painel de fim de ronda
                      Expanded(
                        flex: 7,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withAlpha(230),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.black.withAlpha(40),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 6),
                              // Palavra mascarada
                              Text(
                                masked,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),

                              if (isPlaying) ...[
                                Expanded(
                                  child: _Keyboard(
                                    disabled: round.guessedLettersBase,
                                    onTap: controller.guess,
                                  ),
                                ),
                              ] else if (isRoundEnd) ...[
                                Expanded(
                                  child: Center(
                                    child: GameOverlayCard(
                                      maxWidth: 500,
                                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            round.status == RoundStatus.won
                                                ? 'Acertaste!'
                                                : 'Falhaste!',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(color: 
                                                  round.status == RoundStatus.won 
                                                    ? Colors.green[600] : Colors.red[400], fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 4),
                                          if (round.status == RoundStatus.lost)
                                          Text(
                                            'A palavra era: ${round.challenge.word}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: Colors.black87,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          if (breakdown != null) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              'Pontos Base: ${breakdown.basePoints}',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            Text(
                                              'Bónus de Tempo: ${breakdown.timeBonus}',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            Text(
                                              'Bónus de Tentativas: ${breakdown.attemptsBonus}',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Total de Pontos da Ronda: ${breakdown.total}',
                                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                await controller.nextRound();
                                              },
                                              icon: const Icon(Icons.arrow_forward),
                                              label: const Text(
                                                'Próxima Ronda',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const Spacer(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isGameOver) ...[
                Positioned.fill(
                  child: Container(color: Colors.black.withAlpha(71)),
                ),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: GameOverlayCard(
                        backgroundColor: Colors.white.withAlpha(255),
                        maxWidth: 500,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Fim de Jogo',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Pontuação: ${session.score}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Palavras Correctas: ${session.correctCount}/${session.totalRounds}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  controller.startGame(_selectedDifficulty);
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Jogar Novamente'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                label: const Text('Voltar ao Hub'),
                                icon: const Icon(Icons.arrow_back),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (!isGameOver) 
              // Botão de menu, exceto no ecrã de fim de jogo (porque já tem opções)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
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
      ),
    );
  }
}

class _Keyboard extends StatelessWidget {
  final Set<String> disabled;
  final void Function(String letter) onTap;

  const _Keyboard({required this.disabled, required this.onTap});

  static const _rows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  @override
  Widget build(BuildContext context) {
    // Ajusta estes valores conforme o “feeling” no emulador
    const double gap = 8; // espaço entre teclas
    const double rowGap = 10; // espaço entre linhas
    const double minKey = 36; // mínimo para dedos (em dp)
    const double maxKey = 56; // máximo para não ficar gigante em telas grandes

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxKeysInRow = _rows
            .map((r) => r.length)
            .reduce((a, b) => a > b ? a : b);

        // 1) limite por largura (linha de 10 teclas)
        final widthAvailable =
            constraints.maxWidth - (gap * (maxKeysInRow - 1));
        final keyByWidth = widthAvailable / maxKeysInRow;

        // 2) limite por altura (3 linhas + espaçamento entre linhas)
        // Nota: Column tem 3 rows e 2 gaps (rowGap * 2)
        final heightAvailable = constraints.maxHeight - (rowGap * 2);
        final keyByHeight = heightAvailable / 3;

        // 3) escolher o menor dos dois (para caber em ambos)
        final keySize = (keyByWidth < keyByHeight ? keyByWidth : keyByHeight)
            .clamp(minKey, maxKey);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _rows.length; i++) ...[
              _KeyRow(
                letters: _rows[i],
                disabled: disabled,
                onTap: onTap,
                keySize: keySize,
                gap: gap,
                // offset para parecer teclado real
                leftInset: i == 1
                    ? keySize * 0.5
                    : (i == 2 ? keySize * 1.0 : 0),
              ),
              if (i != _rows.length - 1) const SizedBox(height: rowGap),
            ],
          ],
        );
      },
    );
  }
}

class _KeyRow extends StatelessWidget {
  final List<String> letters;
  final Set<String> disabled;
  final void Function(String) onTap;
  final double keySize;
  final double gap;
  final double leftInset;

  const _KeyRow({
    required this.letters,
    required this.disabled,
    required this.onTap,
    required this.keySize,
    required this.gap,
    required this.leftInset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: leftInset),
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final l in letters)
            _KeyButton(
              letter: l,
              size: keySize,
              disabled: disabled.contains(l),
              onTap: onTap,
            ),
        ],
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String letter;
  final double size;
  final bool disabled;
  final void Function(String) onTap;

  const _KeyButton({
    required this.letter,
    required this.size,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: disabled ? null : () => onTap(letter),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          minimumSize: Size(size, size),
          elevation: disabled ? 0 : 2,
        ),
        child: Text(
          letter,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color:
                disabled // teclas desativadas ficam mais escuras para indicar que já foram usadas
                ? Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.35)
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class EcoMeter extends StatelessWidget {
  final int attemptsLeft;
  final int maxAttempts;

  const EcoMeter({
    super.key,
    required this.attemptsLeft,
    required this.maxAttempts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EcoLivesBar(
          attemptsLeft: attemptsLeft,
          maxAttempts: maxAttempts,
          iconSize: 24, // afina conforme o teu layout
        ),
        const SizedBox(width: 12),
        //Text('Score: ${score}'),
      ],
    );
  }
}
