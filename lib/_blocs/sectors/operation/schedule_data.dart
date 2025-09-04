import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

// ... imports iguais
class ScheduleData {
  // --------- dados da célula ----------
  final int numero;
  final int faixaIndex;
  final String? tipo;

  /// Valor cru que vem/sai do banco:
  /// 'concluido' | 'em_andamento' | 'a_iniciar' | variações com acento/espaços
  final String? status;
  final String? comentario;

  final List<String> fotos;
  final List<Map<String, dynamic>> fotosMeta;

  final int? takenAtMs;
  DateTime? get takenAt =>
      takenAtMs == null ? null : DateTime.fromMillisecondsSinceEpoch(takenAtMs!);

  // auditoria
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  // meta UI
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const ScheduleData({
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
  });

  // ================= Helpers de status =================

  /// Remove acentos e normaliza para comparar
  static String _strip(String s) {
    const from = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖòóôõöÙÚÛÜùúûüÇçÑñÝýÿ';
    const to   = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCcNnYyy';
    final map = { for (var i = 0; i < from.length; i++) from[i]: to[i] };
    final noAccents = s.split('').map((c) => map[c] ?? c).join();
    return noAccents.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
  }

  /// Canônico: 'concluido' | 'em_andamento' | 'a_iniciar'
  String get statusCanonical {
    final raw = status ?? '';
    final s = _strip(raw);
    if (s.contains('conclu')) return 'concluido';
    if (s.contains('andamento') || s.contains('progress')) return 'em_andamento';
    if (s.contains('iniciar') || s == 'a_iniciar' || s == 'a') return 'a_iniciar';
    return 'a_iniciar';
  }

  /// Label bonitinha para UI
  String get statusLabel {
    switch (statusCanonical) {
      case 'concluido':     return 'Concluído';
      case 'em_andamento':  return 'Em andamento';
      case 'a_iniciar':     return 'A iniciar';
      default:              return (status ?? '').isEmpty ? 'A iniciar' : _titleCase(status!);
    }
  }

  bool get isConcluido    => statusCanonical == 'concluido';
  bool get isEmAndamento  => statusCanonical == 'em_andamento';
  bool get isAIniciar     => statusCanonical == 'a_iniciar';

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

  // ================= Helpers de fotos/data (como antes) =================

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
          try { d = DateTime.parse(rawTaken); } catch (_) {}
        }
      } else if (rawTaken is DateTime) {
        d = rawTaken;
      } else if (rawTaken is Timestamp) {
        d = rawTaken.toDate();
      }
      if (d == null) {
        final up = m['uploadedAtMs'];
        if (up is int) d = DateTime.fromMillisecondsSinceEpoch(up);
        if (up is String) {
          final asInt = int.tryParse(up);
          if (asInt != null) d = DateTime.fromMillisecondsSinceEpoch(asInt);
        } else if (up is Timestamp) {
          d = up.toDate();
        }
      }
      if (d != null && (best == null || d.isAfter(best))) best = d;
    }
    return best;
  }

  // ================= Factory / persistência (inalterado) =================

  factory ScheduleData.fromMap(Map<String, dynamic> m, {ScheduleData? meta}) {
    final def = ScheduleData(
      numero: 0,
      faixaIndex: 0,
      key: 'geral',
      label: 'GERAL',
      icon: Icons.clear_all,
      color: Colors.grey,
    );
    return ScheduleData(
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
      key: meta?.key ?? def.key,
      label: meta?.label ?? def.label,
      icon: meta?.icon ?? def.icon,
      color: meta?.color ?? def.color,
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
    };
    if (includeMeta) {
      map.addAll({
        'key': key,
        'label': label,
        'icon': icon.codePoint,
        'color': color.value,
      });
    }
    return map;
  }

  ScheduleData copyWith({
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
  }) {
    return ScheduleData(
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
    );
  }

  // parsers
  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v);
    return null;
  }
  static String? _asString(dynamic v) => v?.toString();
  static List<String> _asStringList(dynamic v) {
    if (v is List) {
      return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    return const <String>[];
  }
  static List<Map<String, dynamic>> _asMapList(dynamic v) {
    if (v is List) {
      return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const <Map<String, dynamic>>[];
  }
  static DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) { try { return DateTime.parse(v); } catch (_) {} }
    if (v is Timestamp) return v.toDate();
    return null;
  }
  static int? _parseTakenAtMs(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final d = DateTime.tryParse(v);
      return d?.millisecondsSinceEpoch;
    }
    if (v is DateTime) return v.millisecondsSinceEpoch;
    if (v is Timestamp) return v.millisecondsSinceEpoch;
    return null;
  }
}
