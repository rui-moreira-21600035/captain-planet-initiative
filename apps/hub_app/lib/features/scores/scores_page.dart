import 'package:flutter/material.dart';

class ScoresPage extends StatelessWidget {
  const ScoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.emoji_events_outlined, size: 56),
            SizedBox(height: 16),
            Text(
              'Pontuações',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Este ecrã fica preparado para mostrar o leaderboard local e, numa fase posterior, classificações globais via API.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
