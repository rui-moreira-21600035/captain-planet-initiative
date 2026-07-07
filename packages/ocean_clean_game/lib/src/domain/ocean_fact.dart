class OceanFact {
  final String id;
  final String factPT;
  final String factEN;

  const OceanFact({
    required this.id,
    required this.factPT,
    required this.factEN   
  });

  factory OceanFact.fromJson(Map<String, dynamic> json) {
    return OceanFact(
      id: json['id'] as String,
      factPT: json['fact_pt'] as String,
      factEN: json['fact_en'] as String,
    );
  }
}