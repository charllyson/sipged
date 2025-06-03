import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class ValidityData extends ChangeNotifier {
  String? uid;
  String? uidContract; // <-- Adicione isso
  DateTime? orderdate;
  int? ordernumber;
  String? ordertype;

  ValidityData({
    this.uid,
    this.uidContract, // <-- Atribua no construtor também
    this.orderdate,
    this.ordernumber,
    this.ordertype,
  });

  factory ValidityData.fromDocument({required DocumentSnapshot snapshot}) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ValidityData(
      uid: snapshot.id,
      ordernumber: (data['ordernumber'] as num?)?.toInt(),
      ordertype: data['ordertype'],
      orderdate: (data['orderdate'] as Timestamp?)?.toDate(),
    );
  }
}
