class OceanCleanScoringController {
  int _score = 0;
  int _trashCollected = 0;
  int _fishLost = 0;

  int get score => _score;
  int get trashCollected => _trashCollected;
  int get fishLost => _fishLost;

  void collectTrash() {
    _trashCollected++;
    _score += 10;
  }

  void loseFish() {
    _fishLost++;
    _score = (_score - 15).clamp(0, 1 << 30);
  }

  void addSurvivalBonus(int fishRemaining) {
    _score += fishRemaining * 5;
  }

  void addTimeBonus(int remainingSeconds) {
    _score += remainingSeconds;
  }

  void reset() {
    _score = 0;
    _trashCollected = 0;
    _fishLost = 0;
  }
}