import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:ocean_clean_game/src/domain/ocean_fact.dart';

class OceanFactCatalog {
  final List<OceanFact> facts;

  const OceanFactCatalog(this.facts);

  factory OceanFactCatalog.fromJsonList(List<dynamic> list) {
    return OceanFactCatalog(
      list
          .map((item) => OceanFact.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  static Future<OceanFactCatalog> load() async {
    final raw = await rootBundle.loadString(
      'packages/ocean_clean_game/assets/data/ocean_facts.json',
    );

    final decoded = jsonDecode(raw) as List<dynamic>;
    return OceanFactCatalog.fromJsonList(decoded);
  }

  OceanFact random(Random random) {
    if (facts.isEmpty) {
      throw StateError("OceanFactCatalog can't be empty.");
    }

    return facts[random.nextInt(facts.length)];
  }
}