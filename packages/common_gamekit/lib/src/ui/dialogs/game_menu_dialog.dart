import 'package:flutter/material.dart';

class GameMenuItem<T> {
  final String label;
  final Widget? icon;
  final bool isDestructive;
  final T value;

  const GameMenuItem({
    required this.label,
    required this.value,
    this.icon,
    this.isDestructive = false,
  });
}

Future<T?> showGameMenuDialog<T>({
  required BuildContext context,
  String title = 'MENU DE JOGO',
  Widget? icon,
  Widget? headerBadge,
  required List<GameMenuItem<T>> items,
}) async {
  return showGeneralDialog<T>(
    context: context,
    barrierLabel: 'Menu',
    barrierDismissible: true,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => Center(
      child: _GameMenuDialogBody<T>(title: title, icon: icon, headerBadge: headerBadge, items: items),
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
  final Widget? headerBadge;
  final List<GameMenuItem<T>> items;

  const _GameMenuDialogBody({
    required this.title,
    required this.icon,
    this.headerBadge,
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
              color: theme.colorScheme.onSurface.withAlpha(30),
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
              if (headerBadge != null) ...[
                headerBadge!,
                const SizedBox(height: 16),
              ],

              // Botões do menu
              for (var i = 0; i < items.length; i++) ...[
                _MenuButton(
                  label: items[i].label,
                  icon: items[i].icon,
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
  final Widget? icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _MenuButton({
    required this.label,
    required this.onPressed,
    required this.isDestructive,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contentColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: theme.colorScheme.onSurface.withAlpha(
              isDestructive ? 97 : 64,
            ),
            width: 1.6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: isDestructive
              ? theme.colorScheme.error.withAlpha(15)
              : theme.colorScheme.surface,
          foregroundColor: contentColor,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              SizedBox(
                width: 24,
                child: Center(
                  child: IconTheme(
                    data: IconThemeData(
                      color: contentColor,
                      size: 20,
                    ),
                    child: icon!,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ] else ...[
              const SizedBox(width: 36),
            ],
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: contentColor,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}