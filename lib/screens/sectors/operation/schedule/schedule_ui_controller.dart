// COMPLETO — controlador ÚNICO da UI de Schedule (inclui a lógica do modal)
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Fotos / metas
import 'package:sisged/_datas/widgets/pickedPhoto/carousel_photo.dart';
import 'package:sisged/_datas/widgets/pickedPhoto/carousel_metadata.dart' as pm;

// Resultado do modal
import 'package:sisged/_datas/sectors/operation/schedule/schedule_modal_result_class.dart'
as sm;

// Status do cronograma
import 'package:sisged/_widgets/schedule/schedule_status.dart';

// Conversão HEIC (Web) e JPEG preservando EXIF (mobile)
import 'package:sisged/_utils/images/heic_web_convert.dart' show convertHeicBytesToJpegWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ScheduleUiController extends ChangeNotifier {
  ScheduleUiController({
    ScheduleStatus? initialStatus,
    String? initialComment,
    DateTime? initialDate,
    List<String> existingPhotoUrls = const [],
    Map<String, pm.CarouselMetadata> existingMetaByUrl = const {},
  })  : _status = initialStatus ?? ScheduleStatus.aIniciar,
        _selectedDate = initialDate ?? DateTime.now(),
        _existingUrls = List<String>.from(existingPhotoUrls),
        _existingMetaByUrl = Map<String, pm.CarouselMetadata>.from(existingMetaByUrl) {
    _commentCtrl.text = initialComment ?? '';
    _dateCtrl.text = _fmtDate(_selectedDate);
  }

  // =================== Campos compartilhados entre páginas ===================
  // (Seleção/drag da grid, overlays etc) — se já existir no seu controller,
  // mantenha/mescle estes conforme necessário.

  // =================== Estado do Modal (Fotos + Campos) ======================
  ScheduleStatus _status;
  final TextEditingController _commentCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  DateTime _selectedDate;

  // Fotos novas (bytes) + metadados
  final List<CarouselPhoto> _newPhotos = [];
  final List<pm.CarouselMetadata> _newMetas = [];

  // Fotos existentes (URLs + meta)
  List<String> _existingUrls;
  Map<String, pm.CarouselMetadata> _existingMetaByUrl;

  // Busy flag (desabilitar botões/inputs durante operações)
  bool _busy = false;

  // =================== Getters p/ UI ===================
  ScheduleStatus get status => _status;
  TextEditingController get commentCtrl => _commentCtrl;
  TextEditingController get dateCtrl => _dateCtrl;
  DateTime get selectedDate => _selectedDate;

  List<String> get existingUrls => _existingUrls;
  Map<String, pm.CarouselMetadata> get existingMetaByUrl => _existingMetaByUrl;

  List<CarouselPhoto> get newPhotos => _newPhotos;
  List<pm.CarouselMetadata> get newMetas => _newMetas;

  bool get busy => _busy;

  // =================== Mutators simples p/ UI ===================
  void setStatus(ScheduleStatus s) {
    _status = s;
    notifyListeners();
  }

  void setDate(DateTime? d) {
    if (d == null) return;
    _selectedDate = d;
    _dateCtrl.text = _fmtDate(d);
    notifyListeners();
  }

  void removeExistingAt(int index) {
    final removed = _existingUrls.removeAt(index);
    _existingMetaByUrl.remove(removed);
    notifyListeners();
  }

  void removeNewAt(int index) {
    _newPhotos.removeAt(index);
    _newMetas.removeAt(index);
    notifyListeners();
  }

  // =================== Lógica pesada (picker, conversões, EXIF) ==============
  Future<void> pickPhotos() async {
    if (_busy) return;
    _setBusy(true);
    try {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
        withReadStream: true,
      );
      if (res == null) return;

      final List<CarouselPhoto> picked = [];
      final List<pm.CarouselMetadata> metas = [];

      for (final f in res.files) {
        Uint8List? data = f.bytes;
        if (data == null && f.readStream != null) {
          data = await _readAll(f.readStream!);
        }
        if (data == null) continue;

        String name = (f.name.isNotEmpty ? f.name : 'foto')
            .replaceAll(RegExp(r'[^a-zA-Z0-9\.\-_]'), '_');

        var fmt = pm.sniffFormat(data);

        // Web: HEIC -> JPEG (heic2any)
        if (kIsWeb && fmt == pm.ImgFmt.heic) {
          final jpg = await convertHeicBytesToJpegWeb(data);
          data = jpg;
          name = _ensureJpgExtension(name);
          fmt = pm.sniffFormat(data);
        }

        // Mobile: converte != JPEG para JPEG mantendo EXIF
        if (!kIsWeb && fmt != pm.ImgFmt.jpeg) {
          final converted = await _toJpegPreservingExif(data);
          if (!listEquals(converted, data)) {
            data = converted;
            name = _ensureJpgExtension(name);
            fmt = pm.sniffFormat(data);
          }
        }

        var meta = await pm.extractPhotoMetadata(data, debugLabel: name);
        meta = meta.copyWith(
          name: meta.name ?? name,
          takenAt: meta.takenAt ?? pm.parseDateFromFileName(name) ?? _selectedDate,
        );

        picked.add(CarouselPhoto(name: name, bytes: data));
        metas.add(meta);
      }

      if (picked.isNotEmpty) {
        _newPhotos.addAll(picked);
        _newMetas.addAll(metas);
        notifyListeners();
      }
    } finally {
      _setBusy(false);
    }
  }

  // =================== Saída do Modal ===================
  sm.ScheduleModalResultClass buildModalResult() {
    final trimmed = _commentCtrl.text.trim();
    final comment = trimmed.isEmpty ? null : trimmed;

    return sm.ScheduleModalResultClass(
      _status,
      comment,
      date: _selectedDate,
      photosBytes: _newPhotos.map((p) => p.bytes).toList(),
      photoNames: _newPhotos.map((p) => p.name).toList(),
      photoMetas: List<pm.CarouselMetadata>.from(_newMetas),
    );
  }

  // =================== Internos ===================
  static String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString().padLeft(4, '0');
    return '$dd/$mm/$yy';
  }

  String _ensureJpgExtension(String name) {
    final idx = name.lastIndexOf('.');
    final base = (idx > 0) ? name.substring(0, idx) : name;
    return '$base.jpg';
  }

  Future<Uint8List> _readAll(Stream<List<int>> s) async {
    final bb = BytesBuilder(copy: false);
    await for (final chunk in s) {
      bb.add(chunk);
    }
    return bb.toBytes();
  }

  Future<Uint8List> _toJpegPreservingExif(Uint8List data) async {
    if (kIsWeb) return data; // plugin não suporta web
    try {
      final out = await FlutterImageCompress.compressWithList(
        data,
        quality: 95,
        format: CompressFormat.jpeg,
        keepExif: true,
      );
      return Uint8List.fromList(out);
    } catch (_) {
      return data;
    }
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  // Chamar quando for descartar o controller (ex.: Page dispose)
  @override
  void dispose() {
    _commentCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }
}
