import 'bin_type.dart';

class BinTypeMapper {
  static BinType fromId(String id) {
    switch (id) {
      case 'blue':
        return BinType.blue;
      case 'green':
        return BinType.green;
      case 'yellow':
        return BinType.yellow;
      case 'brown':
        return BinType.brown;
      default:
        throw StateError('Bin id desconhecido: $id');
    }
  }

  static String toId(BinType type) {
    switch (type) {
      case BinType.blue:
        return 'blue';
      case BinType.green:
        return 'green';
      case BinType.yellow:
        return 'yellow';
      case BinType.brown:
        return 'brown';
    }
  }
}