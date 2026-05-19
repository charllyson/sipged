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
    for (final status in ScheduleLinearCellStatus.values) {
      if (status.key == value) {
        return status;
      }
    }

    throw ArgumentError(
      'Status de célula inválido: "$value". '
          'Valores aceitos: ${ScheduleLinearCellStatus.values.map((e) => e.key).join(', ')}.',
    );
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
      serviceKey: serviceKey.trim(),
      status: ScheduleLinearCellStatus.aIniciar,
    );
  }

  factory ScheduleLinearCellData.fromMap(Map<String, dynamic> map) {
    return ScheduleLinearCellData(
      numero: _asInt(map['numero']) ?? 0,
      faixaIndex: _asInt(map['faixaIndex']) ?? 0,
      serviceKey: _asString(map['serviceKey']) ??
          _asString(map['tipo']) ??
          ScheduleLinearServicesData.geralKey,
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

  DateTime? get takenAt {
    if (takenAtMs == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(takenAtMs!);
  }

  /// Metro inicial da estaca.
  ///
  /// Estaca 1 = 0m até 20m.
  /// Estaca 2 = 20m até 40m.
  ///
  /// Antes estava `numero * metersPerStake`, o que deslocava a estaca 1 para
  /// iniciar em 20m e gerava divergência entre board e mapa.
  int get initialMeter {
    return (numero - 1) * metersPerStake;
  }

  /// Metro final da estaca.
  int get finalMeter {
    return numero * metersPerStake;
  }

  String get cellKey {
    return '${serviceKey.trim()}_${faixaIndex}_$numero';
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

  bool get hasPhotos {
    return fotos.any((url) => url.trim().isNotEmpty);
  }

  int get photosCount {
    return fotos.where((url) => url.trim().isNotEmpty).length;
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
      DateTime? date;

      final rawTaken = meta['takenAtMs'];

      if (rawTaken is int) {
        date = DateTime.fromMillisecondsSinceEpoch(rawTaken);
      } else if (rawTaken is num) {
        date = DateTime.fromMillisecondsSinceEpoch(rawTaken.toInt());
      } else if (rawTaken is String) {
        final asInt = int.tryParse(rawTaken);

        if (asInt != null) {
          date = DateTime.fromMillisecondsSinceEpoch(asInt);
        } else {
          date = DateTime.tryParse(rawTaken);
        }
      } else if (rawTaken is DateTime) {
        date = rawTaken;
      } else if (rawTaken is Timestamp) {
        date = rawTaken.toDate();
      }

      if (date == null) {
        final uploadedAt = meta['uploadedAtMs'];

        if (uploadedAt is int) {
          date = DateTime.fromMillisecondsSinceEpoch(uploadedAt);
        } else if (uploadedAt is num) {
          date = DateTime.fromMillisecondsSinceEpoch(uploadedAt.toInt());
        } else if (uploadedAt is String) {
          final asInt = int.tryParse(uploadedAt);

          if (asInt != null) {
            date = DateTime.fromMillisecondsSinceEpoch(asInt);
          } else {
            date = DateTime.tryParse(uploadedAt);
          }
        } else if (uploadedAt is Timestamp) {
          date = uploadedAt.toDate();
        } else if (uploadedAt is DateTime) {
          date = uploadedAt;
        }
      }

      if (date != null && (best == null || date.isAfter(best))) {
        best = date;
      }
    }

    return best;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'numero': numero,
      'faixaIndex': faixaIndex,
      'serviceKey': serviceKey.trim(),
      'status': status.key,
      'comentario': comentario,
      'fotos': fotos,
      'fotosMeta': fotosMeta,
      if (takenAtMs != null) 'takenAtMs': takenAtMs,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'updatedBy': updatedBy,
    };
  }

  ScheduleLinearCellData copyWith({
    int? numero,
    int? faixaIndex,
    String? serviceKey,
    ScheduleLinearCellStatus? status,
    String? comentario,
    List<String>? fotos,
    List<Map<String, dynamic>>? fotosMeta,
    int? takenAtMs,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return ScheduleLinearCellData(
      numero: numero ?? this.numero,
      faixaIndex: faixaIndex ?? this.faixaIndex,
      serviceKey: serviceKey ?? this.serviceKey,
      status: status ?? this.status,
      comentario: comentario ?? this.comentario,
      fotos: fotos ?? this.fotos,
      fotosMeta: fotosMeta ?? this.fotosMeta,
      takenAtMs: takenAtMs ?? this.takenAtMs,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  static ScheduleLinearCellStatus _asStatus(dynamic value) {
    if (value is ScheduleLinearCellStatus) {
      return value;
    }

    if (value is String) {
      final cleaned = value.trim();

      if (cleaned.isEmpty) {
        throw ArgumentError(
          'Status da célula não pode ser vazio. '
              'Use um dos valores: ${ScheduleLinearCellStatus.values.map((e) => e.key).join(', ')}.',
        );
      }

      return ScheduleLinearCellStatus.fromKey(cleaned);
    }

    throw ArgumentError(
      'Status da célula é obrigatório e deve ser String. '
          'Use um dos valores: ${ScheduleLinearCellStatus.values.map((e) => e.key).join(', ')}.',
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
    if (value == null) return null;

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final cleaned = value.trim();

      if (cleaned.isEmpty) return null;

      final intValue = int.tryParse(cleaned);

      if (intValue != null) return intValue;

      final date = DateTime.tryParse(cleaned);

      return date?.millisecondsSinceEpoch;
    }

    if (value is DateTime) {
      return value.millisecondsSinceEpoch;
    }

    if (value is Timestamp) {
      return value.toDate().millisecondsSinceEpoch;
    }

    return null;
  }

  @override
  List<Object?> get props => <Object?>[
    numero,
    faixaIndex,
    serviceKey,
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