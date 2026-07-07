import 'package:flutter/material.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_game_outcome.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_game_result.dart';

class OceanCleanGameOverDialog extends StatelessWidget {
  final OceanCleanGameResult result;
  final VoidCallback onContinue;

  const OceanCleanGameOverDialog({
    super.key,
    required this.result,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final won = result.outcome == OceanCleanGameOutcome.victory;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.86,
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                won ? '🌊 OCEANO PROTEGIDO 🌊' : '🐟 FIM DO JOGO 🐟',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Pontuação: ${result.score}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatBox(
                    icon: '🗑️',
                    value: '${result.trashCollected}',
                    label: 'Lixo recolhido',
                  ),
                  _StatBox(
                    icon: '🐠',
                    value: '${result.fishRemaining}/${result.fishInitialCount}',
                    label: 'Peixes salvos',
                  ),
                  _StatBox(
                    icon: '⏱️',
                    value: '${result.duration.inSeconds}s',
                    label: 'Duração',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 6),
                  Flexible(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          const TextSpan(
                            text: '💡 Sabias que? ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: result.oceanFact.factPT,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              FractionallySizedBox(
                widthFactor: 0.35,
                child: FilledButton(
                  onPressed: onContinue,
                  child: const Text("CONTINUAR"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}