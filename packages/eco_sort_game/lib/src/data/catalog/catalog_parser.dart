import 'dart:convert';

class Catalog {
  final int version;
  final List<CatalogBin> bins;
  final List<CatalogItem> items;

  const Catalog({
    required this.version,
    required this.bins,
    required this.items,
  });
}

class CatalogBin {
  final String id;      // ex: blue
  final String label;   // ex: Azul
  final String asset;   // path do sprite

  const CatalogBin({
    required this.id,
    required this.label,
    required this.asset,
  });
}

class CatalogItem {
  final String id;        // único
  final String label;     // nome legível
  final String bin;       // id do bin (string)
  final String asset;     // path do sprite
  final double? scaleBias;

  const CatalogItem({
    required this.id,
    required this.label,
    required this.bin,
    required this.asset,
    this.scaleBias,
  });
}

/// Excepções específicas para erros do catálogo.
class CatalogFormatException implements Exception {
  final String message;
  const CatalogFormatException(this.message);

  @override
  String toString() => 'CatalogFormatException: $message';
}

class CatalogParser {
  static const supportedVersion = 1;

  static const allowedBinIds = {'blue', 'green', 'yellow', 'brown'};

  /// Faz parse + valida invariantes.
  static Catalog parse(String jsonStr) {
    final dynamic root;
    try {
      root = json.decode(jsonStr);
    } catch (e) {
      throw const CatalogFormatException('JSON inválido.');
    }

    if (root is! Map<String, dynamic>) {
      throw const CatalogFormatException('Raiz do catálogo tem de ser um objecto JSON.');
    }

    final version = _readInt(root, 'version');
    if (version != supportedVersion) {
      throw CatalogFormatException('Versão do catálogo não suportada: $version (suportada: $supportedVersion).');
    }

    final binsRaw = _readList(root, 'bins');
    final itemsRaw = _readList(root, 'items');

    final bins = binsRaw.map((e) => _parseBin(e)).toList(growable: false);
    final items = itemsRaw.map((e) => _parseItem(e)).toList(growable: false);

    _validate(bins: bins, items: items);

    return Catalog(version: version, bins: bins, items: items);
  }

  static CatalogBin _parseBin(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      throw const CatalogFormatException('Entrada de bin inválida (não é objecto).');
    }
    final id = _readString(raw, 'id');
    final label = _readString(raw, 'label');
    final asset = _readString(raw, 'asset');

    return CatalogBin(id: id, label: label, asset: asset);
  }

  static CatalogItem _parseItem(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      throw const CatalogFormatException('Entrada de item inválida (não é objecto).');
    }
    final id = _readString(raw, 'id');
    final label = _readString(raw, 'label');
    final bin = _readString(raw, 'bin');
    final asset = _readString(raw, 'asset');

    final scaleBiasRaw = raw['scaleBias'];
    double? scaleBias;
    if (scaleBiasRaw != null) {
      if (scaleBiasRaw is num) {
        scaleBias = scaleBiasRaw.toDouble();
      } else {
        throw const CatalogFormatException('scaleBias tem de ser numérico.');
      }
    }

    return CatalogItem(id: id, label: label, bin: bin, asset: asset, scaleBias: scaleBias);
  }

  static void _validate({required List<CatalogBin> bins, required List<CatalogItem> items}) {
    if (bins.isEmpty) {
      throw const CatalogFormatException('Catálogo inválido: lista de bins vazia.');
    }
    if (items.isEmpty) {
      throw const CatalogFormatException('Catálogo inválido: lista de items vazia.');
    }

    // bins: ids únicos + ids permitidos
    final binIds = <String>{};
    for (final b in bins) {
      if (!allowedBinIds.contains(b.id)) {
        throw CatalogFormatException('Bin id inválido no catálogo: "${b.id}".');
      }
      if (!binIds.add(b.id)) {
        throw CatalogFormatException('Bin id duplicado no catálogo: "${b.id}".');
      }
      // if (b.asset.trim().isEmpty) {
      //   throw CatalogFormatException('Bin "${b.id}" tem asset vazio.');
      // }
    }

    // items: ids únicos + bin existente + asset não vazio
    final itemIds = <String>{};
    for (final it in items) {
      if (!itemIds.add(it.id)) {
        throw CatalogFormatException('Item id duplicado no catálogo: "${it.id}".');
      }
      if (!binIds.contains(it.bin)) {
        throw CatalogFormatException('Item "${it.id}" refere bin inexistente: "${it.bin}".');
      }
      // if (it.asset.trim().isEmpty) {
      //   throw CatalogFormatException('Item "${it.id}" tem asset vazio.');
      // }
      if (it.scaleBias != null && (it.scaleBias! <= 0 || it.scaleBias! > 1.2)) {
        throw CatalogFormatException('Item "${it.id}" tem scaleBias fora do intervalo (0, 1.2].');
      }
    }
  }

  static String _readString(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v is! String) throw CatalogFormatException('Campo "$key" em falta ou inválido (string).');
    final s = v.trim();
    if (s.isEmpty) throw CatalogFormatException('Campo "$key" vazio.');
    return s;
  }

  static int _readInt(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v is! num) throw CatalogFormatException('Campo "$key" em falta ou inválido (num).');
    return v.toInt();
  }

  static List<dynamic> _readList(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v is! List) throw CatalogFormatException('Campo "$key" em falta ou inválido (lista).');
    return v;
  }
}