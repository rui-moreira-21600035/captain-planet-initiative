import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../../domain/models/eco_fact.dart';

class FactsRepository {
  final Random _rng;

  List<EcoFact>? _cache;

  FactsRepository({Random? rng}) : _rng = rng ?? Random();

  Future<List<EcoFact>> loadAll() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString(
      'packages/eco_guess_game/assets/data/facts.json',
      cache: true,
    );

    final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

    _cache = data
        .map(
          (m) => EcoFact(
            id: m['id'] as String,
            text: m['text'] as String,
            theme: m['theme'] as String,
          ),
        )
        .toList(growable: false);

    return _cache!;
  }

  /// Devolve um facto aleatório. Se [theme] for fornecido e existirem factos desse tema,
  /// dá prioridade a esses.
  Future<EcoFact> pickRandom({String? theme}) async {
    final all = await loadAll();
    if (all.isEmpty) {
      throw StateError('No eco facts found.');
    }

    if (theme == null || theme.trim().isEmpty) {
      return all[_rng.nextInt(all.length)];
    }

    final themed =
        all.where((f) => f.theme.toLowerCase() == theme.toLowerCase()).toList();

    if (themed.isEmpty) {
      // fallback: qualquer tema
      return all[_rng.nextInt(all.length)];
    }

    return themed[_rng.nextInt(themed.length)];
  }

  /// Devolve um facto aleatório diferente do anterior (se possível).
  /// Útil para evitar repetições em sessões seguidas.
  Future<EcoFact> pickRandomNotSame({
    required String? previousFactId,
    String? theme,
  }) async {
    final all = await loadAll();
    if (all.isEmpty) throw StateError('No eco facts found.');

    List<EcoFact> pool;
    if (theme == null || theme.trim().isEmpty) {
      pool = all.toList();
    } else {
      pool = all
          .where((f) => f.theme.toLowerCase() == theme.toLowerCase())
          .toList();
      if (pool.isEmpty) pool = all.toList();
    }

    if (previousFactId == null || pool.length == 1) {
      return pool[_rng.nextInt(pool.length)];
    }

    final filtered = pool.where((f) => f.id != previousFactId).toList();
    if (filtered.isEmpty) {
      // Só existia um facto possível
      return pool.first;
    }
    return filtered[_rng.nextInt(filtered.length)];
  }
}