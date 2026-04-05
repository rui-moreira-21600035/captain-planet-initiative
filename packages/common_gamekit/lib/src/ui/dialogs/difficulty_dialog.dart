import 'package:common_gamekit/src/ui/widgets/difficulty_badge.dart';
import 'package:flutter/material.dart';
import '../../domain/game_difficulty.dart';

Future<GameDifficulty?> showDifficultyDialog(
  BuildContext context, {
  String title = 'Seleccionar Dificuldade',
  GameDifficulty? initial,
}) async {
  GameDifficulty selected = initial ?? GameDifficulty.easy;

  return showGeneralDialog<GameDifficulty>(
    context: context,
    barrierLabel: 'Dificuldade',
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) {
      return Center(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: Offset(0, 10),
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      DifficultyBadge(difficulty: selected),
                      const SizedBox(height: 16),

                      _DifficultyOption(
                        label: GameDifficulty.easy.labelPt,
                        selected: selected == GameDifficulty.easy,
                        onTap: () => setState(() => selected = GameDifficulty.easy),
                      ),
                      const SizedBox(height: 10),
                      _DifficultyOption(
                        label: GameDifficulty.medium.labelPt,
                        selected: selected == GameDifficulty.medium,
                        onTap: () => setState(() => selected = GameDifficulty.medium),
                      ),
                      const SizedBox(height: 10),
                      _DifficultyOption(
                        label: GameDifficulty.hard.labelPt,
                        selected: selected == GameDifficulty.hard,
                        onTap: () => setState(() => selected = GameDifficulty.hard),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(null),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                minimumSize: const Size.fromHeight(52),
                              ),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(selected),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                minimumSize: const Size.fromHeight(52),
                              ),
                              child: const Text('Começar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _DifficultyOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.onSurface.withAlpha(selected ? 115 : 51),
            width: selected ? 2.0 : 1.2,
          ),
          color: selected
              ? theme.colorScheme.onSurface.withAlpha(10)
              : theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}