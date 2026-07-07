import 'package:flame/components.dart';

class OceanCleanSafeZone {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const OceanCleanSafeZone({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory OceanCleanSafeZone.fromResolution(Vector2 resolution) {
    return OceanCleanSafeZone(
      left: resolution.x * 0.10,
      right: resolution.x * 0.40,
      top: resolution.y * 0.20,
      bottom: resolution.y * 0.80,
    );
  }

  double get width => right - left;
  double get height => bottom - top;

  bool contains(Vector2 position) {
    return position.x >= left &&
        position.x <= right &&
        position.y >= top &&
        position.y <= bottom;
  }
}