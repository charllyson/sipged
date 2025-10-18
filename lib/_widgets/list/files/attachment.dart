
import 'package:cloud_firestore/cloud_firestore.dart';

/// ===============================
/// Modelo leve de anexo com rótulo
/// ===============================
class Attachment {
  String id;
  String label;
  String url;
  String path;
  String ext;
  int? size;
  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;

  Attachment({
    required this.id,
    required this.label,
    required this.url,
    required this.path,
    required this.ext,
    this.size,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

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

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: (map['id'] as String?) ?? '',
      label: (map['label'] as String?) ?? 'Arquivo',
      url: (map['url'] as String?) ?? '',
      path: (map['path'] as String?) ?? '',
      ext: (map['ext'] as String?) ?? '',
      size: _toInt(map['size']),
      createdAt: _toDate(map['createdAt']),
      createdBy: map['createdBy'] as String?,
      updatedAt: _toDate(map['updatedAt']),
      updatedBy: map['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'url': url,
    'path': path,
    'ext': ext,
    'size': size,
    'createdAt': createdAt,
    'createdBy': createdBy,
    'updatedAt': updatedAt,
    'updatedBy': updatedBy,
  }..removeWhere((k, v) => v == null);
}
