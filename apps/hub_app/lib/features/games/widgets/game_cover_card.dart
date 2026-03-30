import 'package:flutter/material.dart';

class GameCoverCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String coverAsset; // ex: assets/images/games/eco_guess_cover.png
  final VoidCallback onTap;

  const GameCoverCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.coverAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orientation = MediaQuery.of(context).orientation;

    final double coverHeight = orientation == Orientation.portrait ? 120 : 80;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // COVER com altura controlada
            SizedBox(
              height: coverHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    coverAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter, // evita cortar o "importante" em baixo
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: coverHeight * 0.55,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.surface.withOpacity(0.0),
                            theme.colorScheme.surface.withOpacity(0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // BODY (igual)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}