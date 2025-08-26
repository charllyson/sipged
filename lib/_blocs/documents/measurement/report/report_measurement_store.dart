import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sisged/_blocs/documents/measurement/report/report_measurement_bloc.dart'; // ReportsBloc
import 'package:sisged/_blocs/documents/measurement/report/report_measurement_data.dart';      // ReportMeasurementData

class ReportsMeasurementStore extends ChangeNotifier {
  final ReportMeasurementBloc bloc;
  ReportsMeasurementStore(this.bloc);

  // ---- rede de segurança: evita notify durante o build
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

  // ---- estado
  final Map<String, List<ReportMeasurementData>> _byContract = {};
  final Map<String, bool> _loadingByContract = {};
  bool _loadingAll = false;
  bool get loadingAll => _loadingAll;

  List<ReportMeasurementData> _all = const [];
  List<ReportMeasurementData> get all => List.unmodifiable(_all);

  List<ReportMeasurementData> allOf(String contractId) =>
      List.unmodifiable(_byContract[contractId] ?? const []);

  bool isLoading(String contractId) => _loadingByContract[contractId] == true;

  // ==========================================
  // Carregamento
  // ==========================================

  /// Carrega as medições de **um** contrato (idempotente por sessão)
  Future<void> warmupForContract(String contractId) async {
    if (_byContract.containsKey(contractId)) return;
    await refreshForContract(contractId);
  }

  /// Força recarga das medições de um contrato
  Future<void> refreshForContract(String contractId) async {
    _loadingByContract[contractId] = true; _notifySafe();
    try {
      final lst = await bloc.getAllMeasurementsOfContract(uidContract: contractId);
      _byContract[contractId] = List.unmodifiable(lst);

      // mantém _all coerente (append/update/removal simples)
      _rebuildAllFromMap();
    } finally {
      _loadingByContract[contractId] = false; _notifySafe();
    }
  }

  /// Pré-carrega em paralelo um conjunto de contratos
  Future<void> preloadForContracts(Set<String> contractIds) async {
    _loadingAll = true; _notifySafe();
    try {
      await Future.wait(contractIds.map((id) async {
        if (!_byContract.containsKey(id)) {
          final lst = await bloc.getAllMeasurementsOfContract(uidContract: id);
          _byContract[id] = List.unmodifiable(lst);
        }
      }));
      _rebuildAllFromMap();
    } finally {
      _loadingAll = false; _notifySafe();
    }
  }

  /// Carrega **todas** as medições (collectionGroup). Evite chamar com frequência.
  Future<void> ensureAllLoaded() async {
    if (_all.isNotEmpty || _loadingAll) return;
    _loadingAll = true; _notifySafe();
    try {
      final lst = await bloc.fetchAllMeasurements();
      _all = List.unmodifiable(lst);

      // também preenche o mapa por contrato a partir do _all
      _byContract
        ..clear();
      for (final m in _all) {
        final cid = m.contractId;
        if (cid == null || cid.isEmpty) continue;
        (_byContract[cid] ??= <ReportMeasurementData>[]).add(m);
      }
      for (final entry in _byContract.entries) {
        entry.value.sort((a, b) {
          final ao = a.orderReportMeasurement ?? 0;
          final bo = b.orderReportMeasurement ?? 0;
          return ao.compareTo(bo);
        });
        _byContract[entry.key] = List.unmodifiable(entry.value);
      }
    } finally {
      _loadingAll = false; _notifySafe();
    }
  }

  void _rebuildAllFromMap() {
    final tmp = <ReportMeasurementData>[];
    for (final lst in _byContract.values) {
      tmp.addAll(lst);
    }
    _all = List.unmodifiable(tmp);
    _notifySafe();
  }

  // ==========================================
  // Consulta pontual
  // ==========================================

  Future<ReportMeasurementData?> getById({
    required String contractId,
    required String measurementId,
  }) async {
    final cached = _byContract[contractId];
    if (cached != null) {
      final found = cached.firstWhere(
            (m) => m.idReportMeasurement == measurementId,
        orElse: () => ReportMeasurementData(),
      );
      if (found.idReportMeasurement != null) return found;
    }

    final doc = await FirebaseFirestore.instance
        .collection('contracts')
        .doc(contractId)
        .collection('measurements')
        .doc(measurementId)
        .get();

    if (!doc.exists) return null;
    final m = ReportMeasurementData.fromDocument(snapshot: doc);

    final list = [...(_byContract[contractId] ?? const [])];
    final idx = list.indexWhere((e) => e.idReportMeasurement == m.idReportMeasurement);
    if (idx == -1) list.add(m); else list[idx] = m;
    _byContract[contractId] = List.unmodifiable(list);
    _rebuildAllFromMap();

    return m;
  }

  Future<List<ReportMeasurementData>> getForContractIds(Set<String> contractIds) async {
    await preloadForContracts(contractIds);
    return contractIds
        .expand((id) => _byContract[id] ?? const <ReportMeasurementData>[])
        .toList(growable: false);
  }

  // ==========================================
  // Mutação local (pós-CRUD)
  // ==========================================

  void upsert(String contractId, ReportMeasurementData m) {
    final list = [...(_byContract[contractId] ?? const [])];
    final idx = list.indexWhere((e) => e.idReportMeasurement == m.idReportMeasurement);
    if (idx == -1) list.add(m); else list[idx] = m;

    // mantém ordenação (por ordem da medição)
    list.sort((a, b) {
      final ao = a.orderReportMeasurement ?? 0;
      final bo = b.orderReportMeasurement ?? 0;
      return ao.compareTo(bo);
    });

    _byContract[contractId] = List.unmodifiable(list);
    _rebuildAllFromMap();
  }

  void remove(String contractId, String measurementId) {
    final list = [...(_byContract[contractId] ?? const [])];
    list.removeWhere((e) => e.idReportMeasurement == measurementId);
    _byContract[contractId] = List.unmodifiable(list);
    _rebuildAllFromMap();
  }

  // ==========================================
  // Utilidades de soma (espelham o bloc)
  // ==========================================

  double sumMedicoes(List<ReportMeasurementData> medicoes) =>
      medicoes.fold<double>(0.0, (s, m) => s + (m.valueReportMeasurement ?? 0.0));

  double sumReajustes(List<ReportMeasurementData> medicoes) =>
      medicoes.fold<double>(0.0, (s, m) => s + (m.valueAdjustmentMeasurement ?? 0.0));

  double sumRevisoes(List<ReportMeasurementData> medicoes) =>
      medicoes.fold<double>(0.0, (s, m) => s + (m.valueRevisionMeasurement ?? 0.0));

  List<double> calcularTotais(List<ReportMeasurementData> dados) => [
    sumMedicoes(dados),
    sumReajustes(dados),
    sumRevisoes(dados),
  ];
}
