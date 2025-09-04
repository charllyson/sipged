import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:siged/_widgets/carousel/photo_item.dart';
import 'package:siged/_blocs/widgets/carousel/carousel_photo_theme.dart';
import 'package:siged/_blocs/widgets/carousel/carousel_metadata.dart' as pm;

// IMPORTE o loader condicional (ele puxa web/io certo):
import 'package:siged/_utils/images/image_adapter_loader.dart';

class PhotoThumb extends StatelessWidget {
  final PhotoItem item;
  final CarouselPhotoTheme theme;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final Widget? removeIcon;
  final BorderRadius? borderRadius;

  const PhotoThumb({
    super.key,
    required this.item,
    required this.theme,
    this.onTap,
    this.onRemove,
    this.removeIcon,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final size = theme.itemSize;
    final br = borderRadius ?? theme.borderRadius;

    final Widget img = _buildImage(size);

    return ClipRRect(
      borderRadius: br,
      child: Stack(
        children: [
          GestureDetector(onTap: onTap, child: img),
          if (onRemove != null)
            Positioned(
              right: 4,
              top: 4,
              child: InkWell(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.removerBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: removeIcon ??
                      Icon(Icons.close, size: 14, color: theme.removerIconColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(double size) {
    // Placeholder para HEIC em BYTES locais
    if (item is PhotoBytesItem && item.looksHeic) {
      return _heicPlaceholder(size);
    }

    if (item is PhotoUrlItem) {
      final url = (item as PhotoUrlItem).url;

      if (!kIsWeb) {
        // Mobile/Desktop nativo pode usar network direto
        final looksHeicUrl = url.toLowerCase().endsWith('.heic') || url.toLowerCase().endsWith('.heif');
        if (looksHeicUrl) {
          // Android pode não renderizar HEIC -> mostre placeholder
          return _heicPlaceholder(size);
        }
        return Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (c, child, prog) => prog == null ? child : _loadingBox(size),
          errorBuilder: (_, __, ___) => _errorBox(size),
        );
      }

      // WEB: baixar bytes + converter HEIC se possível
      return FutureBuilder<Uint8List>(
        future: () async {
          final raw = await loadImageBytes(url);
          final isHeic = pm.sniffFormat(raw) == pm.ImgFmt.heic || sniffIsHeic(raw);
          if (isHeic) {
            final jpg = await tryConvertHeicToJpeg(raw);
            return jpg ?? raw; // se não converter, usa raw
          }
          return raw; // jpg/png/webp...
        }(),
        builder: (c, snap) {
          if (snap.connectionState != ConnectionState.done) return _loadingBox(size);
          if (!snap.hasData) return _errorBox(size);
          return Image.memory(
            snap.data!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _errorBox(size),
          );
        },
      );
    }

    if (item is PhotoBytesItem) {
      final bytes = (item as PhotoBytesItem).bytes;
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorBox(size),
      );
    }

    return _errorBox(size);
  }

  Widget _heicPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported, color: Colors.grey),
          SizedBox(height: 6),
          Text(
            'HEIC\nsem preview',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _loadingBox(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _errorBox(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image),
    );
  }
}
