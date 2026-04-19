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
  });

  static const ScheduleRoadData emptyGeral = ScheduleRoadData(
    numero: 0,
    faixaIndex: 0,
    key: 'geral',
    label: 'GERAL',
    icon: Icons.clear_all,
    color: Colors.grey,
  );

  DateTime? get takenAt =>
      takenAtMs == null ? null : DateTime.fromMillisecondsSinceEpoch(takenAtMs!);

  List<List<LatLng>> getSegments() {
    if (multiLine != null && multiLine!.isNotEmpty) {
      return multiLine!.map((s) => List<LatLng>.from(s)).toList(growable: false);
    }
    if (points != null && points!.isNotEmpty) {
      return <List<LatLng>>[List<LatLng>.from(points!)];
    }
    return const <List<LatLng>>[];
  }

  List<LatLng> get axis => getSegments().expand((s) => s).toList(growable: false);

  static String _strip(String s) {
    const from =
        'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖòóôõöÙÚÛÜùúûüÇçÑñÝýÿ';
    const to =
        'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCcNnYyy';
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

  bool get hasPhotos => fotos.any((u) => u.trim().isNotEmpty);

  int get photosCount => fotos.where((u) => u.trim().isNotEmpty).length;

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
      } else if (rawTaken is String) {
        final asInt = int.tryParse(rawTaken);
        if (asInt != null) {
          d = DateTime.fromMillisecondsSinceEpoch(asInt);
        } else {
          try {
            d = DateTime.parse(rawTaken);
          } catch (_) {}
        }
      } else if (rawTaken is DateTime) {
        d = rawTaken;
      } else if (rawTaken is Timestamp) {
        d = rawTaken.toDate();
      }

      if (d == null) {
        final up = m['uploadedAtMs'];
        if (up is int) {
          d = DateTime.fromMillisecondsSinceEpoch(up);
        } else if (up is String) {
          final asInt = int.tryParse(up);
          if (asInt != null) {
            d = DateTime.fromMillisecondsSinceEpoch(asInt);
          }
        } else if (up is Timestamp) {
          d = up.toDate();
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
    final def = emptyGeral;

    return ScheduleRoadData(
      numero: _asInt(m['numero']) ?? 0,
      faixaIndex: _asInt(m['faixa_index']) ?? 0,
      tipo: _asString(m['tipo']),
      status: _asString(m['status']),
      comentario: _asString(m['comentario']),
      createdAt: _asDateTime(m['createdAt']),
      updatedAt: _asDateTime(m['updatedAt']),
      createdBy: _asString(m['createdBy']),
      updatedBy: _asString(m['updatedBy']),
      fotos: _asStringList(m['fotos']),
      fotosMeta: _asMapList(m['fotos_meta']),
      takenAtMs: _parseTakenAtMs(m['takenAtMs'] ?? m['takenAt']),
      key: meta?.key ?? _asString(m['key']) ?? def.key,
      label: meta?.label ?? _asString(m['label']) ?? def.label,
      icon: meta?.icon ?? _asIconData(m['icon']) ?? def.icon,
      color: meta?.color ?? _asColor(m['color']) ?? def.color,
      geometryType: _asString(m['geometryType']),
      multiLine: _parseMulti(m['multiLine']),
      points: _parsePoints(m['points']),
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
    };

    if (includeMeta) {
      map.addAll({
        'key': key,
        'label': label,
        'icon': icon.codePoint,
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
    );
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static String? _asString(dynamic v) => v?.toString();

  static IconData? _asIconData(dynamic v) {
    final codePoint = _asInt(v);
    if (codePoint == null) return null;
    return IconData(codePoint, fontFamily: 'MaterialIcons');
  }

  static Color? _asColor(dynamic v) {
    final colorInt = _asInt(v);
    if (colorInt == null) return null;
    return Color(colorInt);
  }

  static List<String> _asStringList(dynamic v) {
    if (v is List) {
      return v
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static List<Map<String, dynamic>> _asMapList(dynamic v) {
    if (v is List) {
      return v
          .whereType<Object>()
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .where((m) => m.isNotEmpty)
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  static DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    if (v is Timestamp) return v.toDate();
    return null;
  }

  static int? _parseTakenAtMs(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final intValue = int.tryParse(v);
      if (intValue != null) return intValue;
      final d = DateTime.tryParse(v);
      return d?.millisecondsSinceEpoch;
    }
    if (v is DateTime) return v.millisecondsSinceEpoch;
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    return null;
  }

  static List<List<LatLng>>? _parseMulti(dynamic g) {
    if (g is! List) return null;

    final out = <List<LatLng>>[];
    for (final seg in g) {
      if (seg is! List) continue;

      final line = <LatLng>[];
      for (final p in seg) {
        if (p is List && p.length >= 2) {
          final lon = (p[0] as num?)?.toDouble();
          final lat = (p[1] as num?)?.toDouble();
          if (lat != null && lon != null) {
            line.add(LatLng(lat, lon));
          }
        } else if (p is Map) {
          final lat = (p['lat'] ?? p['latitude']) as num?;
          final lon = (p['lng'] ?? p['longitude']) as num?;
          if (lat != null && lon != null) {
            line.add(LatLng(lat.toDouble(), lon.toDouble()));
          }
        } else if (p is GeoPoint) {
          line.add(LatLng(p.latitude, p.longitude));
        }
      }

      if (line.isNotEmpty) {
        out.add(line);
      }
    }

    return out.isEmpty ? null : out;
  }

  static List<LatLng>? _parsePoints(dynamic v) {
    if (v is! List) return null;

    final out = <LatLng>[];
    for (final p in v) {
      if (p is GeoPoint) {
        out.add(LatLng(p.latitude, p.longitude));
      } else if (p is List && p.length >= 2) {
        final lon = (p[0] as num?)?.toDouble();
        final lat = (p[1] as num?)?.toDouble();
        if (lat != null && lon != null) {
          out.add(LatLng(lat, lon));
        }
      } else if (p is Map) {
        final lat = (p['lat'] ?? p['latitude']) as num?;
        final lon = (p['lng'] ?? p['longitude']) as num?;
        if (lat != null && lon != null) {
          out.add(LatLng(lat.toDouble(), lon.toDouble()));
        }
      }
    }

    return out.isEmpty ? null : out;
  }

  static List<List<dynamic>>? _toMultiList(List<List<LatLng>>? ml) {
    if (ml == null) return null;
    return ml
        .map((seg) => seg.map((p) => <double>[p.longitude, p.latitude]).toList())
        .toList(growable: false);
  }

  static List<dynamic>? _toPoints(List<LatLng>? pts) {
    if (pts == null) return null;
    return pts
        .map((p) => <String, double>{
      'latitude': p.latitude,
      'longitude': p.longitude,
    })
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
  ];
}