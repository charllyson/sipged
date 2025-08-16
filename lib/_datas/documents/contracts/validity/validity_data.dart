import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class ValidityData extends ChangeNotifier {
  String? id;
  String? uidContract;
  DateTime? orderdate;
  int? orderNumber;
  String? ordertype;
  String? pdfUrl;
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
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
    this.deletedBy,
  });

  static List<String> typeOfOrder = [
    'ORDEM DE INÍCIO',
    'ORDEM DE PARALISAÇÃO',
    'ORDEM DE REINÍCIO',
    'ORDEM DE FINALIZAÇÃO',
  ];

  factory ValidityData.fromDocument({required DocumentSnapshot snapshot}) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ValidityData(
      id: snapshot.id,
      orderNumber: (data['ordernumber'] as num?)?.toInt(),
      ordertype: data['ordertype'],
      orderdate: (data['orderdate'] as Timestamp?)?.toDate(),
      uidContract: data['uidcontract'],
      pdfUrl: data['pdfUrl'],
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ordernumber': orderNumber,
      'ordertype': ordertype,
      'orderdate': orderdate,
      'uidcontract': uidContract,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ordernumber': orderNumber,
      'ordertype': ordertype,
      'orderdate': orderdate,
      'uidcontract': uidContract,
    };
  }
}
