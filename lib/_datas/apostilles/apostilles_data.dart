import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class ApostillesData extends ChangeNotifier {
  ///Informações de medições
  String? id;
  String? apostilleNumberProcess;
  int? apostilleOrder;
  DateTime? apostilleData;
  double? apostilleValue;

  ApostillesData({
    this.id,
    this.apostilleNumberProcess,
    this.apostilleOrder,
    this.apostilleData,
    this.apostilleValue,
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
      apostilleNumberProcess: data['apostillenumberprocess'],
      apostilleOrder: (data['apostilleorder'] as num).toInt(),
      apostilleData: data['apostilledata'].toDate() as DateTime,
      apostilleValue: data['apostillevalue'].toDouble() ?? 0.0,


    );

  }

}
