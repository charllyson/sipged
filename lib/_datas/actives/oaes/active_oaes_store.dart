import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../_blocs/actives/active_oaes_bloc.dart';
import 'active_oaes_data.dart';

/// Store para OAEs (Obras de Arte Especiais).
/// - Cache completo em memória (lista + mapa por id)
/// - Carregamento único (ensureAllLoaded) e refresh
/// - Upsert/Remove locais sem re-fetch
/// - Filtros em memória para a UI
class ActiveOaesStore extends ChangeNotifier {
  ActiveOaesStore([ActiveOaesBloc? bloc]) : _bloc = bloc ?? ActiveOaesBloc();

  final ActiveOaesBloc _bloc;

  bool _loading = false;
  bool get loading => _loading;

  bool _initialized = false;
  bool get initialized => _initialized;

  List<ActiveOaesData> _all = const <ActiveOaesData>[];
  List<ActiveOaesData> get all => _all;

  final Map<String, ActiveOaesData> _byId = <String, ActiveOaesData>{};

  /// Carrega tudo 1x (idempotente). Evite chamar no meio do build; caso chame,
  /// o store só notificará após o frame (anti "setState during build").
  Future<void> ensureAllLoaded() async {
    if (_initialized || _loading) return;
    _loading = true;

    try {
      final List<ActiveOaesData> lista = await _bloc.getAllOAEs();
      _setAll(lista);
      _initialized = true;
    } finally {
      _loading = false;
      _notifyAfterBuild();
    }
  }

  /// Força recarga do Firestore.
  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _notifyAfterBuild();

    try {
      final List<ActiveOaesData> lista = await _bloc.getAllOAEs();
      _setAll(lista);
      _initialized = true;
    } finally {
      _loading = false;
      _notifyAfterBuild();
    }
  }

  void _setAll(List<ActiveOaesData> list) {
    final sorted = _sorted(list);
    _all = List<ActiveOaesData>.unmodifiable(sorted);
    _byId
      ..clear()
      ..addEntries(_all.where((e) => e.id != null).map((e) => MapEntry(e.id!, e)));
  }

  /// Upsert local (sem re-fetch)
  void upsert(ActiveOaesData o) {
    if (o.id != null) _byId[o.id!] = o;

    final idx = o.id == null ? -1 : _all.indexWhere((e) => e.id == o.id);
    if (idx == -1) {
      _all = List<ActiveOaesData>.unmodifiable(<ActiveOaesData>[..._all, o]..sort(_compare));
    } else {
      final tmp = List<ActiveOaesData>.of(_all);
      tmp[idx] = o;
      tmp.sort(_compare);
      _all = List<ActiveOaesData>.unmodifiable(tmp);
    }
    notifyListeners();
  }

  /// Remove local
  void removeById(String id) {
    _byId.remove(id);
    final tmp = List<ActiveOaesData>.of(_all)..removeWhere((e) => e.id == id);
    _all = List<ActiveOaesData>.unmodifiable(tmp);
    notifyListeners();
  }

  /// Busca por id com cache (opcional: tenta Firestore se não achar).
  Future<ActiveOaesData?> getById(String id) async {
    if (_byId.containsKey(id)) return _byId[id];

    // fallback direto ao Firestore (sem passar pelo bloc, para não precisar alterar o bloc)
    final snap = await FirebaseFirestore.instance.collection('actives_oaes').doc(id).get();
    if (!snap.exists) return null;

    final o = ActiveOaesData.fromDocument(snap);
    upsert(o);
    return o;
  }

  // ---------- AÇÕES (wrappers do Bloc) ----------
  Future<void> saveOrUpdate(ActiveOaesData data) async {
    await _bloc.saveOrUpdateOAE(data);
    upsert(data);
  }

  Future<void> delete(String id) async {
    await _bloc.deletarOAE(id);
    removeById(id);
  }

  // ---------- Filtros em memória ----------
  List<ActiveOaesData> filter({
    String? state,
    String? region,
    String? road,
    String? structureType,
    String? searchText,
  }) {
    Iterable<ActiveOaesData> r = _all;

    if (state != null && state.isNotEmpty) {
      r = r.where((e) => (e.state ?? '').toUpperCase() == state.toUpperCase());
    }
    if (region != null && region.isNotEmpty) {
      r = r.where((e) => (e.region ?? '').toUpperCase() == region.toUpperCase());
    }
    if (road != null && road.isNotEmpty) {
      r = r.where((e) => (e.road ?? '').toUpperCase() == road.toUpperCase());
    }
    if (structureType != null && structureType.isNotEmpty) {
      r = r.where((e) => (e.structureType ?? '').toUpperCase() == structureType.toUpperCase());
    }
    if (searchText != null && searchText.isNotEmpty) {
      final s = searchText.toUpperCase();
      r = r.where((e) =>
      (e.identificationName ?? '').toUpperCase().contains(s) ||
          (e.road ?? '').toUpperCase().contains(s) ||
          (e.region ?? '').toUpperCase().contains(s) ||
          (e.state ?? '').toUpperCase().contains(s));
    }

    final list = r.toList()..sort(_compare);
    return list;
  }

  // ---------- Utils ----------
  List<ActiveOaesData> _sorted(List<ActiveOaesData> list) {
    final l = List<ActiveOaesData>.of(list)..sort(_compare);
    return l;
  }

  int _compare(ActiveOaesData a, ActiveOaesData b) {
    // 1) order crescente (nulos por último)
    final ao = a.order ?? 1 << 30;
    final bo = b.order ?? 1 << 30;
    final byOrder = ao.compareTo(bo);
    if (byOrder != 0) return byOrder;

    // 2) identificationName alfabético (para desempate)
    final an = (a.identificationName ?? '').toUpperCase();
    final bn = (b.identificationName ?? '').toUpperCase();
    return an.compareTo(bn);
  }

  void _notifyAfterBuild() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }
}
