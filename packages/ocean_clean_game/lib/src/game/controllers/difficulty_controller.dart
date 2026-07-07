class DifficultyController {

  double spawnInterval(double elapsed) {

    if (elapsed < 15) return 2.2;
    if (elapsed < 30) return 1.8;
    if (elapsed < 45) return 1.4;

    return 1.0;
  }

}