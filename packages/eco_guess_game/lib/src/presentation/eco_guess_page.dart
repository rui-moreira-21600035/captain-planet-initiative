import 'package:eco_guess_game/src/application/state/eco_guess_session_state.dart';
import 'package:eco_guess_game/src/domain/models/round_status.dart';
import 'package:eco_guess_game/src/presentation/widgets/eco_lives_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:common_gamekit/common_gamekit.dart';

import '../application/providers/providers.dart';
import '../domain/models/difficulty.dart';
import '../domain/services/masked_word.dart';

class EcoGuessPage extends ConsumerStatefulWidget {
  final ScoreRepository scoreRepo;

  const EcoGuessPage({super.key, required this.scoreRepo});

  @override
  ConsumerState<EcoGuessPage> createState() => _EcoGuessPageState();
}

class _EcoGuessPageState extends ConsumerState<EcoGuessPage> {
  var _started = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_started) return;
      _started = true;
      await ref
          .read(ecoGuessControllerProvider.notifier)
          .startGame(EcoGuessDifficulty.easy);
    });
  }

  @override
  void dispose() {
    // Restaura as orientações normais para o resto da app
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

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(title: const Text('Eco Guess')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // COLUNA ESQUERDA
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ronda ${session.roundIndex + 1} / ${session.totalRounds}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text('Tentativas: ${round.attemptsLeft}   •   Score: ${session.score}'),
                    const SizedBox(height: 12),
                    
                    // TODO: eco-meter/forca aqui (placeholder)
                    EcoMeter(
                      attemptsLeft: round.attemptsLeft,
                      maxAttempts: round.difficulty.maxAttempts,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      round.challenge.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // COLUNA DIREITA
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      masked,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),

                    if (isPlaying) ...[
                      Expanded(
                        child: _Keyboard(
                          disabled: round.guessedLettersBase,
                          onTap: controller.guess,
                        ),
                      ),
                    ] else ...[
                      // Painel de fim de ronda / jogo
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      round.status == RoundStatus.won ? 'Acertaste!' : 'Falhaste!',
                                      style: Theme.of(context).textTheme.titleLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'A palavra era: ${round.challenge.word}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await controller.nextRound();
                                        },
                                        child: Text(isGameOver ? 'Ver resultado' : 'Próxima ronda'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
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
    const double gap = 8;        // espaço entre teclas
    const double rowGap = 10;     // espaço entre linhas
    const double minKey = 36;     // mínimo para dedos (em dp)
    const double maxKey = 56;     // máximo para não ficar gigante em telas grandes

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxKeysInRow = _rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);

        // 1) limite por largura (linha de 10 teclas)
        final widthAvailable = constraints.maxWidth - (gap * (maxKeysInRow - 1));
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
                leftInset: i == 1 ? keySize * 0.5 : (i == 2 ? keySize * 1.0 : 0),
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
            color: disabled // teclas desativadas ficam mais escuras para indicar que já foram usadas
                ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)
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
    final value = attemptsLeft / maxAttempts;
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