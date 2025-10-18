// lib/_datas/process/contracts/additive/additive_store.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'package:siged/_blocs/process/additives/additives_bloc.dart';
import 'package:siged/_blocs/process/additives/additives_storage_bloc.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'additive_data.dart';

class AdditivesStore extends ChangeNotifier {
  AdditivesStore({
    AdditivesBloc? bloc,
    AdditivesStorageBloc? storage,
  })  : _bloc = bloc ?? AdditivesBloc(),
        _storage = storage ?? AdditivesStorageBloc();

  final AdditivesBloc _bloc;
  final AdditivesStorageBloc _storage;

  AdditivesBloc get bloc => _bloc;
  AdditivesStorageBloc get storage => _storage;

  final Map<String, List<AdditiveData>> _byContract = <String, List<AdditiveData>>{};
  final Map<String, bool> _loading = <String, bool>{};

  List<AdditiveData> listFor(String contractId) =>
      _byContract[contractId] ?? const <AdditiveData>[];

  bool loadingFor(String contractId) => _loading[contractId] == true;

  Iterable<AdditiveData> get all => _byContract.values.expand((e) => e);

  AdditiveData? getById(String contractId, String additiveId) {
    final list = _byContract[contractId];
    if (list == null) return null;
    final i = list.indexWhere((e) => e.id == additiveId);
    return i >= 0 ? list[i] : null;
  }

  Future<void> ensureFor(String contractId) async {
    if (contractId.isEmpty) return;
    if (_byContract.containsKey(contractId)) return;
    if (_loading[contractId] == true) return;

    _loading[contractId] = true;
    try {
      final lista = await _bloc.getAllAdditivesOfContract(uidContract: contractId);
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
      final lista = await _bloc.getAllAdditivesOfContract(uidContract: contractId);
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

  void clearAll() {
    _byContract.clear();
    _loading.clear();
    _notifyAfterBuild();
  }

  Future<List<AdditiveData>> getForContractIds(Set<String> contractIds) async {
    if (contractIds.isEmpty) return const <AdditiveData>[];
    await warmupFor(contractIds);
    final List<AdditiveData> out = <AdditiveData>[];
    for (final id in contractIds) {
      out.addAll(listFor(id));
    }
    return out;
  }

  void upsert(AdditiveData a) {
    final contractId = a.contractId ?? '';
    if (contractId.isEmpty) return;
    _upsertInternal(contractId, a);
  }

  void upsertFor(String contractId, AdditiveData a) {
    if (contractId.isEmpty) return;
    _upsertInternal(contractId, a);
  }

  void _upsertInternal(String contractId, AdditiveData a) {
    final list = List<AdditiveData>.from(_byContract[contractId] ?? const <AdditiveData>[]);
    final idx = list.indexWhere((e) => e.id == a.id);
    if (idx >= 0) {
      list[idx] = a;
    } else {
      list.add(a);
    }
    _byContract[contractId] = _sorted(list);
    _notifyAfterBuild();
  }

  void remove(String contractId, String additiveId) {
    final list = List<AdditiveData>.from(_byContract[contractId] ?? const <AdditiveData>[])
      ..removeWhere((e) => e.id == additiveId);
    _byContract[contractId] = _sorted(list);
    _notifyAfterBuild();
  }

  void removeFor(String contractId, String additiveId) => remove(contractId, additiveId);

  Future<void> saveOrUpdate(String contractId, AdditiveData data) async {
    await _bloc.salvarOuAtualizarAditivo(data, contractId);
    await refreshFor(contractId);
  }

  Future<void> delete(String contractId, String additiveId) async {
    await _bloc.deleteAdditive(contractId, additiveId);
    remove(contractId, additiveId);
  }

  Future<void> uploadPdfWithProgress({
    required ContractData contract,
    required AdditiveData additive,
    required void Function(double progress) onProgress,
  }) async {
    await _storage.sendPdf(
      contract: contract,
      additive: additive,
      onProgress: onProgress,
      onUploaded: (url) => savePdfUrl(contract.id!, additive.id!, url),
    );
  }

  Future<void> savePdfUrl(String contractId, String additiveId, String url) async {
    await _storage.salvarUrlPdfDoAditivo(
      contractId: contractId,
      additiveId: additiveId,
      url: url,
    );
    await refreshFor(contractId);
  }

  Future<bool> pdfExists({
    required ContractData contract,
    required AdditiveData additive,
  }) {
    return _storage.verificarSePdfDeAditivoExiste(
      contract: contract,
      additive: additive,
    );
  }

  Future<String?> getPdfUrl({
    required ContractData contract,
    required AdditiveData additive,
  }) {
    return _storage.getPdfUrlDoAditivo(
      contract: contract,
      additive: additive,
    );
  }

  Future<void> deletePdf({
    required ContractData contract,
    required AdditiveData additive,
  }) async {
    await _storage.delete(contract, additive);
    await refreshFor(contract.id!);
  }

  List<AdditiveData> _sorted(List<AdditiveData> list) {
    final l = List<AdditiveData>.from(list);
    l.sort((a, b) => (a.additiveOrder ?? 0).compareTo(b.additiveOrder ?? 0));
    return List<AdditiveData>.unmodifiable(l);
  }

  void _notifyAfterBuild() {
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
