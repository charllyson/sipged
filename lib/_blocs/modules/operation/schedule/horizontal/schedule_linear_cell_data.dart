// lib/_blocs/modules/operation/schedule/horizontal/schedule_linear_cell_data.dart

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:equatable/equatable.dart';

import 'schedule_linear_services_data.dart';

enum ScheduleLinearCellStatus {
  concluido(
    key: 'concluido',
    label: 'Concluído',
  ),
  emAndamento(
    key: 'em_andamento',
    label: 'Em andamento',
  ),
  aIniciar(
    key: 'a_iniciar',
    label: 'A iniciar',
  );

  const ScheduleLinearCellStatus({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;

  static ScheduleLinearCellStatus fromKey(String value) {
    final cleaned = value.trim().toLowerCase();

    for (final status in ScheduleLinearCellStatus.values) {
      if (status.key == cleaned) {
        return status;
      }
    }

    throw ArgumentError(
      'Status de célula inválido: "$value". '
          'Valores aceitos: ${ScheduleLinearCellStatus.values.map((e) => e.key).join(', ')}.',
    );
  }

  static ScheduleLinearCellStatus fromKeyOrDefault(
      dynamic value, {
        ScheduleLinearCellStatus fallback = ScheduleLinearCellStatus.aIniciar,
      }) {
    if (value is ScheduleLinearCellStatus) {
      return value;
    }

    if (value is String) {
      final cleaned = value.trim();

      if (cleaned.isEmpty) {
        return fallback;
      }

      try {
        return ScheduleLinearCellStatus.fromKey(cleaned);
      } catch (_) {
        return fallback;
      }
    }

    return fallback;
  }
}

class ScheduleLinearCellData extends Equatable {
  /// Número da estaca.
  ///
  /// Cada célula representa uma estaca.
  /// Por convenção do sistema, cada estaca corresponde a 20 metros.
  final int numero;

  /// Índice da faixa/lane onde a célula está posicionada.
  final int faixaIndex;

  /// Serviço executado nesta célula.
  final String serviceKey;

  /// Status padronizado da célula.
  final ScheduleLinearCellStatus status;

  final String? comentario;

  final List<String> fotos;
  final List<Map<String, dynamic>> fotosMeta;

  final int? takenAtMs;

  final DateTime? createdAt;
  final String? createdBy;

  final DateTime? updatedAt;
  final String? updatedBy;

  const ScheduleLinearCellData({
    required this.numero,
    required this.faixaIndex,
    required this.serviceKey,
    required this.status,
    this.comentario,
    this.fotos = const <String>[],
    this.fotosMeta = const <Map<String, dynamic>>[],
    this.takenAtMs,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  static const int metersPerStake = 20;

  factory ScheduleLinearCellData.empty({
    required int numero,
    required int faixaIndex,
    required String serviceKey,
  }) {
    return ScheduleLinearCellData(
      numero: numero,
      faixaIndex: faixaIndex,
      serviceKey: normalizeServiceKey(serviceKey),
      status: ScheduleLinearCellStatus.aIniciar,
    );
  }

  factory ScheduleLinearCellData.fromMap(Map<String, dynamic> map) {
    return ScheduleLinearCellData(
      numero: _asInt(map['numero']) ?? 0,
      faixaIndex: _asInt(map['faixaIndex']) ?? 0,
      serviceKey: normalizeServiceKey(
        _asString(map['serviceKey']) ??
            _asString(map['tipo']) ??
            ScheduleLinearServicesData.geralKey,
      ),
      status: _asStatus(map['status']),
      comentario: _asString(map['comentario']),
      fotos: _asStringList(map['fotos']),
      fotosMeta: _asMapList(map['fotosMeta']),
      takenAtMs: _parseTakenAtMs(map['takenAtMs']),
      createdAt: _asDateTime(map['createdAt']),
      createdBy: _asString(map['createdBy']),
      updatedAt: _asDateTime(map['updatedAt']),
      updatedBy: _asString(map['updatedBy']),
    );
  }

  static String normalizeServiceKey(String value) {
    final clean = value.trim();

    if (clean.isEmpty) {
      return ScheduleLinearServicesData.geralKey;
    }

    return clean;
  }

  static String cellKeyFor({
    required String serviceKey,
    required int faixaIndex,
    required int numero,
  }) {
    return '${normalizeServiceKey(serviceKey)}_${faixaIndex}_$numero';
  }

  /// Chave lógica da célula usada no índice em memória.
  String get cellKey {
    return cellKeyFor(
      serviceKey: serviceKey,
      faixaIndex: faixaIndex,
      numero: numero,
    );
  }

  /// Alias semântico para quando a chave for usada como ID lógico.
  String get docKey {
    return cellKey;
  }

  DateTime? get takenAt {
    if (takenAtMs == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(takenAtMs!);
  }

  /// Metro inicial da estaca.
  ///
  /// Estaca 1 = 0m até 20m.
  /// Estaca 2 = 20m até 40m.
  int get initialMeter {
    final safeNumero = numero <= 0 ? 1 : numero;

    return (safeNumero - 1) * metersPerStake;
  }

  /// Metro final da estaca.
  int get finalMeter {
    final safeNumero = numero <= 0 ? 1 : numero;

    return safeNumero * metersPerStake;
  }

  String get statusKey {
    return status.key;
  }

  String get statusLabel {
    return status.label;
  }

  bool get isConcluido {
    return status == ScheduleLinearCellStatus.concluido;
  }

  bool get isEmAndamento {
    return status == ScheduleLinearCellStatus.emAndamento;
  }

  bool get isAIniciar {
    return status == ScheduleLinearCellStatus.aIniciar;
  }

  bool get hasComment {
    return comentario?.trim().isNotEmpty ?? false;
  }

  bool get hasPhotos {
    return fotos.any((url) => url.trim().isNotEmpty);
  }

  int get photosCount {
    return fotos.where((url) => url.trim().isNotEmpty).length;
  }

  bool get hasEvidence {
    return hasComment || hasPhotos;
  }

  DateTime? get primaryDate {
    if (takenAt != null) return takenAt;

    final metaMax = _maxDateFromMetas();

    if (metaMax != null) return metaMax;

    return updatedAt ?? createdAt;
  }

  DateTime? _maxDateFromMetas() {
    DateTime? best;

    for (final meta in fotosMeta) {
      final date = _dateFromMeta(meta);

      if (date != null && (best == null || date.isAfter(best))) {
        best = date;
      }
    }

    return best;
  }

  DateTime? _dateFromMeta(Map<String, dynamic> meta) {
    final rawTaken = meta['takenAtMs'] ?? meta['takenAt'];
    final takenDate = _asDateTime(rawTaken);

    if (takenDate != null) {
      return takenDate;
    }

    final rawUploaded = meta['uploadedAtMs'] ?? meta['uploadedAt'];

    return _asDateTime(rawUploaded);
  }

  Map<String, dynamic> toMap({
    bool includeNullAuditFields = true,
  }) {
    return <String, dynamic>{
      'numero': numero,
      'faixaIndex': faixaIndex,
      'serviceKey': normalizeServiceKey(serviceKey),
      'status': status.key,
      if (comentario != null) 'comentario': comentario,
      if (comentario == null && includeNullAuditFields) 'comentario': null,
      if (fotos.isNotEmpty) 'fotos': fotos,
      if (fotos.isEmpty && includeNullAuditFields) 'fotos': fotos,
      if (fotosMeta.isNotEmpty) 'fotosMeta': fotosMeta,
      if (fotosMeta.isEmpty && includeNullAuditFields) 'fotosMeta': fotosMeta,
      if (takenAtMs != null) 'takenAtMs': takenAtMs,
      if (createdAt != null) 'createdAt': createdAt!.millisecondsSinceEpoch,
      if (createdBy != null) 'createdBy': createdBy,
      if (updatedAt != null) 'updatedAt': updatedAt!.millisecondsSinceEpoch,
      if (updatedBy != null) 'updatedBy': updatedBy,
    };
  }

  ScheduleLinearCellData copyWith({
    int? numero,
    int? faixaIndex,
    String? serviceKey,
    ScheduleLinearCellStatus? status,
    String? comentario,
    bool clearComentario = false,
    List<String>? fotos,
    List<Map<String, dynamic>>? fotosMeta,
    int? takenAtMs,
    bool clearTakenAtMs = false,
    DateTime? createdAt,
    bool clearCreatedAt = false,
    String? createdBy,
    bool clearCreatedBy = false,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
    String? updatedBy,
    bool clearUpdatedBy = false,
  }) {
    return ScheduleLinearCellData(
      numero: numero ?? this.numero,
      faixaIndex: faixaIndex ?? this.faixaIndex,
      serviceKey: serviceKey == null
          ? this.serviceKey
          : normalizeServiceKey(serviceKey),
      status: status ?? this.status,
      comentario: clearComentario ? null : comentario ?? this.comentario,
      fotos: fotos ?? this.fotos,
      fotosMeta: fotosMeta ?? this.fotosMeta,
      takenAtMs: clearTakenAtMs ? null : takenAtMs ?? this.takenAtMs,
      createdAt: clearCreatedAt ? null : createdAt ?? this.createdAt,
      createdBy: clearCreatedBy ? null : createdBy ?? this.createdBy,
      updatedAt: clearUpdatedAt ? null : updatedAt ?? this.updatedAt,
      updatedBy: clearUpdatedBy ? null : updatedBy ?? this.updatedBy,
    );
  }

  static ScheduleLinearCellStatus _asStatus(dynamic value) {
    return ScheduleLinearCellStatus.fromKeyOrDefault(
      value,
      fallback: ScheduleLinearCellStatus.aIniciar,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();

    if (value is String) {
      final cleaned = value.trim();

      if (cleaned.isEmpty) return null;

      return int.tryParse(cleaned);
    }

    return null;
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return text;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }

    return const <String>[];
  }

  static List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Object>()
          .map((item) {
        if (item is Map) {
          return Map<String, dynamic>.from(item);
        }

        return <String, dynamic>{};
      })
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    return const <Map<String, dynamic>>[];
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }

    if (value is String) {
      final cleaned = value.trim();

      if (cleaned.isEmpty) return null;

      final asInt = int.tryParse(cleaned);

      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      }

      return DateTime.tryParse(cleaned);
    }

    return null;
  }

  static int? _parseTakenAtMs(dynamic value) {
    final date = _asDateTime(value);

    return date?.millisecondsSinceEpoch;
  }

  @override
  List<Object?> get props => <Object?>[
    numero,
    faixaIndex,
    normalizeServiceKey(serviceKey),
    status,
    comentario,
    fotos,
    fotosMeta,
    takenAtMs,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
  ];
}