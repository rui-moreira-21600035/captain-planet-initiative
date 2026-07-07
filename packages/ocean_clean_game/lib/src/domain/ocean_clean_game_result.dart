import 'package:common_gamekit/common_gamekit.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_game_outcome.dart';
import 'package:ocean_clean_game/src/domain/ocean_clean_gameover_reason.dart';
import 'package:ocean_clean_game/src/domain/ocean_fact.dart';

class OceanCleanGameResult {
  final int score;
  final int trashCollected;
  final int fishInitialCount;
  final int fishRemaining;
  final int fishLost;
  final Duration duration;
  final OceanCleanGameOutcome outcome;
  final OceanCleanGameOverReason reason;
  final OceanFact oceanFact;
  final GameDifficulty difficulty;

  const OceanCleanGameResult({
    required this.score,
    required this.trashCollected,
    required this.fishInitialCount,
    required this.fishRemaining,
    required this.fishLost,
    required this.duration,
    required this.outcome,
    required this.reason,
    required this.oceanFact,
    required this.difficulty,
  });

  Map<String, dynamic> toMetricsJson() => {
        'trashCollected': trashCollected,
        'fishInitialCount': fishInitialCount,
        'fishRemaining': fishRemaining,
        'fishLost': fishLost,
        'durationMs': duration.inMilliseconds,
        'outcome': outcome.name,
        'reason': reason.name,
        'oceanFact': oceanFact,
        'difficulty': difficulty
      };
}



