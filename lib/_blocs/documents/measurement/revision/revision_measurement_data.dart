import 'package:cloud_firestore/cloud_firestore.dart';

class RevisionMeasurementData {
  static const String collectionName = 'revisionsMeasurement';

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

  RevisionMeasurementData({
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

  factory RevisionMeasurementData.fromDocument(DocumentSnapshot snap) {
    final data = (snap.data() as Map<String, dynamic>?) ?? {};
    final contractId = snap.reference.parent.parent?.id;

    return RevisionMeasurementData(
      id: data['id'] as String? ?? snap.id,
      order: _toInt(data['order']),
      numberprocess: data['numberprocess'] as String?,
      date: _toDate(data['date']),
      value: _toDouble(data['value']),
      pdfUrl: data['pdfUrl'] as String?,
      contractId: contractId,
      createdAt: _toDate(data['createdAt']),
      createdBy: data['createdBy'] as String?,
      updatedAt: _toDate(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  factory RevisionMeasurementData.fromMap(Map<String, dynamic> json) {
    return RevisionMeasurementData(
      id: json['id'] as String?,
      order: _toInt(json['order']),
      numberprocess: json['numberprocess'],
      date: _toDate(json['date']),
      value: _toDouble(json['value']),
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
      'date': date,
      'value': value,
      'pdfUrl': pdfUrl,
      'contractId': contractId,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    }..removeWhere((k, v) => v == null);
  }
}
