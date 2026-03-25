class GameMenuItem {
  final String label;
  final bool isDestructive;
  final Object? value; // para identificar a ação

  const GameMenuItem({
    required this.label,
    this.isDestructive = false,
    this.value,
  });
}