import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class AdditiveData extends ChangeNotifier {
  String? id;
  String? contractId;
  int? additiveOrder;
  String? additiveNumberProcess;
  DateTime? additiveDate;
  String? typeOfAdditive;
  double? additiveValue;

  int? additiveValidityContractDays;
  int? additiveValidityExecutionDays;

  // Legado: último PDF salvo no doc
  String? pdfUrl;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  String? deletedBy;

  AdditiveData({
    this.id,
    this.contractId,
    this.additiveNumberProcess,
    this.additiveOrder,
    this.additiveValidityExecutionDays,
    this.additiveDate,
    this.additiveValidityContractDays,
    this.additiveValue,
    this.typeOfAdditive,
    this.pdfUrl,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
  });

  factory AdditiveData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) throw Exception("Contrato não encontrado");

    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) throw Exception("Os dados do contrato estão vazios");

    return AdditiveData(
      id: snapshot.id,
      contractId: data['contractId'] ?? '',
      additiveNumberProcess: data['additivenumberprocess'],
      additiveOrder: (data['additiveorder'] as num?)?.toInt(),
      additiveValidityContractDays: (data['additivevaliditycontractdays'] as num?)?.toInt(),
      additiveValidityExecutionDays: (data['additivevalidityexecutiondays'] as num?)?.toInt(),
      additiveDate: (data['additivedata'] as Timestamp?)?.toDate(),
      additiveValue: (data['additivevalue'] as num?)?.toDouble(),
      typeOfAdditive: data['typeOfAdditive'],
      pdfUrl: data['pdfUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'] ?? '',
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'] ?? '',
    );
  }

  factory AdditiveData.fromMap(Map<String, dynamic> map, {String? id}) {
    return AdditiveData(
      id: id ?? map['id'],
      contractId: map['contractId'],
      additiveNumberProcess: map['additivenumberprocess'],
      additiveOrder: (map['additiveorder'] as num?)?.toInt(),
      additiveValidityContractDays: (map['additivevaliditycontractdays'] as num?)?.toInt(),
      additiveValidityExecutionDays: (map['additivevalidityexecutiondays'] as num?)?.toInt(),
      additiveDate: (map['additivedata'] is Timestamp)
          ? (map['additivedata'] as Timestamp).toDate()
          : null,
      additiveValue: (map['additivevalue'] as num?)?.toDouble(),
      typeOfAdditive: map['typeOfAdditive'],
      pdfUrl: map['pdfUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      createdBy: map['createdBy'],
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: map['updatedBy'],
      deletedAt: (map['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: map['deletedBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id ?? '',
      'contractId': contractId ?? '',
      'additivenumberprocess': additiveNumberProcess ?? '',
      'additiveorder': additiveOrder ?? 0,
      'additivevaliditycontractdays': additiveValidityContractDays ?? 0,
      'additivevalidityexecutiondays': additiveValidityExecutionDays ?? 0,
      'additivedata': additiveDate,
      'additivevalue': additiveValue ?? 0,
      'typeOfAdditive': typeOfAdditive ?? '',
      'pdfUrl': pdfUrl,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contractId': contractId,
      'additivenumberprocess': additiveNumberProcess,
      'additiveorder': additiveOrder,
      'additivevaliditycontractdays': additiveValidityContractDays,
      'additivevalidityexecutiondays': additiveValidityExecutionDays,
      'additivedata': additiveDate,
      'additivevalue': additiveValue ?? 0,
      'typeOfAdditive': typeOfAdditive,
      'pdfUrl': pdfUrl,
    };
  }
}
