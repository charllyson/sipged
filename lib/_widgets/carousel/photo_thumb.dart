import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sisged/_widgets/carousel/photo_item.dart';
import 'package:sisged/_blocs/widgets/carousel/carousel_photo_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:js_util' as jsu;
import 'package:sisged/_utils/images/web_fetch_bytes.dart' show fetchBytesWeb;
import 'package:sisged/_utils/images/heic_web_convert.dart' show convertHeicBytesToJpegWeb;
import 'package:sisged/_blocs/widgets/carousel/carousel_metadata.dart' as pm;

import '../../_utils/images/web_fetch_bytes.dart';

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
    // ⚠️ Placeholder só para HEIC em BYTES locais (não para URL)
    if (item is PhotoBytesItem && item.looksHeic) {
      return _heicPlaceholder(size);
    }

    if (item is PhotoUrlItem) {
      final url = (item as PhotoUrlItem).url;

      if (!kIsWeb) {
        // Mobile/desktop nativo pode usar network direto
        return Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (c, child, prog) => prog == null ? child : _loadingBox(size),
          errorBuilder: (_, __, ___) => _errorBox(size),
        );
      }

      // WEB: sempre carrega por BYTES e converte HEIC se necessário
      return FutureBuilder<Uint8List>(
        future: () async {
          final raw = await fetchBytesWeb(url);
          final fmt = pm.sniffFormat(raw);
          if (fmt == pm.ImgFmt.heic) {
            if (!jsu.hasProperty(html.window, 'heic2any')) {
              // sem conversor -> devolve PNG 1x1 p/ não quebrar layout
              return Uint8List.fromList([137,80,78,71,13,10,26,10,0,0,0,13,73,72,68,82,0,0,0,1,0,0,0,1,8,6,0,0,0,31,21,196,137,0,0,0,10,73,68,65,84,120,156,99,0,1,0,0,5,0,1,13,10,45,66,0,0,0,0,73,69,78,68,174,66,96,130]);
            }
            final jpg = await convertHeicBytesToJpegWeb(raw);
            final isJpeg = jpg.length >= 2 && jpg[0] == 0xFF && jpg[1] == 0xD8;
            return isJpeg ? jpg : raw; // se falhar conversão, pelo menos não explode
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
        child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2
        ),
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
