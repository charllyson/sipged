// lib/_widgets/images/carousel/photo_preview_page.dart

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class PhotoPreviewPage extends StatefulWidget {
  const PhotoPreviewPage({
    super.key,
    required this.originalBytes,
    this.outputJpegQuality = 100,
    this.previewFit = BoxFit.contain,
    this.showOverlayInPreview = true,
    this.debugLog = false,
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
  bool _exporting = false;
  late BoxFit _fit;

  Future<ui.Image>? _imageFuture;

  @override
  void initState() {
    super.initState();
    _fit = widget.previewFit;
    _imageFuture = _decodeImage(widget.originalBytes);
  }

  String _formatDate(DateTime? date) {
    final d = date ?? DateTime.now();

    String two(int v) => v.toString().padLeft(2, '0');

    return '${two(d.day)}/${two(d.month)}/${d.year} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  String _coordValue(double? value) {
    if (value == null) return '—';
    return value.toStringAsFixed(6);
  }

  String _coordLine() {
    if (widget.stampLatitude == null || widget.stampLongitude == null) {
      return 'Sem coordenadas na foto';
    }

    return '${_coordValue(widget.stampLatitude)}, '
        '${_coordValue(widget.stampLongitude)}';
  }

  String _cityStateLine() {
    final city = widget.stampCity?.trim() ?? '';
    final state = widget.stampState?.trim() ?? '';

    if (city.isNotEmpty && state.isNotEmpty) {
      return '$city - $state';
    }

    if (city.isNotEmpty) {
      return city;
    }

    if (state.isNotEmpty) {
      return state;
    }

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

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final completer = Completer<ui.Image>();

    ui.decodeImageFromList(bytes, (image) {
      completer.complete(image);
    });

    return completer.future;
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

  TextPainter _textPainter({
    required String text,
    required double fontSize,
    required FontWeight fontWeight,
    required TextAlign textAlign,
    int maxLines = 1,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: fontWeight,
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
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    );
  }

  Future<Uint8List> _buildStampedImage() async {
    final image = await _decodeImage(widget.originalBytes);

    final outputSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, outputSize.width, outputSize.height),
    );

    final imagePaint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, outputSize.width, outputSize.height),
      Rect.fromLTWH(0, 0, outputSize.width, outputSize.height),
      imagePaint,
    );

    _paintStampOnCanvas(
      canvas: canvas,
      visibleImageRect: Rect.fromLTWH(
        0,
        0,
        outputSize.width,
        outputSize.height,
      ),
      scaleBase: outputSize.shortestSide,
    );

    final picture = recorder.endRecording();

    final stampedImage = await picture.toImage(
      outputSize.width.round(),
      outputSize.height.round(),
    );

    final byteData = await stampedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    image.dispose();
    stampedImage.dispose();

    if (byteData == null) {
      throw StateError('Não foi possível gerar a imagem carimbada.');
    }

    return byteData.buffer.asUint8List();
  }

  void _paintStampOnCanvas({
    required Canvas canvas,
    required Rect visibleImageRect,
    required double scaleBase,
  }) {
    final rect = visibleImageRect;

    if (rect.width <= 0 || rect.height <= 0) return;

    final double fontSize =
    (scaleBase * 0.030).clamp(12.0, 34.0).toDouble();

    final double padding =
    (scaleBase * 0.022).clamp(10.0, 28.0).toDouble();

    final double innerPadding =
    (scaleBase * 0.016).clamp(8.0, 20.0).toDouble();

    final double radius =
    (scaleBase * 0.018).clamp(8.0, 18.0).toDouble();

    final lines = _stampLines();

    final painter = _textPainter(
      text: lines.join('\n'),
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      textAlign: TextAlign.right,
      maxLines: 4,
    );

    final maxStampWidth = rect.width * 0.68;

    painter.layout(
      minWidth: 0,
      maxWidth: maxStampWidth,
    );

    final stampWidth = painter.width + (innerPadding * 2);
    final stampHeight = painter.height + (innerPadding * 2);

    final maxLeft = rect.right - stampWidth - padding;
    final maxTop = rect.bottom - stampHeight - padding;

    final left = maxLeft.clamp(
      rect.left + padding,
      rect.right - stampWidth - padding,
    );

    final top = maxTop.clamp(
      rect.top + padding,
      rect.bottom - stampHeight - padding,
    );

    final stampRect = Rect.fromLTWH(
      left,
      top,
      stampWidth,
      stampHeight,
    );

    final shadowRRect = RRect.fromRectAndRadius(
      stampRect.shift(const Offset(0, 2)),
      Radius.circular(radius),
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.34)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      );

    canvas.drawRRect(shadowRRect, shadowPaint);

    final backgroundRRect = RRect.fromRectAndRadius(
      stampRect,
      Radius.circular(radius),
    );

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.58);

    canvas.drawRRect(backgroundRRect, backgroundPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (scaleBase * 0.002).clamp(0.8, 2.0).toDouble();

    canvas.drawRRect(backgroundRRect, borderPaint);

    painter.paint(
      canvas,
      Offset(
        stampRect.left + innerPadding,
        stampRect.top + innerPadding,
      ),
    );
  }

  Future<void> _confirm() async {
    if (_exporting) return;

    setState(() => _exporting = true);

    try {
      final stampedBytes = await _buildStampedImage();

      if (!mounted) return;

      Navigator.of(context).pop<Uint8List>(stampedBytes);
    } catch (e, s) {
      debugPrint('[PhotoPreviewPage] Falha ao exportar foto carimbada: $e');
      debugPrintStack(stackTrace: s);

      if (!mounted) return;

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Falha ao gerar a foto com carimbo: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  void _toggleFit() {
    setState(() {
      _fit = _fit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = _fit == BoxFit.contain ? 'Preencher' : 'Ajustar';
    final icon = _fit == BoxFit.contain
        ? Icons.crop_free_rounded
        : Icons.fit_screen_rounded;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              bottom: 86,
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
                          child: CircularProgressIndicator(),
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

                      return CustomPaint(
                        size: canvasSize,
                        painter: _PhotoPreviewPainter(
                          image: image,
                          sourceRect: sourceRect,
                          destinationRect: destRect,
                          paintStamp: widget.showOverlayInPreview
                              ? ({
                            required Canvas canvas,
                            required Rect visibleImageRect,
                            required double scaleBase,
                          }) {
                            _paintStampOnCanvas(
                              canvas: canvas,
                              visibleImageRect: visibleImageRect,
                              scaleBase: scaleBase,
                            );
                          }
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: _TopActionButton(
                icon: icon,
                label: label,
                onTap: _exporting ? null : _toggleFit,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: 'Fechar',
                onPressed: _exporting
                    ? null
                    : () => Navigator.of(context).pop<Uint8List?>(null),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _exporting
                          ? null
                          : () => Navigator.of(context).pop<Uint8List?>(null),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exporting ? null : _confirm,
                      icon: _exporting
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                        ),
                      )
                          : const Icon(Icons.check_rounded),
                      label: Text(_exporting ? 'Gerando...' : 'Usar foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreviewPainter extends CustomPainter {
  const _PhotoPreviewPainter({
    required this.image,
    required this.sourceRect,
    required this.destinationRect,
    this.paintStamp,
  });

  final ui.Image image;
  final Rect sourceRect;
  final Rect destinationRect;

  final void Function({
  required Canvas canvas,
  required Rect visibleImageRect,
  required double scaleBase,
  })? paintStamp;

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

    paintStamp?.call(
      canvas: canvas,
      visibleImageRect: destinationRect,
      scaleBase: destinationRect.shortestSide,
    );
  }

  @override
  bool shouldRepaint(covariant _PhotoPreviewPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.sourceRect != sourceRect ||
        oldDelegate.destinationRect != destinationRect ||
        oldDelegate.paintStamp != paintStamp;
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}