class CatalogItem {
  final String id;
  final String asset;
  final String bin;
  final String labelPt;
  final String labelEn;

  const CatalogItem({
    required this.id,
    required this.asset,
    required this.bin,
    required this.labelPt,
    required this.labelEn,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) => CatalogItem(
        id: json['id'] as String,
        asset: json['asset'] as String,
        bin: json['bin'] as String,
        labelPt: json['label_pt'] as String,
        labelEn: json['label_en'] as String,
      );
}