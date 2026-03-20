class Challenge {
  final String id;
  final String word;        // com acentos/ç (ex: "POLUIÇÃO")
  final String description; // pista textual
  final String theme;       // ex: "reciclagem"

  const Challenge({
    required this.id,
    required this.word,
    required this.description,
    required this.theme,
  });
}