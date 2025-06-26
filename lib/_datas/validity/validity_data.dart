import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class ValidityData extends ChangeNotifier {
  String? id;
  String? uidContract;
  DateTime? orderdate;
  int? orderNumber;
  String? ordertype;

  ValidityData({
    this.id,
    this.uidContract,
    this.orderdate,
    this.orderNumber,
    this.ordertype,
  });

  factory ValidityData.fromDocument({required DocumentSnapshot snapshot}) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ValidityData(
      id: snapshot.id,
      orderNumber: (data['ordernumber'] as num?)?.toInt(),
      ordertype: data['ordertype'],
      orderdate: (data['orderdate'] as Timestamp?)?.toDate(),
    );
  }
}
