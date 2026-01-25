import 'package:flutter/material.dart';
import 'game_registry.dart';

class LauncherPage extends StatelessWidget {
  const LauncherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hub de Mini-jogos')),
      body: ListView.separated(
        itemCount: gameRegistry.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final module = gameRegistry[index];
          return ListTile(
            title: Text(module.name),
            subtitle: Text(module.description),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => module.pageBuilder()),
              );
            },
          );
        },
      ),
    );
  }
}