// lib/_blocs/modules/planning/geo/localidades/ibge_location_service.dart
import 'dart:convert';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_data.dart';
import 'package:sipged/_widgets/map/polygon/polygon_changed.dart';

class IBGELocationService {
  IBGELocationService();

  // ===========================================================================
  // ✅ BASE URL DO PROXY (Firebase Function)
  // - Se você NÃO passar --dart-define, usa esse fixo (produção)
  // - Se passar, ele sobrescreve (útil p/ emulator/local)
  // ===========================================================================
  static const String _proxyBase = String.fromEnvironment(
    'IBGE_PROXY_BASE_URL',
    defaultValue: 'https://ibgeproxy-tcje2gcwpa-uc.a.run.app',
  );

  Uri _proxyUri(String path) {
    final base = Uri.parse(_proxyBase);
    return base.replace(queryParameters: {'path': path});
  }

  Future<dynamic> _getJsonProxy(String path) async {
    final resp = await http.get(_proxyUri(path)).timeout(const Duration(seconds: 25));

    if (resp.statusCode != 200) {
      throw Exception('Erro IBGE Proxy [$path]: ${resp.statusCode} | ${resp.body}');
    }
    return jsonDecode(resp.body);
  }

  Future<String> _getTextProxy(String path) async {
    final resp = await http.get(_proxyUri(path)).timeout(const Duration(seconds: 25));

    if (resp.statusCode != 200) {
      throw Exception('Erro IBGE Proxy [$path]: ${resp.statusCode} | ${resp.body}');
    }
    return resp.body;
  }

  // ---------------------------------------------------------------------------
  // Cache interno simples (helpers)
  // ---------------------------------------------------------------------------
  bool _statesLoaded = false;
  List<IBGELocationStateData> _states = [];
  final Map<int, List<IBGELocationData>> _municipiosByUfId = {};

  String _norm(String s) =>
      removeDiacritics(s).replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();

  // ---------------------------------------------------------------------------
  // 1) LOCALIDADES
  // ---------------------------------------------------------------------------

  Future<List<IBGELocationStateData>> fetchStates() async {
    final list = await _getJsonProxy('localidades/estados?orderBy=nome') as List<dynamic>;

    return list
        .map((j) => IBGELocationStateData.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<IBGELocationData>> fetchMunicipiosByUf(int ufCode) async {
    final list =
    await _getJsonProxy('localidades/estados/$ufCode/municipios') as List<dynamic>;

    return list
        .map(
          (m) => IBGELocationData(
        idIbge: m['id'].toString(),
        nome: (m['nome'] ?? '').toString(),
      ),
    )
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchDistritosByMunicipio(String municipioId) async {
    final list =
    await _getJsonProxy('localidades/municipios/$municipioId/distritos') as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchMesorregioesByUf(int ufCode) async {
    final list =
    await _getJsonProxy('localidades/estados/$ufCode/mesorregioes') as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchMicrorregioesByUf(int ufCode) async {
    final list =
    await _getJsonProxy('localidades/estados/$ufCode/microrregioes') as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchRegioes() async {
    final list = await _getJsonProxy('localidades/regioes') as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  // ---------------------------------------------------------------------------
  // 2) MALHAS (POLÍGONOS)
  // ---------------------------------------------------------------------------

  Future<List<PolygonChanged>> fetchMunicipioPolygonsByUf(int ufCode) async {
    final municipios = await fetchMunicipiosByUf(ufCode);
    if (municipios.isEmpty) return const [];

    final futures = municipios.map((m) => _loadPolygonForMunicipio(m)).toList();
    final results = await Future.wait(futures);

    return results.whereType<PolygonChanged>().toList();
  }

  Future<IBGELocationDetailData> fetchMunicipioDetails(String idIbge) async {
    final decoded = await _getJsonProxy('localidades/municipios/$idIbge');

    if (decoded is List && decoded.isNotEmpty) {
      return IBGELocationDetailData.fromJson(decoded.first as Map<String, dynamic>);
    } else if (decoded is Map<String, dynamic>) {
      return IBGELocationDetailData.fromJson(decoded);
    } else {
      throw Exception('Resposta inesperada ao buscar município $idIbge');
    }
  }

  Future<String> fetchMunicipioMalhaGeoJsonRaw(String idIbge) async {
    return _getTextProxy(
      'malhas/municipios/$idIbge?formato=application/vnd.geo+json&qualidade=minima',
    );
  }

  // ---------------------------------------------------------------------------
  // 4) Helpers públicos
  // ---------------------------------------------------------------------------

  List<String> get ufsSigla => _states.map((s) => s.sigla.toUpperCase()).toList();

  int? getUfIdBySigla(String sigla) {
    final s = sigla.trim().toUpperCase();
    final st = _states.firstWhere(
          (e) => e.sigla.toUpperCase() == s,
      orElse: () => const IBGELocationStateData(id: -1, sigla: '', nome: ''),
    );
    if (st.id <= 0) return null;
    return st.id;
  }

  Future<void> ensureStatesLoaded() async {
    if (_statesLoaded && _states.isNotEmpty) return;
    _states = await fetchStates();
    _statesLoaded = true;
  }

  Future<List<String>> getMunicipiosByUfSigla(String ufSigla) async {
    await ensureStatesLoaded();

    final id = getUfIdBySigla(ufSigla);
    if (id == null) return const <String>[];

    final cached = _municipiosByUfId[id];
    if (cached != null && cached.isNotEmpty) {
      return cached.map((m) => m.nome).toList()..sort();
    }

    final municipios = await fetchMunicipiosByUf(id);
    _municipiosByUfId[id] = municipios;

    final nomes = municipios.map((m) => m.nome).toList()..sort();
    return nomes;
  }

  Future<int?> inferUfFromMunicipios(List<String> municipiosAlvo) async {
    if (municipiosAlvo.isEmpty) return null;

    await ensureStatesLoaded();

    final alvoNorm = municipiosAlvo.map(_norm).where((s) => s.isNotEmpty).toSet();
    if (alvoNorm.isEmpty) return null;

    int? bestUfId;
    int bestCount = 0;

    for (final uf in _states) {
      var lista = _municipiosByUfId[uf.id];
      if (lista == null || lista.isEmpty) {
        lista = await fetchMunicipiosByUf(uf.id);
        _municipiosByUfId[uf.id] = lista;
      }

      final nomesNorm = lista.map((m) => _norm(m.nome)).toSet();
      final intersec = nomesNorm.intersection(alvoNorm);
      final count = intersec.length;

      if (count > bestCount) {
        bestCount = count;
        bestUfId = uf.id;
      }
    }

    if (bestCount == 0) return null;
    return bestUfId;
  }

  // ===========================================================================
  // Helpers internos (malha -> PolygonChanged)
  // ===========================================================================
  Future<PolygonChanged?> _loadPolygonForMunicipio(IBGELocationData m) async {
    final id = m.idIbge;
    final nome = m.nome;

    final path = 'malhas/municipios/$id?formato=application/vnd.geo+json&qualidade=minima';

    try {
      final body = await _getTextProxy(path);

      final polygonChanged = await compute<Map<String, dynamic>, PolygonChanged?>(
        _parseGeoJsonToPolygonCompute,
        {
          'body': body,
          'id': id,
          'nome': nome,
        },
      );

      return polygonChanged;
    } catch (_) {
      return null;
    }
  }
}

PolygonChanged? _parseGeoJsonToPolygonCompute(Map<String, dynamic> data) {
  final body = data['body'] as String;
  final id = data['id'] as String;
  final nome = data['nome'] as String;

  try {
    final Map<String, dynamic> geo = jsonDecode(body);

    Map<String, dynamic> geometry;
    if (geo['type'] == 'FeatureCollection') {
      final features = geo['features'] as List?;
      if (features == null || features.isEmpty) return null;
      geometry = features.first['geometry'] as Map<String, dynamic>;
    } else if (geo['type'] == 'Feature') {
      geometry = geo['geometry'] as Map<String, dynamic>;
    } else {
      geometry = geo;
    }

    final points = _geometryToLatLng(geometry);
    if (points.isEmpty) return null;

    final polygon = Polygon(points: points);

    final props = <Map<String, dynamic>>[
      {'idIbge': id, 'nome': nome},
    ];

    final titleNome = nome.trim().toUpperCase();

    return PolygonChanged(
      polygon: polygon,
      title: titleNome,
      properties: props,
    );
  } catch (_) {
    return null;
  }
}

List<LatLng> _geometryToLatLng(Map<String, dynamic> geometry) {
  final String? type = geometry['type']?.toString();

  if (type == 'Polygon') {
    final List<dynamic> rings = geometry['coordinates'] as List<dynamic>;
    if (rings.isEmpty) return [];
    final List<dynamic> outerRing = rings.first as List<dynamic>;
    return outerRing
        .map<LatLng>(
          (coord) => LatLng(
        (coord[1] as num).toDouble(),
        (coord[0] as num).toDouble(),
      ),
    )
        .toList();
  } else if (type == 'MultiPolygon') {
    final List<dynamic> polys = geometry['coordinates'] as List<dynamic>;
    final List<LatLng> all = [];
    for (final poly in polys) {
      final List<dynamic> rings = poly as List<dynamic>;
      if (rings.isEmpty) continue;
      final List<dynamic> outerRing = rings.first as List<dynamic>;
      all.addAll(
        outerRing.map<LatLng>(
              (coord) => LatLng(
            (coord[1] as num).toDouble(),
            (coord[0] as num).toDouble(),
          ),
        ),
      );
    }
    return all;
  } else {
    return [];
  }
}
