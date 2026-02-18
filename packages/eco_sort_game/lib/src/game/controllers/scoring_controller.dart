class ScoringController {
  int _score = 0;
  int _streak = 0;
  int _streakMax = 0;
  int _correct = 0;
  int _wrong = 0;

  int get score => _score;
  int get streak => _streak;
  int get streakMax => _streakMax;
  int get correct => _correct;
  int get wrong => _wrong;

  void registerCorrect() {
    _correct++;
    _streak++;
    if (_streak > _streakMax) _streakMax = _streak;

    // regra de pontos (ajusta depois)
    _score += 10 + (_streak >= 3 ? 5 : 0);
  }

  void registerWrong() {
    _wrong++;
    _streak = 0;
    _score = (_score - 5).clamp(0, 1 << 30);
  }

  void reset() {
    _score = 0;
    _streak = 0;
    _streakMax = 0;
    _correct = 0;
    _wrong = 0;
  }
}