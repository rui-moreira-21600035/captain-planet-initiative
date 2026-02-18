class CatalogBin {
  final String id;     // "blue"
  final String label;  // "Papel"
  final String asset;  // "assets/images/containers/blue.png"

  const CatalogBin({
    required this.id,
    required this.label,
    required this.asset,
  });

  factory CatalogBin.fromJson(Map<String, dynamic> json) => CatalogBin(
        id: json['id'] as String,
        label: json['label'] as String,
        asset: json['asset'] as String,
      );
}