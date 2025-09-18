import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:siged/_blocs/sectors/planning/right_way_properties/planning_right_way_property_data.dart';

/// Store em memória dos imóveis do **Domínio de Faixa** por contrato.
/// Novo path: contracts/{contractId}/planning_right_way_properties
class PlanningRightWayPropertyStore extends ChangeNotifier {
  final FirebaseFirestore _db;
  PlanningRightWayPropertyStore({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final Map<String, List<PlanningRightWayPropertyData>> _byContract = {};
  final Map<String, bool> _loading = {};

  List<PlanningRightWayPropertyData> listFor(String contractId) =>
      _byContract[contractId] ?? const [];

  bool loadingFor(String contractId) => _loading[contractId] == true;

  CollectionReference<Map<String, dynamic>> _colFor(String contractId) =>
      _db.collection('contracts').doc(contractId).collection('planning_right_way_properties');

  Future<void> ensureFor(String contractId) async {
    if (contractId.isEmpty) return;
    if (_byContract.containsKey(contractId) || _loading[contractId] == true) return;

    _loading[contractId] = true; _notifyLater();
    try {
      final s = await _colFor(contractId).orderBy('ownerName').get();
      _byContract[contractId] = s.docs.map(PlanningRightWayPropertyData.fromDocument).toList(growable: false);
    } finally {
      _loading[contractId] = false; _notifyLater();
    }
  }

  Future<void> refreshFor(String contractId) async {
    if (contractId.isEmpty) return;
    _loading[contractId] = true; _notifyLater();
    try {
      final s = await _colFor(contractId).orderBy('ownerName').get();
      _byContract[contractId] = s.docs.map(PlanningRightWayPropertyData.fromDocument).toList(growable: false);
    } finally {
      _loading[contractId] = false; _notifyLater();
    }
  }

  Future<void> saveOrUpdate(String contractId, PlanningRightWayPropertyData data) async {
    final col = _colFor(contractId);
    final doc = (data.id?.isNotEmpty ?? false) ? col.doc(data.id) : col.doc();
    data.id ??= doc.id;
    data.contractId = contractId;

    await doc.set({
      ...data.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await refreshFor(contractId);
  }

  Future<void> delete(String contractId, String id) async {
    await _colFor(contractId).doc(id).delete();
    await refreshFor(contractId);
  }

  void _notifyLater() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      if (hasListeners) notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }
}
