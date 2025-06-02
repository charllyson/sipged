import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class ApostillesData extends ChangeNotifier {
  ///Informações de medições
  String? uid;
  String? apostillenumberprocess;
  int? apostilleorder;
  DateTime? apostilledata;
  double? apostillevalue;

  ApostillesData({
    this.uid,
    this.apostillenumberprocess,
    this.apostilleorder,
    this.apostilledata,
    this.apostillevalue,
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
      uid: snapshot.id,
      apostillenumberprocess: data['apostillenumberprocess'],
      apostilleorder: (data['apostilleorder'] as num).toInt(),
      apostilledata: data['apostilledata'].toDate() as DateTime,
      apostillevalue: data['apostillevalue'].toDouble() ?? 0.0,


    );

  }

}
