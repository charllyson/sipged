// lib/_datas/documents/contracts/apostilles/apostilles_store.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../../_blocs/documents/contracts/apostilles/apostilles_bloc.dart';
import '../../../../_blocs/documents/contracts/apostilles/apostilles_storage_bloc.dart';
import '../contracts/contract_data.dart';
import 'apostilles_data.dart';

/// Store em memória de **apostilamentos**, indexado por `contractId`.
/// - Firestore via [ApostillesBloc]
/// - Storage (PDF) via [ApostillesStorageBloc]
class ApostillesStore extends ChangeNotifier {
  ApostillesStore({
    ApostillesBloc? bloc,
    ApostillesStorageBloc? storage,
  })  : _bloc = bloc ?? ApostillesBloc(),
        _storage = storage ?? ApostillesStorageBloc();

  final ApostillesBloc _bloc;                 // Firestore
  final ApostillesStorageBloc _storage;       // Storage

  ApostillesBloc get bloc => _bloc;
  ApostillesStorageBloc get storage => _storage;

  /// contractId -> lista de apostilamentos (ordenados por apostilleOrder)
  final Map<String, List<ApostillesData>> _byContract = <String, List<ApostillesData>>{};

  /// contractId -> carregando?
  final Map<String, bool> _loading = <String, bool>{};

  // ---------- leitura ----------
  List<ApostillesData> listFor(String contractId) =>
      _byContract[contractId] ?? const <ApostillesData>[];

  bool loadingFor(String contractId) => _loading[contractId] == true;

  Iterable<ApostillesData> get all => _byContract.values.expand((e) => e);

  // ---------- carregamento ----------
  Future<void> ensureFor(String contractId) async {
    if (contractId.isEmpty) return;
    if (_byContract.containsKey(contractId)) return;
    if (_loading[contractId] == true) return;

    _loading[contractId] = true;
    try {
      final lista = await _bloc.getAllApostillesOfContract(uidContract: contractId);
      _byContract[contractId] = _sorted(lista);
    } finally {
      _loading[contractId] = false;
      _notifyAfterBuild();
    }
  }

  Future<void> warmupFor(Set<String> contractIds) async {
    final pending = contractIds.where((id) => !_byContract.containsKey(id)).toList();
    if (pending.isEmpty) return;
    await Future.wait(pending.map(ensureFor));
  }

  Future<void> refreshFor(String contractId) async {
    if (contractId.isEmpty) return;
    _loading[contractId] = true;
    _notifyAfterBuild();

    try {
      final lista = await _bloc.getAllApostillesOfContract(uidContract: contractId);
      _byContract[contractId] = _sorted(lista);
    } finally {
      _loading[contractId] = false;
      _notifyAfterBuild();
    }
  }

  void clearFor(String contractId) {
    _byContract.remove(contractId);
    _loading.remove(contractId);
    _notifyAfterBuild();
  }

  // ---------- agregação ----------
  Future<List<ApostillesData>> getForContractIds(Set<String> contractIds) async {
    if (contractIds.isEmpty) return const <ApostillesData>[];
    await warmupFor(contractIds);
    final List<ApostillesData> out = <ApostillesData>[];
    for (final id in contractIds) {
      out.addAll(listFor(id));
    }
    return out;
  }

  // ---------- upserts locais ----------
  void upsert(ApostillesData a) {
    final contractId = a.contractId ?? '';
    if (contractId.isEmpty) return;
    _upsertInternal(contractId, a);
  }

  void upsertFor(String contractId, ApostillesData a) {
    if (contractId.isEmpty) return;
    _upsertInternal(contractId, a);
  }

  void _upsertInternal(String contractId, ApostillesData a) {
    final list = List<ApostillesData>.from(_byContract[contractId] ?? const <ApostillesData>[]);
    final idx = list.indexWhere((e) => e.id == a.id);
    if (idx >= 0) {
      list[idx] = a;
    } else {
      list.add(a);
    }
    _byContract[contractId] = _sorted(list);
    _notifyAfterBuild();
  }

  void remove(String contractId, String apostilleId) {
    final list = List<ApostillesData>.from(_byContract[contractId] ?? const <ApostillesData>[])
      ..removeWhere((e) => e.id == apostilleId);
    _byContract[contractId] = _sorted(list);
    _notifyAfterBuild();
  }

  void removeFor(String contractId, String apostilleId) => remove(contractId, apostilleId);

  // ---------- Firestore ----------
  Future<void> saveOrUpdate(String contractId, ApostillesData data) async {
    await _bloc.saveOrUpdateApostille(data, contractId);
    await refreshFor(contractId);
  }

  Future<void> delete(String contractId, String apostilleId) async {
    await _bloc.deletarApostille(contractId, apostilleId);
    remove(contractId, apostilleId);
  }

  /// Salva (ou atualiza) no Firestore apenas o metadado `pdfUrl`.
  Future<void> savePdfUrl(String contractId, String apostilleId, String url) async {
    await _storage.salvarUrlPdfDaApostila(
      contractId: contractId,
      apostilleId: apostilleId,
      url: url,
    );
    await refreshFor(contractId);
  }

  // ---------- Storage (PDF) ----------
  /// Upload via picker e salva a URL no Firestore (conveniência).
  Future<void> uploadPdfWithProgress({
    required ContractData contract,
    required ApostillesData apostille,
    required void Function(double progress) onProgress,
  }) async {
    await _storage.sendPdf(
      contract: contract,
      apostille: apostille,
      onProgress: onProgress,
      onUploaded: (url) => savePdfUrl(contract.id!, apostille.id!, url),
    );
  }

  Future<bool> pdfExists({
    required ContractData contract,
    required ApostillesData apostille,
  }) {
    return _storage.verificarSePdfDeApostilaExiste(
      contract: contract,
      apostille: apostille,
    );
  }

  Future<String?> getPdfUrl({
    required ContractData contract,
    required ApostillesData apostille,
  }) {
    return _storage.getPdfUrlDaApostila(
      contract: contract,
      apostille: apostille,
    );
  }

  /// Deleta o PDF no Storage (metadado deve ser limpo fora, se necessário).
  Future<void> deletePdf({
    required ContractData contract,
    required ApostillesData apostille,
  }) async {
    await _storage.delete(contract, apostille);
    await refreshFor(contract.id!);
  }

  // ---------- utils ----------
  List<ApostillesData> _sorted(List<ApostillesData> list) {
    final l = List<ApostillesData>.from(list);
    l.sort((a, b) => (a.apostilleOrder ?? 0).compareTo(b.apostilleOrder ?? 0));
    return List<ApostillesData>.unmodifiable(l);
  }

  void _notifyAfterBuild() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      if (hasListeners) notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }
}
