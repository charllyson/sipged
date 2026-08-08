// lib/_widgets/images/carousel/photo_editor_page.dart

import 'dart:io' show File, Platform;
import 'package:exif/exif.dart' as exif;
import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/image_editor.dart' as ien;
import 'package:native_exif/native_exif.dart';
import 'package:path_provider/path_provider.dart';

class PhotoEditorPage extends StatefulWidget {
  const PhotoEditorPage({
    super.key,
    required this.originalBytes,
    this.maxScale = 5.0,
    this.exportQuality = 90,
    this.circleCrop = false,
    this.aspectRatios,
    this.preferNative = true,
    this.writeExif = true,
    this.exifImageDescription,
    this.exifUserComment,
    this.exifSoftware = 'Sipged/Flutter',
    this.exifArtist,
    this.exifCopyright,
    this.exifDateTime,
    this.exifLatitude,
    this.exifLongitude,
    this.exifAltitude,
  });

  final Uint8List originalBytes;
  final double maxScale;
  final int exportQuality;
  final bool circleCrop;
  final List<double>? aspectRatios;

  /// Tenta usar image_editor primeiro.
  /// Se falhar, agora cai automaticamente no exportador Dart.
  final bool preferNative;

  final bool writeExif;
  final String? exifImageDescription;
  final String? exifUserComment;
  final String? exifSoftware;
  final String? exifArtist;
  final String? exifCopyright;
  final DateTime? exifDateTime;
  final double? exifLatitude;
  final double? exifLongitude;
  final double? exifAltitude;

  @override
  State<PhotoEditorPage> createState() => _PhotoEditorPageState();
}

class _PhotoEditorPageState extends State<PhotoEditorPage> {
  final GlobalKey<ExtendedImageEditorState> _editorKey =
  GlobalKey<ExtendedImageEditorState>();

  late final ImageEditorController _controller;

  double? _currentAspect;
  bool _saving = false;
  _OrigExif? _origExif;

  List<_Aspect> get _ratios {
    final custom = widget.aspectRatios;

    if (custom != null && custom.isNotEmpty) {
      return <_Aspect>[
        const _Aspect('Livre', null),
        ...custom.map((r) => _Aspect(_aspectLabelOf(r), r)),
      ];
    }

    return const <_Aspect>[
      _Aspect('Livre', null),
      _Aspect('1:1', 1.0),
      _Aspect('4:3', 4 / 3),
      _Aspect('3:2', 3 / 2),
      _Aspect('16:9', 16 / 9),
    ];
  }

  static String _aspectLabelOf(double r) {
    if ((r - 1.0).abs() < 1e-6) return '1:1';
    if ((r - 4 / 3).abs() < 1e-6) return '4:3';
    if ((r - 3 / 2).abs() < 1e-6) return '3:2';
    if ((r - 16 / 9).abs() < 1e-6) return '16:9';

    return r.toStringAsFixed(2);
  }

  String get _currentAspectLabel {
    final list = _ratios;
    final index = _currentAspectIndexIn(list);

    return list[index].label;
  }

  int _currentAspectIndexIn(List<_Aspect> list) {
    final value = _currentAspect;

    final index = list.indexWhere((aspect) {
      if (aspect.value == null && value == null) return true;
      if (aspect.value == null || value == null) return false;

      return (aspect.value! - value).abs() < 1e-6;
    });

    return index < 0 ? 0 : index;
  }

  ExtendedImageEditorState? get _state => _editorKey.currentState;

  @override
  void initState() {
    super.initState();

    _controller = ImageEditorController();

    _readOriginalExif(widget.originalBytes).then((value) {
      _origExif = value;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _debugError(String message, Object error, StackTrace? stackTrace) {
    debugPrint('[PhotoEditorPage] $message: $error');

    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _cycleAspect() {
    if (_saving) return;

    final list = _ratios;
    final nextIndex = (_currentAspectIndexIn(list) + 1) % list.length;
    final selected = list[nextIndex];

    setState(() {
      _currentAspect = selected.value;
      _controller.updateCropAspectRatio(
        selected.value ?? CropAspectRatios.custom,
      );
    });
  }

  void _reset() {
    if (_saving) return;

    _controller.reset();

    setState(() {
      _currentAspect = null;
      _controller.updateCropAspectRatio(CropAspectRatios.custom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final editor = ExtendedImage.memory(
      widget.originalBytes,
      key: ValueKey<String>('editor_${_currentAspect ?? 'free'}'),
      mode: ExtendedImageMode.editor,
      fit: BoxFit.contain,
      enableLoadState: false,
      extendedImageEditorKey: _editorKey,
      initEditorConfigHandler: (_) {
        return EditorConfig(
          controller: _controller,
          maxScale: widget.maxScale,
          hitTestSize: 24,
          cropRectPadding: const EdgeInsets.all(16),
          cornerColor: Colors.white,
          lineColor: Colors.white,
          lineHeight: 1.2,
          cornerSize: const Size(22, 5),
          cropAspectRatio: _currentAspect,
        );
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Ajustar foto',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            icon: _saving
                ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.check),
            label: Text(_saving ? 'Aplicando...' : 'Usar'),
            onPressed: _saving ? null : _export,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(child: editor),
          ),
          _toolbar(),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 8,
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _btn(
                icon: Icons.rotate_90_degrees_ccw,
                label: 'Rot 90',
                onTap: () {
                  if (_saving) return;
                  _controller.rotate();
                },
              ),
              const SizedBox(width: 8),
              _btn(
                icon: Icons.flip,
                label: 'Flip',
                onTap: () {
                  if (_saving) return;
                  _controller.flip();
                },
              ),
              const SizedBox(width: 8),
              _btn(
                icon: Icons.refresh,
                label: 'Reset',
                onTap: _reset,
              ),
              const SizedBox(width: 8),
              _btn(
                icon: Icons.aspect_ratio,
                label: _currentAspectLabel,
                onTap: _cycleAspect,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.35),
        side: BorderSide(
          color: Colors.white.withValues(alpha: _saving ? 0.18 : 0.35),
        ),
      ),
      onPressed: _saving ? null : onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }

  Future<void> _export() async {
    if (_saving) return;

    final editorState = _state;

    if (editorState == null) {
      _showError('Editor ainda não está pronto. Tente novamente.');
      return;
    }

    setState(() => _saving = true);

    try {
      final edited = await _exportWithFallback();
      final withExif = await _applyExifIfSupported(edited);

      if (!mounted) return;

      Navigator.of(context).pop<Uint8List>(withExif);
    } catch (e, s) {
      _debugError('Falha ao exportar edição', e, s);

      _showError(
        'Não foi possível aplicar a edição da foto. '
            'Tente novamente ou use a foto sem editar.',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<Uint8List> _exportWithFallback() async {
    Object? nativeError;
    StackTrace? nativeStack;

    if (widget.preferNative) {
      try {
        return await _exportNative();
      } catch (e, s) {
        nativeError = e;
        nativeStack = s;

        _debugError(
          'Exportação nativa falhou. Tentando fallback Dart',
          e,
          s,
        );
      }
    }

    try {
      return await _exportDart();
    } catch (dartError, dartStack) {
      if (nativeError != null) {
        _debugError(
          'Fallback Dart também falhou depois da falha nativa',
          nativeError,
          nativeStack,
        );
      }

      _debugError(
        'Exportação Dart falhou',
        dartError,
        dartStack,
      );

      rethrow;
    }
  }

  Future<Uint8List> _exportNative() async {
    final state = _state;

    if (state == null) {
      throw StateError('Editor não pronto.');
    }

    final raw = state.rawImageData;

    if (raw.isEmpty) {
      throw StateError('Imagem original vazia no editor.');
    }

    final crop = _controller.getCropRect();
    final action = state.editAction;

    final rotateDegrees = action?.rotateDegrees ?? 0.0;

    /// No extended_image, o flip horizontal normalmente vem em flipY.
    final flipHorizontal = action?.flipY ?? false;

    final options = ien.ImageEditorOption();

    if (rotateDegrees.abs() > 0.01) {
      options.addOption(
        ien.RotateOption(rotateDegrees.round()),
      );
    }

    if (flipHorizontal) {
      options.addOption(
        const ien.FlipOption(
          horizontal: true,
          vertical: false,
        ),
      );
    }

    if (crop != null && crop.width > 1 && crop.height > 1) {
      options.addOption(
        ien.ClipOption.fromRect(crop),
      );
    }

    options.outputFormat = ien.OutputFormat.jpeg(
      widget.exportQuality.clamp(1, 100),
    );

    final output = await ien.ImageEditor.editImage(
      image: raw,
      imageEditorOption: options,
    );

    if (output == null || output.isEmpty) {
      throw StateError('Edição nativa retornou imagem vazia.');
    }

    return output;
  }

  Future<Uint8List> _exportDart() async {
    final state = _state;

    if (state == null) {
      throw StateError('Editor não pronto.');
    }

    final raw = state.rawImageData;

    if (raw.isEmpty) {
      throw StateError('Imagem original vazia no editor.');
    }

    final crop = _controller.getCropRect();
    final action = state.editAction;

    final rotateDegrees = action?.rotateDegrees ?? 0.0;
    final flipHorizontal = action?.flipY ?? false;

    final decoded = await compute(_decodeImageWorker, raw);

    img.Image output = img.bakeOrientation(decoded);

    if (rotateDegrees.abs() > 0.01) {
      output = img.copyRotate(
        output,
        angle: rotateDegrees,
      );
    }

    if (flipHorizontal) {
      output = img.flipHorizontal(output);
    }

    if (crop != null && crop.width > 1 && crop.height > 1) {
      final x = _clampInt(crop.left.round(), 0, output.width - 1);
      final y = _clampInt(crop.top.round(), 0, output.height - 1);

      final maxWidth = output.width - x;
      final maxHeight = output.height - y;

      final width = _clampInt(crop.width.round(), 1, maxWidth);
      final height = _clampInt(crop.height.round(), 1, maxHeight);

      output = img.copyCrop(
        output,
        x: x,
        y: y,
        width: width,
        height: height,
      );
    }

    return compute(
      _encodeJpgWorker,
      _JpgArgs(
        image: output,
        quality: widget.exportQuality.clamp(1, 100),
      ),
    );
  }

  static int _clampInt(int value, int min, int max) {
    if (max < min) return min;
    if (value < min) return min;
    if (value > max) return max;

    return value;
  }

  Future<_OrigExif?> _readOriginalExif(Uint8List data) async {
    try {
      final tags = await exif.readExifFromBytes(data);

      if (tags.isEmpty) return null;

      DateTime? dateTime;

      for (final key in const [
        'Image DateTime',
        'EXIF DateTimeOriginal',
        'EXIF DateTimeDigitized',
      ]) {
        final value = tags[key]?.printable;

        if (value == null || value.trim().isEmpty) continue;

        final parsed = _tryParseExifDate(value);

        if (parsed != null) {
          dateTime = parsed;
          break;
        }
      }

      double? latitude;
      double? longitude;

      final latTag = tags['GPS GPSLatitude'];
      final latRef = tags['GPS GPSLatitudeRef']?.printable;
      final lonTag = tags['GPS GPSLongitude'];
      final lonRef = tags['GPS GPSLongitudeRef']?.printable;

      double? ratiosToDeg(exif.IfdValues? values) {
        if (values is exif.IfdRatios && values.ratios.length >= 3) {
          final d = values.ratios[0].toDouble();
          final m = values.ratios[1].toDouble();
          final s = values.ratios[2].toDouble();

          return d + (m / 60.0) + (s / 3600.0);
        }

        return null;
      }

      if (latTag != null &&
          lonTag != null &&
          latRef != null &&
          lonRef != null) {
        latitude = ratiosToDeg(latTag.values);
        longitude = ratiosToDeg(lonTag.values);

        if (latitude != null && longitude != null) {
          if (latRef.toUpperCase().startsWith('S')) {
            latitude = -latitude;
          }

          if (lonRef.toUpperCase().startsWith('W')) {
            longitude = -longitude;
          }
        }
      }

      return _OrigExif(
        dateTime: dateTime,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e, s) {
      _debugError('Falha ao ler EXIF original', e, s);
      return null;
    }
  }

  Future<Uint8List> _applyExifIfSupported(Uint8List editedJpeg) async {
    if (!widget.writeExif) return editedJpeg;

    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return editedJpeg;
    }

    try {
      final tempDir = await getTemporaryDirectory();

      final file = File(
        '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await file.writeAsBytes(editedJpeg, flush: true);

      final exifFile = await Exif.fromPath(file.path);

      final now = DateTime.now();
      final finalDate = widget.exifDateTime ?? _origExif?.dateTime ?? now;
      final finalLat = widget.exifLatitude ?? _origExif?.latitude;
      final finalLon = widget.exifLongitude ?? _origExif?.longitude;

      final dateStr = _formatExifDate(finalDate);

      await exifFile.writeAttributes({
        'DateTime': dateStr,
        'DateTimeOriginal': dateStr,
        'DateTimeDigitized': dateStr,
        if ((widget.exifImageDescription ?? '').trim().isNotEmpty)
          'ImageDescription': widget.exifImageDescription!.trim(),
        if ((widget.exifUserComment ?? '').trim().isNotEmpty)
          'UserComment': widget.exifUserComment!.trim(),
        if ((widget.exifSoftware ?? '').trim().isNotEmpty)
          'Software': widget.exifSoftware!.trim(),
        if ((widget.exifArtist ?? '').trim().isNotEmpty)
          'Artist': widget.exifArtist!.trim(),
        if ((widget.exifCopyright ?? '').trim().isNotEmpty)
          'Copyright': widget.exifCopyright!.trim(),
      });

      if (finalLat != null && finalLon != null) {
        final latRef = finalLat >= 0 ? 'N' : 'S';
        final lonRef = finalLon >= 0 ? 'E' : 'W';

        await exifFile.writeAttributes({
          'GPSLatitude': finalLat.abs().toString(),
          'GPSLatitudeRef': latRef,
          'GPSLongitude': finalLon.abs().toString(),
          'GPSLongitudeRef': lonRef,
        });
      }

      await exifFile.close();

      final output = await file.readAsBytes();

      if (output.isEmpty) return editedJpeg;

      return output;
    } catch (e, s) {
      _debugError('Falha ao aplicar EXIF na foto editada', e, s);
      return editedJpeg;
    }
  }

  static String _formatExifDate(DateTime dt) {
    String two(int value) => value.toString().padLeft(2, '0');

    return '${dt.year}:${two(dt.month)}:${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  static DateTime? _tryParseExifDate(String value) {
    try {
      final text = value.trim();
      final parts = text.split(' ');

      final date = parts.first;
      final time = parts.length > 1 ? parts[1] : '00:00:00';

      final dateParts = date.split(':');
      final timeParts = time.split(':');

      if (dateParts.length != 3 || timeParts.length < 2) {
        return null;
      }

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

      return DateTime(
        year,
        month,
        day,
        hour,
        minute,
        second,
      );
    } catch (_) {
      return null;
    }
  }
}

class _Aspect {
  const _Aspect(this.label, this.value);

  final String label;
  final double? value;
}

class _JpgArgs {
  const _JpgArgs({
    required this.image,
    required this.quality,
  });

  final img.Image image;
  final int quality;
}

class _OrigExif {
  const _OrigExif({
    this.dateTime,
    this.latitude,
    this.longitude,
  });

  final DateTime? dateTime;
  final double? latitude;
  final double? longitude;
}

img.Image _decodeImageWorker(Uint8List data) {
  final decoded = img.decodeImage(data);

  if (decoded == null) {
    throw StateError('Imagem inválida.');
  }

  return decoded;
}

Uint8List _encodeJpgWorker(_JpgArgs args) {
  final encoder = img.JpegEncoder(
    quality: args.quality.clamp(1, 100),
  );

  return Uint8List.fromList(
    encoder.encode(args.image),
  );
}