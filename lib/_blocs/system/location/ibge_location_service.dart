// lib/_blocs/system/location/ibge_location_service.dart

import 'dart:convert';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/system/location/ibge_localidade_data.dart';

class IBGELocationService {
  IBGELocationService();

  // ===========================================================================
  // BASE URL DO PROXY (Firebase Function)
  // - Se você NÃO passar --dart-define, usa esse fixo (produção)
  // - Se passar, ele sobrescreve (útil p/ emulator/local)
  // ===========================================================================
  static const String _proxyBase = String.fromEnvironment(
    'IBGE_PROXY_BASE_URL',
    defaultValue: 'https://ibgeproxy-tcje2gcwpa-uc.a.run.app',
  );

  Uri _proxyUri(String path) {
    final base = Uri.parse(_proxyBase);

    return base.replace(
      queryParameters: {
        'path': path,
      },
    );
  }

  Future<dynamic> _getJsonProxy(String path) async {
    final resp = await http
        .get(_proxyUri(path))
        .timeout(const Duration(seconds: 25));

    if (resp.statusCode != 200) {
      throw Exception(
        'Erro IBGE Proxy [$path]: ${resp.statusCode} | ${resp.body}',
      );
    }

    return jsonDecode(resp.body);
  }

  Future<String> _getTextProxy(String path) async {
    final resp = await http
        .get(_proxyUri(path))
        .timeout(const Duration(seconds: 25));

    if (resp.statusCode != 200) {
      throw Exception(
        'Erro IBGE Proxy [$path]: ${resp.statusCode} | ${resp.body}',
      );
    }

    return resp.body;
  }

  // ---------------------------------------------------------------------------
  // Cache interno simples
  // ---------------------------------------------------------------------------

  bool _statesLoaded = false;

  List<IBGELocationStateData> _states = [];

  final Map<int, List<IBGELocationData>> _municipiosByUfId = {};

  String _norm(String s) {
    return removeDiacritics(s)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toUpperCase();
  }

  // ---------------------------------------------------------------------------
  // 1) LOCALIDADES
  // ---------------------------------------------------------------------------

  Future<List<IBGELocationStateData>> fetchStates() async {
    final list =
    await _getJsonProxy('localidades/estados?orderBy=nome') as List<dynamic>;

    return list
        .map(
          (j) => IBGELocationStateData.fromJson(
        j as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<List<IBGELocationData>> fetchMunicipiosByUf(int ufCode) async {
    final list = await _getJsonProxy(
      'localidades/estados/$ufCode/municipios',
    ) as List<dynamic>;

    return list
        .map(
          (m) => IBGELocationData(
        idIbge: m['id'].toString(),
        nome: (m['nome'] ?? '').toString(),
      ),
    )
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchDistritosByMunicipio(
      String municipioId,
      ) async {
    final list = await _getJsonProxy(
      'localidades/municipios/$municipioId/distritos',
    ) as List<dynamic>;

    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchMesorregioesByUf(int ufCode) async {
    final list = await _getJsonProxy(
      'localidades/estados/$ufCode/mesorregioes',
    ) as List<dynamic>;

    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchMicrorregioesByUf(int ufCode) async {
    final list = await _getJsonProxy(
      'localidades/estados/$ufCode/microrregioes',
    ) as List<dynamic>;

    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchRegioes() async {
    final list = await _getJsonProxy('localidades/regioes') as List<dynamic>;

    return list.cast<Map<String, dynamic>>();
  }

  // ---------------------------------------------------------------------------
  // 2) MALHAS (POLÍGONOS)
  // ---------------------------------------------------------------------------

  Future<List<Polygon<Map<String, dynamic>>>> fetchMunicipioPolygonsByUf(
      int ufCode,
      ) async {
    final municipios = await fetchMunicipiosByUf(ufCode);

    if (municipios.isEmpty) {
      return const <Polygon<Map<String, dynamic>>>[];
    }

    final futures = municipios.map(_loadPolygonsForMunicipio).toList();

    final results = await Future.wait(futures);

    return results.expand((list) => list).toList(growable: false);
  }

  Future<IBGELocationDetailData> fetchMunicipioDetails(String idIbge) async {
    final decoded = await _getJsonProxy('localidades/municipios/$idIbge');

    if (decoded is List && decoded.isNotEmpty) {
      return IBGELocationDetailData.fromJson(
        decoded.first as Map<String, dynamic>,
      );
    }

    if (decoded is Map<String, dynamic>) {
      return IBGELocationDetailData.fromJson(decoded);
    }

    throw Exception('Resposta inesperada ao buscar município $idIbge');
  }

  Future<String> fetchMunicipioMalhaGeoJsonRaw(String idIbge) async {
    return _getTextProxy(
      'malhas/municipios/$idIbge?formato=application/vnd.geo+json&qualidade=minima',
    );
  }

  // ---------------------------------------------------------------------------
  // 4) Helpers públicos
  // ---------------------------------------------------------------------------

  List<String> get ufsSigla {
    return _states.map((s) => s.sigla.toUpperCase()).toList();
  }

  int? getUfIdBySigla(String sigla) {
    final s = sigla.trim().toUpperCase();

    final st = _states.firstWhere(
          (e) => e.sigla.toUpperCase() == s,
      orElse: () => const IBGELocationStateData(
        id: -1,
        sigla: '',
        nome: '',
      ),
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

    if (id == null) {
      return const <String>[];
    }

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

    final alvoNorm = municipiosAlvo
        .map(_norm)
        .where((s) => s.isNotEmpty)
        .toSet();

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
  // Helpers internos: malha GeoJSON -> Polygon nativo do flutter_map
  // ===========================================================================

  Future<List<Polygon<Map<String, dynamic>>>> _loadPolygonsForMunicipio(
      IBGELocationData municipio,
      ) async {
    final id = municipio.idIbge;
    final nome = municipio.nome;

    final path =
        'malhas/municipios/$id?formato=application/vnd.geo+json&qualidade=minima';

    try {
      final body = await _getTextProxy(path);

      final parsed = await compute<Map<String, dynamic>, List<Map<String, dynamic>>>(
        _parseGeoJsonToPolygonPayloadsCompute,
        {
          'body': body,
          'id': id,
          'nome': nome,
        },
      );

      return parsed
          .map(_polygonFromPayload)
          .whereType<Polygon<Map<String, dynamic>>>()
          .toList(growable: false);
    } catch (_) {
      return const <Polygon<Map<String, dynamic>>>[];
    }
  }

  Polygon<Map<String, dynamic>>? _polygonFromPayload(
      Map<String, dynamic> payload,
      ) {
    final id = payload['id']?.toString() ?? '';
    final nome = payload['nome']?.toString() ?? '';
    final titleNome = nome.trim().toUpperCase();

    final pointsRaw = payload['points'];

    if (pointsRaw is! List || pointsRaw.isEmpty) {
      return null;
    }

    final points = pointsRaw
        .whereType<Map>()
        .map(
          (p) => LatLng(
        (p['lat'] as num).toDouble(),
        (p['lng'] as num).toDouble(),
      ),
    )
        .toList(growable: false);

    if (points.length < 3) return null;

    final holesRaw = payload['holes'];

    final holes = <List<LatLng>>[];

    if (holesRaw is List) {
      for (final holeRaw in holesRaw) {
        if (holeRaw is! List) continue;

        final hole = holeRaw
            .whereType<Map>()
            .map(
              (p) => LatLng(
            (p['lat'] as num).toDouble(),
            (p['lng'] as num).toDouble(),
          ),
        )
            .toList(growable: false);

        if (hole.length >= 3) {
          holes.add(hole);
        }
      }
    }

    return Polygon<Map<String, dynamic>>(
      points: points,
      holePointsList: holes,
      color: Colors.blue.withOpacity(0.20),
      borderColor: Colors.blue.withOpacity(0.75),
      borderStrokeWidth: 1,
      label: titleNome,
      hitValue: {
        'idIbge': id,
        'nome': nome,
        'title': titleNome,
        'processo': titleNome,
        'properties': {
          'idIbge': id,
          'nome': nome,
          'title': titleNome,
          'processo': titleNome,
        },
      },
    );
  }
}

// ===========================================================================
// COMPUTE: retorna apenas payload serializável.
// Não retorna Polygon direto para evitar problema de isolate / objetos do Flutter.
// ===========================================================================

List<Map<String, dynamic>> _parseGeoJsonToPolygonPayloadsCompute(
    Map<String, dynamic> data,
    ) {
  final body = data['body'] as String;
  final id = data['id'] as String;
  final nome = data['nome'] as String;

  try {
    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      return const <Map<String, dynamic>>[];
    }

    final geometries = _extractGeometries(decoded);

    if (geometries.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final payloads = <Map<String, dynamic>>[];

    for (final geometry in geometries) {
      final ringsPayloads = _geometryToPolygonPayloads(
        geometry: geometry,
        id: id,
        nome: nome,
      );

      payloads.addAll(ringsPayloads);
    }

    return payloads;
  } catch (_) {
    return const <Map<String, dynamic>>[];
  }
}

List<Map<String, dynamic>> _extractGeometries(Map<String, dynamic> geo) {
  final type = geo['type']?.toString();

  if (type == 'FeatureCollection') {
    final features = geo['features'];

    if (features is! List || features.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    return features
        .whereType<Map>()
        .map((feature) => feature.cast<String, dynamic>())
        .map((feature) => feature['geometry'])
        .whereType<Map>()
        .map((geometry) => geometry.cast<String, dynamic>())
        .toList(growable: false);
  }

  if (type == 'Feature') {
    final geometry = geo['geometry'];

    if (geometry is Map) {
      return <Map<String, dynamic>>[
        geometry.cast<String, dynamic>(),
      ];
    }

    return const <Map<String, dynamic>>[];
  }

  if (type == 'Polygon' || type == 'MultiPolygon') {
    return <Map<String, dynamic>>[
      geo,
    ];
  }

  return const <Map<String, dynamic>>[];
}

List<Map<String, dynamic>> _geometryToPolygonPayloads({
  required Map<String, dynamic> geometry,
  required String id,
  required String nome,
}) {
  final type = geometry['type']?.toString();

  if (type == 'Polygon') {
    final coordinates = geometry['coordinates'];

    if (coordinates is! List || coordinates.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final payload = _polygonCoordinatesToPayload(
      coordinates: coordinates,
      id: id,
      nome: nome,
    );

    if (payload == null) {
      return const <Map<String, dynamic>>[];
    }

    return <Map<String, dynamic>>[payload];
  }

  if (type == 'MultiPolygon') {
    final multipolygon = geometry['coordinates'];

    if (multipolygon is! List || multipolygon.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final payloads = <Map<String, dynamic>>[];

    for (final polygonCoordinates in multipolygon) {
      if (polygonCoordinates is! List || polygonCoordinates.isEmpty) {
        continue;
      }

      final payload = _polygonCoordinatesToPayload(
        coordinates: polygonCoordinates,
        id: id,
        nome: nome,
      );

      if (payload != null) {
        payloads.add(payload);
      }
    }

    return payloads;
  }

  return const <Map<String, dynamic>>[];
}

Map<String, dynamic>? _polygonCoordinatesToPayload({
  required List<dynamic> coordinates,
  required String id,
  required String nome,
}) {
  if (coordinates.isEmpty) return null;

  final outerRingRaw = coordinates.first;

  if (outerRingRaw is! List || outerRingRaw.length < 3) {
    return null;
  }

  final outer = _ringToPointPayload(outerRingRaw);

  if (outer.length < 3) {
    return null;
  }

  final holes = <List<Map<String, double>>>[];

  for (int i = 1; i < coordinates.length; i++) {
    final holeRaw = coordinates[i];

    if (holeRaw is! List || holeRaw.length < 3) {
      continue;
    }

    final hole = _ringToPointPayload(holeRaw);

    if (hole.length >= 3) {
      holes.add(hole);
    }
  }

  return {
    'id': id,
    'nome': nome,
    'points': outer,
    'holes': holes,
  };
}

List<Map<String, double>> _ringToPointPayload(List<dynamic> ring) {
  final points = <Map<String, double>>[];

  for (final coord in ring) {
    if (coord is! List || coord.length < 2) {
      continue;
    }

    final lngRaw = coord[0];
    final latRaw = coord[1];

    if (lngRaw is! num || latRaw is! num) {
      continue;
    }

    points.add({
      'lat': latRaw.toDouble(),
      'lng': lngRaw.toDouble(),
    });
  }

  return points;
}