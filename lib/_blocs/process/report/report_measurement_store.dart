import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'report_measurement_data.dart';
import 'report_measurement_bloc.dart';

class ReportsMeasurementStore extends ChangeNotifier {
  ReportsMeasurementStore(this.bloc);

  final ReportMeasurementBloc bloc; // disponível caso você queira reagir a eventos
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<ReportMeasurementData> _all = <ReportMeasurementData>[];
  bool loading = false;

  List<ReportMeasurementData> get all => List.unmodifiable(_all);

  Future<void> ensureAllLoaded() async {
    if (loading || _all.isNotEmpty) return;
    loading = true;
    notifyListeners();
    try {
      final qs = await _db.collectionGroup(ReportMeasurementData.collectionName).get();
      _all
        ..clear()
        ..addAll(qs.docs.map((d) => ReportMeasurementData.fromDocument(d)));
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _all.clear();
    notifyListeners();
    await ensureAllLoaded();
  }

  Future<void> saveMeasurement({
    required String contractId,
    required ReportMeasurementData data,
  }) async {
    final docId = data.id ?? _db.collection('_').doc().id;
    final ref = _db
        .collection('contracts')
        .doc(contractId)
        .collection(ReportMeasurementData.collectionName)
        .doc(docId);

    final payload = data
        .copyWith(id: docId, contractId: contractId)
        .toFirestore()
      ..addAll({'contractPath': ref.path});

    await ref.set(payload, SetOptions(merge: true));

    final snap = await ref.get();
    final updated = ReportMeasurementData.fromDocument(snap);
    final idx = _all.indexWhere((e) => e.id == docId);
    if (idx >= 0) {
      _all[idx] = updated;
    } else {
      _all.add(updated);
    }
    notifyListeners();
  }

  double sumMedicoes(List<ReportMeasurementData> items) {
    double total = 0.0;
    for (final i in items) {
      total += (i.value ?? 0.0);
    }
    return total;
  }
}
