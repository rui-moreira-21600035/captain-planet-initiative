import 'package:common_gamekit/common_gamekit.dart';

extension OceanCleanDifficultyConfig on GameDifficulty  {
  int get initialFishCount => switch(this){
    GameDifficulty.easy => 6,
    GameDifficulty.medium => 5,
    GameDifficulty.hard => 4,
  };

  int get maxActiveTrash => switch(this){
    GameDifficulty.easy => 10,
    GameDifficulty.medium => 18,
    GameDifficulty.hard => 25,
  };
  Duration get gameDuration => switch(this){
    GameDifficulty.easy => Duration(seconds: 60),
    GameDifficulty.medium => Duration(seconds: 60),
    GameDifficulty.hard => Duration(seconds: 60),
  };

  double get spawnStart => switch(this){
    GameDifficulty.easy => 2.5,
    GameDifficulty.medium => 1.2,
    GameDifficulty.hard => 0.3,
  };

  double get spawnEnd => switch(this){
    GameDifficulty.easy => 1.5,
    GameDifficulty.medium => 0.8,
    GameDifficulty.hard => 0.15,
  };

  double get speedStart => switch(this){
    GameDifficulty.easy => 120,
    GameDifficulty.medium => 150,
    GameDifficulty.hard => 270,
  };

  double get speedEnd => switch(this){
    GameDifficulty.easy => 200,
    GameDifficulty.medium => 230,
    GameDifficulty.hard => 350,
  };

  static GameDifficulty fromJson(String s) {
    switch (s.toLowerCase()) {
      case 'easy':
        return GameDifficulty.easy;
      case 'medium':
        return GameDifficulty.medium;
      case 'hard':
        return GameDifficulty.hard;
      default:
        throw FormatException('Unknown difficulty: $s');
    }
  }
}