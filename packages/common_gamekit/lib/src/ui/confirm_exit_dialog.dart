import 'package:flutter/material.dart';

Future<bool> showConfirmExitDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (context) => AlertDialog(
      title: const Text('Sair do jogo?'),
      content: const Text('Vais voltar ao hub. O progresso desta sessão será perdido.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sair'),
        ),
      ],
    ),
  );
  return result ?? false;
}