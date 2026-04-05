import 'package:flutter/material.dart';
import '../../domain/game_difficulty.dart';

class DifficultyIcon extends StatelessWidget {
  final GameDifficulty difficulty;
  final double size;

  const DifficultyIcon({
    super.key,
    required this.difficulty,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return Icon(
          Icons.eco,
          size: size,
          color: Colors.green,
        );

      case GameDifficulty.medium:
        return Icon(
          Icons.speed,
          size: size,
          color: Colors.orange,
        );

      case GameDifficulty.hard:
        return Icon(
          Icons.local_fire_department,
          size: size,
          color: Colors.red,
        );
    }
  }
}