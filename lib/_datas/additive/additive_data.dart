import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class AdditiveData extends ChangeNotifier {
  ///Informações de medições
  String? id;
  int? additiveOrder;
  String? additiveNumberProcess;
  DateTime? additiveData;
  String? typeOfAdditive;
  double? additiveValue;

  DateTime? additiveValidityContractData;
  DateTime? additiveValidityExecutionData;

  int? additionalAdditiveContractDays;
  int? additionalAdditiveExecutionDays;


  AdditiveData({
    this.id,
    this.additiveNumberProcess,
    this.additiveOrder,
    this.additionalAdditiveExecutionDays,
    this.additiveData,
    this.additiveValidityContractData,
    this.additiveValidityExecutionData,
    this.additionalAdditiveContractDays,
    this.additiveValue,
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
      id: snapshot.id,
      additiveNumberProcess: data['additivenumberprocess'],
      additiveOrder: (data['additiveorder'] as num?)?.toInt(),
      additionalAdditiveContractDays: (data['additivevaliditycontractdays'] as num?)?.toInt(),
      additionalAdditiveExecutionDays: (data['additivevalidityexecutiondays'] as num?)?.toInt(),
      additiveData: (data['additivedata'] as Timestamp?)?.toDate(),
      additiveValidityContractData: (data['additivevaliditycontractdata'] as Timestamp?)?.toDate(),
      additiveValidityExecutionData: (data['additivevalidityexecutiondata'] as Timestamp?)?.toDate(),
      additiveValue: (data['additivevalue'] as num?)?.toDouble(),
      typeOfAdditive: data['typeOfAdditive'], // ✅ agora lido corretamente
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'additivenumberprocess': additiveNumberProcess,
      'additiveorder': additiveOrder,
      'additivevaliditycontractdays': additionalAdditiveContractDays,
      'additivevalidityexecutiondays': additionalAdditiveExecutionDays,
      'additivedata': additiveData,
      'additivevaliditycontractdata': additiveValidityContractData,
      'additivevalidityexecutiondata': additiveValidityExecutionData,
      'additivevalue': additiveValue,
      'typeOfAdditive': typeOfAdditive,
    };
  }

}
