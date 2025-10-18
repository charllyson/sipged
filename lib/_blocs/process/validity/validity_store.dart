// ==============================
// lib/_blocs/process/contracts/validity/validity_store.dart
// ==============================
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:siged/_blocs/process/additives/additive_store.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';

import 'package:siged/_blocs/process/validity/validity_bloc.dart';
import 'package:siged/_blocs/process/validity/validity_storage_bloc.dart';
import 'validity_data.dart';

class ValidityStore extends ChangeNotifier {
  ValidityStore({
    ValidityBloc? bloc,
    ValidityStorageBloc? storage,
  })  : _bloc = bloc ?? ValidityBloc(),
        _storage = storage ?? ValidityStorageBloc();

  final ValidityBloc _bloc;               // Firestore
  final ValidityStorageBloc _storage;     // Storage

  ValidityBloc get bloc => _bloc;         // 🆕 expõe para controller usar setAttachments

  final Map<String, List<ValidityData>> _byContract = <String, List<ValidityData>>{};
  final Map<String, bool> _loading     = <String, bool>{};

  bool get isEmpty => _byContract.isEmpty;

  List<ValidityData> listFor(String contractId) =>
      _byContract[contractId] ?? const <ValidityData>[];

  bool loadingFor(String contractId) => _loading[contractId] == true;

  // ---------- Carregamento ----------
  Future<void> ensureFor(String contractId) async {
    if (contractId.isEmpty) return;
    if (_byContract.containsKey(contractId)) return;
    if (_loading[contractId] == true) return;

    _loading[contractId] = true;
    try {
      final lista = await _bloc.getAllValidityOfContract(uidContract: contractId);
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
      final lista = await _bloc.getAllValidityOfContract(uidContract: contractId);
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

  // ---------- Upserts locais ----------
  void upsert(ValidityData v) {
    final contractId = v.uidContract;
    if (contractId == null || contractId.isEmpty) return;

    final list = List<ValidityData>.from(
      _byContract[contractId] ?? const <ValidityData>[],
    );
    final idx = list.indexWhere((e) => e.id == v.id);
    if (idx >= 0) {
      list[idx] = v;
    } else {
      list.add(v);
    }
    _byContract[contractId] = _sorted(list);
    _notifyAfterBuild();
  }

  void remove(String contractId, String validityId) {
    final list = List<ValidityData>.from(
      _byContract[contractId] ?? const <ValidityData>[],
    )..removeWhere((e) => e.id == validityId);

    _byContract[contractId] = _sorted(list);
    _notifyAfterBuild();
  }

  // ---------- Firestore ----------
  Future<void> saveOrUpdate(ValidityData data) async {
    await _bloc.salvarOuAtualizarValidade(data);
    upsert(data);
  }

  Future<void> delete(String contractId, String validityId) async {
    await _bloc.deletarValidade(contractId, validityId);
    remove(contractId, validityId);
  }

  // ---------- Storage + Metadado ----------
  Future<bool> uploadPdfWithProgress({
    required String contractId,
    required ValidityData validity,
    required void Function(double) onProgress,
    required void Function(bool) onComplete,
  }) async {
    try {
      final contract = await _bloc.buscarContrato(contractId);
      if (contract == null || validity.id == null) {
        onComplete(false);
        return false;
      }

      await _storage.sendPdf(
        contract: contract,
        validade: validity,
        onProgress: onProgress,
        onUploaded: (url) async {
          await _storage.salvarUrlPdfDaValidade(
            contractId: contract.id!,
            validadeId: validity.id!,
            url: url,
          );
        },
      );

      onComplete(true);
      return true;
    } catch (_) {
      onComplete(false);
      return false;
    }
  }

  Future<bool> deletePdf({
    required String contractId,
    required ValidityData validity,
  }) async {
    try {
      final contract = await _bloc.buscarContrato(contractId);
      if (contract == null || validity.id == null) return false;

      final ok = await _storage.delete(contract, validity);
      if (ok) {
        await FirebaseFirestore.instance
            .collection('contracts')
            .doc(contractId)
            .collection('orders')
            .doc(validity.id)
            .update({'pdfUrl': FieldValue.delete()});
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> pdfExists({
    required ContractData contract,
    required ValidityData validity,
  }) =>
      _storage.verificarSePdfDeValidadeExiste(
        contract: contract,
        validade: validity,
      );

  Future<String?> getPdfUrl({
    required ContractData contract,
    required ValidityData validity,
  }) =>
      _storage.getPdfUrlDaValidade(
        contract: contract,
        validade: validity,
      );

  // ---------- Regras de negócio ----------
  int calcularDiasParalisados(List<ValidityData> validities) {
    int dias = 0;
    for (int i = 0; i < validities.length; i++) {
      final atual = validities[i];
      final tipoAtual = (atual.ordertype ?? '').toUpperCase();

      if (tipoAtual.contains('REINÍCIO') && i > 0) {
        final anterior = validities[i - 1];
        final tipoAnterior = (anterior.ordertype ?? '').toUpperCase();

        if (tipoAnterior.contains('PARALISA') &&
            atual.orderdate != null &&
            anterior.orderdate != null) {
          dias += atual.orderdate!.difference(anterior.orderdate!).inDays;
        }
      }
    }
    return dias;
  }

  Future<DateTime?> calcularDataFinalContrato({
    required ContractData contract,
    required AdditivesStore additivesStore,
  }) async {
    if (contract.id == null || contract.publicationDateDoe == null) return null;

    await additivesStore.ensureFor(contract.id!);
    final aditivos = additivesStore.listFor(contract.id!);

    final int diasValidadeInicial = contract.initialValidityContractDays ?? 0;
    final int diasAditivos = aditivos.fold<int>(
      0, (soma, a) => soma + (a.additiveValidityContractDays ?? 0),
    );

    final int totalDias = diasValidadeInicial + diasAditivos;
    return contract.publicationDateDoe!.add(Duration(days: totalDias));
  }

  Future<DateTime?> calcularDataFinalExecucao({
    required ContractData contract,
    required AdditivesStore additivesStore,
  }) async {
    if (contract.id == null) return null;

    await ensureFor(contract.id!);
    final validades = listFor(contract.id!);

    final inicio = validades.firstWhere(
          (v) => ((v.ordertype ?? '').toUpperCase()).contains('INÍCIO'),
      orElse: () => ValidityData(orderdate: null),
    ).orderdate;

    if (inicio == null) return null;

    await additivesStore.ensureFor(contract.id!);
    final aditivos = additivesStore.listFor(contract.id!);

    final int diasParalisados = calcularDiasParalisados(validades);
    final int diasExecucaoInicial = contract.initialValidityExecutionDays ?? 0;
    final int diasExecucaoAditivos = aditivos.fold<int>(
      0, (soma, a) => soma + (a.additiveValidityExecutionDays ?? 0),
    );

    final int total = diasExecucaoInicial + diasExecucaoAditivos + diasParalisados;
    return inicio.add(Duration(days: total));
  }

  // ---------- Utils ----------
  List<ValidityData> _sorted(List<ValidityData> list) {
    final l = List<ValidityData>.from(list);
    l.sort((a, b) => (a.orderNumber ?? 0).compareTo(b.orderNumber ?? 0));
    return List<ValidityData>.unmodifiable(l);
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
