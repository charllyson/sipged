// ==============================
// lib/_blocs/process/contracts/validity/validity_data.dart
// ==============================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:siged/_widgets/list/files/attachment.dart';

class ValidityData extends ChangeNotifier {
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

  static List<String> typeOfOrder = const [
    'ORDEM DE INÍCIO',
    'ORDEM DE PARALISAÇÃO',
    'ORDEM DE REINÍCIO',
    'ORDEM DE FINALIZAÇÃO',
  ];

  static List<Attachment>? _toAttachments(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v
          .map((e) => Attachment.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return null;
  }

  factory ValidityData.fromDocument({required DocumentSnapshot snapshot}) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ValidityData(
      id: snapshot.id,
      orderNumber: (data['ordernumber'] as num?)?.toInt(),
      ordertype: data['ordertype'],
      orderdate: (data['orderdate'] as Timestamp?)?.toDate(),
      uidContract: data['uidcontract'],
      pdfUrl: data['pdfUrl'] as String?,
      attachments: _toAttachments(data['attachments']),
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'],
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
    };
  }

  Map<String, dynamic> toMap() => toJson();
}
