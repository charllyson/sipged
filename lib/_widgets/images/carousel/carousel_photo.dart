import 'dart:typed_data';
import 'package:siged/_widgets/images/carousel/carousel_metadata.dart';

class CarouselPhoto {
  final String name;
  final Uint8List bytes;
  final CarouselMetadata meta; // ⟵ metadados EXIF (pode estar vazio)

  CarouselPhoto({
    required this.name,
    required this.bytes,
    this.meta = const CarouselMetadata(),
  });
}
