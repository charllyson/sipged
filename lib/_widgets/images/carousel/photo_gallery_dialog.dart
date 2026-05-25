// lib/_widgets/images/carousel/photo_gallery_dialog.dart

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:sipged/_widgets/images/carousel/adapters/image_adapter_loader.dart';
import 'package:sipged/_widgets/images/carousel/models/photo_data.dart';
import 'package:sipged/_widgets/images/carousel/services/photo_stamp_service.dart';
import 'package:sipged/_widgets/images/carousel/services/photo_utils.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

enum _FitMode {
  cover,
  contain,
}

Future<void> showPhotoGalleryDialog(
    BuildContext context, {
      required List<PhotoData> photos,
      int initialIndex = 0,
    }) async {
  if (!context.mounted || photos.isEmpty) return;

  await showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.8),
    builder: (_) => _PhotoGalleryDialog(
      photos: photos,
      initialIndex: initialIndex,
    ),
  );
}

class _PhotoGalleryDialog extends StatefulWidget {
  const _PhotoGalleryDialog({
    required this.photos,
    required this.initialIndex,
  });

  final List<PhotoData> photos;
  final int initialIndex;

  @override
  State<_PhotoGalleryDialog> createState() => _PhotoGalleryDialogState();
}

class _PhotoGalleryDialogState extends State<_PhotoGalleryDialog> {
  late final PageController _controller;
  late int _index;

  _FitMode _fitMode = _FitMode.cover;

  final Map<String, Future<Uint8List>> _bytesCache = <String, Future<Uint8List>>{};
  final Map<String, Future<ui.Image>> _imageCache = <String, Future<ui.Image>>{};

  @override
  void initState() {
    super.initState();

    _index = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _cacheKey(PhotoData photo) {
    if (photo.bytes != null) return 'bytes_${photo.id}_${photo.bytes!.length}';
    return 'url_${photo.id}_${photo.url ?? ''}';
  }

  Future<Uint8List> _loadPhotoBytes(PhotoData photo) {
    final key = _cacheKey(photo);

    return _bytesCache.putIfAbsent(key, () async {
      final localBytes = photo.bytes;

      if (localBytes != null && localBytes.isNotEmpty) {
        return _normalizePreviewBytes(localBytes);
      }

      final url = photo.url?.trim();

      if (url == null || url.isEmpty) {
        throw StateError('Imagem sem bytes e sem URL.');
      }

      final raw = await loadImageBytes(url);

      return _normalizePreviewBytes(raw);
    });
  }

  Future<Uint8List> _normalizePreviewBytes(Uint8List raw) async {
    final isHeic = PhotoUtils.sniffIsHeic(raw) || sniffIsHeic(raw);

    if (!isHeic) return raw;

    final converted = await tryConvertHeicToJpeg(raw);

    return converted ?? raw;
  }

  Future<ui.Image> _decodeImage(PhotoData photo) {
    final key = _cacheKey(photo);

    return _imageCache.putIfAbsent(key, () async {
      final bytes = await _loadPhotoBytes(photo);

      final completer = Completer<ui.Image>();

      ui.decodeImageFromList(bytes, (image) {
        completer.complete(image);
      });

      return completer.future;
    });
  }

  Widget _buildPhotoPreview(PhotoData photo) {
    return FutureBuilder<ui.Image>(
      future: _decodeImage(photo),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: LoadingTreeDots(
              size: 24,
              strokeWidth: 2,
            ),
          );
        }

        final image = snapshot.data;

        if (image == null) {
          return _errorText('Falha ao carregar imagem');
        }

        final fit = _fitMode == _FitMode.cover ? BoxFit.cover : BoxFit.contain;

        return Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final canvasSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              return CustomPaint(
                size: canvasSize,
                painter: _PhotoGalleryStampedPainter(
                  image: image,
                  photo: photo,
                  fit: fit,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _errorText(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  void _toggleFitMode() {
    setState(() {
      _fitMode = _fitMode == _FitMode.cover
          ? _FitMode.contain
          : _FitMode.cover;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1200,
          maxHeight: 800,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) {
                  setState(() {
                    _index = i;
                  });
                },
                itemCount: widget.photos.length,
                itemBuilder: (_, pageIndex) {
                  return Stack(
                    children: [
                      _buildPhotoPreview(widget.photos[pageIndex]),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                color: Colors.white,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                tooltip: 'Fechar',
              ),
            ),
            if (widget.photos.length > 1) ...[
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: _index > 0
                        ? () => _controller.previousPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    )
                        : null,
                    icon: const Icon(Icons.chevron_left, size: 42),
                    color: Colors.white.withValues(
                      alpha: _index > 0 ? 0.9 : 0.3,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    onPressed: _index < widget.photos.length - 1
                        ? () => _controller.nextPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    )
                        : null,
                    icon: const Icon(Icons.chevron_right, size: 42),
                    color: Colors.white.withValues(
                      alpha: _index < widget.photos.length - 1 ? 0.9 : 0.3,
                    ),
                  ),
                ),
              ),
            ],
            Positioned(
              left: 8,
              top: 8,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black.withValues(alpha: 0.22),
                ),
                onPressed: _toggleFitMode,
                icon: Icon(
                  _fitMode == _FitMode.cover
                      ? Icons.crop
                      : Icons.fit_screen,
                ),
                label: Text(
                  _fitMode == _FitMode.cover ? 'Preencher' : 'Ajustar',
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_index + 1} de ${widget.photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
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
}

class _PhotoGalleryStampedPainter extends CustomPainter {
  const _PhotoGalleryStampedPainter({
    required this.image,
    required this.photo,
    required this.fit,
  });

  final ui.Image image;
  final PhotoData photo;
  final BoxFit fit;

  Rect _sourceRect({
    required Size imageSize,
    required Size canvasSize,
  }) {
    final fitted = applyBoxFit(fit, imageSize, canvasSize);
    final sourceSize = fitted.source;

    final dx = (imageSize.width - sourceSize.width) / 2.0;
    final dy = (imageSize.height - sourceSize.height) / 2.0;

    return Rect.fromLTWH(
      dx,
      dy,
      sourceSize.width,
      sourceSize.height,
    );
  }

  Rect _destinationRect({
    required Size imageSize,
    required Size canvasSize,
  }) {
    final fitted = applyBoxFit(fit, imageSize, canvasSize);
    final destinationSize = fitted.destination;

    final dx = (canvasSize.width - destinationSize.width) / 2.0;
    final dy = (canvasSize.height - destinationSize.height) / 2.0;

    return Rect.fromLTWH(
      dx,
      dy,
      destinationSize.width,
      destinationSize.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final source = _sourceRect(
      imageSize: imageSize,
      canvasSize: size,
    );

    final destination = _destinationRect(
      imageSize: imageSize,
      canvasSize: size,
    );

    final imagePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      image,
      source,
      destination,
      imagePaint,
    );

    PhotoStampService.paintStampOnCanvas(
      canvas: canvas,
      visibleImageRect: destination,
      scaleBase: destination.shortestSide,
      photo: photo,
    );
  }

  @override
  bool shouldRepaint(covariant _PhotoGalleryStampedPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.photo != photo ||
        oldDelegate.fit != fit;
  }
}