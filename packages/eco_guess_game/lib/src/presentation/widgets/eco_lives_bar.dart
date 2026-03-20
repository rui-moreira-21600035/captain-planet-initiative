import 'package:flutter/material.dart';

class EcoLivesBar extends StatelessWidget {
  final int attemptsLeft;
  final int maxAttempts;

  /// Opacidade das “vidas” perdidas
  final double lostOpacity;

  /// Tamanho do ícone
  final double iconSize;

  const EcoLivesBar({
    super.key,
    required this.attemptsLeft,
    required this.maxAttempts,
    this.lostOpacity = 0.18,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final clampedLeft = attemptsLeft.clamp(0, maxAttempts);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxAttempts, (i) {
        final isActive = i < clampedLeft;

        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Opacity(
            opacity: isActive ? 1.0 : lostOpacity,
            child: Image.asset(
              'packages/eco_guess_game/assets/images/recycle_light.png',
              width: iconSize,
              height: iconSize,
              filterQuality: FilterQuality.high,
            ),
          ),
        );
      }),
    );
  }
}