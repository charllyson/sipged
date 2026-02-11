import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

class AdjustmentMeasurementData {
  static const String collectionName = 'adjustmentsMeasurement';

  String? id;
  int? order;
  String? numberprocess;
  DateTime? date;
  double? value;

  // meta
  String? contractId;
  String? pdfUrl; // legado
  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;

  // anexos
  List<Attachment>? attachments;

  AdjustmentMeasurementData({
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
    this.attachments,
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

  static List<Attachment>? _toAttachments(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v.map((e) => Attachment.fromMap(Map<String, dynamic>.from(e))).toList();
    }
    return null;
  }

  // path helpers
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

  // from/to
  factory AdjustmentMeasurementData.fromDocument(DocumentSnapshot snap) {
    final data = (snap.data() as Map<String, dynamic>?) ?? {};
    final contractId = snap.reference.parent.parent?.id;

    return AdjustmentMeasurementData(
      id: (data['id'] as String?) ?? snap.id,
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
      attachments: _toAttachments(data['attachments']),
    );
  }

  factory AdjustmentMeasurementData.fromMap(Map<String, dynamic> json) {
    return AdjustmentMeasurementData(
      id: json['id'] as String?,
      order: _toInt(json['order']),
      numberprocess: json['numberprocess'] as String?,
      date: _toDate(json['date']),
      value: _toDouble(json['value']),
      pdfUrl: json['pdfUrl'] as String?,
      contractId: json['contractId'] as String?,
      createdAt: _toDate(json['createdAt']),
      createdBy: json['createdBy'] as String?,
      updatedAt: _toDate(json['updatedAt']),
      updatedBy: json['updatedBy'] as String?,
      attachments: _toAttachments(json['attachments']),
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
      'attachments': attachments?.map((e) => e.toMap()).toList(),
    }..removeWhere((k, v) => v == null);
  }

  // copyWith
  AdjustmentMeasurementData copyWith({
    String? id,
    int? order,
    String? numberprocess,
    DateTime? date,
    double? value,
    String? contractId,
    String? pdfUrl,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    List<Attachment>? attachments,
  }) {
    return AdjustmentMeasurementData(
      id: id ?? this.id,
      order: order ?? this.order,
      numberprocess: numberprocess ?? this.numberprocess,
      date: date ?? this.date,
      value: value ?? this.value,
      contractId: contractId ?? this.contractId,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      attachments: attachments ?? this.attachments,
    );
  }
}
