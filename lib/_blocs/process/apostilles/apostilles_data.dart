import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:siged/_widgets/list/files/attachment.dart';

/// 🧩 Modelo de apostilamento (somente dados, sem lógica de UI)
class ApostillesData {
  String? id;
  String? contractId;
  String? apostilleNumberProcess;
  int? apostilleOrder;
  DateTime? apostilleData;
  double? apostilleValue;

  /// Legado: último PDF salvo no doc
  String? pdfUrl;

  /// 🆕 múltiplos anexos com rótulo
  List<Attachment>? attachments;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  String? deletedBy;

  ApostillesData({
    this.id,
    this.contractId,
    this.apostilleNumberProcess,
    this.apostilleOrder,
    this.apostilleData,
    this.apostilleValue,
    this.pdfUrl,
    this.attachments,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
  });

  // =========================
  // Helpers locais
  // =========================

  static DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) {
      final sanitized = v.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(sanitized);
    }
    return null;
  }

  static List<Attachment>? _toAttachments(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v
          .map((e) => Attachment.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return null;
  }

  // =========================
  // FACTORY: Firestore Document
  // =========================
  factory ApostillesData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) throw Exception('Apostilamento não encontrado');

    final Map<String, dynamic> data =
        (snapshot.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    final String? contractIdFromPath = snapshot.reference.parent.parent?.id;

    return ApostillesData(
      id: snapshot.id,
      contractId: (data['contractId'] ?? contractIdFromPath) as String?,
      apostilleNumberProcess:
      data['apostillenumberprocess'] ?? data['apostilleNumberProcess'],
      apostilleOrder: _toInt(data['apostilleorder'] ?? data['apostilleOrder']),
      apostilleData: _toDate(data['apostilledata'] ?? data['apostilleDate']),
      apostilleValue:
      _toDouble(data['apostillevalue'] ?? data['apostilleValue']) ?? 0.0,
      pdfUrl: data['pdfUrl'] as String?,
      attachments: _toAttachments(data['attachments']),
      createdAt: _toDate(data['createdAt']),
      createdBy: data['createdBy'] as String?,
      updatedAt: _toDate(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
      deletedAt: _toDate(data['deletedAt']),
      deletedBy: data['deletedBy'] as String?,
    );
  }

  // =========================
  // FACTORY: Map genérico
  // =========================
  factory ApostillesData.fromMap(Map<String, dynamic> map, {String? id}) {
    return ApostillesData(
      id: id ?? map['id'],
      contractId: map['contractId'],
      apostilleNumberProcess:
      map['apostillenumberprocess'] ?? map['apostilleNumberProcess'],
      apostilleOrder: _toInt(map['apostilleorder'] ?? map['apostilleOrder']),
      apostilleData: _toDate(map['apostilledata'] ?? map['apostilleDate']),
      apostilleValue:
      _toDouble(map['apostillevalue'] ?? map['apostilleValue']) ?? 0.0,
      pdfUrl: map['pdfUrl'] as String?,
      attachments: _toAttachments(map['attachments']),
      createdAt: _toDate(map['createdAt']),
      createdBy: map['createdBy'],
      updatedAt: _toDate(map['updatedAt']),
      updatedBy: map['updatedBy'],
      deletedAt: _toDate(map['deletedAt']),
      deletedBy: map['deletedBy'],
    );
  }

  /// Mapa enxuto para gravar/atualizar no Firestore.
  Map<String, dynamic> toJson() {
    return {
      'id': id ?? '',
      'contractId': contractId ?? '',
      'apostillenumberprocess': apostilleNumberProcess ?? '',
      'apostilleorder': apostilleOrder ?? 0,
      'apostilledata': apostilleData,
      'apostillevalue': apostilleValue ?? 0.0,
      'pdfUrl': pdfUrl,
      'attachments': attachments?.map((e) => e.toMap()).toList(),
    };
  }

  /// Versão completa (caso precise em memória).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contractId': contractId,
      'apostillenumberprocess': apostilleNumberProcess,
      'apostilleorder': apostilleOrder,
      'apostilledata': apostilleData,
      'apostillevalue': apostilleValue ?? 0.0,
      'pdfUrl': pdfUrl,
      'attachments': attachments?.map((e) => e.toMap()).toList(),
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt,
      'deletedBy': deletedBy,
    };
  }
}
