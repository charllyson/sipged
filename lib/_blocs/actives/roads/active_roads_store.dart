import 'package:flutter/foundation.dart';
import 'package:sisged/_blocs/actives/roads/active_road_bloc.dart';

import 'package:sisged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:sisged/_blocs/actives/roads/active_roads_data.dart';

/// Store de Rodovias:
/// - Cache em memória (lista e mapa por id)
/// - Carregamento idempotente (ensureLoaded) e refresh
/// - Upsert/Remove locais sem re-fetch
/// - Seleção de polyline (realça no mapa)
/// - Geração de polylines estilizadas delegada ao Bloc
class ActiveRoadsStore extends ChangeNotifier {
  ActiveRoadsStore({ActiveRoadsBloc? bloc}) : _bloc = bloc ?? ActiveRoadsBloc();

  final ActiveRoadsBloc _bloc;

  bool _loading = false;
  bool get loading => _loading;

  /// Lista total em memória (somente leitura)
  List<ActiveRoadsData> _all = const [];
  List<ActiveRoadsData> get all => _all;

  /// Atalho por id
  final Map<String, ActiveRoadsData> _byId = {};

  /// Polyline selecionada (para highlight)
  String? _selectedId;
  String? get selectedId => _selectedId;

  bool _initialized = false;

  /// Carrega 1x (ou reutiliza cache). Usa o normalizador do Bloc para MultiLineString.
  Future<void> ensureLoaded() async {
    if (_initialized && _all.isNotEmpty) return;
    await _loadInternal(normalize: true);
    _initialized = true;
  }

  /// Força recarregar do Firestore
  Future<void> refresh() async => _loadInternal(normalize: true);

  /// Salva/atualiza no Firestore e reflete localmente
  Future<void> saveOrUpdate(ActiveRoadsData data) async {
    await _bloc.saveOrUpdateRoad(data);
    upsert(data);
  }

  /// Remove no Firestore e localmente
  Future<void> deleteById(String id) async {
    await _bloc.deleteRoad(id);
    remove(id);
  }

  /// Importação em lote (quando usar seu utilitário de import)
  Future<void> importarRodoviasComCoordenadas({
    required List<Map<String, dynamic>> linhasPrincipais,
    required List<Map<String, dynamic>> subcolecoes,
  }) async {
    _loading = true; notifyListeners();
    try {
      await _bloc.importarRodoviasComCoordenadas(
        linhasPrincipais: linhasPrincipais,
        subcolecoes: subcolecoes,
      );
      await refresh();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  /// Seleciona uma polyline (id) para destacar
  void select(String? roadId) {
    _selectedId = roadId;
    _bloc.setSelectedPolyline(roadId);
    notifyListeners();
  }

  /// Polylines estilizadas para o mapa (usa dados atuais + seleção)
  List<TappableChangedPolyline> get polylines {
    return _bloc.gerarPolylinesEstilizadas(selectedId: _selectedId);
  }

  /// --------- Mutações locais ---------
  void upsert(ActiveRoadsData rd) {
    if (rd.id == null) return;
    final id = rd.id!;
    final list = [..._all];
    final idx = list.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      list[idx] = rd;
    } else {
      list.add(rd);
    }
    _applyList(list);
  }

  void remove(String id) {
    final list = [..._all]..removeWhere((e) => e.id == id);
    _applyList(list);
    if (_selectedId == id) _selectedId = null;
    notifyListeners();
  }

  // --------- Internals ---------
  Future<void> _loadInternal({bool normalize = false}) async {
    _loading = true; notifyListeners();
    try {
      if (normalize) {
        // usa a rotina do bloc que corrige MultiLineString -> LineString e
        // atualiza o Firestore quando necessário
        await _bloc.carregarRodoviasDoFirebase();
        final values = _bloc.roadDataMap.values.toList(growable: false);
        _applyList(values);
      } else {
        final list = await _bloc.getAllRoads();
        _applyList(list);
        // mantém o network interno do bloc coerente para que a estilização funcione
        _bloc.roadDataMap
          ..clear()
          ..addEntries(_all.where((e) => e.id != null).map((e) => MapEntry(e.id!, e)));
      }
    } finally {
      _loading = false; notifyListeners();
    }
  }

  void _applyList(List<ActiveRoadsData> list) {
    // ordena por acrônimo/rodovia + início (se existir)
    list.sort((a, b) {
      final aKey = '${a.acronym ?? ''}_${a.initialKm ?? 0}';
      final bKey = '${b.acronym ?? ''}_${b.initialKm ?? 0}';
      return aKey.compareTo(bKey);
    });
    _all = List.unmodifiable(list);
    _byId
      ..clear()
      ..addEntries(_all.where((e) => e.id != null).map((e) => MapEntry(e.id!, e)));
    // sincroniza fonte do bloc para geração de polylines
    _bloc.roadDataMap
      ..clear()
      ..addEntries(_byId.entries);
    notifyListeners();
  }
}
