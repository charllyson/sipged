// lib/_widgets/carousel/models/photo_item.dart
import 'dart:typed_data';
import 'package:siged/_blocs/widgets/carousel/carousel_photo.dart';
import 'package:siged/_blocs/widgets/carousel/carousel_metadata.dart' as pm;

/// Fonte unificada de foto: URL remota ou bytes locais.
sealed class PhotoItem {
  final pm.CarouselMetadata? meta;
  const PhotoItem({this.meta});

  bool get isBytes => this is PhotoBytesItem;
  bool get isUrl => this is PhotoUrlItem;

  /// Helper: tenta detectar HEIC a partir do conteúdo/arquivo
  bool get looksHeic;
}

class PhotoUrlItem extends PhotoItem {
  final String url;
  const PhotoUrlItem(this.url, {super.meta});

  @override
  bool get looksHeic {
    final lower = url.split('?').first.toLowerCase();
    return lower.endsWith('.heic') || lower.endsWith('.heif');
  }
}

class PhotoBytesItem extends PhotoItem {
  final Uint8List bytes;
  const PhotoBytesItem(this.bytes, {super.meta});

  @override
  bool get looksHeic {
    final fmt = pm.sniffFormat(bytes);
    return fmt == pm.ImgFmt.heic;
  }

  factory PhotoBytesItem.fromPicked(CarouselPhoto p, {pm.CarouselMetadata? meta}) {
    return PhotoBytesItem(p.bytes, meta: meta);
  }
}
