import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class MeasurementData extends ChangeNotifier {
  ///Informações de medições
  String? id;
  DateTime? measurementadjustmentdate;
  String? measurementadjustmentnumberprocess;
  double? measurementadjustmentvalue;
  double? measurementconsolidatedvalue;
  DateTime? measurementdata;
  double? measurementinitialvalue;
  String? measurementnumberprocess;
  int? measurementorder;
  DateTime? measurementrevisiondate;
  String? measurementrevisionnumberprocess;
  double? measurementvalueprediction;
  double? measurementvaluerevisionsadjustments;



  MeasurementData({
    this.id,
    this.measurementadjustmentdate,
    this.measurementadjustmentnumberprocess,
    this.measurementadjustmentvalue,
    this.measurementconsolidatedvalue,
    this.measurementdata,
    this.measurementinitialvalue,
    this.measurementnumberprocess,
    this.measurementorder,
    this.measurementrevisiondate,
    this.measurementrevisionnumberprocess,
    this.measurementvalueprediction,
    this.measurementvaluerevisionsadjustments,
});

  ///Recuperando informações no banco de dados
  factory MeasurementData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) {
      throw Exception("Contrato não encontrado");
    }

    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception("Os dados do contrato estão vazios");
    }

    return MeasurementData(
      id: snapshot.id,
      measurementadjustmentdate: data['measurementadjustmentdate'].toDate() as DateTime,
      measurementadjustmentnumberprocess: data['measurementadjustmentnumberprocess'],
      measurementadjustmentvalue: data['measurementadjustmentvalue'].toDouble() ?? 0.0,
      measurementconsolidatedvalue: data['measurementconsolidatedvalue'].toDouble() ?? 0.0,
      measurementdata: data['measurementdata'].toDate() as DateTime,
      measurementinitialvalue: data['measurementinitialvalue'].toDouble() ?? 0.0,
      measurementnumberprocess: data['measurementnumberprocess'],
      measurementorder: (data['measurementorder'] as num).toInt(),
      measurementrevisiondate: data['measurementrevisiondate'].toDate() as DateTime,
      measurementrevisionnumberprocess: data['measurementrevisionnumberprocess'],
      measurementvalueprediction: data['measurementvalueprediction'].toDouble() ?? 0.0,
      measurementvaluerevisionsadjustments: data['measurementvaluerevisionsadjustments'].toDouble() ?? 0.0,

    );

  }

  Map<String, dynamic> toJson() {
    return {
      'measurementadjustmentdate': measurementadjustmentdate,
      'measurementadjustmentnumberprocess': measurementadjustmentnumberprocess,
      'measurementadjustmentvalue': measurementadjustmentvalue,
      'measurementconsolidatedvalue': measurementconsolidatedvalue,
      'measurementdata': measurementdata,
      'measurementinitialvalue': measurementinitialvalue,
      'measurementnumberprocess': measurementnumberprocess,
      'measurementorder': measurementorder,
      'measurementrevisiondate': measurementrevisiondate,
      'measurementrevisionnumberprocess': measurementrevisionnumberprocess,
      'measurementvalueprediction': measurementvalueprediction,
      'measurementvaluerevisionsadjustments': measurementvaluerevisionsadjustments,
    };
  }


}
