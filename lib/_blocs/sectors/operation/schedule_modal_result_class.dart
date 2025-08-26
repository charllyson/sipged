import 'dart:typed_data';
import 'package:sisged/_blocs/widgets/carousel/carousel_metadata.dart';
import 'package:sisged/_widgets/schedule/schedule_status.dart';


class ScheduleModalResultClass {
  final ScheduleStatus status;     // enum
  final String? comment;           // comentário opcional
  final DateTime? date;            // data (ex.: da foto/campo do modal)

  /// Fotos selecionadas (bytes + nomes dos arquivos)
  /// OBS: bytes não são serializáveis para Firestore; use no upload.
  final List<Uint8List> photosBytes;
  final List<String> photoNames;

  /// ⟵ NOVO: metadados EXIF alinhados com `photosBytes`/`photoNames`
  final List<CarouselMetadata> photoMetas;

  const ScheduleModalResultClass(
      this.status,
      this.comment, {
        this.date,
        this.photosBytes = const [],
        this.photoNames = const [],
        this.photoMetas = const [], // default p/ compatibilidade
      });

  // ---- conveniências ----
  String get statusKey => status.key; // ✅ use isto ao salvar no Firestore
  bool get hasPhotos => photosBytes.isNotEmpty;

  String? get trimmedComment {
    final c = comment?.trim();
    return (c == null || c.isEmpty) ? null : c;
  }

  // ---- (de)serialização simples (para guardar localmente) ----
  Map<String, dynamic> toMap() => {
    'status': status.key,
    'comment': trimmedComment,
    'dateMs': date?.millisecondsSinceEpoch,
    // fotoBytes não entram no mapa; nomes sim (útil para logs/UI)
    'photoNames': photoNames,
    // Metas serializadas
    'photoMetas': photoMetas
        .map((m) => {
      'takenAt': m.takenAt?.toIso8601String(),
      'lat': m.lat,
      'lng': m.lng,
      'make': m.make,
      'model': m.model,
      'orientation': m.orientation,
    })
        .toList(),
  };

  factory ScheduleModalResultClass.fromMap(Map<String, dynamic> map) {
    DateTime? _parseIso(String? s) {
      if (s == null || s.isEmpty) return null;
      try { return DateTime.parse(s); } catch (_) { return null; }
    }

    final metasRaw = (map['photoMetas'] as List?) ?? const [];
    final metas = metasRaw.map((e) {
      final m = (e as Map?) ?? const {};
      return CarouselMetadata(
        takenAt: _parseIso(m['takenAt']?.toString()),
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        make: m['make']?.toString(),
        model: m['model']?.toString(),
        orientation: (m['orientation'] is num)
            ? (m['orientation'] as num).toInt()
            : int.tryParse(m['orientation']?.toString() ?? ''),
      );
    }).toList();

    return ScheduleModalResultClass(
      ScheduleStatusX.fromAny(map['status']),
      map['comment'] as String?,
      date: (map['dateMs'] is num)
          ? DateTime.fromMillisecondsSinceEpoch(map['dateMs'] as int)
          : null,
      photosBytes: const [], // não vem do mapa
      photoNames: (map['photoNames'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          const [],
      photoMetas: metas,
    );
  }
}
