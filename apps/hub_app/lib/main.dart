import 'package:flutter/material.dart';

import 'features/navigation/launcher_shell.dart';

void main() {
  runApp(const HubApp());
}

class HubApp extends StatelessWidget {
  const HubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Captain Planet Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const LauncherShell(),
    );
  }
}
