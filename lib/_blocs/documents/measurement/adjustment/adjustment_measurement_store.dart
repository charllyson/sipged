import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:siged/_blocs/documents/measurement/adjustment/adjustment_measurement_bloc.dart';
import 'package:siged/_blocs/documents/measurement/adjustment/adjustment_measurement_data.dart';

class AdjustmentEntry {
  final String measurementId; // docId da medição
  final int order;            // measurementorder do doc
  final AdjustmentMeasurementData data;

  AdjustmentEntry({
    required this.measurementId,
    required this.order,
    required this.data,
  });
}

class AdjustmentsMeasurementStore extends ChangeNotifier {
  final AdjustmentMeasurementBloc bloc;
  AdjustmentsMeasurementStore(this.bloc);

  void _notifySafe() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.postFrameCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    } else {
      if (hasListeners) notifyListeners();
    }
  }

  final Map<String, List<AdjustmentEntry>> _byContract = {};
  final Map<String, bool> _loadingByContract = {};
  bool _loadingAll = false;
  bool get loadingAll => _loadingAll;

  List<AdjustmentEntry> _all = const [];
  List<AdjustmentEntry> get all => List.unmodifiable(_all);

  List<AdjustmentEntry> allOf(String contractId) =>
      List.unmodifiable(_byContract[contractId] ?? const []);

  bool isLoading(String contractId) => _loadingByContract[contractId] == true;

  Future<void> warmupForContract(String contractId) async {
    if (_byContract.containsKey(contractId)) return;
    await refreshForContract(contractId);
  }

  Future<void> refreshForContract(String contractId) async {
    _loadingByContract[contractId] = true; _notifySafe();
    try {
      final docs = await FirebaseFirestore.instance
          .collection('contracts').doc(contractId)
          .collection('measurements')
          .orderBy('measurementorder')
          .get();

      final entries = docs.docs.map((d) {
        final order = (d.data()['measurementorder'] ?? 0);
        return AdjustmentEntry(
          measurementId: d.id,
          order: order is num ? order.toInt() : 0,
          data: AdjustmentMeasurementData.fromDocument(d),
        );
      }).toList();

      _byContract[contractId] = List.unmodifiable(entries);
      _rebuildAllFromMap();
    } finally {
      _loadingByContract[contractId] = false; _notifySafe();
    }
  }

  Future<void> preloadForContracts(Set<String> contractIds) async {
    _loadingAll = true; _notifySafe();
    try {
      await Future.wait(contractIds.map((id) async {
        if (!_byContract.containsKey(id)) {
          await refreshForContract(id);
        }
      }));
    } finally {
      _loadingAll = false; _notifySafe();
    }
  }

  Future<void> ensureAllLoaded() async {
    if (_all.isNotEmpty || _loadingAll) return;
    _loadingAll = true; _notifySafe();
    try {
      final qs = await FirebaseFirestore.instance.collectionGroup('measurements').get();

      _byContract.clear();
      for (final d in qs.docs) {
        final path = d.reference.path.split('/');
        if (path.length < 3) continue;
        final contractId = path[path.length - 3];
        final order = (d.data()['measurementorder'] ?? 0);
        final entry = AdjustmentEntry(
          measurementId: d.id,
          order: order is num ? order.toInt() : 0,
          data: AdjustmentMeasurementData.fromMap(d.data()),
        );
        (_byContract[contractId] ??= <AdjustmentEntry>[]).add(entry);
      }

      for (final e in _byContract.entries) {
        e.value.sort((a, b) => a.order.compareTo(b.order));
        _byContract[e.key] = List.unmodifiable(e.value);
      }

      _rebuildAllFromMap();
    } finally {
      _loadingAll = false; _notifySafe();
    }
  }

  void _rebuildAllFromMap() {
    final tmp = <AdjustmentEntry>[];
    for (final lst in _byContract.values) {
      tmp.addAll(lst);
    }
    _all = List.unmodifiable(tmp);
    _notifySafe();
  }

  Future<AdjustmentEntry?> getById({
    required String contractId,
    required String measurementId,
  }) async {
    final cached = _byContract[contractId];
    if (cached != null) {
      final found = cached.firstWhere(
            (e) => e.measurementId == measurementId,
        orElse: () => AdjustmentEntry(measurementId: '', order: 0, data: AdjustmentMeasurementData()),
      );
      if (found.measurementId.isNotEmpty) return found;
    }

    final doc = await FirebaseFirestore.instance
        .collection('contracts').doc(contractId)
        .collection('measurements').doc(measurementId).get();
    if (!doc.exists) return null;

    final order = (doc.data()?['measurementorder'] ?? 0);
    final entry = AdjustmentEntry(
      measurementId: doc.id,
      order: order is num ? order.toInt() : 0,
      data: AdjustmentMeasurementData.fromDocument(doc),
    );

    final list = [...(_byContract[contractId] ?? const [])];
    final idx = list.indexWhere((e) => e.measurementId == measurementId);
    if (idx == -1) list.add(entry); else list[idx] = entry;
    list.sort((a, b) => a.order.compareTo(b.order));
    _byContract[contractId] = List.unmodifiable(list);
    _rebuildAllFromMap();

    return entry;
  }

  Future<List<AdjustmentEntry>> getForContractIds(Set<String> contractIds) async {
    await preloadForContracts(contractIds);
    return contractIds
        .expand((id) => _byContract[id] ?? const <AdjustmentEntry>[])
        .toList(growable: false);
  }

  void upsert(String contractId, String measurementId, AdjustmentMeasurementData data, {int? order}) {
    final list = [...(_byContract[contractId] ?? const [])];
    final idx = list.indexWhere((e) => e.measurementId == measurementId);
    final ord = order ?? (data.order ?? 0);
    final entry = AdjustmentEntry(measurementId: measurementId, order: ord, data: data);
    if (idx == -1) list.add(entry); else list[idx] = entry;
    list.sort((a, b) => a.order.compareTo(b.order));
    _byContract[contractId] = List.unmodifiable(list);
    _rebuildAllFromMap();
  }

  void remove(String contractId, String measurementId) {
    final list = [...(_byContract[contractId] ?? const [])];
    list.removeWhere((e) => e.measurementId == measurementId);
    _byContract[contractId] = List.unmodifiable(list);
    _rebuildAllFromMap();
  }

  double sumAdjustments(List<AdjustmentEntry> entries) =>
      entries.fold<double>(0.0, (s, e) => s + (e.data.value ?? 0.0));
}
