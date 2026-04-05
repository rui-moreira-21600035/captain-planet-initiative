import 'package:flutter/material.dart';

class EcoGuessGameOverPage extends StatelessWidget {
  final int score;
  final int correct;
  final int wrong;
  final int totalRounds;
  final String ecoFact;

  const EcoGuessGameOverPage({
    super.key,
    required this.score,
    required this.correct,
    required this.wrong,
    required this.totalRounds,
    required this.ecoFact,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = totalRounds == 0 ? 0 : (correct / totalRounds * 100).round();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),

              Text(
                'Fim de Jogo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Score: $score',
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 8),

              Text('Acertos: $correct • Erros: $wrong'),
              Text('Precisão: $accuracy%'),

              const SizedBox(height: 24),

              // FACTO ECOLÓGICO
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withAlpha(229),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  ecoFact,
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),

              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // volta ao jogo e reinicia
                      },
                      child: const Text('Jogar novamente'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text('Voltar ao menu'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}