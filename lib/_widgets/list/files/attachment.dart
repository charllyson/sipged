// lib/_widgets/list/files/attachment.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// ===============================
/// Modelo leve de anexo com rótulo
/// ===============================
class Attachment {
  /// ID do documento no Firestore (quando disponível)
  String id;

  /// Rótulo amigável para exibição
  String label;

  /// URL pública (downloadURL)
  String url;

  /// Caminho no Firebase Storage
  String path;

  /// Extensão do arquivo (ex.: pdf, png)
  String ext;

  /// Tamanho em bytes
  int? size;

  /// Content-Type/MIME (ex.: application/pdf)
  String? contentType;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;

  Attachment({
    this.id = '',
    this.label = 'Arquivo',
    this.url = '',
    this.path = '',
    this.ext = '',
    this.size,
    this.contentType,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  // ---------- copyWith ----------
  Attachment copyWith({
    String? id,
    String? label,
    String? url,
    String? path,
    String? ext,
    int? size,
    String? contentType,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return Attachment(
      id: id ?? this.id,
      label: label ?? this.label,
      url: url ?? this.url,
      path: path ?? this.path,
      ext: ext ?? this.ext,
      size: size ?? this.size,
      contentType: contentType ?? this.contentType,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  // ---------- Helpers ----------
  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  // ---------- Serialização ----------
  factory Attachment.fromMap(Map<String, dynamic> map, {String id = ''}) {
    return Attachment(
      id: id,
      label: (map['label'] as String?) ?? (map['name'] as String?) ?? 'Arquivo',
      url: (map['url'] as String?) ?? '',
      path: (map['path'] as String?) ?? '',
      ext: (map['ext'] as String?) ?? '',
      size: _toInt(map['size']),
      contentType: map['contentType'] as String?,
      createdAt: _toDate(map['createdAt']),
      createdBy: map['createdBy'] as String?,
      updatedAt: _toDate(map['updatedAt']),
      updatedBy: map['updatedBy'] as String?,
    );
  }

  factory Attachment.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data() ?? <String, dynamic>{};
    return Attachment.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() => {
    'label': label,
    'url': url,
    'path': path,
    'ext': ext,
    'size': size,
    'contentType': contentType,
    'createdAt': createdAt,
    'createdBy': createdBy,
    'updatedAt': updatedAt,
    'updatedBy': updatedBy,
  }..removeWhere((k, v) => v == null);

  @override
  String toString() =>
      'Attachment(id: $id, label: $label, url: $url, ext: $ext, size: $size, contentType: $contentType)';
}
