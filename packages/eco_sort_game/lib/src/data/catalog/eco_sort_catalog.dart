import 'catalog_bin.dart';
import 'catalog_item.dart';

class EcoSortCatalog {
  final int version;
  final List<CatalogBin> bins;
  final List<CatalogItem> items;

  const EcoSortCatalog({
    required this.version,
    required this.bins,
    required this.items,
  });
}