// lib/_blocs/modules/planning/geo/localidades/ibge_location_service.dart
import 'dart:convert';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:siged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_data.dart';
import 'package:siged/_widgets/map/polygon/polygon_changed.dart';

/// ============================================================================
/// SERVICE PRINCIPAL (LOCALIDADES + MALHAS)
/// ============================================================================
///
/// Core de localidades (UF, municípios, meso/micro, distritos) + malhas.
/// Também incorpora helpers tipo "inferUfFromMunicipios", que antes ficavam
/// em um serviço separado.
class IBGELocationService {
  IBGELocationService();

  // ---------------------------------------------------------------------------
  // Cache interno simples (somente para helpers de localidades)
  // ---------------------------------------------------------------------------

  bool _statesLoaded = false;
  List<IBGELocationStateData> _states = [];
  final Map<int, List<IBGELocationData>> _municipiosByUfId = {};

  String _norm(String s) =>
      removeDiacritics(s).replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();

  // ---------------------------------------------------------------------------
  // Helper genérico HTTP
  // ---------------------------------------------------------------------------

  Future<dynamic> _getJson(String url) async {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      throw Exception('Erro IBGE [$url]: ${resp.statusCode}');
    }
    return jsonDecode(resp.body);
  }

  // ---------------------------------------------------------------------------
  // 1) LOCALIDADES: UFs, Municípios, Distritos...
  // ---------------------------------------------------------------------------

  /// Lista de estados (ordenados por nome)
  Future<List<IBGELocationStateData>> fetchStates() async {
    const url =
        'https://servicodados.ibge.gov.br/api/v1/localidades/estados?orderBy=nome';

    final List<dynamic> list = await _getJson(url) as List<dynamic>;
    return list
        .map((j) => IBGELocationStateData.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Lista de municípios de um estado (UF) pelo código (ex: 27 = AL)
  Future<List<IBGELocationData>> fetchMunicipiosByUf(
      int ufCode) async {
    final url =
        'https://servicodados.ibge.gov.br/api/v1/localidades/estados/$ufCode/municipios';

    final List<dynamic> list = await _getJson(url) as List<dynamic>;
    return list
        .map(
          (m) => IBGELocationData(
        idIbge: m['id'].toString(),
        nome: (m['nome'] ?? '').toString(),
      ),
    )
        .toList();
  }

  /// Lista de distritos de um município específico
  ///
  /// Endpoint: /localidades/municipios/{id}/distritos
  Future<List<Map<String, dynamic>>> fetchDistritosByMunicipio(
      String municipioId,
      ) async {
    final url =
        'https://servicodados.ibge.gov.br/api/v1/localidades/municipios/$municipioId/distritos';

    final List<dynamic> list = await _getJson(url) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// Lista de mesorregiões de uma UF
  ///
  /// Endpoint: /localidades/estados/{id}/mesorregioes
  Future<List<Map<String, dynamic>>> fetchMesorregioesByUf(int ufCode) async {
    final url =
        'https://servicodados.ibge.gov.br/api/v1/localidades/estados/$ufCode/mesorregioes';

    final List<dynamic> list = await _getJson(url) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// Lista de microrregiões de uma UF
  ///
  /// Endpoint: /localidades/estados/{id}/microrregioes
  Future<List<Map<String, dynamic>>> fetchMicrorregioesByUf(int ufCode) async {
    final url =
        'https://servicodados.ibge.gov.br/api/v1/localidades/estados/$ufCode/microrregioes';

    final List<dynamic> list = await _getJson(url) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// Lista de regiões do Brasil (Norte, Nordeste, etc.)
  Future<List<Map<String, dynamic>>> fetchRegioes() async {
    const url =
        'https://servicodados.ibge.gov.br/api/v1/localidades/regioes';

    final List<dynamic> list = await _getJson(url) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  // ---------------------------------------------------------------------------
  // 2) MALHAS (POLÍGONOS) – MUNICÍPIOS POR UF
  // ---------------------------------------------------------------------------

  /// Malhas (polígonos) dos municípios de um estado em formato PolygonChanged
  ///
  /// Otimizações:
  ///  - Requisições em paralelo (Future.wait)
  ///  - Parsing pesado de GeoJSON em outro isolate (compute)
  Future<List<PolygonChanged>> fetchMunicipioPolygonsByUf(int ufCode) async {
    final municipios = await fetchMunicipiosByUf(ufCode);

    if (municipios.isEmpty) return const [];

    final futures =
    municipios.map((m) => _loadPolygonForMunicipio(m)).toList();

    final results = await Future.wait(futures);

    return results.whereType<PolygonChanged>().toList();
  }

  /// 🔍 Detalhes completos de um município por ID IBGE
  ///
  /// Usa o endpoint /localidades/municipios/{id}
  Future<IBGELocationDetailData> fetchMunicipioDetails(
      String idIbge,
      ) async {
    final url =
        'https://servicodados.ibge.gov.br/api/v1/localidades/municipios/$idIbge';

    final dynamic decoded = await _getJson(url);

    // Por segurança, trata tanto objeto único quanto lista com 1 elemento
    if (decoded is List && decoded.isNotEmpty) {
      return IBGELocationDetailData.fromJson(
        decoded.first as Map<String, dynamic>,
      );
    } else if (decoded is Map<String, dynamic>) {
      return IBGELocationDetailData.fromJson(decoded);
    } else {
      throw Exception('Resposta inesperada ao buscar município $idIbge');
    }
  }

  // ---------------------------------------------------------------------------
  // 3) MALHA BRUTA COMO GEOJSON (para debug/download)
  // ---------------------------------------------------------------------------

  /// Retorna o GeoJSON bruto da malha de um município (string).
  ///
  /// Útil se você quiser salvar em arquivo ou fazer parsing customizado.
  Future<String> fetchMunicipioMalhaGeoJsonRaw(String idIbge) async {
    final malhaUrl =
        'https://servicodados.ibge.gov.br/api/v3/malhas/municipios/$idIbge'
        '?formato=application/vnd.geo+json&qualidade=minima';

    final resp = await http
        .get(Uri.parse(malhaUrl))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      throw Exception(
        'Erro ao buscar malha do município $idIbge: ${resp.statusCode}',
      );
    }
    return resp.body;
  }

  // ---------------------------------------------------------------------------
  // 4) Helpers públicos (UFs, inferência, etc.)
  // ---------------------------------------------------------------------------

  List<String> get ufsSigla =>
      _states.map((s) => s.sigla.toUpperCase()).toList();

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

  /// 🔍 Descobre automaticamente a UF com base nos nomes de municípios
  /// (escolhe a UF com MAIOR número de matches).
  Future<int?> inferUfFromMunicipios(List<String> municipiosAlvo) async {
    if (municipiosAlvo.isEmpty) return null;

    await ensureStatesLoaded();

    final alvoNorm =
    municipiosAlvo.map(_norm).where((s) => s.isNotEmpty).toSet();
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

    // se não encontrou nenhum match, retorna null
    if (bestCount == 0) return null;

    return bestUfId;
  }
}

// ============================================================================
// Helpers top-level para poderem ser usados com compute (Isolate)
// ============================================================================

Future<PolygonChanged?> _loadPolygonForMunicipio(
    IBGELocationData m,
    ) async {
  final id = m.idIbge;
  final nome = m.nome;

  final malhaUrl =
      'https://servicodados.ibge.gov.br/api/v3/malhas/municipios/$id'
      '?formato=application/vnd.geo+json&qualidade=minima';

  try {
    final malhaResp = await http
        .get(Uri.parse(malhaUrl))
        .timeout(const Duration(seconds: 15));

    if (malhaResp.statusCode != 200) {
      return null;
    }

    final polygonChanged =
    await compute<Map<String, dynamic>, PolygonChanged?>(
      _parseGeoJsonToPolygonCompute,
      {
        'body': malhaResp.body,
        'id': id,
        'nome': nome,
      },
    );

    return polygonChanged;
  } catch (_) {
    return null;
  }
}

/// Função usada pelo compute.
/// Recebe um map com body/id/nome e devolve PolygonChanged ou null.
PolygonChanged? _parseGeoJsonToPolygonCompute(
    Map<String, dynamic> data,
    ) {
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
      {
        'idIbge': id,
        'nome': nome,
      },
    ];

    // 🔹 Normaliza o nome para casar com o que você usa no dashboard/mapa
    // (se quiser remover acentos, pode usar diacritic aqui também)
    final titleNome = nome.trim().toUpperCase();

    return PolygonChanged(
      polygon: polygon,
      // title agora é o NOME do município
      title: titleNome,
      properties: props,
    );
  } catch (_) {
    return null;
  }
}


// ---------- Helpers internos ----------

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
