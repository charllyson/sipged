import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class ApostillesData extends ChangeNotifier {
  ///Informações de medições
  String? id;
  String? contractId;
  String? apostilleNumberProcess;
  int? apostilleOrder;
  DateTime? apostilleData;
  double? apostilleValue;

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
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
});

  ///Recuperando informações no banco de dados
  factory ApostillesData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) {
      throw Exception("Apostilamentos não encontrado");
    }

    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception("Os dados dos apostilamentos estão vazios");
    }

    return ApostillesData(
      id: snapshot.id,
      contractId: data['contractId'] ?? '',
      apostilleNumberProcess: data['apostillenumberprocess'],
      apostilleOrder: (data['apostilleorder'] as num).toInt(),
      apostilleData: data['apostilledata'].toDate() as DateTime,
      apostilleValue: data['apostillevalue'].toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'] ?? '',
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'] ?? '',
    );
  }

  factory ApostillesData.fromMap(Map<String, dynamic> map, {String? id}) {
    return ApostillesData(
      id: id ?? map['id'],
      contractId: map['contractId'],
      apostilleNumberProcess: map['apostillenumberprocess'],
      apostilleOrder: (map['apostilleorder'] as num?)?.toInt(),
      apostilleData: (map['apostilledata'] is Timestamp)
          ? (map['apostilledata'] as Timestamp).toDate()
          : (map['apostilledata'] is String)
          ? DateTime.tryParse(map['apostilledata'])
          : null,
      apostilleValue: (map['apostillevalue'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      createdBy: map['createdBy'],
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      updatedBy: map['updatedBy'],
      deletedAt: (map['deletedAt'] is Timestamp)
          ? (map['deletedAt'] as Timestamp).toDate()
          : null,
      deletedBy: map['deletedBy'],
    );
  }



  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contractId': contractId,
      'apostillenumberprocess': apostilleNumberProcess,
      'apostilleorder': apostilleOrder,
      'apostilledata': apostilleData,
      'apostillevalue': apostilleValue,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contractId': contractId,
      'apostillenumberprocess': apostilleNumberProcess,
      'apostilleorder': apostilleOrder,
      'apostilledata': apostilleData,
      'apostillevalue': apostilleValue,
    };
  }

}
