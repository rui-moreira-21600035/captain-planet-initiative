import 'package:flutter/material.dart';
import 'features/launcher/launcher_page.dart';

void main() => runApp(const HubApp());

class HubApp extends StatelessWidget {
  const HubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minigames Hub',
      theme: ThemeData(useMaterial3: true),
      home: const LauncherPage(),
    );
  }
}