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
  String? typeOfAdditive;

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
    this.typeOfAdditive,

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
      additiveorder: (data['additiveorder'] as num?)?.toInt(),
      additivevaliditycontractdays: (data['additivevaliditycontractdays'] as num?)?.toInt(),
      additivevalidityexecutiondays: (data['additivevalidityexecutiondays'] as num?)?.toInt(),
      additivedata: (data['additivedata'] as Timestamp?)?.toDate(),
      additivevaliditycontractdata: (data['additivevaliditycontractdata'] as Timestamp?)?.toDate(),
      additivevalidityexecutiondata: (data['additivevalidityexecutiondata'] as Timestamp?)?.toDate(),
      additivevalue: (data['additivevalue'] as num?)?.toDouble(),
      typeOfAdditive: data['typeOfAdditive'], // ✅ agora lido corretamente
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'additivenumberprocess': additivenumberprocess,
      'additiveorder': additiveorder,
      'additivevaliditycontractdays': additivevaliditycontractdays,
      'additivevalidityexecutiondays': additivevalidityexecutiondays,
      'additivedata': additivedata,
      'additivevaliditycontractdata': additivevaliditycontractdata,
      'additivevalidityexecutiondata': additivevalidityexecutiondata,
      'additivevalue': additivevalue,
      'typeOfAdditive': typeOfAdditive,
    };
  }

}
