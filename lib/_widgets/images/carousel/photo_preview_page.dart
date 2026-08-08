// lib/_widgets/images/carousel/photo_preview_page.dart

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:sipged/_widgets/images/carousel/models/photo_data.dart';
import 'package:sipged/_widgets/images/carousel/photo_editor_page.dart';
import 'package:sipged/_widgets/images/carousel/services/photo_stamp_service.dart';

class PhotoPreviewPage extends StatefulWidget {
  const PhotoPreviewPage({
    super.key,
    required this.originalBytes,
    this.outputJpegQuality = 88,
    this.previewFit = BoxFit.contain,
    this.showOverlayInPreview = true,
    this.debugLog = false,
    this.allowEditCrop = true,
    this.editorMaxScale = 5.0,
    this.editorAspectRatios,
    this.stampDate,
    this.stampName,
    this.stampLatitude,
    this.stampLongitude,
    this.stampDevice,
    this.stampAddress,
    this.stampCity,
    this.stampState,
  });

  final Uint8List originalBytes;
  final int outputJpegQuality;
  final BoxFit previewFit;
  final bool showOverlayInPreview;
  final bool debugLog;

  final bool allowEditCrop;

  final double editorMaxScale;
  final List<double>? editorAspectRatios;

  final DateTime? stampDate;
  final String? stampName;
  final double? stampLatitude;
  final double? stampLongitude;
  final String? stampDevice;
  final String? stampAddress;
  final String? stampCity;
  final String? stampState;

  @override
  State<PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<PhotoPreviewPage> {
  static const double _bottomBarHeight = 118.0;

  bool _exporting = false;
  bool _editing = false;

  late BoxFit _fit;
  late Uint8List _workingBytes;
  Future<ui.Image>? _imageFuture;

  bool _stampVisible = true;
  bool _favorite = false;

  Offset _stampRelativePosition = const Offset(1.0, 1.0);

  @override
  void initState() {
    super.initState();

    _fit = widget.previewFit;
    _workingBytes = widget.originalBytes;
    _imageFuture = _decodeImage(_workingBytes);
    _stampVisible = widget.showOverlayInPreview;
  }


  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final completer = Completer<ui.Image>();

    ui.decodeImageFromList(bytes, (image) {
      completer.complete(image);
    });

    return completer.future;
  }

  String _formatDate(DateTime? date) {
    final d = date ?? DateTime.now();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(d.day)}/${two(d.month)}/${d.year} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  String _coordLine() {
    final lat = widget.stampLatitude;
    final lng = widget.stampLongitude;

    if (lat == null || lng == null) {
      return 'Sem coordenadas na foto';
    }

    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  String _cityStateLine() {
    final city = widget.stampCity?.trim() ?? '';
    final state = widget.stampState?.trim() ?? '';

    if (city.isNotEmpty && state.isNotEmpty) {
      return '$city - $state';
    }

    if (city.isNotEmpty) return city;
    if (state.isNotEmpty) return state;

    return 'Cidade não disponível';
  }

  List<String> _stampLines() {
    final address = widget.stampAddress?.trim();

    return <String>[
      _formatDate(widget.stampDate),
      _coordLine(),
      address == null || address.isEmpty ? 'Endereço não disponível' : address,
      _cityStateLine(),
    ];
  }

  PhotoData _stampPhoto() {
    return PhotoData(
      id: 'preview_stamp',
      name: widget.stampName?.trim().isNotEmpty == true
          ? widget.stampName!.trim()
          : 'foto.jpg',
      bytes: _workingBytes,
      takenAt: widget.stampDate,
      lat: widget.stampLatitude,
      lng: widget.stampLongitude,
      address: widget.stampAddress,
      city: widget.stampCity,
      state: widget.stampState,
      make: widget.stampDevice,
    );
  }

  Rect _destinationRect({
    required Size imageSize,
    required Size canvasSize,
    required BoxFit fit,
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

  Rect _sourceRect({
    required Size imageSize,
    required Size canvasSize,
    required BoxFit fit,
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

  Future<void> _openEditor() async {
    if (_editing || _exporting || !widget.allowEditCrop) return;

    setState(() => _editing = true);

    try {
      final editedBytes = await Navigator.of(context, rootNavigator: true)
          .push<Uint8List?>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PhotoEditorPage(
            originalBytes: _workingBytes,
            maxScale: widget.editorMaxScale,
            exportQuality: widget.outputJpegQuality,
            circleCrop: false,
            aspectRatios: widget.editorAspectRatios,
            preferNative: true,
            writeExif: true,
            exifDateTime: widget.stampDate,
            exifLatitude: widget.stampLatitude,
            exifLongitude: widget.stampLongitude,
            exifSoftware: 'Sipged/Flutter',
          ),
        ),
      );

      if (editedBytes == null || editedBytes.isEmpty) return;
      if (!mounted) return;

      setState(() {
        _workingBytes = editedBytes;
        _imageFuture = _decodeImage(_workingBytes);
      });
    } catch (e, s) {
      debugPrint('[PhotoPreviewPage] Falha ao editar foto: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Falha ao editar a foto: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _editing = false);
      }
    }
  }

  Future<Uint8List> _buildFinalImage() async {
    final image = await _decodeImage(_workingBytes);

    final outputSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(
        0,
        0,
        outputSize.width,
        outputSize.height,
      ),
    );

    final imagePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    final fullImageRect = Rect.fromLTWH(
      0,
      0,
      outputSize.width,
      outputSize.height,
    );

    canvas.drawImageRect(
      image,
      fullImageRect,
      fullImageRect,
      imagePaint,
    );

    if (_stampVisible) {
      PhotoStampService.paintStampOnCanvas(
        canvas: canvas,
        visibleImageRect: fullImageRect,
        scaleBase: outputSize.shortestSide,
        photo: _stampPhoto(),
      );
    }

    final picture = recorder.endRecording();

    final finalImage = await picture.toImage(
      outputSize.width.round(),
      outputSize.height.round(),
    );

    final byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    image.dispose();
    finalImage.dispose();

    if (byteData == null) {
      throw StateError('Não foi possível gerar a imagem final.');
    }

    return byteData.buffer.asUint8List();
  }

  Future<void> _confirm() async {
    await _closeApplyingCurrentPhoto();
  }

  Future<void> _closeApplyingCurrentPhoto() async {
    if (_exporting || _editing) return;

    setState(() => _exporting = true);

    try {
      final finalBytes = await _buildFinalImage();

      if (!mounted) return;

      Navigator.of(context).pop<Uint8List>(finalBytes);
    } catch (e, s) {
      debugPrint('[PhotoPreviewPage] Falha ao aplicar foto final: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Falha ao aplicar a foto: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  void _discardAndClose() {
    if (_exporting || _editing) return;

    Navigator.of(context).pop<Uint8List?>(null);
  }

  void _toggleFit() {
    if (_exporting || _editing) return;

    setState(() {
      _fit = _fit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
    });
  }

  void _toggleStampVisible() {
    if (_exporting || _editing) return;

    setState(() {
      _stampVisible = !_stampVisible;
    });
  }

  void _toggleFavorite() {
    if (_exporting || _editing) return;

    setState(() {
      _favorite = !_favorite;
    });
  }

  void _moveStamp({
    required DragUpdateDetails details,
    required Rect imageRect,
  }) {
    if (!_stampVisible) return;
    if (imageRect.width <= 0 || imageRect.height <= 0) return;

    final dx = details.delta.dx / imageRect.width;
    final dy = details.delta.dy / imageRect.height;

    setState(() {
      _stampRelativePosition = Offset(
        (_stampRelativePosition.dx + dx).clamp(0.0, 1.0),
        (_stampRelativePosition.dy + dy).clamp(0.0, 1.0),
      );
    });
  }

  void _confirmDelete() {
    if (_exporting || _editing) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  size: 42,
                  color: Color(0xFFFF3B30),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Excluir esta foto?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A foto será descartada deste preview.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Color(0xFF6E6E73),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3B30),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _discardAndClose();
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Excluir'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _exporting || _editing;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              bottom: _bottomBarHeight,
              child: Container(
                color: Colors.black,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );

                    return FutureBuilder<ui.Image>(
                      future: _imageFuture,
                      builder: (context, snapshot) {
                        final image = snapshot.data;

                        if (image == null) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }

                        final imageSize = Size(
                          image.width.toDouble(),
                          image.height.toDouble(),
                        );

                        final destRect = _destinationRect(
                          imageSize: imageSize,
                          canvasSize: canvasSize,
                          fit: _fit,
                        );

                        final sourceRect = _sourceRect(
                          imageSize: imageSize,
                          canvasSize: canvasSize,
                          fit: _fit,
                        );

                        return Stack(
                          children: [
                            CustomPaint(
                              size: canvasSize,
                              painter: _PhotoPreviewImagePainter(
                                image: image,
                                sourceRect: sourceRect,
                                destinationRect: destRect,
                              ),
                            ),
                            if (_stampVisible)
                              _StampPreviewOverlay(
                                imageRect: destRect,
                                relativePosition: _stampRelativePosition,
                                lines: _stampLines(),
                                onDrag: (details) {
                                  _moveStamp(
                                    details: details,
                                    imageRect: destRect,
                                  );
                                },
                                onRemove: _toggleStampVisible,
                              ),
                            if (_favorite)
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.42),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _FloatingCloseButton(
                enabled: !isBusy,
                onTap: _closeApplyingCurrentPhoto,
              ),
            ),
            if (isBusy)
              Positioned.fill(
                bottom: _bottomBarHeight,
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.18),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _editing ? 'Editando...' : 'Gerando...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _PhotoBottomActionBar(
                exporting: _exporting,
                editing: _editing,
                favorite: _favorite,
                stampVisible: _stampVisible,
                fit: _fit,
                allowEditCrop: widget.allowEditCrop,
                onUse: _confirm,
                onFavorite: _toggleFavorite,
                onToggleStamp: _toggleStampVisible,
                onEditCrop: _openEditor,
                onToggleFit: _toggleFit,
                onDelete: _confirmDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreviewImagePainter extends CustomPainter {
  const _PhotoPreviewImagePainter({
    required this.image,
    required this.sourceRect,
    required this.destinationRect,
  });

  final ui.Image image;
  final Rect sourceRect;
  final Rect destinationRect;

  @override
  void paint(Canvas canvas, Size size) {
    final imagePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      image,
      sourceRect,
      destinationRect,
      imagePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PhotoPreviewImagePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.sourceRect != sourceRect ||
        oldDelegate.destinationRect != destinationRect;
  }
}

class _StampPreviewOverlay extends StatelessWidget {
  const _StampPreviewOverlay({
    required this.imageRect,
    required this.relativePosition,
    required this.lines,
    required this.onDrag,
    required this.onRemove,
  });

  final Rect imageRect;
  final Offset relativePosition;
  final List<String> lines;
  final void Function(DragUpdateDetails details) onDrag;
  final VoidCallback onRemove;

  double _safeClampDouble(
      double value, {
        required double min,
        required double max,
      }) {
    if (value.isNaN || min.isNaN || max.isNaN) return 0.0;
    if (max <= 0) return 0.0;

    final safeMin = math.min(min, max);
    final safeMax = math.max(safeMin, max);

    return value.clamp(safeMin, safeMax).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (imageRect.width <= 0 || imageRect.height <= 0) {
      return const SizedBox.shrink();
    }

    final scaleBase = imageRect.shortestSide;

    final fontSize = _safeClampDouble(
      scaleBase * 0.030,
      min: 10.0,
      max: 26.0,
    );

    final padding = _safeClampDouble(
      scaleBase * 0.016,
      min: 7.0,
      max: 16.0,
    );

    final width = _safeClampDouble(
      imageRect.width * 0.68,
      min: 140.0,
      max: imageRect.width,
    );

    final estimatedHeight = _safeClampDouble(
      fontSize * 4.9 + padding * 2,
      min: 64.0,
      max: imageRect.height,
    );

    final maxLeft = imageRect.right - width;
    final maxTop = imageRect.bottom - estimatedHeight;

    final left =
        imageRect.left + (maxLeft - imageRect.left) * relativePosition.dx;
    final top =
        imageRect.top + (maxTop - imageRect.top) * relativePosition.dy;

    final resolvedLeft = _safeClampDouble(
      left,
      min: imageRect.left,
      max: maxLeft,
    );

    final resolvedTop = _safeClampDouble(
      top,
      min: imageRect.top,
      max: maxTop,
    );

    return Positioned(
      left: resolvedLeft,
      top: resolvedTop,
      width: width,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onDrag,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: width,
              child: Container(
                width: width,
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.34),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  lines.join('\n'),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    height: 1.16,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.86),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -10,
              top: -10,
              child: Material(
                color: Colors.black.withValues(alpha: 0.80),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
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

class _PhotoBottomActionBar extends StatelessWidget {
  const _PhotoBottomActionBar({
    required this.exporting,
    required this.editing,
    required this.favorite,
    required this.stampVisible,
    required this.fit,
    required this.allowEditCrop,
    required this.onUse,
    required this.onFavorite,
    required this.onToggleStamp,
    required this.onEditCrop,
    required this.onToggleFit,
    required this.onDelete,
  });

  final bool exporting;
  final bool editing;
  final bool favorite;
  final bool stampVisible;
  final BoxFit fit;
  final bool allowEditCrop;

  final VoidCallback onUse;
  final VoidCallback onFavorite;
  final VoidCallback onToggleStamp;
  final VoidCallback onEditCrop;
  final VoidCallback onToggleFit;
  final VoidCallback onDelete;

  bool get _busy => exporting || editing;

  @override
  Widget build(BuildContext context) {
    final fitIsContain = fit == BoxFit.contain;

    return Container(
      height: 118,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 22,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          child: Row(
            children: [
              _RoundActionButton(
                tooltip: 'Usar foto',
                icon: exporting
                    ? Icons.hourglass_top_rounded
                    : Icons.ios_share_rounded,
                onTap: _busy ? null : onUse,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FlatActionButton(
                      tooltip: favorite
                          ? 'Remover dos favoritos'
                          : 'Adicionar aos favoritos',
                      icon: favorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      active: favorite,
                      onTap: _busy ? null : onFavorite,
                    ),
                    const SizedBox(width: 23),
                    _FlatActionButton(
                      tooltip: stampVisible
                          ? 'Ocultar carimbo'
                          : 'Mostrar carimbo',
                      icon: stampVisible
                          ? Icons.info_outline_rounded
                          : Icons.info_rounded,
                      active: stampVisible,
                      onTap: _busy ? null : onToggleStamp,
                    ),
                    const SizedBox(width: 23),
                    _FlatActionButton(
                      tooltip: 'Editar corte',
                      icon: Icons.tune_rounded,
                      onTap: _busy || !allowEditCrop ? null : onEditCrop,
                    ),
                    const SizedBox(width: 23),
                    _FlatActionButton(
                      tooltip:
                      fitIsContain ? 'Preencher tela' : 'Ajustar imagem',
                      icon: fitIsContain
                          ? Icons.crop_free_rounded
                          : Icons.fit_screen_rounded,
                      onTap: _busy ? null : onToggleFit,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _RoundActionButton(
                tooltip: 'Excluir',
                icon: Icons.delete_outline_rounded,
                destructive: true,
                onTap: _busy ? null : onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFFF3B30)
        : const Color(0xFF1C1C1E);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFF8F8F8),
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Icon(
              icon,
              color: onTap == null ? color.withValues(alpha: 0.30) : color,
              size: 31,
            ),
          ),
        ),
      ),
    );
  }
}

class _FlatActionButton extends StatelessWidget {
  const _FlatActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF007AFF)
        : const Color(0xFF1C1C1E);

    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Icon(
          icon,
          color: onTap == null ? color.withValues(alpha: 0.30) : color,
          size: 33,
        ),
      ),
    );
  }
}

class _FloatingCloseButton extends StatelessWidget {
  const _FloatingCloseButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            Icons.close_rounded,
            color: enabled
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
            size: 28,
          ),
        ),
      ),
    );
  }
}