import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class AdditiveData extends ChangeNotifier {
  ///Informações de medições
  String? uid;
  String? additivenumberprocess;
  int? additiveorder;
  int? additivevaliditycontractdays;
  int? additivevalidityexecutiondays;
  DateTime? additivedata;
  DateTime? additivevaliditycontractdata;
  DateTime? additivevalidityexecutiondata;
  double? additivevalue;


  AdditiveData({
    this.uid,
    this.additivenumberprocess,
    this.additiveorder,
    this.additivevaliditycontractdays,
    this.additivevalidityexecutiondays,
    this.additivedata,
    this.additivevaliditycontractdata,
    this.additivevalidityexecutiondata,
    this.additivevalue,
});

  ///Recuperando informações no banco de dados
  factory AdditiveData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) {
      throw Exception("Contrato não encontrado");
    }

    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception("Os dados do contrato estão vazios");
    }

    return AdditiveData(
      uid: snapshot.id,
      additivenumberprocess: data['additivenumberprocess'],
      additiveorder: (data['additiveorder'] as num).toInt(),
      additivevaliditycontractdays: (data['additivevaliditycontractdays'] as num).toInt(),
      additivevalidityexecutiondays: (data['additivevalidityexecutiondays'] as num).toInt(),

      additivedata: data['additivedata'].toDate() as DateTime,
      additivevaliditycontractdata: data['additivevaliditycontractdata'].toDate() as DateTime,
      additivevalidityexecutiondata: data['additivevalidityexecutiondata'].toDate() as DateTime,


      additivevalue: data['additivevalue'].toDouble() ?? 0.0,


    );

  }

}
