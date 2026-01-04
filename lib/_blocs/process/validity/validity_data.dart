// lib/_blocs/process/contracts/validity/validity_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

class ValidityData {
  String? id;
  String? uidContract;
  DateTime? orderdate;
  int? orderNumber;
  String? ordertype;

  // Legado: último PDF salvo no doc
  String? pdfUrl;

  // 🆕 anexos com rótulo (múltiplos)
  List<Attachment>? attachments;

  String? createdBy;
  DateTime? createdAt;
  String? updatedBy;
  DateTime? updatedAt;
  String? deletedBy;
  DateTime? deletedAt;

  ValidityData({
    this.id,
    this.uidContract,
    this.orderdate,
    this.orderNumber,
    this.ordertype,
    this.pdfUrl,
    this.attachments,
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.deletedBy,
    this.deletedAt,
  });

  static const List<String> typeOfOrder = [
    'ORDEM DE INÍCIO',
    'ORDEM DE PARALISAÇÃO',
    'ORDEM DE REINÍCIO',
    'ORDEM DE FINALIZAÇÃO',
  ];

  static List<Attachment>? _toAttachments(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v
          .map((e) => Attachment.fromMap(
        Map<String, dynamic>.from(e as Map),
      ))
          .toList();
    }
    return null;
  }

  factory ValidityData.fromDocument({required DocumentSnapshot snapshot}) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ValidityData(
      id: snapshot.id,
      orderNumber: (data['ordernumber'] as num?)?.toInt(),
      ordertype: data['ordertype'] as String?,
      orderdate: (data['orderdate'] as Timestamp?)?.toDate(),
      uidContract: data['uidcontract'] as String?,
      pdfUrl: data['pdfUrl'] as String?,
      attachments: _toAttachments(data['attachments']),
      createdBy: data['createdBy'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'] as String?,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ordernumber': orderNumber,
      'ordertype': ordertype,
      'orderdate': orderdate,
      'uidcontract': uidContract,
      'pdfUrl': pdfUrl,
      'attachments': attachments?.map((e) => e.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt,
      'deletedBy': deletedBy,
      'deletedAt': deletedAt,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  ValidityData copyWith({
    String? id,
    String? uidContract,
    DateTime? orderdate,
    int? orderNumber,
    String? ordertype,
    String? pdfUrl,
    List<Attachment>? attachments,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
    String? deletedBy,
    DateTime? deletedAt,
  }) {
    return ValidityData(
      id: id ?? this.id,
      uidContract: uidContract ?? this.uidContract,
      orderdate: orderdate ?? this.orderdate,
      orderNumber: orderNumber ?? this.orderNumber,
      ordertype: ordertype ?? this.ordertype,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      attachments: attachments ?? this.attachments,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
