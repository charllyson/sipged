import 'dart:async';
import 'dart:typed_data';
import 'dart:io' show File, Platform;
import 'dart:ui' as ui;

import 'package:exif/exif.dart' as exif;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:native_exif/native_exif.dart';
import 'package:path_provider/path_provider.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:image/image.dart' as im;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import 'package:siged/_widgets/images/carousel/photo_editor_page.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class PhotoPreviewPage extends StatefulWidget {
  final Uint8List originalBytes;

  // (fallbacks manuais se quiser forçar)
  final String? overlayLogradouro;
  final String? overlayMunicipio;
  final String? overlayUF;
  final DateTime? exifDateTime;
  final double? exifLatitude;
  final double? exifLongitude;

  final bool writeExif;
  final int outputJpegQuality;

  /// Fit inicial do preview (contain = sem corte; cover = preenche cortando)
  final BoxFit previewFit;
  final bool showOverlayInPreview;
  final bool debugLog;

  const PhotoPreviewPage({
    super.key,
    required this.originalBytes,
    this.overlayLogradouro,
    this.overlayMunicipio,
    this.overlayUF,
    this.exifDateTime,
    this.exifLatitude,
    this.exifLongitude,
    this.writeExif = true,
    this.outputJpegQuality = 100,
    this.previewFit = BoxFit.contain,
    this.showOverlayInPreview = true,
    this.debugLog = false,
  });

  @override
  State<PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<PhotoPreviewPage> {
  late Uint8List _bytes;            // bytes originais
  _OrigExif? _orig;                 // exif do original

  Uint8List? _previewBytes;         // bytes "baked" p/ PREVIEW
  bool _busy = false;
  bool _preparing = true;           // controla overlay de preparo

  // Fit com toggle
  late BoxFit _fit;

  // Dados de endereço resolvidos por geocoding
  double? _latUsed, _lonUsed;
  String? _street, _city, _state;

  @override
  void initState() {
    super.initState();
    _bytes = widget.originalBytes;
    _fit = widget.previewFit;
    _preparePreview();
  }

  @override
  void didUpdateWidget(covariant PhotoPreviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.originalBytes, widget.originalBytes)) {
      _bytes = widget.originalBytes;
      _preparePreview();
    }
  }

  // 🔔 helper central p/ publicar toasts
  void _notify(
      String title, {
        AppNotificationType type = AppNotificationType.info,
        String? subtitle,
        String? id,
      }) {
    if (id != null) {
      NotificationCenter.instance.dismissById(id);
    }
    NotificationCenter.instance.show(
      AppNotification(
        id: id,
        title: Text(title),
        subtitle: (subtitle != null && subtitle.isNotEmpty) ? Text(subtitle) : null,
        type: type,
      ),
    );
  }

  Future<void> _preparePreview() async {
    if (mounted) {
      setState(() {
        _preparing = true;
        _previewBytes = null;
      });
    }

    // roda em paralelo: bake + leitura exif + suggestions
    final bakeF = compute(_bakeOrientationBytes, _bytes);
    final exifF = _readOriginalExif(_bytes);

    final baked = await bakeF;
    final orig = await exifF;

    if (widget.debugLog) {
      final o = await _probe(_bytes);
      final b = await _probe(baked);
      // ignore: avoid_print
      print('ORIG: ${o.width}x${o.height} | BAKED: ${b.width}x${b.height} bytes=${_bytes.length}→${baked.length}');
    }

    if (!mounted) return;
    setState(() {
      _previewBytes = baked;
      _orig = orig;
      _preparing = false; // pronto
    });

    // Resolve endereço (prioriza EXIF; senão, GPS do aparelho)
    unawaited(_resolveAddressAndCoords());
  }

  Future<void> _resolveAddressAndCoords() async {
    try {
      double? lat = widget.exifLatitude ?? _orig?.latitude;
      double? lon = widget.exifLongitude ?? _orig?.longitude;

      if (lat == null || lon == null) {
        if (!kIsWeb) {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            if (mounted) setState(() { _latUsed = null; _lonUsed = null; });
            return;
          }
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            if (mounted) setState(() { _latUsed = null; _lonUsed = null; });
            return;
          }
          final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          lat = pos.latitude;
          lon = pos.longitude;
        }
      }

      if (lat != null && lon != null) {
        final placemarks = await geocoding.placemarkFromCoordinates(lat, lon);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final street = _joinNotEmpty([p.thoroughfare, p.subThoroughfare], ', ');
          final city = (p.locality?.isNotEmpty ?? false) ? p.locality : p.subAdministrativeArea;
          final ufRaw = p.administrativeArea;

          if (mounted) {
            setState(() {
              _latUsed = lat;
              _lonUsed = lon;
              _street = street?.isNotEmpty == true ? street : widget.overlayLogradouro;
              _city = (city?.isNotEmpty == true ? city : widget.overlayMunicipio);
              _state = (ufRaw?.isNotEmpty == true ? ufRaw : widget.overlayUF);
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _latUsed = lat;
              _lonUsed = lon;
              _street = widget.overlayLogradouro;
              _city = widget.overlayMunicipio;
              _state = widget.overlayUF;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _street = widget.overlayLogradouro;
            _city = widget.overlayMunicipio;
            _state = widget.overlayUF;
          });
        }
      }
    } catch (_) {
      // falhou geocoding → mantém o que tiver
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = _buildOverlayLines();

    return Scaffold(
      backgroundColor: Colors.black26,
      appBar: AppBar(
        title: const Text('Pré-visualização'),
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        actions: [
          // Toggle contain/cover
          IconButton(
            tooltip: _fit == BoxFit.contain
                ? 'Preencher (pode cortar)'
                : 'Encaixar (sem corte)',
            onPressed: () => setState(() {
              _fit = _fit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
            }),
            icon: Icon(_fit == BoxFit.contain ? Icons.fullscreen : Icons.fit_screen),
          ),
          TextButton.icon(
            onPressed: _busy ? null : _confirm,
            icon: const Icon(Icons.check),
            label: const Text('Usar'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Preview da foto
          if (_previewBytes == null)
            const Positioned.fill(child: ColoredBox(color: Colors.black))
          else
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black,
                child: SizedBox.expand(
                  child: Image.memory(
                    _previewBytes!,
                    fit: _fit,
                    alignment: Alignment.center,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),

          // Botão Crop no canto esquerdo, circular black54
          Positioned(
            left: 16,
            bottom: 16,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _busy ? null : _openCrop,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.crop, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),

          // Overlay à direita: linhas brancas com sombra (sem container)
          if (widget.showOverlayInPreview && lines.isNotEmpty && _previewBytes != null)
            Positioned(
              right: 16,
              bottom: 16,
              child: IgnorePointer(
                child: _PreviewStamp(
                  lines: lines,
                  fontSize: 18,
                  lineHeight: 1.15,
                ),
              ),
            ),

          // BLOQUEIOS
          if (_preparing) _buildBlocking('Preparando pré-visualização…'),
          if (_busy) _buildBlocking('Finalizando…'),
        ],
      ),
    );
  }

  Widget _buildBlocking(String message) {
    return Stack(
      children: [
        const Positioned.fill(
          child: ModalBarrier(dismissible: false, color: Color(0x80000000)),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6E6E6E)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openCrop() async {
    final edited = await Navigator.of(context).push<Uint8List?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoEditorPage(
          originalBytes: _bytes,
          exportQuality: 100,
        ),
      ),
    );
    if (edited != null) {
      setState(() {
        _bytes = edited;
        _orig = null;
        _previewBytes = null;
        _street = _city = _state = null;
        _latUsed = _lonUsed = null;
        _preparing = true; // volta para carregando enquanto refaz preview
      });
      await _preparePreview();
    }
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // carimba (mantendo L×A originais)
      final stamped = await _burnStampOnImage(_bytes, _buildOverlayLines());
      // grava EXIF
      final withExif = await _applyExifIfSupported(stamped);
      if (!mounted) return;
      Navigator.of(context).pop<Uint8List>(withExif);
    } catch (e) {
      _notify('Falha ao finalizar', type: AppNotificationType.error, subtitle: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ========= Linhas do overlay =========
  List<String> _buildOverlayLines() {
    final dt = widget.exifDateTime ?? _orig?.dateTime ?? DateTime.now();
    final df = DateFormat("d 'de' MMM. 'de' y HH:mm:ss", 'pt_BR');
    final dateLine = df.format(dt);

    final lat = _latUsed ?? widget.exifLatitude ?? _orig?.latitude;
    final lon = _lonUsed ?? widget.exifLongitude ?? _orig?.longitude;

    final lines = <String>[];
    lines.add(dateLine); // 1) data e hora

    // 2) coordenadas
    if (lat != null && lon != null) {
      lines.add(_toDms(ll.LatLng(lat, lon)));
    } else {
      lines.add('Sem coordenadas');
    }

    // 3) Rua
    final rua = _street ?? widget.overlayLogradouro;
    lines.add((rua ?? '').isNotEmpty ? rua! : 'Rua não disponível');

    // 4) Cidade
    final cidade = _city ?? widget.overlayMunicipio;
    lines.add((cidade ?? '').isNotEmpty ? cidade! : 'Cidade não disponível');

    // 5) Estado (NOME COMPLETO)
    final ufRaw = _state ?? widget.overlayUF;
    final ufFull = _fullStateNameBR(ufRaw);
    lines.add((ufFull ?? '').isNotEmpty ? ufFull! : 'Estado não disponível');

    return lines;
  }

  // ========= EXIF leitura =========
  Future<_OrigExif?> _readOriginalExif(Uint8List data) async {
    try {
      final tags = await exif.readExifFromBytes(data);
      if (tags.isEmpty) return null;

      // Data/hora
      DateTime? dt;
      for (final key in const [
        'Image DateTime',
        'EXIF DateTimeOriginal',
        'EXIF DateTimeDigitized',
      ]) {
        final v = tags[key]?.printable;
        if (v != null) {
          final parsed = _tryParseExifDate(v);
          if (parsed != null) { dt = parsed; break; }
        }
      }

      // GPS
      double? lat, lon;
      final latTag = tags['GPS GPSLatitude'];
      final latRef = tags['GPS GPSLatitudeRef']?.printable; // N/S
      final lonTag = tags['GPS GPSLongitude'];
      final lonRef = tags['GPS GPSLongitudeRef']?.printable; // E/W

      double? ratiosToDeg(exif.IfdValues? v) {
        if (v is exif.IfdRatios && v.ratios.length >= 3) {
          final d = v.ratios[0].toDouble();
          final m = v.ratios[1].toDouble();
          final s = v.ratios[2].toDouble();
          return d + (m / 60.0) + (s / 3600.0);
        }
        return null;
      }

      if (latTag != null && lonTag != null && latRef != null && lonRef != null) {
        lat = ratiosToDeg(latTag.values);
        lon = ratiosToDeg(lonTag.values);
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

  // ========= EXIF escrita (Android/iOS) =========
  Future<Uint8List> _applyExifIfSupported(Uint8List jpeg) async {
    if (!widget.writeExif) return jpeg;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return jpeg;

    try {
      final temp = await getTemporaryDirectory();
      final f = File('${temp.path}/preview_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await f.writeAsBytes(jpeg, flush: true);

      final ex = await Exif.fromPath(f.path);

      final now = DateTime.now();
      final dt = widget.exifDateTime ?? _orig?.dateTime ?? now;
      final lat = _latUsed ?? widget.exifLatitude ?? _orig?.latitude;
      final lon = _lonUsed ?? widget.exifLongitude ?? _orig?.longitude;

      String two(int v) => v.toString().padLeft(2, '0');
      final dateStr = '${dt.year}:${two(dt.month)}:${two(dt.day)} '
          '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';

      await ex.writeAttributes({
        'DateTime': dateStr,
        'DateTimeOriginal': dateStr,
        'DateTimeDigitized': dateStr,
      });

      if (lat != null && lon != null) {
        final latRef = lat >= 0 ? 'N' : 'S';
        final lonRef = lon >= 0 ? 'E' : 'W';
        await ex.writeAttributes({
          'GPSLatitude': lat.toString(),
          'GPSLatitudeRef': latRef,
          'GPSLongitude': lon.toString(),
          'GPSLongitudeRef': lonRef,
        });
      }

      await ex.close();
      final out = await f.readAsBytes();
      return out;
    } catch (_) {
      return jpeg;
    }
  }

  // ========= Carimbar no bitmap (mantendo L×A originais) =========
  Future<Uint8List> _burnStampOnImage(Uint8List jpgBytes, List<String> lines) async {
    if (lines.isEmpty) return jpgBytes;

    // bake de orientação antes de desenhar
    final baked = await compute(_bakeOrientationBytes, jpgBytes);
    final uiImage = await _decodeUiImage(baked);

    final width  = uiImage.width;
    final height = uiImage.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width.toDouble(), height.toDouble());

    canvas.drawImage(uiImage, Offset.zero, Paint());

    // texto branco com sombra preta
    final font = (width / 22).clamp(24, 64).toDouble();
    final textSpan = TextSpan(
      text: lines.join('\n'),
      style: TextStyle(
        color: Colors.white,
        fontSize: font,
        height: 1.15,
        shadows: const [
          Shadow(blurRadius: 4, color: Colors.black87, offset: Offset(1, 1)),
          Shadow(blurRadius: 6, color: Colors.black87, offset: Offset(0, 0)),
        ],
      ),
    );

    final tp = TextPainter(
      text: textSpan,
      textAlign: TextAlign.right,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.9);

    final dx = size.width - tp.width - 24;
    final dy = size.height - tp.height - 24;
    tp.paint(canvas, Offset(dx, dy));

    final picture = recorder.endRecording();
    final stamped = await picture.toImage(width, height);

    final byteData = await stamped.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final raster = im.decodeImage(pngBytes)!;
    final out = Uint8List.fromList(
      im.JpegEncoder(quality: widget.outputJpegQuality).encode(raster),
    );
    return out;
  }

  // ========= Helpers =========
  static Future<ui.Image> _decodeUiImage(Uint8List bytes) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (img) => c.complete(img));
    return c.future;
  }

  static Uint8List _bakeOrientationBytes(Uint8List data) {
    final decoded = im.decodeImage(data);
    if (decoded == null) { throw 'Imagem inválida'; }
    final baked = im.bakeOrientation(decoded);
    return Uint8List.fromList(im.JpegEncoder(quality: 100).encode(baked));
  }

  static Future<ui.Image> _probe(Uint8List bytes) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (img) => c.complete(img));
    return c.future;
  }

  static DateTime? _tryParseExifDate(String s) {
    try {
      final parts = s.trim().split(' ');
      final d = parts[0].split(':');
      final t = (parts.length > 1 ? parts[1] : '00:00:00').split(':');
      if (d.length == 3 && t.length >= 2) {
        return DateTime(
          int.parse(d[0]), int.parse(d[1]), int.parse(d[2]),
          int.parse(t[0]), int.parse(t[1]),
          t.length > 2 ? int.parse(t[2]) : 0,
        );
      }
    } catch (_) {}
    return null;
  }

  static String? _joinNotEmpty(List<String?> parts, String sep) {
    final nonEmpty = parts.where((e) => e != null && e.trim().isNotEmpty).map((e) => e!.trim()).toList();
    if (nonEmpty.isEmpty) return null;
    return nonEmpty.join(sep);
  }

  /// DMS: S 09° 39' 23.7"   W 035° 42' 15.3"
  String _toDms(ll.LatLng p) {
    String fmt(double v, {required bool isLat}) {
      final hemi = isLat ? (v >= 0 ? 'N' : 'S') : (v >= 0 ? 'E' : 'W');
      final av = v.abs();
      final d = av.floor();
      final mFloat = (av - d) * 60.0;
      final m = mFloat.floor();
      final s = (mFloat - m) * 60.0;

      final dPad = isLat ? d.toString().padLeft(2, '0') : d.toString().padLeft(3, '0');
      final mPad = m.toString().padLeft(2, '0');
      final sPad = s.toStringAsFixed(1).padLeft(4, '0');

      return '$hemi $dPad° $mPad\' $sPad"';
    }
    return '${fmt(p.latitude, isLat: true)}   ${fmt(p.longitude, isLat: false)}';
  }

  /// Converte "AL" -> "Alagoas"; se já for nome completo, retorna como veio.
  String? _fullStateNameBR(String? input) {
    if (input == null) return null;
    var s = input.trim();
    if (s.isEmpty) return null;

    // remove prefixos comuns, ex.: "Estado de Alagoas"
    final re = RegExp(r'^\s*Estado\s+de\s+', caseSensitive: false);
    s = s.replaceFirst(re, '');

    final uf = s.toUpperCase();
    if (_ufToNomeBR.containsKey(uf)) return _ufToNomeBR[uf];

    // já é nome completo ou algo não mapeado
    return s;
  }
}

/// Mapa UF -> Nome do Estado (Brasil)
const Map<String, String> _ufToNomeBR = {
  'AC': 'Acre',
  'AL': 'Alagoas',
  'AP': 'Amapá',
  'AM': 'Amazonas',
  'BA': 'Bahia',
  'CE': 'Ceará',
  'DF': 'Distrito Federal',
  'ES': 'Espírito Santo',
  'GO': 'Goiás',
  'MA': 'Maranhão',
  'MT': 'Mato Grosso',
  'MS': 'Mato Grosso do Sul',
  'MG': 'Minas Gerais',
  'PA': 'Pará',
  'PB': 'Paraíba',
  'PR': 'Paraná',
  'PE': 'Pernambuco',
  'PI': 'Piauí',
  'RJ': 'Rio de Janeiro',
  'RN': 'Rio Grande do Norte',
  'RS': 'Rio Grande do Sul',
  'RO': 'Rondônia',
  'RR': 'Roraima',
  'SC': 'Santa Catarina',
  'SP': 'São Paulo',
  'SE': 'Sergipe',
  'TO': 'Tocantins',
};

class _OrigExif {
  final DateTime? dateTime;
  final double? latitude;
  final double? longitude;
  const _OrigExif({this.dateTime, this.latitude, this.longitude});
}

class _PreviewStamp extends StatelessWidget {
  final List<String> lines;
  final double fontSize;
  final double lineHeight;
  const _PreviewStamp({
    required this.lines,
    this.fontSize = 18,
    this.lineHeight = 1.15,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      lines.join('\n'),
      textAlign: TextAlign.right,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        height: lineHeight,
        shadows: const [
          Shadow(blurRadius: 4, color: Colors.black87, offset: Offset(1, 1)),
          Shadow(blurRadius: 6, color: Colors.black87, offset: Offset(0, 0)),
        ],
      ),
    );
  }
}
