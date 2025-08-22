import 'package:flutter/material.dart';

class ScheduleData {
  // --------- dados da célula ----------
  final int numero;                 // estaca (>=0)
  final int faixaIndex;             // índice da faixa (>=0)
  final String? tipo;
  final String? status;             // 'concluido' | 'em andamento' | 'a iniciar'
  final String? comentario;

  /// URLs das fotos anexadas
  final List<String> fotos;
  final List<Map<String, dynamic>> fotosMeta;

  // --------- metadados de criação ----------
  final DateTime? createdAt;
  final String? createdBy;

  // --------- metadados de última edição ----------
  final DateTime? updatedAt;
  final String? updatedBy;

  // --------- metadados do serviço (UI) ----------
  final String key;                 // ex.: 'servicos-preliminares' | 'geral'
  final String label;               // ex.: 'SERVIÇOS PRELIMINARES' | 'GERAL'
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
  });

  /// Fábrica TOLERANTE: nunca usa `!`, preenche defaults e normaliza listas.
  /// Se `meta` não vier, cai para “GERAL”.
  factory ScheduleData.fromMap(Map<String, dynamic> m, {ScheduleData? meta}) {
    final def = ScheduleData(
      numero: 0,
      faixaIndex: 0,
      key: 'geral',
      label: 'GERAL',
      icon: Icons.clear_all,
      color: Colors.grey, // cor neutra
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

      // meta opcional para ícone/cor/label da UI
      key: meta?.key ?? def.key,
      label: meta?.label ?? def.label,
      icon: meta?.icon ?? def.icon,
      color: meta?.color ?? def.color,
    );
  }

  /// Mapa para persistir (normalmente sem meta de UI)
  Map<String, dynamic> toDbMap({bool includeMeta = false}) {
    final map = <String, dynamic>{
      'numero': numero,
      'faixa_index': faixaIndex,
      'tipo': tipo,
      'status': status,
      'comentario': comentario,
      // Obs.: se você preferir salvar Timestamp, converta no repositório
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'updatedBy': updatedBy,
      'fotos': fotos,
      'fotos_meta': fotosMeta,
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

  // --------- copyWith ---------
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
    );
  }

  // ---------------- parsers ----------------

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
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  static DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) {
      try { return DateTime.parse(v); } catch (_) {}
    }
    return null;
  }
}
