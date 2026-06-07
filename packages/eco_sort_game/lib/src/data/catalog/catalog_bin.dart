class CatalogBin {
  final String id;     // "blue"
  final String labelPt;  // "Papel"
  final String labelEn;  // "Paper"
  final String asset;  // "assets/images/containers/blue.png"

  const CatalogBin({
    required this.id,
    required this.labelPt,
    required this.labelEn,
    required this.asset,
  });

  factory CatalogBin.fromJson(Map<String, dynamic> json) => CatalogBin(
        id: json['id'] as String,
        labelPt: json['label_pt'] as String,
        labelEn: json['label_en'] as String,
        asset: json['asset'] as String,
      );
}