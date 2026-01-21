import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

/// =======================================
/// Documento de Medição (REPORT)
/// =======================================
class ReportMeasurementData {
  static const String collectionName = 'reportsMeasurement';

  // dados principais
  String? id;
  int? order;
  String? numberprocess;
  DateTime? date;
  double? value;

  // meta
  String? contractId;
  String? pdfUrl; // legado (único PDF)
  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;

  // anexos com rótulo (novo)
  List<Attachment>? attachments;

  ReportMeasurementData({
    this.id,
    this.order,
    this.numberprocess,
    this.date,
    this.value,
    this.contractId,
    this.pdfUrl,
    this.attachments,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  // ---------- helpers (parsers) ----------
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static List<Attachment>? _toAttachments(dynamic v, {String? fallbackPdfUrl}) {
    if (v == null) {
      if (fallbackPdfUrl != null && fallbackPdfUrl.isNotEmpty) {
        return [
          Attachment(
            id: 'pdf',
            label: 'PDF da medição',
            url: fallbackPdfUrl,
            path: '',
            ext: '.pdf',
          )
        ];
      }
      return null;
    }
    if (v is List) {
      return v.map<Attachment>((e) {
        if (e is Attachment) return e;
        return Attachment.fromMap(Map<String, dynamic>.from(e as Map));
      }).toList();
    }
    return null;
  }

  // ---------- leitura segura do snapshot ----------
  static Map<String, dynamic> _readSnapData(DocumentSnapshot snap) {
    if (snap is DocumentSnapshot<Map<String, dynamic>>) {
      return snap.data() ?? <String, dynamic>{};
    }
    final raw = snap.data();
    return (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
  }

  // ---------- from/to ----------
  factory ReportMeasurementData.fromDocument(DocumentSnapshot snap) {
    final data = _readSnapData(snap);
    final _contractId = snap.reference.parent.parent?.id;
    final _pdfUrl = data['pdfUrl'] as String?;

    return ReportMeasurementData(
      id: (data['id'] as String?) ?? snap.id,
      order: _toInt(data['order'] ?? data['measurementorder']),
      numberprocess: data['numberprocess'] as String? ??
          data['measurementnumberprocess'] as String?,
      date: _toDate(data['date'] ?? data['measurementdata']),
      value: _toDouble(data['value'] ?? data['measurementinitialvalue']),
      pdfUrl: _pdfUrl,
      contractId: _contractId,
      createdAt: _toDate(data['createdAt']),
      createdBy: data['createdBy'] as String?,
      updatedAt: _toDate(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
      attachments: _toAttachments(data['attachments'], fallbackPdfUrl: _pdfUrl),
    );
  }

  factory ReportMeasurementData.fromMap(Map<String, dynamic> json) {
    final _pdfUrl = json['pdfUrl'] as String?;
    return ReportMeasurementData(
      id: json['id'] as String?,
      order: _toInt(json['order'] ?? json['measurementorder']),
      numberprocess: json['numberprocess'] as String? ??
          json['measurementnumberprocess'] as String?,
      date: _toDate(json['date'] ?? json['measurementdata']),
      value: _toDouble(json['value'] ?? json['measurementinitialvalue']),
      pdfUrl: _pdfUrl,
      contractId: json['contractId'] as String?,
      createdAt: _toDate(json['createdAt']),
      createdBy: json['createdBy'] as String?,
      updatedAt: _toDate(json['updatedAt']),
      updatedBy: json['updatedBy'] as String?,
      attachments: _toAttachments(json['attachments'], fallbackPdfUrl: _pdfUrl),
    );
  }

  Map<String, dynamic> toFirestore() {
    // Firestore SDK converte DateTime para Timestamp.
    return {
      'id': id,
      'order': order,
      'numberprocess': numberprocess,
      'date': date,
      'value': value,
      'pdfUrl': pdfUrl,
      'contractId': contractId,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
      'attachments': attachments?.map((e) => e.toMap()).toList(),
    }..removeWhere((k, v) => v == null);
  }

  // ---------- copyWith ----------
  ReportMeasurementData copyWith({
    String? id,
    int? order,
    String? numberprocess,
    DateTime? date,
    double? value,
    String? contractId,
    String? pdfUrl,
    List<Attachment>? attachments,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return ReportMeasurementData(
      id: id ?? this.id,
      order: order ?? this.order,
      numberprocess: numberprocess ?? this.numberprocess,
      date: date ?? this.date,
      value: value ?? this.value,
      contractId: contractId ?? this.contractId,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
