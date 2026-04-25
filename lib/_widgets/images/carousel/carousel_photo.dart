import 'dart:typed_data';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart';

class CarouselData {
  final String name;
  final Uint8List bytes;
  final CarouselMetadata meta; // ⟵ metadados EXIF (pode estar vazio)

  CarouselData({
    required this.name,
    required this.bytes,
    this.meta = const CarouselMetadata(),
  });
}
