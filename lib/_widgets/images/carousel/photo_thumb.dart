import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:sipged/_utils/images/image_adapter_loader.dart';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;
import 'package:sipged/_widgets/images/carousel/carousel_photo_theme.dart';
import 'package:sipged/_widgets/images/carousel/photo_item.dart';

class PhotoThumb extends StatefulWidget {
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
  State<PhotoThumb> createState() => _PhotoThumbState();
}

class _PhotoThumbState extends State<PhotoThumb> {
  Future<Uint8List>? _webBytesFuture;
  String? _cachedUrl;

  @override
  void initState() {
    super.initState();
    _prepareIfNeeded();
  }

  @override
  void didUpdateWidget(covariant PhotoThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _prepareIfNeeded(force: true);
    }
  }

  void _prepareIfNeeded({bool force = false}) {
    final item = widget.item;

    if (item is! PhotoUrlItem || !kIsWeb) {
      _webBytesFuture = null;
      _cachedUrl = null;
      return;
    }

    if (!force && _cachedUrl == item.url && _webBytesFuture != null) return;

    _cachedUrl = item.url;
    _webBytesFuture = _loadWebBytes(item.url);
  }

  Future<Uint8List> _loadWebBytes(String url) async {
    final raw = await loadImageBytes(url);
    final isHeic =
        pm.sniffFormat(raw) == pm.ImgFmt.heic || sniffIsHeic(raw);
    if (isHeic) {
      final jpg = await tryConvertHeicToJpeg(raw);
      return jpg ?? raw;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.theme.itemSize;
    final br = widget.borderRadius ?? widget.theme.borderRadius;

    return ClipRRect(
      borderRadius: br,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onTap,
            child: _buildImage(size),
          ),
          if (widget.onRemove != null)
            Positioned(
              right: 4,
              top: 4,
              child: InkWell(
                onTap: widget.onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: widget.theme.removerBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.removeIcon ??
                      Icon(
                        Icons.close,
                        size: 14,
                        color: widget.theme.removerIconColor,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(double size) {
    final item = widget.item;

    if (item is PhotoBytesItem && item.looksHeic) {
      return _heicPlaceholder(size);
    }

    if (item is PhotoBytesItem) {
      return Image.memory(
        item.bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _errorBox(size),
      );
    }

    if (item is PhotoUrlItem) {
      final url = item.url;

      if (!kIsWeb) {
        final looksHeicUrl =
            url.toLowerCase().endsWith('.heic') ||
                url.toLowerCase().endsWith('.heif');

        if (looksHeicUrl) {
          return _heicPlaceholder(size);
        }

        return Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          loadingBuilder: (c, child, prog) =>
          prog == null ? child : _loadingBox(size),
          errorBuilder: (_, _, _) => _errorBox(size),
        );
      }

      final future = _webBytesFuture;
      if (future == null) return _loadingBox(size);

      return FutureBuilder<Uint8List>(
        future: future,
        builder: (c, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return _loadingBox(size);
          }
          if (!snap.hasData) return _errorBox(size);

          return Image.memory(
            snap.data!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _errorBox(size),
          );
        },
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