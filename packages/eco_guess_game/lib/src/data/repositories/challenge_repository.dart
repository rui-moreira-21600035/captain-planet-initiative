import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/models/challenge.dart';

class ChallengeRepository {
  List<Challenge>? _cache;

  Future<List<Challenge>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(
      'packages/eco_guess_game/assets/data/challenges.json',
      cache: true,
    );
    final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    _cache = data.map((m) => Challenge(
      id: m['id'] as String,
      word: (m['word'] as String).toUpperCase(),
      description: m['description'] as String,
      theme: m['theme'] as String,
    )).toList();

    return _cache!;
  }
}