class ScoreEntry {
  final String id;          // uuid
  final String gameId;      // ex: "eco_sort"
  final int score;          // pontos finais
  final String metricsJson; // JSON string
  final int durationMs;     // tempo total em ms
  final int createdAtMs;    // epoch ms
  final DateTime? syncedAt;        // null = não sincronizado, DateTime = quando foi sincronizado

  const ScoreEntry({
    required this.id,
    required this.gameId,
    required this.score,
    required this.metricsJson,
    required this.durationMs,
    required this.createdAtMs,
    required this.syncedAt,
  });
}