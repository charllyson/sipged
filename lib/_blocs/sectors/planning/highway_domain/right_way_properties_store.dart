import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:siged/_blocs/sectors/planning/highway_domain/highway_property_data.dart';

/// Store em memória dos imóveis do **Domínio de Faixa** por contrato.
/// Firestore path sugerido: planning_highway_domain/{contractId}/properties
class RightWayPropertiesStore extends ChangeNotifier {
  final FirebaseFirestore _db;
  RightWayPropertiesStore({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final Map<String, List<RightWayPropertyData>> _byContract = {};
  final Map<String, bool> _loading = {};

  List<RightWayPropertyData> listFor(String contractId) =>
      _byContract[contractId] ?? const [];

  bool loadingFor(String contractId) => _loading[contractId] == true;

  Future<void> ensureFor(String contractId) async {
    if (contractId.isEmpty) return;
    if (_byContract.containsKey(contractId) || _loading[contractId] == true) return;

    _loading[contractId] = true; _notifyLater();
    try {
      final col = _db
          .collection('planning_highway_domain')
          .doc(contractId)
          .collection('properties');
      final s = await col.orderBy('ownerName').get();
      _byContract[contractId] = s.docs.map(RightWayPropertyData.fromDocument).toList(growable: false);
    } finally {
      _loading[contractId] = false; _notifyLater();
    }
  }

  Future<void> refreshFor(String contractId) async {
    if (contractId.isEmpty) return;
    _loading[contractId] = true; _notifyLater();
    try {
      final col = _db
          .collection('planning_highway_domain')
          .doc(contractId)
          .collection('properties');
      final s = await col.orderBy('ownerName').get();
      _byContract[contractId] = s.docs.map(RightWayPropertyData.fromDocument).toList(growable: false);
    } finally {
      _loading[contractId] = false; _notifyLater();
    }
  }

  Future<void> saveOrUpdate(String contractId, RightWayPropertyData data) async {
    final col = _db
        .collection('planning_highway_domain')
        .doc(contractId)
        .collection('properties');

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
    final col = _db
        .collection('planning_highway_domain')
        .doc(contractId)
        .collection('properties');
    await col.doc(id).delete();
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
