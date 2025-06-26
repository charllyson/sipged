import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../_datas/measurement/measurement_data.dart';

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

    final list = snapshot.docs.map((doc) {
      return MeasurementData.fromDocument(snapshot: doc);
    }).toList();
    return list;
  }

  Future<void> saveOrUpdateMeasurement(MeasurementData data) async {
    final ref = _db
        .collection('contracts')
        .doc(data.id)
        .collection('measurements');

    if (data.id != null) {
      // Atualizar medição existente
      await ref.doc(data.id).set(data.toJson(), SetOptions(merge: true));
    } else {
      // Criar nova medição
      await ref.add(data.toJson());
    }
  }



  Future<void> deletarMedicao(String uidContract, String uidMedicao) async {
    final ref = _db
        .collection('contracts')
        .doc(uidContract)
        .collection('measurements')
        .doc(uidMedicao);
    await ref.delete();
  }
}
