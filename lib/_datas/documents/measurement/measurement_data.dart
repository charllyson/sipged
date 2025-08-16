import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class ReportData extends ChangeNotifier {
  ///Informações de medições
  String? contractId;

  String? idReportMeasurement;
  int? orderReportMeasurement;
  String? numberProcessReportMeasurement;
  DateTime? dateReportMeasurement;
  double? valueReportMeasurement;

  ///Informações de reajustes de medições
  String? idAdjustmentMeasurement;
  int? orderAdjustmentMeasurement;
  String? numberAdjustmentProcessMeasurement;
  DateTime? dateAdjustmentMeasurement;
  double? valueAdjustmentMeasurement;

  ///Informações de revisões de medições
  String? idRevisionMeasurement;
  int? orderRevisionMeasurement;
  String? numberRevisionProcessMeasurement;
  DateTime? dateRevisionMeasurement;
  double? valueRevisionMeasurement;


  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  String? deletedBy;


  ReportData({
    this.contractId,

    this.idReportMeasurement,
    this.orderReportMeasurement,
    this.numberProcessReportMeasurement,
    this.dateReportMeasurement,
    this.valueReportMeasurement,

    this.idAdjustmentMeasurement,
    this.orderAdjustmentMeasurement,
    this.numberAdjustmentProcessMeasurement,
    this.dateAdjustmentMeasurement,
    this.valueAdjustmentMeasurement,

    this.idRevisionMeasurement,
    this.orderRevisionMeasurement,
    this.numberRevisionProcessMeasurement,
    this.dateRevisionMeasurement,
    this.valueRevisionMeasurement,

    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
});

  ///Recuperando informações no banco de dados
  factory ReportData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) {
      throw Exception("Medição não encontrada");
    }

    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception("Os dados da medição estão vazios");
    }

    final contractId = snapshot.reference.parent.parent?.id; // 👈 Captura o ID do contrato pai

    return ReportData(
      contractId: contractId,

      idReportMeasurement: snapshot.id,
      orderReportMeasurement: (data['measurementorder'] as num?)?.toInt(),
      numberProcessReportMeasurement: data['measurementnumberprocess'],
      dateReportMeasurement: (data['measurementdata'] as Timestamp?)?.toDate(),
      valueReportMeasurement: (data['measurementinitialvalue'] as num?)?.toDouble() ?? 0.0,

      idAdjustmentMeasurement: data['measurementadjustment'],
      orderAdjustmentMeasurement: data['measurementadjustmentorder'],
      numberAdjustmentProcessMeasurement: data['measurementadjustmentnumberprocess'],
      dateAdjustmentMeasurement: (data['measurementadjustmentdate'] as Timestamp?)?.toDate(),
      valueAdjustmentMeasurement: (data['measurementadjustmentvalue'] as num?)?.toDouble() ?? 0.0,

      idRevisionMeasurement: data['measurementrevision'],
      orderRevisionMeasurement: data['measurementrevisionorder'],
      numberRevisionProcessMeasurement: data['measurementrevisionnumberprocess'],
      dateRevisionMeasurement: (data['measurementrevisiondate'] as Timestamp?)?.toDate(),
      valueRevisionMeasurement: (data['measurementvaluerevisionsadjustments'] as num?)?.toDouble() ?? 0.0,

      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: data['updatedBy'] ?? '',
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'] ?? '',
    );
  }


  Map<String, dynamic> toJson() {

    return {
      'reports': idReportMeasurement,
      'measurementorder': orderReportMeasurement,
      'measurementnumberprocess': numberProcessReportMeasurement,
      'measurementdata': dateReportMeasurement,
      'measurementinitialvalue': valueReportMeasurement,

      'measurementadjustment': idAdjustmentMeasurement,
      'measurementadjustmentorder': orderAdjustmentMeasurement,
      'measurementadjustmentnumberprocess': numberAdjustmentProcessMeasurement,
      'measurementadjustmentdate': dateAdjustmentMeasurement,
      'measurementadjustmentvalue': valueAdjustmentMeasurement,

      'measurementrevision': idRevisionMeasurement,
      'measurementrevisionorder': orderRevisionMeasurement,
      'measurementrevisionnumberprocess': numberRevisionProcessMeasurement,
      'measurementrevisiondate': dateRevisionMeasurement,
      'measurementvaluerevisionsadjustments': valueRevisionMeasurement,

    };
  }

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      orderReportMeasurement: json['measurementorder'] is int
          ? json['measurementorder']
          : int.tryParse(json['measurementorder']?.toString() ?? ''),
      dateReportMeasurement: (json['measurementdata'] as Timestamp?)?.toDate(),
      numberProcessReportMeasurement: json['measurementnumberprocess'],
      valueReportMeasurement: json['measurementinitialvalue'] is double
          ? json['measurementinitialvalue']
          : double.tryParse(json['measurementinitialvalue']?.toString() ?? ''),

      dateAdjustmentMeasurement: (json['measurementadjustmentdate'] as Timestamp?)?.toDate(),
      numberAdjustmentProcessMeasurement: json['measurementadjustmentnumberprocess'],
      valueAdjustmentMeasurement: json['measurementadjustmentvalue'],

      dateRevisionMeasurement: (json['measurementrevisiondate'] as Timestamp?)?.toDate(),
      numberRevisionProcessMeasurement: json['measurementrevisionnumberprocess'],
      valueRevisionMeasurement: json['measurementvaluerevisionsadjustments'],

      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      createdBy: json['createdBy'] ?? '',
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: json['updatedBy'] ?? '',
      deletedAt: (json['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: json['deletedBy'] ?? '',
    );
  }

}
