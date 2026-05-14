// lib/_blocs/modules/operation/schedule/horizontal/schedule_road_data.dart

import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint, Timestamp;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class ScheduleLaneResult {
  final List<ScheduleRoadData> lanes;
  final List<ScheduleRoadData> services;

  const ScheduleLaneResult({
    required this.lanes,
    required this.services,
  });

  ScheduleLaneResult copyWith({
    List<ScheduleRoadData>? lanes,
    List<ScheduleRoadData>? services,
  }) {
    return ScheduleLaneResult(
      lanes: lanes ?? this.lanes,
      services: services ?? this.services,
    );
  }
}

class ScheduleRoadData extends Equatable {
  final int numero;
  final int faixaIndex;
  final String? tipo;
  final String? status;
  final String? comentario;

  final List<String> fotos;
  final List<Map<String, dynamic>> fotosMeta;

  final int? takenAtMs;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  final String key;
  final String label;
  final IconData icon;
  final Color color;

  final String? geometryType;
  final List<List<LatLng>>? multiLine;
  final List<LatLng>? points;

  /// Dados de faixa.
  final String? pos;
  final String? nome;
  final double? altura;
  final int? anchor;
  final Map<String, bool> allowedByService;

  /// Campos locais de edição/UI.
  /// Não devem ser persistidos no Firestore.
  final String? editorId;
  final TextEditingController? posCtrl;
  final TextEditingController? nameCtrl;

  const ScheduleRoadData({
    required this.numero,
    required this.faixaIndex,
    this.tipo,
    this.status,
    this.comentario,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    this.fotos = const <String>[],
    this.fotosMeta = const <Map<String, dynamic>>[],
    this.takenAtMs,
    this.geometryType,
    this.multiLine,
    this.points,
    this.pos,
    this.nome,
    this.altura,
    this.anchor,
    this.allowedByService = const <String, bool>{},
    this.editorId,
    this.posCtrl,
    this.nameCtrl,
  });

  static const ScheduleRoadData emptyGeral = ScheduleRoadData(
    numero: 0,
    faixaIndex: 0,
    key: 'geral',
    label: 'GERAL',
    icon: Icons.clear_all,
    color: Colors.grey,
  );

  factory ScheduleRoadData.service({
    required String key,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return ScheduleRoadData(
      numero: 0,
      faixaIndex: 0,
      key: key.trim(),
      label: label.trim(),
      icon: icon,
      color: color,
    );
  }

  factory ScheduleRoadData.lane({
    required int faixaIndex,
    required String pos,
    required String nome,
    required double altura,
    int? anchor,
    Map<String, bool> allowedByService = const <String, bool>{},
  }) {
    return ScheduleRoadData(
      numero: 0,
      faixaIndex: faixaIndex,
      key: 'lane',
      label: 'LANE',
      icon: Icons.view_stream_outlined,
      color: Colors.grey,
      pos: pos,
      nome: nome,
      altura: altura,
      anchor: anchor,
      allowedByService: allowedByService,
    );
  }

  factory ScheduleRoadData.laneEditor({
    required int faixaIndex,
    required String pos,
    required String nome,
    required double altura,
    required Color color,
    String? editorId,
    int? anchor,
    Map<String, bool> allowedByService = const <String, bool>{},
  }) {
    return ScheduleRoadData(
      numero: 0,
      faixaIndex: faixaIndex,
      key: 'lane',
      label: 'LANE',
      icon: Icons.view_stream_outlined,
      color: color,
      pos: pos,
      nome: nome,
      altura: altura,
      anchor: anchor,
      allowedByService: allowedByService,
      editorId: editorId ?? UniqueKey().toString(),
      posCtrl: TextEditingController(text: pos),
      nameCtrl: TextEditingController(text: nome),
    );
  }

  DateTime? get takenAt {
    if (takenAtMs == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(takenAtMs!);
  }

  List<List<LatLng>> getSegments() {
    if (multiLine != null && multiLine!.isNotEmpty) {
      return multiLine!
          .where((segmento) => segmento.length >= 2)
          .map((segmento) => List<LatLng>.from(segmento))
          .toList(growable: false);
    }

    if (points != null && points!.length >= 2) {
      return <List<LatLng>>[
        List<LatLng>.from(points!),
      ];
    }

    return const <List<LatLng>>[];
  }

  List<LatLng> get axis {
    return getSegments().expand((segment) => segment).toList(growable: false);
  }

  String get laneLabel {
    final p = (posCtrl?.text ?? pos ?? '').trim();
    final n = (nameCtrl?.text ?? nome ?? '').trim();

    if (p.isEmpty) return n;
    if (n.isEmpty) return p;

    return '$p - $n';
  }

  String get resolvedPos => (posCtrl?.text ?? pos ?? '').trim();

  String get resolvedNome => (nameCtrl?.text ?? nome ?? '').trim();

  double get resolvedAltura => altura ?? 20.0;

  bool isAllowed(String serviceKey) {
    final cleanServiceKey = serviceKey.trim();

    if (cleanServiceKey.isEmpty || cleanServiceKey == 'geral') {
      return true;
    }

    return allowedByService[cleanServiceKey] ?? true;
  }

  void disposeEditorControllers() {
    posCtrl?.dispose();
    nameCtrl?.dispose();
  }

  String get statusCanonical {
    final value = (status ?? '').trim();

    if (value == 'concluido') return 'concluido';
    if (value == 'em_andamento') return 'em_andamento';
    if (value == 'a_iniciar') return 'a_iniciar';

    return value.isEmpty ? 'a_iniciar' : value;
  }

  String get statusLabel {
    switch (statusCanonical) {
      case 'concluido':
        return 'Concluído';

      case 'em_andamento':
        return 'Em andamento';

      case 'a_iniciar':
        return 'A iniciar';

      default:
        return statusCanonical;
    }
  }

  bool get isConcluido => statusCanonical == 'concluido';

  bool get isEmAndamento => statusCanonical == 'em_andamento';

  bool get isAIniciar => statusCanonical == 'a_iniciar';

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

  factory ScheduleRoadData.fromMap(
      Map<String, dynamic> map, {
        ScheduleRoadData? meta,
      }) {
    final key = meta?.key ?? _asString(map['key']) ?? emptyGeral.key;
    final label = meta?.label ?? _asString(map['label']) ?? emptyGeral.label;

    return ScheduleRoadData(
      numero: _asInt(map['numero']) ?? 0,
      faixaIndex: _asInt(map['faixaIndex']) ?? 0,
      tipo: _asString(map['tipo']),
      status: _asString(map['status']),
      comentario: _asString(map['comentario']),
      createdAt: _asDateTime(map['createdAt']),
      updatedAt: _asDateTime(map['updatedAt']),
      createdBy: _asString(map['createdBy']),
      updatedBy: _asString(map['updatedBy']),
      fotos: _asStringList(map['fotos']),
      fotosMeta: _asMapList(map['fotosMeta']),
      takenAtMs: _parseTakenAtMs(map['takenAtMs']),
      key: key,
      label: label,
      icon: meta?.icon ?? _iconForKey(key),
      color: meta?.color ?? _asColor(map['color']) ?? emptyGeral.color,
      geometryType: _asString(map['geometryType']),
      multiLine: _parseMulti(map['multiLine']),
      points: _parsePoints(map['points']),
      pos: _asString(map['pos']),
      nome: _asString(map['nome']),
      altura: _asDouble(map['altura']),
      anchor: _asInt(map['anchor']),
      allowedByService: _asBoolMap(map['allowedByService']),
    );
  }

  Map<String, dynamic> toDbMap({bool includeMeta = false}) {
    final map = <String, dynamic>{
      'numero': numero,
      'faixaIndex': faixaIndex,
      'tipo': tipo,
      'status': status,
      'comentario': comentario,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'updatedBy': updatedBy,
      'fotos': fotos,
      'fotosMeta': fotosMeta,
      if (takenAtMs != null) 'takenAtMs': takenAtMs,
      if (geometryType != null) 'geometryType': geometryType,
      if (multiLine != null) 'multiLine': _toMultiList(multiLine),
      if (points != null) 'points': _toPoints(points),
      if (pos != null) 'pos': pos,
      if (nome != null) 'nome': nome,
      if (altura != null) 'altura': altura,
      if (anchor != null) 'anchor': anchor,
      if (allowedByService.isNotEmpty) 'allowedByService': allowedByService,
    };

    if (includeMeta) {
      map.addAll({
        'key': key,
        'label': label,
        'iconKey': key,
        'color': color.toARGB32(),
      });
    }

    return map;
  }

  Map<String, dynamic> toServiceMap() {
    return <String, dynamic>{
      'key': key.trim(),
      'label': label.trim(),
      'iconKey': key.trim(),
      'color': color.toARGB32(),
    };
  }

  Map<String, dynamic> toLaneMap() {
    return <String, dynamic>{
      'faixaIndex': faixaIndex,
      'pos': resolvedPos,
      'nome': resolvedNome,
      'altura': resolvedAltura,
      if (anchor != null) 'anchor': anchor,
      'allowedByService': allowedByService,
    };
  }

  ScheduleRoadData copyWith({
    int? numero,
    int? faixaIndex,
    String? tipo,
    String? status,
    String? comentario,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    String? key,
    String? label,
    IconData? icon,
    Color? color,
    List<String>? fotos,
    List<Map<String, dynamic>>? fotosMeta,
    int? takenAtMs,
    String? geometryType,
    List<List<LatLng>>? multiLine,
    List<LatLng>? points,
    String? pos,
    String? nome,
    double? altura,
    int? anchor,
    Map<String, bool>? allowedByService,
    String? editorId,
    TextEditingController? posCtrl,
    TextEditingController? nameCtrl,
  }) {
    return ScheduleRoadData(
      numero: numero ?? this.numero,
      faixaIndex: faixaIndex ?? this.faixaIndex,
      tipo: tipo ?? this.tipo,
      status: status ?? this.status,
      comentario: comentario ?? this.comentario,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      key: key ?? this.key,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      fotos: fotos ?? this.fotos,
      fotosMeta: fotosMeta ?? this.fotosMeta,
      takenAtMs: takenAtMs ?? this.takenAtMs,
      geometryType: geometryType ?? this.geometryType,
      multiLine: multiLine ?? this.multiLine,
      points: points ?? this.points,
      pos: pos ?? this.pos,
      nome: nome ?? this.nome,
      altura: altura ?? this.altura,
      anchor: anchor ?? this.anchor,
      allowedByService: allowedByService ?? this.allowedByService,
      editorId: editorId ?? this.editorId,
      posCtrl: posCtrl ?? this.posCtrl,
      nameCtrl: nameCtrl ?? this.nameCtrl,
    );
  }

  static IconData _iconForKey(String key) {
    switch (key.trim()) {
      case 'geral':
        return Icons.clear_all;

      case 'asfalto':
        return Icons.alt_route;

      case 'base':
        return Icons.layers_outlined;

      case 'terraplenagem':
        return Icons.terrain_outlined;

      case 'drenagem':
        return Icons.water_drop_outlined;

      case 'sinalizacao':
        return Icons.traffic_outlined;

      case 'obra_arte':
        return Icons.account_tree_outlined;

      case 'meio_fio':
        return Icons.linear_scale_outlined;

      case 'lane':
        return Icons.view_stream_outlined;

      default:
        return Icons.construction_outlined;
    }
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

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();

    if (value is String) {
      final cleaned = value.trim().replaceAll(',', '.');

      if (cleaned.isEmpty) return null;

      return double.tryParse(cleaned);
    }

    return null;
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return text;
  }

  static Color? _asColor(dynamic value) {
    final colorInt = _asInt(value);

    if (colorInt == null) return null;

    return Color(colorInt);
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

  static Map<String, bool> _asBoolMap(dynamic value) {
    if (value is Map) {
      return <String, bool>{
        for (final entry in value.entries) entry.key.toString().trim(): entry.value == true,
      };
    }

    return const <String, bool>{};
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

  static List<List<LatLng>>? _parseMulti(dynamic geometry) {
    if (geometry is! List) return null;

    final out = <List<LatLng>>[];

    for (final segment in geometry) {
      if (segment is Map) {
        final points = segment['points'];
        final parsed = _parsePoints(points);

        if (parsed != null && parsed.length >= 2) {
          out.add(parsed);
        }

        continue;
      }

      if (segment is! List) continue;

      final line = <LatLng>[];

      for (final pointRaw in segment) {
        final point = _parseLatLngPoint(pointRaw);

        if (point != null) {
          line.add(point);
        }
      }

      if (line.length >= 2) {
        out.add(line);
      }
    }

    return out.isEmpty ? null : out;
  }

  static List<LatLng>? _parsePoints(dynamic value) {
    if (value is! List) return null;

    final out = <LatLng>[];

    for (final pointRaw in value) {
      final point = _parseLatLngPoint(pointRaw);

      if (point != null) {
        out.add(point);
      }
    }

    return out.length < 2 ? null : out;
  }

  static LatLng? _parseLatLngPoint(dynamic pointRaw) {
    if (pointRaw is GeoPoint) {
      return LatLng(pointRaw.latitude, pointRaw.longitude);
    }

    if (pointRaw is List && pointRaw.length >= 2) {
      final lon = _asDouble(pointRaw[0]);
      final lat = _asDouble(pointRaw[1]);

      if (lat != null && lon != null) {
        return LatLng(lat, lon);
      }
    }

    if (pointRaw is Map) {
      final rawLat = pointRaw['lat'] ?? pointRaw['latitude'];
      final rawLon = pointRaw['lng'] ?? pointRaw['longitude'] ?? pointRaw['lon'];

      final lat = _asDouble(rawLat);
      final lon = _asDouble(rawLon);

      if (lat != null && lon != null) {
        return LatLng(lat, lon);
      }
    }

    return null;
  }

  static List<List<dynamic>>? _toMultiList(List<List<LatLng>>? multiLine) {
    if (multiLine == null) return null;

    final validSegments = multiLine.where((segment) => segment.length >= 2).toList();

    if (validSegments.isEmpty) return null;

    return validSegments
        .map(
          (segment) => segment
          .map(
            (point) => <double>[
          point.longitude,
          point.latitude,
        ],
      )
          .toList(growable: false),
    )
        .toList(growable: false);
  }

  static List<dynamic>? _toPoints(List<LatLng>? points) {
    if (points == null || points.length < 2) return null;

    return points
        .map(
          (point) => <String, double>{
        'latitude': point.latitude,
        'longitude': point.longitude,
      },
    )
        .toList(growable: false);
  }

  @override
  List<Object?> get props => [
    numero,
    faixaIndex,
    tipo,
    status,
    comentario,
    fotos,
    fotosMeta,
    takenAtMs,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    key,
    label,
    icon.codePoint,
    color.toARGB32(),
    geometryType,
    multiLine,
    points,
    pos,
    nome,
    altura,
    anchor,
    allowedByService,
    editorId,
    posCtrl?.text,
    nameCtrl?.text,
  ];
}