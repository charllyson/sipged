import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'adjustment_measurement_data.dart';
import 'adjustment_measurement_bloc.dart';

class AdjustmentsMeasurementStore extends ChangeNotifier {
  AdjustmentsMeasurementStore(this.bloc);

  final AdjustmentMeasurementBloc bloc;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<AdjustmentMeasurementData> _all = <AdjustmentMeasurementData>[];
  bool loading = false;

  List<AdjustmentMeasurementData> get all => List.unmodifiable(_all);

  Future<void> ensureAllLoaded() async {
    if (loading || _all.isNotEmpty) return;
    loading = true;
    notifyListeners();
    try {
      final qs = await _db.collectionGroup(AdjustmentMeasurementData.collectionName).get();
      _all
        ..clear()
        ..addAll(qs.docs.map((d) => AdjustmentMeasurementData.fromDocument(d)));
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

  Future<void> saveAdjustment({
    required String contractId,
    required AdjustmentMeasurementData data,
  }) async {
    final docId = data.id ?? _db.collection('_').doc().id;
    final ref = _db
        .collection('contracts')
        .doc(contractId)
        .collection(AdjustmentMeasurementData.collectionName)
        .doc(docId);

    final payload = data
        .copyWith(id: docId, contractId: contractId)
        .toFirestore()
      ..addAll({'contractPath': ref.path});

    await ref.set(payload, SetOptions(merge: true));

    final snap = await ref.get();
    final updated = AdjustmentMeasurementData.fromDocument(snap);
    final idx = _all.indexWhere((e) => e.id == docId);
    if (idx >= 0) {
      _all[idx] = updated;
    } else {
      _all.add(updated);
    }
    notifyListeners();
  }

  double sumAdjustments(List<AdjustmentMeasurementData> items) {
    double total = 0.0;
    for (final i in items) {
      total += (i.value ?? 0.0);
    }
    return total;
  }
}
