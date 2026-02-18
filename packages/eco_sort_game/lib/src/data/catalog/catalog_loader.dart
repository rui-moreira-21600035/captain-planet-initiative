import 'dart:convert';
import 'package:flutter/services.dart';

import 'catalog_bin.dart';
import 'catalog_item.dart';
import 'eco_sort_catalog.dart';

class CatalogLoader {
  static const String _pkgPrefix = 'packages/eco_sort_game/';
  static const String _catalogRelative = 'assets/data/eco_sort/catalog_v1.json';

  Future<EcoSortCatalog> load() async {
    final raw = await rootBundle.loadString('$_pkgPrefix$_catalogRelative');
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;

    final version = (json['version'] as num).toInt();

    final bins = (json['bins'] as List<dynamic>)
        .map((e) => CatalogBin.fromJson(e as Map<String, dynamic>))
        .toList();

    final items = (json['items'] as List<dynamic>)
        .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return EcoSortCatalog(version: version, bins: bins, items: items);
  }
}