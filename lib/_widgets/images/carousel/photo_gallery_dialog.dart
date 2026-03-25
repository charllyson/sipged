import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:sipged/_utils/images/image_adapter_loader.dart';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;
import 'package:sipged/_widgets/images/carousel/photo_item.dart';
import 'package:sipged/_widgets/images/carousel/photo_metadata_overlay.dart';

enum _FitMode { cover, contain }

Future<void> showPhotoGalleryDialog(
    BuildContext context, {
      required List<PhotoItem> items,
      int initialIndex = 0,
    }) async {
  if (!context.mounted || items.isEmpty) return;

  await showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.8),
    builder: (_) => _PhotoGalleryDialog(
      items: items,
      initialIndex: initialIndex,
    ),
  );
}

class _PhotoGalleryDialog extends StatefulWidget {
  final List<PhotoItem> items;
  final int initialIndex;

  const _PhotoGalleryDialog({
    required this.items,
    required this.initialIndex,
  });

  @override
  State<_PhotoGalleryDialog> createState() => _PhotoGalleryDialogState();
}

class _PhotoGalleryDialogState extends State<_PhotoGalleryDialog> {
  late final PageController _controller;
  late int _idx;
  _FitMode _fitMode = _FitMode.cover;
  final Map<String, Future<Uint8List>> _webCache = {};

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex.clamp(0, widget.items.length - 1);
    _controller = PageController(initialPage: _idx);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<Uint8List> _loadWebUrl(String url) {
    return _webCache.putIfAbsent(url, () async {
      final raw = await loadImageBytes(url);
      final isHeic =
          pm.sniffFormat(raw) == pm.ImgFmt.heic || sniffIsHeic(raw);
      final converted = isHeic ? await tryConvertHeicToJpeg(raw) : null;
      return converted ?? raw;
    });
  }

  Widget _buildImage(PhotoItem item) {
    final fit = _fitMode == _FitMode.cover ? BoxFit.cover : BoxFit.contain;

    if (item is PhotoBytesItem) {
      return Positioned.fill(
        child: Image.memory(
          item.bytes,
          fit: fit,
          gaplessPlayback: true,
        ),
      );
    }

    if (item is PhotoUrlItem) {
      if (!kIsWeb) {
        return Positioned.fill(
          child: Image.network(
            item.url,
            fit: fit,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const Center(
              child: Text(
                'Erro ao carregar',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        );
      }

      return FutureBuilder<Uint8List>(
        future: _loadWebUrl(item.url),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          if (!snap.hasData) {
            return const Center(
              child: Text(
                'Falha ao carregar imagem',
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }

          return Positioned.fill(
            child: Image.memory(
              snap.data!,
              fit: fit,
              gaplessPlayback: true,
            ),
          );
        },
      );
    }

    return const Center(
      child: Text(
        'Tipo de foto desconhecido',
        style: TextStyle(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_idx];

    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, c) {
          return ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1200,
              maxHeight: 800,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _idx = i),
                    itemCount: widget.items.length,
                    itemBuilder: (_, pageIndex) {
                      return Stack(
                        children: [
                          _buildImage(widget.items[pageIndex]),
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
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: PhotoMetadataOverlay(meta: item.meta),
                ),
                if (widget.items.length > 1) ...[
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: IconButton(
                        onPressed: _idx > 0
                            ? () => _controller.previousPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        )
                            : null,
                        icon: const Icon(Icons.chevron_left, size: 42),
                        color: Colors.white.withValues(
                          alpha: _idx > 0 ? 0.9 : 0.3,
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
                        onPressed: _idx < widget.items.length - 1
                            ? () => _controller.nextPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        )
                            : null,
                        icon: const Icon(Icons.chevron_right, size: 42),
                        color: Colors.white.withValues(
                          alpha: _idx < widget.items.length - 1 ? 0.9 : 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
                Positioned(
                  left: 8,
                  top: 8,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () {
                      setState(() {
                        _fitMode = _fitMode == _FitMode.cover
                            ? _FitMode.contain
                            : _FitMode.cover;
                      });
                    },
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
              ],
            ),
          );
        },
      ),
    );
  }
}