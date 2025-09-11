// lib/_widgets/schedule/square_modal/photo_editor_page.dart
import 'dart:typed_data';
import 'dart:ui';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Export nativo (Android/iOS) — rápido
import 'package:image_editor/image_editor.dart' as ien;

// Export Dart puro — funciona em todas as plataformas
import 'package:image/image.dart' as img;

// EXIF leitura e escrita nativa
import 'package:exif/exif.dart' as exif;
import 'dart:io' show File, Platform;
import 'package:path_provider/path_provider.dart';
import 'package:native_exif/native_exif.dart';

/// Tela de preview/edição (crop, rotate, flip, zoom).
/// Retorna os bytes recortados via `Navigator.pop<Uint8List>(bytes)`.
class PhotoEditorPage extends StatefulWidget {
  final Uint8List originalBytes;

  /// Zoom máximo no editor
  final double maxScale;

  /// Qualidade JPEG na exportação (0..100)
  final int exportQuality;

  /// (Sem efeito no v10 — mantido por compat)
  final bool circleCrop;

  /// Proporções disponíveis (ex.: [1, 4/3, 16/9]). Se null → [Livre, 1:1, 4:3, 16:9].
  final List<double>? aspectRatios;

  /// Tenta export nativo primeiro e cai pro Dart em erro.
  final bool preferNative;

  /// Gravar EXIF no resultado (Android/iOS). No Web/Desktop, ignora.
  final bool writeExif;

  /// Overrides para EXIF de saída (se null, tenta herdar do EXIF original).
  final String? exifImageDescription;
  final String? exifUserComment;
  final String? exifSoftware;
  final String? exifArtist;
  final String? exifCopyright;
  final DateTime? exifDateTime;
  final double? exifLatitude;
  final double? exifLongitude;
  final double? exifAltitude;

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
    this.exifSoftware = 'SisGeo/Flutter',
    this.exifArtist,
    this.exifCopyright,
    this.exifDateTime,
    this.exifLatitude,
    this.exifLongitude,
    this.exifAltitude,
  });

  @override
  State<PhotoEditorPage> createState() => _PhotoEditorPageState();
}

class _PhotoEditorPageState extends State<PhotoEditorPage> {
  final GlobalKey<ExtendedImageEditorState> _editorKey =
  GlobalKey<ExtendedImageEditorState>();
  final ImageEditorController _controller = ImageEditorController();

  double? _currentAspect;
  bool _saving = false;

  // cache do EXIF original (lido uma vez)
  _OrigExif? _origExif;

  List<_Aspect> get _ratios {
    final custom = widget.aspectRatios;
    if (custom != null && custom.isNotEmpty) {
      return [
        const _Aspect('Livre', null),
        ...custom.map((r) => _Aspect(_aspectLabelOf(r), r)),
      ];
    }
    return const [
      _Aspect('Livre', null),
      _Aspect('1:1', 1.0),
      _Aspect('4:3', 4 / 3),
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
    final idx = _currentAspectIndexIn(list);
    return list[idx].label;
  }

  int _currentAspectIndexIn(List<_Aspect> list) {
    final val = _currentAspect;
    final i = list.indexWhere((a) {
      if (a.value == null && val == null) return true;
      if (a.value == null || val == null) return false;
      return (a.value! - val).abs() < 1e-6;
    });
    return i < 0 ? 0 : i;
  }

  void _cycleAspect() {
    final list = _ratios;
    final next = (_currentAspectIndexIn(list) + 1) % list.length;
    final sel = list[next];
    setState(() {
      _currentAspect = sel.value;
      _controller.updateCropAspectRatio(sel.value ?? CropAspectRatios.custom);
    });
  }

  ExtendedImageEditorState? get _state => _editorKey.currentState;

  @override
  void initState() {
    super.initState();
    _readOriginalExif(widget.originalBytes).then((value) {
      _origExif = value;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editor = ExtendedImage.memory(
      widget.originalBytes,
      key: ValueKey(_currentAspect), // reinit ao trocar proporção
      mode: ExtendedImageMode.editor,
      fit: BoxFit.contain,
      enableLoadState: false,
      extendedImageEditorKey: _editorKey,
      initEditorConfigHandler: (st) {
        return EditorConfig(
          controller: _controller,
          maxScale: widget.maxScale,
          hitTestSize: 20,
          cropRectPadding: const EdgeInsets.all(16),
          cornerColor: Colors.white,
          lineColor: Colors.white,
          lineHeight: 1.2,
          cornerSize: const Size(20, 5),
          cropAspectRatio: _currentAspect,
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title:
        const Text('Ajustar foto', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.check),
            label: const Text('Usar'),
            onPressed: _saving ? null : _export,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: Center(child: editor)),
          _toolbar(),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _btn(Icons.rotate_90_degrees_ccw, 'Rot 90', () => _controller.rotate()),
              const SizedBox(width: 8),
              _btn(Icons.flip, 'Flip', () => _controller.flip()),
              const SizedBox(width: 8),
              _btn(Icons.refresh, 'Reset', () {
                _controller.reset();
                setState(() => _currentAspect = null);
              }),
              const SizedBox(width: 8),
              _btn(Icons.aspect_ratio, _currentAspectLabel, _cycleAspect),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0x55FFFFFF)),
      ),
      onPressed: _saving ? null : onTap,
      icon: Icon(icon, size: 12),
      label: Text(label),
    );
  }

  Future<void> _export() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      // 1) Exporta (nativo ou Dart)
      final edited = widget.preferNative ? await _exportNative() : await _exportDart();

      // 2) Tenta gravar EXIF no resultado (Android/iOS)
      final withExif = await _applyExifIfSupported(edited);

      if (!mounted) return;
      Navigator.of(context).pop<Uint8List>(withExif);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao exportar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// ===== Export nativo (image_editor) =====
  Future<Uint8List> _exportNative() async {
    final st = _state;
    if (st == null) throw 'Editor não pronto';

    final Uint8List raw = st.rawImageData;
    final Rect? crop = _controller.getCropRect();

    final action = st.editAction;
    final double deg = action?.rotateDegrees ?? 0.0; // v10
    final bool flipH = action?.flipY ?? false;       // v10 (só horizontal)

    final opt = ien.ImageEditorOption();

    if (deg.abs() > 0.01) {
      opt.addOption(ien.RotateOption(deg.round()));
    }

    if (flipH) {
      opt.addOption(const ien.FlipOption(
        horizontal: true,
        vertical: false,
      ));
    }

    if (crop != null && crop.width > 0 && crop.height > 0) {
      opt.addOption(ien.ClipOption.fromRect(crop));
    }

    opt.outputFormat = ien.OutputFormat.jpeg(widget.exportQuality);

    final out = await ien.ImageEditor.editImage(
      image: raw,
      imageEditorOption: opt,
    );
    if (out == null) throw 'Edição nativa retornou null';

    return out;
  }

  /// ===== Export Dart (package:image) =====
  Future<Uint8List> _exportDart() async {
    final st = _state;
    if (st == null) throw 'Editor não pronto';

    final Uint8List raw = st.rawImageData;
    final Rect? crop = _controller.getCropRect();

    final action = st.editAction;
    final double deg = action?.rotateDegrees ?? 0.0;
    final bool flipH = action?.flipY ?? false;

    // Decode em isolate
    final img.Image src = await compute(_decodeImage, raw);
    img.Image out = img.bakeOrientation(src);

    // Rotação / flip / crop
    if (deg.abs() > 0.01) {
      out = img.copyRotate(out, angle: deg);
    }
    if (flipH) {
      out = img.flipHorizontal(out);
    }
    if (crop != null && crop.width > 0 && crop.height > 0) {
      out = img.copyCrop(
        out,
        x: crop.left.round().clamp(0, out.width - 1),
        y: crop.top.round().clamp(0, out.height - 1),
        width: crop.width.round().clamp(1, out.width),
        height: crop.height.round().clamp(1, out.height),
      );
    }

    // Encode JPG em isolate (sem EXIF aqui — escrita via nativo se disponível)
    final Uint8List encoded = await compute(_encodeJpg, _JpgArgs(out, widget.exportQuality));
    return encoded;
  }

  // ====== EXIF: leitura do original e escrita no resultado ======

  /// Lê alguns campos do EXIF original (se existirem).
  Future<_OrigExif?> _readOriginalExif(Uint8List data) async {
    try {
      final tags = await exif.readExifFromBytes(data);
      if (tags.isEmpty) return null;

      // --- Data/hora (pega a primeira que existir)
      DateTime? dt;
      for (final key in const [
        'Image DateTime',
        'EXIF DateTimeOriginal',
        'EXIF DateTimeDigitized',
      ]) {
        final v = tags[key]?.printable;
        if (v != null) {
          final parsed = _tryParseExifDate(v);
          if (parsed != null) {
            dt = parsed;
            break;
          }
        }
      }

      // --- GPS: Latitude/Longitude (DMS -> decimal)
      double? lat, lon;

      final latTag = tags['GPS GPSLatitude'];
      final latRef = tags['GPS GPSLatitudeRef']?.printable; // 'N' ou 'S'
      final lonTag = tags['GPS GPSLongitude'];
      final lonRef = tags['GPS GPSLongitudeRef']?.printable; // 'E' ou 'W'

      double? _ratiosToDeg(exif.IfdValues? v) {
        if (v is exif.IfdRatios && v.ratios.length >= 3) {
          final d = v.ratios[0].toDouble();
          final m = v.ratios[1].toDouble();
          final s = v.ratios[2].toDouble();
          return d + (m / 60.0) + (s / 3600.0);
        }
        return null;
      }

      if (latTag != null && lonTag != null && latRef != null && lonRef != null) {
        lat = _ratiosToDeg(latTag.values);
        lon = _ratiosToDeg(lonTag.values);
        if (lat != null && lon != null) {
          if (latRef.toUpperCase().startsWith('S')) lat = -lat;
          if (lonRef.toUpperCase().startsWith('W')) lon = -lon;
        }
      }

      return _OrigExif(dateTime: dt, latitude: lat, longitude: lon);
    } catch (_) {
      return null;
    }
  }

  /// Aplica EXIF ao JPEG final caso esteja em Android/iOS e writeExif==true.
  Future<Uint8List> _applyExifIfSupported(Uint8List editedJpeg) async {
    if (!widget.writeExif) return editedJpeg;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      // Web/Desktop: sem escrita confiável — retorna como está
      return editedJpeg;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final f = File('${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await f.writeAsBytes(editedJpeg, flush: true);

      final ex = await Exif.fromPath(f.path);

      // === Definição dos campos finais (override > original > agora) ===
      final now = DateTime.now();
      final finalDate = widget.exifDateTime ?? _origExif?.dateTime ?? now;
      final finalLat = widget.exifLatitude ?? _origExif?.latitude;
      final finalLon = widget.exifLongitude ?? _origExif?.longitude;

      // Datas (strings no formato EXIF)
      final dateStr = _formatExifDate(finalDate);

      await ex.writeAttributes({
        'DateTime': dateStr,
        'DateTimeOriginal': dateStr,
        'DateTimeDigitized': dateStr,
        if ((widget.exifImageDescription ?? '').isNotEmpty)
          'ImageDescription': widget.exifImageDescription!,
        if ((widget.exifUserComment ?? '').isNotEmpty)
          'UserComment': widget.exifUserComment!,
        if ((widget.exifSoftware ?? '').isNotEmpty)
          'Software': widget.exifSoftware!,
        if ((widget.exifArtist ?? '').isNotEmpty)
          'Artist': widget.exifArtist!,
        if ((widget.exifCopyright ?? '').isNotEmpty)
          'Copyright': widget.exifCopyright!,
      });

      // GPS (usa Latitude/Longitude + Ref, como string)
      if (finalLat != null && finalLon != null) {
        final latRef = finalLat >= 0 ? 'N' : 'S';
        final lonRef = finalLon >= 0 ? 'E' : 'W';
        await ex.writeAttributes({
          'GPSLatitude': finalLat.toString(),
          'GPSLatitudeRef': latRef,
          'GPSLongitude': finalLon.toString(),
          'GPSLongitudeRef': lonRef,
        });
      }

      await ex.close();

      final updated = await f.readAsBytes();
      return updated;
    } catch (_) {
      // Se qualquer etapa falhar, devolve a imagem editada sem EXIF extra
      return editedJpeg;
    }
  }

  // ===== helpers isolados (para compute/encode) =====
  static img.Image _decodeImage(Uint8List data) {
    final i = img.decodeImage(data);
    if (i == null) {
      throw 'Imagem inválida';
    }
    return i;
  }

  static Uint8List _encodeJpg(_JpgArgs a) {
    final encoder = img.JpegEncoder(quality: a.quality);
    final bytes = encoder.encode(a.image);
    return Uint8List.fromList(bytes);
  }

  static String _formatExifDate(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    // Formato EXIF: "YYYY:MM:DD HH:MM:SS"
    return '${dt.year}:${two(dt.month)}:${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  static DateTime? _tryParseExifDate(String s) {
    try {
      final dateTime = s.trim();
      final date = dateTime.split(' ').first;
      final time = dateTime.split(' ').length > 1 ? dateTime.split(' ')[1] : '00:00:00';
      final partsD = date.split(':');
      final partsT = time.split(':');
      if (partsD.length == 3 && partsT.length >= 2) {
        final y = int.parse(partsD[0]);
        final m = int.parse(partsD[1]);
        final d = int.parse(partsD[2]);
        final hh = int.parse(partsT[0]);
        final mm = int.parse(partsT[1]);
        final ss = partsT.length > 2 ? int.parse(partsT[2]) : 0;
        return DateTime(y, m, d, hh, mm, ss);
      }
    } catch (_) {}
    return null;
  }
}

class _Aspect {
  final String label;
  final double? value;
  const _Aspect(this.label, this.value);
}

class _JpgArgs {
  final img.Image image;
  final int quality;
  const _JpgArgs(this.image, this.quality);
}

class _OrigExif {
  final DateTime? dateTime;
  final double? latitude;
  final double? longitude;
  const _OrigExif({this.dateTime, this.latitude, this.longitude});
}
