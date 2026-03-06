import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          leading: Icon(Icons.volume_up_outlined),
          title: Text('Som'),
          subtitle: Text('Ponto de entrada para preferências globais da aplicação.'),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.palette_outlined),
          title: Text('Aparência'),
          subtitle: Text('Espaço reservado para futuras opções de tema e acessibilidade.'),
        ),
      ],
    );
  }
}
