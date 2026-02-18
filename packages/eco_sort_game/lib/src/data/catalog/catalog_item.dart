class CatalogItem {
  final String id;
  final String asset;
  final String bin;
  final String label;

  const CatalogItem({
    required this.id,
    required this.asset,
    required this.bin,
    required this.label,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) => CatalogItem(
        id: json['id'] as String,
        asset: json['asset'] as String,
        bin: json['bin'] as String,
        label: json['label'] as String,
      );
}