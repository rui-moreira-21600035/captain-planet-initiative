import 'package:flutter/material.dart';

class GameMenuItem<T> {
  final String label;
  final bool isDestructive;
  final T value;

  const GameMenuItem({
    required this.label,
    required this.value,
    this.isDestructive = false,
  });
}

Future<T?> showGameMenuDialog<T>({
  required BuildContext context,
  String title = 'MENU DE JOGO',
  Widget? icon,
  required List<GameMenuItem<T>> items,
}) async {
  return showGeneralDialog<T>(
    context: context,
    barrierLabel: 'Menu',
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => Center(
      child: _GameMenuDialogBody<T>(title: title, icon: icon, items: items),
    ),
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

class _GameMenuDialogBody<T> extends StatelessWidget {
  final String title;
  final Widget? icon;
  final List<GameMenuItem<T>> items;

  const _GameMenuDialogBody({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) { 
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.12),
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
              // Header (título centrado)
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(color: theme.colorScheme.onSurface),
                  child: icon!,
                ),
                const SizedBox(height: 16),
              ],

              // Botões do menu
              for (var i = 0; i < items.length; i++) ...[
                _MenuButton(
                  label: items[i].label,
                  isDestructive: items[i].isDestructive,
                  onPressed: () => Navigator.of(context).pop(items[i].value),
                ),
                if (i != items.length - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _MenuButton({
    required this.label,
    required this.onPressed,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: theme.colorScheme.onSurface.withOpacity(isDestructive ? 0.38 : 0.25),
            width: 1.6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: isDestructive
              ? theme.colorScheme.error.withOpacity(0.06)
              : theme.colorScheme.surface,
        ),
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}