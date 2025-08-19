// lib/screens/commons/listContracts/contracts_store.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'package:sisged/_blocs/documents/contracts/contracts/contract_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_storage_bloc.dart';

import 'package:sisged/_datas/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_datas/system/user_data.dart';

class ContractsStore extends ChangeNotifier {
  // ===== Injeções =====
  final ContractBloc bloc;                 // Firestore (CRUD, permissões, consultas)
  final ContractStorageBloc storageBloc;    // Storage (upload/exists/url/delete)

  ContractsStore(this.bloc, this.storageBloc);

  bool _loading = false;
  bool get loading => _loading;

  bool _initialized = false;
  bool get initialized => _initialized;

  List<ContractData> _all = const [];
  List<ContractData> get all => _all;

  ContractData? _selected;
  ContractData? get selected => _selected;

  final Map<String, ContractData> _cache = {};
  UserData? _currentUser;

  // --------- notifyListeners seguro (evita setState/markNeedsBuild durante build)
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

  // ========= Carregamento / Warmup =========
  /// Carrega 1x por usuário (idempotente)
  Future<void> warmup(UserData currentUser) async {
    if (_initialized && _currentUser?.id == currentUser.id && _all.isNotEmpty) return;

    _currentUser = currentUser;
    _loading = true;
    _notifySafe();

    final lista = await bloc.getFilteredContracts(currentUser: currentUser);
    _setAll(lista);

    _loading = false;
    _initialized = true;
    _notifySafe();
  }

  /// Força recarga do Firestore (mantém item selecionado, se houver)
  Future<void> refresh() async {
    if (_currentUser == null) return;
    _loading = true;
    _notifySafe();

    final lista = await bloc.getFilteredContracts(currentUser: _currentUser!);
    _setAll(lista);

    if (_selected != null) _selected = _cache[_selected!.id ?? ''];

    _loading = false;
    _notifySafe();
  }

  void _setAll(List<ContractData> lista) {
    _all = List.unmodifiable(lista);
    _cache
      ..clear()
      ..addEntries(_all.where((c) => c.id != null).map((c) => MapEntry(c.id!, c)));
  }

  // ========= Seleção =========
  /// Seleciona e garante presença na lista/cache
  void select(ContractData c) {
    if (c.id != null) _cache[c.id!] = c;

    final idx = c.id == null ? -1 : _all.indexWhere((e) => e.id == c.id);
    if (idx == -1) {
      _all = List.unmodifiable([..._all, c]);
    } else {
      final tmp = [..._all];
      tmp[idx] = c;
      _all = List.unmodifiable(tmp);
    }
    _selected = c;
    _notifySafe();
  }

  void clearSelection() {
    _selected = null;
    _notifySafe();
  }

  // ========= CRUD via Bloc (com cache local) =========
  /// Salva/atualiza contrato via Firestore e reflete no cache/local
  Future<ContractData> saveOrUpdate(ContractData c) async {
    final saved = await bloc.salvarOuAtualizarContrato(c);
    upsert(saved);
    return saved;
  }

  /// Atualiza a URL do PDF no Firestore e sincroniza o item no cache
  Future<void> salvarUrlPdfDoContrato(String contractId, String url) async {
    await storageBloc.salvarUrlPdfDoContrato(contractId, url);
    // Atualiza item do cache/lista
    final atualizado = await bloc.getContractById(contractId);
    if (atualizado != null) {
      upsert(atualizado);
    }
  }

  /// Busca por id com cache (útil p/ deep-link)
  Future<ContractData?> getById(String id) async {
    if (_cache.containsKey(id)) return _cache[id];

    final c = await bloc.getContractById(id);
    if (c != null) {
      _cache[id] = c;
      final idx = _all.indexWhere((e) => e.id == id);
      if (idx == -1) {
        _all = List.unmodifiable([..._all, c]);
      } else {
        final tmp = [..._all];
        tmp[idx] = c;
        _all = List.unmodifiable(tmp);
      }
      _notifySafe();
    }
    return c;
  }

  /// Upsert em memória (sem re-fetch)
  void upsert(ContractData c) {
    if (c.id != null) _cache[c.id!] = c;
    final idx = c.id == null ? -1 : _all.indexWhere((e) => e.id == c.id);

    if (idx == -1) {
      _all = List.unmodifiable([..._all, c]);
    } else {
      final tmp = [..._all];
      tmp[idx] = c;
      _all = List.unmodifiable(tmp);
    }
    if (_selected?.id == c.id) _selected = c;
    _notifySafe();
  }

  /// Após deletar
  void removeById(String id) {
    _cache.remove(id);
    final tmp = [..._all]..removeWhere((e) => e.id == id);
    _all = List.unmodifiable(tmp);
    if (_selected?.id == id) _selected = null;
    _notifySafe();
  }

  // ========= Helpers de PDF (Storage + Firestore) =========

  /// Verifica se o PDF existe no Storage (considera fallback legado).
  Future<bool> pdfExists(ContractData c) => storageBloc.exists(c);

  /// Obtém a URL https do Storage (considera fallback). Se tiver no Firestore, prefira-a.
  Future<String?> getPdfUrl(ContractData c, {bool preferirFirestore = true}) async {
    if (preferirFirestore && c.id != null) {
      final fresh = await bloc.getContractById(c.id!);
      final saved = fresh?.urlContractPdf;
      if (saved != null && saved.isNotEmpty) return saved;
    }
    return storageBloc.getUrl(c);
  }

  /// Upload via seletor (Web) e já salva a URL no Firestore; atualiza cache.
  Future<String?> uploadPdfAndSaveUrl({
    required ContractData c,
    void Function(double progress)? onProgress,
  }) async {
    if (c.id == null) throw Exception('Contrato precisa estar salvo para anexar PDF.');
    final url = await storageBloc.uploadWithPicker(
      contract: c,
      onProgress: onProgress ?? (_) {},
    );
    await salvarUrlPdfDoContrato(c.id!, url);
    return url;
  }

  /// Deleta o PDF do Storage e limpa a URL no Firestore; atualiza cache.
  Future<bool> deletePdfAndClearUrl(ContractData c) async {
    final okStorage = await storageBloc.delete(c);
    if (okStorage && c.id != null) {
      await storageBloc.removeUrlPdfDoContrato(c.id!);
      final atualizado = await bloc.getContractById(c.id!);
      if (atualizado != null) upsert(atualizado);
    }
    return okStorage;
  }

  // ========= Filtros em memória =========
  List<ContractData> filter({
    String? status,
    String? company,
    String? regionContains,
    String? searchText,
  }) {
    Iterable<ContractData> r = _all;

    if (status != null && status.isNotEmpty) {
      r = r.where((c) => (c.contractStatus ?? '').toUpperCase() == status.toUpperCase());
    }
    if (company != null && company.isNotEmpty) {
      r = r.where((c) => (c.companyLeader ?? '').toUpperCase() == company.toUpperCase());
    }
    if (regionContains != null && regionContains.isNotEmpty) {
      r = r.where((c) => (c.regionOfState ?? '').toUpperCase().contains(regionContains.toUpperCase()));
    }
    if (searchText != null && searchText.isNotEmpty) {
      final s = searchText.toUpperCase();
      r = r.where((c) =>
      (c.summarySubjectContract ?? '').toUpperCase().contains(s) ||
          (c.contractNumber ?? '').toUpperCase().contains(s) ||
          (c.companyLeader ?? '').toUpperCase().contains(s));
    }
    return r.toList(growable: false);
  }
}
