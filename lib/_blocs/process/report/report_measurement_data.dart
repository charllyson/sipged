import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

/// =======================================
/// Documento de Medição
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

  // detalhamento
  Map<String, dynamic>? breakdown;

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
    this.breakdown,
    this.attachments,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  // ---------- helpers ----------
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
            ext: '.pdf', // padronize 'pdf' se preferir sem ponto
          )
        ];
      }
      return null;
    }
    if (v is List) {
      return v.map((e) => Attachment.fromMap(Map<String, dynamic>.from(e))).toList();
    }
    return null;
  }

  // ---------- path helpers ----------
  static CollectionReference<Map<String, dynamic>> col(
      FirebaseFirestore db,
      String contractId,
      ) {
    return db.collection('contracts').doc(contractId).collection(collectionName);
  }

  static DocumentReference<Map<String, dynamic>> docRef(
      FirebaseFirestore db, {
        required String contractId,
        required String id,
      }) {
    return col(db, contractId).doc(id);
  }

  // ---------- from/to ----------
  factory ReportMeasurementData.fromDocument(DocumentSnapshot snap) {
    final data = (snap.data() as Map<String, dynamic>?) ?? {};
    final _contractId = snap.reference.parent.parent?.id;
    final _pdfUrl = data['pdfUrl'] as String?;
    return ReportMeasurementData(
      id: (data['id'] as String?) ?? snap.id,
      order: _toInt(data['order'] ?? data['measurementorder']),
      numberprocess: data['numberprocess'] as String? ?? data['measurementnumberprocess'] as String?,
      date: _toDate(data['date'] ?? data['measurementdata']),
      value: _toDouble(data['value'] ?? data['measurementinitialvalue']),
      pdfUrl: _pdfUrl,
      contractId: _contractId,
      createdAt: _toDate(data['createdAt']),
      createdBy: data['createdBy'] as String?,
      updatedAt: _toDate(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
      breakdown: (data['breakdown'] is Map) ? Map<String, dynamic>.from(data['breakdown']) : null,
      attachments: _toAttachments(data['attachments'], fallbackPdfUrl: _pdfUrl),
    );
  }

  factory ReportMeasurementData.fromMap(Map<String, dynamic> json) {
    final _pdfUrl = json['pdfUrl'] as String?;
    return ReportMeasurementData(
      id: json['id'] as String?,
      order: _toInt(json['order'] ?? json['measurementorder']),
      numberprocess: json['numberprocess'] as String? ?? json['measurementnumberprocess'] as String?,
      date: _toDate(json['date'] ?? json['measurementdata']),
      value: _toDouble(json['value'] ?? json['measurementinitialvalue']),
      pdfUrl: _pdfUrl,
      contractId: json['contractId'] as String?,
      createdAt: _toDate(json['createdAt']),
      createdBy: json['createdBy'] as String?,
      updatedAt: _toDate(json['updatedAt']),
      updatedBy: json['updatedBy'] as String?,
      breakdown: (json['breakdown'] is Map) ? Map<String, dynamic>.from(json['breakdown']) : null,
      attachments: _toAttachments(json['attachments'], fallbackPdfUrl: _pdfUrl),
    );
  }

  Map<String, dynamic> toFirestore() {
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
      'breakdown': breakdown,
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
    Map<String, dynamic>? breakdown,
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
      breakdown: breakdown ?? this.breakdown,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
