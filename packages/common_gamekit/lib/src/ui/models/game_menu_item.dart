import 'package:flutter/material.dart';

class GameMenuItem {
  final String label;
  final bool isDestructive;
  final Object? value; // para identificar a ação
   final Widget? icon;

  const GameMenuItem({
    required this.label,
    this.isDestructive = false,
    this.value,
    this.icon,
  });
}