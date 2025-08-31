import 'package:cloud_firestore/cloud_firestore.dart';

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
  String? pdfUrl;
  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;

  ReportMeasurementData({
    this.id,
    this.order,
    this.numberprocess,
    this.date,
    this.value,
    this.contractId,
    this.pdfUrl,
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

  // ---------- Firestore path helpers ----------
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
    final contractId = snap.reference.parent.parent?.id;

    return ReportMeasurementData(
      // novos nomes
      id: data['id'] as String? ?? snap.id,
      order: _toInt(data['order'] ?? data['measurementorder']),
      numberprocess: data['numberprocess'] as String? ?? data['measurementnumberprocess'] as String?,
      date: _toDate(data['date'] ?? data['measurementdata']),
      value: _toDouble(data['value'] ?? data['measurementinitialvalue']),
      pdfUrl: data['pdfUrl'] as String?,
      // meta
      contractId: contractId,
      createdAt: _toDate(data['createdAt']),
      createdBy: data['createdBy'] as String?,
      updatedAt: _toDate(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  factory ReportMeasurementData.fromMap(Map<String, dynamic> json) {
    return ReportMeasurementData(
      id: json['id'] as String?,
      order: _toInt(json['order'] ?? json['measurementorder']),
      numberprocess: json['numberprocess'] as String? ?? json['measurementnumberprocess'] as String?,
      date: _toDate(json['date'] ?? json['measurementdata']),
      value: _toDouble(json['value'] ?? json['measurementinitialvalue']),
      pdfUrl: json['pdfUrl'] as String?,
      contractId: json['contractId'] as String?,
      createdAt: _toDate(json['createdAt']),
      createdBy: json['createdBy'] as String?,
      updatedAt: _toDate(json['updatedAt']),
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'order': order,
      'numberprocess': numberprocess,
      'date': date,       // Firestore aceita DateTime
      'value': value,
      'pdfUrl': pdfUrl,
      // meta (opcional manter)
      'contractId': contractId,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    }..removeWhere((k, v) => v == null);
  }
}
