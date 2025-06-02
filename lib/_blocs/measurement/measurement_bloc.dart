// ignore_for_file: avoid_print

import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sisgeo/_datas/measurement/measurement_data.dart';

class MeasurementBloc extends BlocBase {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  MeasurementBloc();

  Future<List<MeasurementData>> getAllMeasurementsOfContract({required String uidContract}) async {
    final snapshot = await _db
        .collection('contracts')
        .doc(uidContract)
        .collection('measurements')
        .orderBy('measurementorder')
        .get();
    print('Quantidade de medições: ${snapshot.docs.length}');

    final list = snapshot.docs.map((doc) {
      return MeasurementData.fromDocument(snapshot: doc);
    }).toList();

    print('Lista convertida com ${list.length} medições');

    return list;
  }

}
