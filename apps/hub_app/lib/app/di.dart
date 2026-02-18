import 'package:common_gamekit/common_gamekit.dart';

// Dependency injection for hub app.
class AppDi {
  AppDi._();

  static final ScoreRepository scoreRepo = LocalScoreRepositorySqflite();
}