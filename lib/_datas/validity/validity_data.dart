import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class ValidityData extends ChangeNotifier {
  ///Informações da ordem
  String? uid;
  DateTime? orderdate;
  int? ordernumber;
  String? ordertype;

  ValidityData({
    this.uid,
    this.orderdate,
    this.ordernumber,
    this.ordertype,
});

  ///Recuperando informações no banco de dados
  factory ValidityData.fromDocument({required DocumentSnapshot snapshot}) {
    if (!snapshot.exists) {
      throw Exception("Contrato não encontrado");
    }

    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception("Os dados do contrato estão vazios");
    }

    return ValidityData(
      uid: snapshot.id,
      ordernumber: (data['ordernumber'] as num).toInt(),
      ordertype: data['ordertype'],
      orderdate: data['orderdate'].toDate() as DateTime,
    );
  }

}
