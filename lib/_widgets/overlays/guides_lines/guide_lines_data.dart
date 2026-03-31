
import 'dart:ui';

class GuideLinesResolvedRect {
  final Rect rect;
  final GuideLinesData? guides;

  const GuideLinesResolvedRect({
    required this.rect,
    required this.guides,
  });
}

class GuideLinesData {
  final double? vertical;
  final double? horizontal;

  const GuideLinesData({
    this.vertical,
    this.horizontal,
  });

  @override
  bool operator ==(Object other) {
    return other is GuideLinesData &&
        other.vertical == vertical &&
        other.horizontal == horizontal;
  }

  @override
  int get hashCode => Object.hash(vertical, horizontal);
}
