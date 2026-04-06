class ProtoCharacterData {
  final String id;
  final String title;
  final String targetImagePath;   // esquerda
  final String optionImagePath;   // direita

  const ProtoCharacterData({
    required this.id,
    required this.title,
    required this.targetImagePath,
    required this.optionImagePath,
  });
}