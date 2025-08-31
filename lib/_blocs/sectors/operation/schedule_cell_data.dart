import 'package:flutter/material.dart';

class ScheduleCell {
  // Identidade da célula
  final int numero;           // estaca
  final int faixaIndex;       // faixa

  // Estado + conteúdo
  final String status;        // 'concluido' | 'em andamento' | 'a iniciar'
  final String? comentario;

  // Mídia (fotos já no Storage)
  final List<SchedulePhoto> fotos;

  // Auditoria mínima
  final DateTime createdAt;
  final String createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  // Metadados de serviço (UI)
  final String key;           // ex.: 'servicos-preliminares' | 'geral'
  final String label;
  final IconData icon;
  final Color color;

  // Histórico enxuto (opcional)
  final List<StatusChange> historico;

  const ScheduleCell({
    required this.numero,
    required this.faixaIndex,
    required this.status,
    this.comentario,
    required this.fotos,
    required this.createdAt,
    required this.createdBy,
    this.updatedAt,
    this.updatedBy,
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    this.historico = const [],
  });

  // ---------- factory segura ----------
  factory ScheduleCell.fromMap(Map<String, dynamic> m) {
    // defaults
    final statusDefault = (m['status']?.toString().trim().isNotEmpty ?? false)
        ? m['status'].toString()
        : 'a iniciar';

    return ScheduleCell(
      numero: _asInt(m['numero']) ?? 0,
      faixaIndex: _asInt(m['faixa_index']) ?? 0,
      status: statusDefault,
      comentario: _asString(m['comentario']),
      fotos: _asList(m['fotos']).map((e) => SchedulePhoto.fromMap(e)).toList(),
      createdAt: _asDateTime(m['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      createdBy: _asString(m['createdBy']) ?? '',
      updatedAt: _asDateTime(m['updatedAt']),
      updatedBy: _asString(m['updatedBy']),
      key: _asString(m['key']) ?? 'geral',
      label: _asString(m['label']) ?? 'GERAL',
      icon: IconData(_asInt(m['icon']) ?? Icons.clear_all.codePoint, fontFamily: 'MaterialIcons'),
      color: Color(_asInt(m['color']) ?? Colors.grey.value),
      historico: _asList(m['historico']).map((e) => StatusChange.fromMap(e)).toList(),
    );
  }

  Map<String, dynamic> toMap({bool includeUiMeta = true}) {
    final map = <String, dynamic>{
      'numero': numero,
      'faixa_index': faixaIndex,
      'status': status,
      'comentario': comentario,
      'fotos': fotos.map((f) => f.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'updatedBy': updatedBy,
      'historico': historico.map((h) => h.toMap()).toList(),
    };
    if (includeUiMeta) {
      map.addAll({
        'key': key,
        'label': label,
        'icon': icon.codePoint,
        'color': color.value,
      });
    }
    return map;
  }

  ScheduleCell copyWith({
    int? numero,
    int? faixaIndex,
    String? status,
    String? comentario,
    List<SchedulePhoto>? fotos,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    String? key,
    String? label,
    IconData? icon,
    Color? color,
    List<StatusChange>? historico,
  }) {
    return ScheduleCell(
      numero: numero ?? this.numero,
      faixaIndex: faixaIndex ?? this.faixaIndex,
      status: status ?? this.status,
      comentario: comentario ?? this.comentario,
      fotos: fotos ?? this.fotos,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      key: key ?? this.key,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      historico: historico ?? this.historico,
    );
  }

  // ------------- helpers -------------
  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v);
    return null;
  }
  static String? _asString(dynamic v) => v?.toString();
  static List _asList(dynamic v) => (v is List) ? v : const [];

  static DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) { try { return DateTime.parse(v); } catch (_) {} }
    return null;
  }
}

class SchedulePhoto {
  final String url;              // Storage URL
  final String? name;            // nome amigável
  final int? size;               // bytes
  final DateTime? takenAt;       // EXIF OU fallback do modal
  final double? lat;
  final double? lng;
  final Map<String, dynamic> exif; // EXIF completo opcional
  final DateTime uploadedAt;
  final String uploadedBy;

  const SchedulePhoto({
    required this.url,
    this.name,
    this.size,
    this.takenAt,
    this.lat,
    this.lng,
    this.exif = const {},
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory SchedulePhoto.fromMap(Map<String, dynamic> m) => SchedulePhoto(
    url: m['url']?.toString() ?? '',
    name: m['name']?.toString(),
    size: m['size'] is int ? m['size'] as int : null,
    takenAt: ScheduleCell._asDateTime(m['takenAt']),
    lat: (m['lat'] is num) ? (m['lat'] as num).toDouble() : null,
    lng: (m['lng'] is num) ? (m['lng'] as num).toDouble() : null,
    exif: (m['exif'] is Map) ? Map<String, dynamic>.from(m['exif']) : const {},
    uploadedAt: ScheduleCell._asDateTime(m['uploadedAt']) ?? DateTime.now(),
    uploadedBy: m['uploadedBy']?.toString() ?? '',
  );

  Map<String, dynamic> toMap() => {
    'url': url,
    'name': name,
    'size': size,
    'takenAt': takenAt?.millisecondsSinceEpoch,
    'lat': lat,
    'lng': lng,
    'exif': exif,
    'uploadedAt': uploadedAt.millisecondsSinceEpoch,
    'uploadedBy': uploadedBy,
  };
}

class StatusChange {
  final String from;
  final String to;
  final String userId;
  final DateTime at;
  const StatusChange({required this.from, required this.to, required this.userId, required this.at});

  factory StatusChange.fromMap(Map<String, dynamic> m) => StatusChange(
    from: m['from']?.toString() ?? '',
    to: m['to']?.toString() ?? '',
    userId: m['userId']?.toString() ?? '',
    at: ScheduleCell._asDateTime(m['at']) ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'from': from,
    'to': to,
    'userId': userId,
    'at': at.millisecondsSinceEpoch,
  };
}
