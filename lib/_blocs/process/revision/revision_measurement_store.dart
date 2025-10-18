import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'revision_measurement_data.dart';
import 'revision_measurement_bloc.dart';

class RevisionsMeasurementStore extends ChangeNotifier {
  RevisionsMeasurementStore(this.bloc);

  final RevisionMeasurementBloc bloc;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<RevisionMeasurementData> _all = <RevisionMeasurementData>[];
  bool loading = false;

  List<RevisionMeasurementData> get all => List.unmodifiable(_all);

  Future<void> ensureAllLoaded() async {
    if (loading || _all.isNotEmpty) return;
    loading = true;
    notifyListeners();
    try {
      final qs = await _db.collectionGroup(RevisionMeasurementData.collectionName).get();
      _all
        ..clear()
        ..addAll(qs.docs.map((d) => RevisionMeasurementData.fromDocument(d)));
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

  Future<void> saveRevision({
    required String contractId,
    required RevisionMeasurementData data,
  }) async {
    final docId = data.id ?? _db.collection('_').doc().id;
    final ref = _db
        .collection('contracts')
        .doc(contractId)
        .collection(RevisionMeasurementData.collectionName)
        .doc(docId);

    final payload = data
        .copyWith(id: docId, contractId: contractId)
        .toFirestore()
      ..addAll({'contractPath': ref.path});

    await ref.set(payload, SetOptions(merge: true));

    final snap = await ref.get();
    final updated = RevisionMeasurementData.fromDocument(snap);
    final idx = _all.indexWhere((e) => e.id == docId);
    if (idx >= 0) {
      _all[idx] = updated;
    } else {
      _all.add(updated);
    }
    notifyListeners();
  }

  double sumRevisions(List<RevisionMeasurementData> items) {
    double total = 0.0;
    for (final i in items) {
      total += (i.value ?? 0.0);
    }
    return total;
  }
}
