import 'package:flutter/material.dart';
import '../../domain/game_difficulty.dart';
import 'difficulty_icon.dart';

class DifficultyBadge extends StatelessWidget {
  final GameDifficulty difficulty;

  const DifficultyBadge({
    super.key,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      GameDifficulty.easy => Colors.green,
      GameDifficulty.medium => Colors.orange,
      GameDifficulty.hard => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DifficultyIcon(
            difficulty: difficulty,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            difficulty.labelPt,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}