import 'package:flutter/material.dart';
import 'package:common_gamekit/common_gamekit.dart';

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
        return Icon(Icons.eco, color: Colors.green, size: size);

      case GameDifficulty.medium:
        return Icon(Icons.speed, color: Colors.orange, size: size);

      case GameDifficulty.hard:
        return Icon(Icons.local_fire_department, color: Colors.red, size: size);
    }
  }
}