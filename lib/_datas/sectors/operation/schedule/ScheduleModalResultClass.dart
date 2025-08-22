/*
// lib/_widgets/schedule/sheet/ScheduleModalResultClass.dart
import 'dart:typed_data';

import 'package:sisged/_widgets/schedule/schedule_status.dart';

class ScheduleModalResultClass {
  final ScheduleStatus status;     // enum
  final String? comment;           // comentário opcional
  final DateTime? date;            // data (ex.: da foto/campo do modal)

  /// Fotos selecionadas no modal (bytes + nomes dos arquivos)
  /// OBS: bytes não são serializáveis para Firestore; use no upload.
  final List<Uint8List> photosBytes;
  final List<String> photoNames;

  const ScheduleModalResultClass(
      this.status,
      this.comment, {
        this.date,
        this.photosBytes = const [],
        this.photoNames = const [],
      });

  // ---- conveniências ----
  String get statusKey => status.key; // ✅ use isto ao salvar no Firestore
  bool get hasPhotos => photosBytes.isNotEmpty;

  String? get trimmedComment {
    final c = comment?.trim();
    return (c == null || c.isEmpty) ? null : c;
  }

  // ---- (de)serialização simples (se quiser guardar o retorno do modal localmente) ----
  Map<String, dynamic> toMap() => {
    'status': status.key,
    'comment': trimmedComment,
    'dateMs': date?.millisecondsSinceEpoch,
    // fotoBytes não entram no mapa; nomes sim (útil para logs/UI)
    'photoNames': photoNames,
  };

  factory ScheduleModalResultClass.fromMap(Map<String, dynamic> map) {
    return ScheduleModalResultClass(
      ScheduleStatusX.fromAny(map['status']),
      map['comment'] as String?,
      date: (map['dateMs'] is num) ? DateTime.fromMillisecondsSinceEpoch(map['dateMs'] as int) : null,
      photosBytes: const [], // não vem do mapa
      photoNames: (map['photoNames'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
*/
