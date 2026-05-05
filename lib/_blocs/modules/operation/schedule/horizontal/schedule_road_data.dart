// lib/_blocs/modules/operation/operation/road/schedule_road_data.dart

import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint, Timestamp;
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

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

  /// Dados de faixa
  final String? pos;
  final String? nome;
  final double? altura;
  final int? anchor;
  final Map<String, bool> allowedByService;

  /// Campos locais de edição/UI (não persistidos)
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
    return getSegments().expand((s) => s).toList(growable: false);
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
    final v = allowedByService[serviceKey.toLowerCase()];
    return v ?? true;
  }

  void disposeEditorControllers() {
    posCtrl?.dispose();
    nameCtrl?.dispose();
  }

  static String _strip(String s) {
    const from =
        'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖòóôõöÙÚÛÜùúûüÇçÑñÝýÿ';
    const to = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCcNnYyy';

    final map = <String, String>{
      for (var i = 0; i < from.length; i++) from[i]: to[i],
    };

    return s
        .split('')
        .map((c) => map[c] ?? c)
        .join()
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
  }

  String get statusCanonical {
    final raw = status ?? '';
    final s = _strip(raw);

    if (s.contains('conclu')) return 'concluido';

    if (s.contains('andamento') || s.contains('progress')) {
      return 'em_andamento';
    }

    if (s.contains('iniciar') || s == 'a_iniciar' || s == 'a') {
      return 'a_iniciar';
    }

    return 'a_iniciar';
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
        return (status ?? '').isEmpty ? 'A iniciar' : _titleCase(status!);
    }
  }

  bool get isConcluido => statusCanonical == 'concluido';

  bool get isEmAndamento => statusCanonical == 'em_andamento';

  bool get isAIniciar => statusCanonical == 'a_iniciar';

  static String _titleCase(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;

    return t.split(RegExp(r'\s+')).map((p) {
      if (p.isEmpty) return p;

      final first = p.characters.first.toUpperCase();
      final rest = p.characters.skip(1).toString().toLowerCase();

      return '$first$rest';
    }).join(' ');
  }

  bool get hasPhotos {
    return fotos.any((u) => u.trim().isNotEmpty);
  }

  int get photosCount {
    return fotos.where((u) => u.trim().isNotEmpty).length;
  }

  DateTime? get primaryDate {
    if (takenAt != null) return takenAt;

    final metaMax = _maxDateFromMetas();
    if (metaMax != null) return metaMax;

    return updatedAt ?? createdAt;
  }

  DateTime? _maxDateFromMetas() {
    DateTime? best;

    for (final m in fotosMeta) {
      DateTime? d;

      final rawTaken = m['takenAt'] ?? m['takenAtMs'];

      if (rawTaken is int) {
        d = DateTime.fromMillisecondsSinceEpoch(rawTaken);
      } else if (rawTaken is num) {
        d = DateTime.fromMillisecondsSinceEpoch(rawTaken.toInt());
      } else if (rawTaken is String) {
        final asInt = int.tryParse(rawTaken);
        if (asInt != null) {
          d = DateTime.fromMillisecondsSinceEpoch(asInt);
        } else {
          d = DateTime.tryParse(rawTaken);
        }
      } else if (rawTaken is DateTime) {
        d = rawTaken;
      } else if (rawTaken is Timestamp) {
        d = rawTaken.toDate();
      }

      if (d == null) {
        final uploadedAt = m['uploadedAtMs'];

        if (uploadedAt is int) {
          d = DateTime.fromMillisecondsSinceEpoch(uploadedAt);
        } else if (uploadedAt is num) {
          d = DateTime.fromMillisecondsSinceEpoch(uploadedAt.toInt());
        } else if (uploadedAt is String) {
          final asInt = int.tryParse(uploadedAt);
          if (asInt != null) {
            d = DateTime.fromMillisecondsSinceEpoch(asInt);
          } else {
            d = DateTime.tryParse(uploadedAt);
          }
        } else if (uploadedAt is Timestamp) {
          d = uploadedAt.toDate();
        } else if (uploadedAt is DateTime) {
          d = uploadedAt;
        }
      }

      if (d != null && (best == null || d.isAfter(best))) {
        best = d;
      }
    }

    return best;
  }

  factory ScheduleRoadData.fromMap(
      Map<String, dynamic> m, {
        ScheduleRoadData? meta,
      }) {
    const def = emptyGeral;

    final rawKey = meta?.key ?? _asString(m['key']) ?? _asString(m['tipo']) ?? def.key;
    final rawLabel = meta?.label ?? _asString(m['label']) ?? _asString(m['tipo']) ?? def.label;

    final normalizedKey = _normalizeServiceKey(rawKey);

    return ScheduleRoadData(
      numero: _asInt(m['numero']) ?? 0,
      faixaIndex: _asInt(m['faixa_index']) ?? _asInt(m['faixaIndex']) ?? 0,
      tipo: _asString(m['tipo']),
      status: _asString(m['status']),
      comentario: _asString(m['comentario']),
      createdAt: _asDateTime(m['createdAt']),
      updatedAt: _asDateTime(m['updatedAt']),
      createdBy: _asString(m['createdBy']),
      updatedBy: _asString(m['updatedBy']),
      fotos: _asStringList(m['fotos']),
      fotosMeta: _asMapList(m['fotos_meta'] ?? m['fotosMeta']),
      takenAtMs: _parseTakenAtMs(m['takenAtMs'] ?? m['takenAt']),
      key: normalizedKey,
      label: rawLabel,
      icon: meta?.icon ?? _iconForKey(normalizedKey),
      color: meta?.color ?? _asColor(m['color']) ?? def.color,
      geometryType: _asString(m['geometryType']),
      multiLine: _parseMulti(m['multiLine']),
      points: _parsePoints(m['points']),
      pos: _asString(m['pos']),
      nome: _asString(m['nome']),
      altura: _asDouble(m['altura']),
      anchor: _asInt(m['anchor']),
      allowedByService: _asBoolMap(m['allowedByService']),
    );
  }

  Map<String, dynamic> toDbMap({bool includeMeta = false}) {
    final map = <String, dynamic>{
      'numero': numero,
      'faixa_index': faixaIndex,
      'tipo': tipo,
      'status': status,
      'comentario': comentario,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'updatedBy': updatedBy,
      'fotos': fotos,
      'fotos_meta': fotosMeta,
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

        // Não salvar IconData/codePoint.
        // Flutter Web release não aceita reconstruir IconData dinamicamente.
        // O ícone agora é resolvido pelo campo "key".
        'iconKey': key,

        'color': color.toARGB32(),
      });
    }

    return map;
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
    final nextKey = key ?? this.key;

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
      key: nextKey,
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

  static String _normalizeServiceKey(String value) {
    final normalized = _strip(value);

    if (normalized.contains('geral')) return 'geral';
    if (normalized.contains('asfalto') || normalized.contains('paviment')) return 'asfalto';
    if (normalized.contains('base') || normalized.contains('sub_base')) return 'base';
    if (normalized.contains('terraplen')) return 'terraplenagem';
    if (normalized.contains('drenagem')) return 'drenagem';
    if (normalized.contains('sinaliz')) return 'sinalizacao';
    if (normalized.contains('obra_arte') || normalized.contains('oae')) return 'obra_arte';
    if (normalized.contains('meio_fio')) return 'meio_fio';
    if (normalized.contains('faixa') || normalized.contains('lane')) return 'lane';

    return normalized.isEmpty ? 'geral' : normalized;
  }

  static IconData _iconForKey(String key) {
    switch (_normalizeServiceKey(key)) {
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

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is num) return v.toInt();

    if (v is String) {
      final cleaned = v.trim();
      if (cleaned.isEmpty) return null;

      return int.tryParse(cleaned);
    }

    return null;
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();

    if (v is String) {
      final cleaned = v.trim().replaceAll(',', '.');
      if (cleaned.isEmpty) return null;

      return double.tryParse(cleaned);
    }

    return null;
  }

  static String? _asString(dynamic v) {
    if (v == null) return null;

    final value = v.toString().trim();
    if (value.isEmpty) return null;

    return value;
  }

  static Color? _asColor(dynamic v) {
    final colorInt = _asInt(v);
    if (colorInt == null) return null;

    return Color(colorInt);
  }

  static List<String> _asStringList(dynamic v) {
    if (v is List) {
      return v
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }

    return const <String>[];
  }

  static List<Map<String, dynamic>> _asMapList(dynamic v) {
    if (v is List) {
      return v
          .whereType<Object>()
          .map((e) {
        if (e is Map) {
          return Map<String, dynamic>.from(e);
        }

        return <String, dynamic>{};
      })
          .where((m) => m.isNotEmpty)
          .toList(growable: false);
    }

    return const <Map<String, dynamic>>[];
  }

  static Map<String, bool> _asBoolMap(dynamic v) {
    if (v is Map) {
      return <String, bool>{
        for (final entry in v.entries)
          entry.key.toString().toLowerCase(): entry.value == true,
      };
    }

    return const <String, bool>{};
  }

  static DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();

    if (v is int) {
      return DateTime.fromMillisecondsSinceEpoch(v);
    }

    if (v is num) {
      return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    }

    if (v is String) {
      final cleaned = v.trim();
      if (cleaned.isEmpty) return null;

      final asInt = int.tryParse(cleaned);
      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      }

      return DateTime.tryParse(cleaned);
    }

    return null;
  }

  static int? _parseTakenAtMs(dynamic v) {
    if (v == null) return null;

    if (v is int) return v;

    if (v is num) {
      return v.toInt();
    }

    if (v is String) {
      final cleaned = v.trim();
      if (cleaned.isEmpty) return null;

      final intValue = int.tryParse(cleaned);
      if (intValue != null) return intValue;

      final d = DateTime.tryParse(cleaned);
      return d?.millisecondsSinceEpoch;
    }

    if (v is DateTime) {
      return v.millisecondsSinceEpoch;
    }

    if (v is Timestamp) {
      return v.millisecondsSinceEpoch;
    }

    return null;
  }

  static List<List<LatLng>>? _parseMulti(dynamic g) {
    if (g is! List) return null;

    final out = <List<LatLng>>[];

    for (final seg in g) {
      if (seg is! List) continue;

      final line = <LatLng>[];

      for (final p in seg) {
        final point = _parseLatLngPoint(p);
        if (point != null) {
          line.add(point);
        }
      }

      // Importante:
      // Segmentos com menos de 2 pontos são ignorados.
      // Isso também ajuda a evitar ligação visual indevida entre partes inválidas.
      if (line.length >= 2) {
        out.add(line);
      }
    }

    return out.isEmpty ? null : out;
  }

  static List<LatLng>? _parsePoints(dynamic v) {
    if (v is! List) return null;

    final out = <LatLng>[];

    for (final p in v) {
      final point = _parseLatLngPoint(p);
      if (point != null) {
        out.add(point);
      }
    }

    return out.length < 2 ? null : out;
  }

  static LatLng? _parseLatLngPoint(dynamic p) {
    if (p is GeoPoint) {
      return LatLng(p.latitude, p.longitude);
    }

    if (p is List && p.length >= 2) {
      final lon = _asDouble(p[0]);
      final lat = _asDouble(p[1]);

      if (lat != null && lon != null) {
        return LatLng(lat, lon);
      }
    }

    if (p is Map) {
      final rawLat = p['lat'] ?? p['latitude'];
      final rawLon = p['lng'] ?? p['longitude'] ?? p['lon'];

      final lat = _asDouble(rawLat);
      final lon = _asDouble(rawLon);

      if (lat != null && lon != null) {
        return LatLng(lat, lon);
      }
    }

    return null;
  }

  static List<List<dynamic>>? _toMultiList(List<List<LatLng>>? ml) {
    if (ml == null) return null;

    final validSegments = ml.where((seg) => seg.length >= 2).toList();

    if (validSegments.isEmpty) return null;

    return validSegments
        .map(
          (seg) => seg
          .map(
            (p) => <double>[
          p.longitude,
          p.latitude,
        ],
      )
          .toList(growable: false),
    )
        .toList(growable: false);
  }

  static List<dynamic>? _toPoints(List<LatLng>? pts) {
    if (pts == null || pts.length < 2) return null;

    return pts
        .map(
          (p) => <String, double>{
        'latitude': p.latitude,
        'longitude': p.longitude,
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