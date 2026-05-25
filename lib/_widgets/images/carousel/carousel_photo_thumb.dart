// lib/_widgets/images/carousel/carousel_photo_thumb.dart

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/images/carousel/carousel_photo_theme.dart';
import 'package:sipged/_widgets/images/carousel/models/photo_data.dart';
import 'package:sipged/_widgets/images/carousel/services/photo_utils.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

import 'adapters/image_adapter.dart';

class CarouselPhotoThumb extends StatefulWidget {
  const CarouselPhotoThumb({
    super.key,
    required this.photo,
    required this.theme,
    this.onTap,
    this.onRemove,
    this.removeIcon,
    this.borderRadius,
  });

  final PhotoData photo;
  final CarouselPhotoTheme theme;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final Widget? removeIcon;
  final BorderRadius? borderRadius;

  @override
  State<CarouselPhotoThumb> createState() => _CarouselPhotoThumbState();
}

class _CarouselPhotoThumbState extends State<CarouselPhotoThumb> {
  Future<Uint8List>? _webBytesFuture;
  String? _cachedUrl;

  @override
  void initState() {
    super.initState();
    _prepareIfNeeded();
  }

  @override
  void didUpdateWidget(covariant CarouselPhotoThumb oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.photo.id != widget.photo.id ||
        oldWidget.photo.url != widget.photo.url ||
        oldWidget.photo.bytes != widget.photo.bytes) {
      _prepareIfNeeded(force: true);
    }
  }

  void _prepareIfNeeded({bool force = false}) {
    final photo = widget.photo;

    if (!photo.isUrl || !kIsWeb) {
      _webBytesFuture = null;
      _cachedUrl = null;
      return;
    }

    final url = photo.url!.trim();

    if (!force && _cachedUrl == url && _webBytesFuture != null) {
      return;
    }

    _cachedUrl = url;
    _webBytesFuture = _loadWebBytes(url);
  }

  Future<Uint8List> _loadWebBytes(String url) async {
    final raw = await loadImageBytes(url);

    final isHeic =
        PhotoUtils.sniffFormat(raw) == ImgFmt.heic || sniffIsHeic(raw);

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

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: widget.onTap,
              child: _buildImage(size),
            ),
            if (widget.onRemove != null)
              Positioned(
                right: 4,
                top: 4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onRemove,
                    borderRadius: BorderRadius.circular(12),
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(double size) {
    final photo = widget.photo;

    if (photo.isBytes) {
      final bytes = photo.bytes;

      if (bytes == null || bytes.isEmpty) {
        return _errorBox(size);
      }

      if (photo.looksHeic) {
        return _heicPlaceholder(size);
      }

      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _errorBox(size),
      );
    }

    if (photo.isUrl) {
      final url = photo.url!.trim();

      if (!kIsWeb) {
        if (photo.looksHeic) {
          return _heicPlaceholder(size);
        }

        return Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          loadingBuilder: (context, child, progress) {
            return progress == null ? child : _loadingBox(size);
          },
          errorBuilder: (_, _, _) => _errorBox(size),
        );
      }

      final future = _webBytesFuture;

      if (future == null) {
        return _loadingBox(size);
      }

      return FutureBuilder<Uint8List>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _loadingBox(size);
          }

          final bytes = snapshot.data;

          if (bytes == null || bytes.isEmpty) {
            return _errorBox(size);
          }

          return Image.memory(
            bytes,
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
          Icon(
            Icons.image_not_supported,
            color: Colors.grey,
          ),
          SizedBox(height: 6),
          Text(
            'HEIC\nsem preview',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
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
      child: const LoadingTreeDots(
        size: 18,
        strokeWidth: 2,
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