import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'sigmine_data.dart';

class SigMineRepository {
  static const _base =
      'https://geo.anm.gov.br/arcgis/rest/services/SIGMINE/dados_anm/MapServer/0/query';

  // Cache simples em memória para melhorar performance
  final Map<String, List<SigMineData>> _cacheByUf = {};
  final Map<String, List<SigMineData>> _cacheByProcess = {};

  // -------------------- Consultas principais --------------------

  Future<List<SigMineData>> fetchByUF(String uf) async {
    final key = uf.toUpperCase();

    if (_cacheByUf.containsKey(key)) {
      return _cacheByUf[key]!;
    }

    final feats = await _fetchByWhere("UF='$key'");
    _cacheByUf[key] = feats;
    return feats;
  }

  Future<List<SigMineData>> fetchByNumeroAno(
      int numero, int ano) async {
    final where = 'NUMERO=$numero AND ANO=$ano';
    return _fetchByWhere(where);
  }

  Future<List<SigMineData>> fetchByProcesso(
      String processo) async {
    final normalized = processo.trim();
    if (_cacheByProcess.containsKey(normalized)) {
      return _cacheByProcess[normalized]!;
    }

    final safe = normalized.replaceAll("'", "''");
    final feats = await _fetchByWhere("PROCESSO='$safe'");
    _cacheByProcess[normalized] = feats;
    return feats;
  }

  Future<List<SigMineData>> _fetchByWhere(String where) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'where': where,
      'outFields': '*',
      'returnGeometry': 'true',
      'outSR': '4326',
      'f': 'json',
    });

    final res = await http
        .get(uri)
        .timeout(const Duration(seconds: 25));

    if (res.statusCode != 200) {
      throw Exception('Erro SIGMINE ${res.statusCode}');
    }
    return _parseFeatures(jsonDecode(res.body));
  }

  // -------------------- Parser --------------------

  List<SigMineData> _parseFeatures(Map<String, dynamic> data) {
    final feats = (data['features'] as List?) ?? [];
    final result = <SigMineData>[];

    for (final f in feats) {
      final attr = (f['attributes'] as Map?) ?? {};
      final geom = f['geometry'];
      final rings = (geom?['rings'] as List?) ?? [];
      if (rings.isEmpty) continue;

      // helpers robustos
      String? s0(Iterable keys) {
        for (final k in keys) {
          final v = attr[k];
          if (v == null) continue;
          final s = v.toString().trim();
          if (s.isNotEmpty) return s;
        }
        return null;
      }

      double? d(Iterable keys) {
        final s = s0(keys);
        if (s == null) return null;
        final ss = s.replaceAll(',', '.');
        return double.tryParse(ss);
      }

      final processo = s0(['PROCESSO']) ?? 'DESCONHECIDO';
      final fase =
      s0(['FASE', 'SITUACAO_FASE', 'SIT_FASE']);
      final subs =
      s0(['SUBS', 'SUBSTANCIA']);
      final titular =
      s0(['NOME', 'TITULAR']);
      final uso =
      s0(['USO', 'CLASSE_USO', 'CLASSE']);
      final uf = s0(['UF']);
      final areaHa =
      d(['AREA_HA', 'AREA_HA_DEC', 'AREA_HA_TXT', 'AREA']);
      final ultimoEvento = s0(
          ['ULT_EVENTO', 'ULTIMO_EVENTO', 'EVENTO_DESCR']);
      final dataUltEvento =
      s0(['DATA', 'DT_EVENTO', 'DATA_ULT_EVENTO']);
      final situacao = s0(['SITUACAO', 'STATUS']);

      for (final ring in rings) {
        final pts = (ring as List)
            .map<LatLng>((c) => LatLng(
          (c[1] as num).toDouble(), // lat
          (c[0] as num).toDouble(), // lng
        ))
            .toList();
        if (pts.length < 3) continue;

        final poly = Polygon(
          points: pts,
          color: const Color(0x223197F3),
          borderColor: const Color(0xFF1976D2),
          borderStrokeWidth: 1.0,
        );

        result.add(
          SigMineData(
            processo: processo,
            fase: fase,
            substancia: subs,
            titular: titular,
            uso: uso,
            uf: uf,
            areaHa: areaHa,
            ultimoEvento: ultimoEvento,
            dataUltEvento: dataUltEvento,
            situacao: situacao,
            polygon: poly,
            labelPoint: _centroidOf(pts),
          ),
        );
      }
    }
    return result;
  }

  // -------------------- Utilidades geométricas --------------------

  static LatLng _centroidOf(List<LatLng> pts) {
    double signedArea = 0, cx = 0, cy = 0;
    for (int i = 0, j = pts.length - 1;
    i < pts.length;
    j = i++) {
      final xi = pts[i].longitude, yi = pts[i].latitude;
      final xj = pts[j].longitude, yj = pts[j].latitude;
      final a = xj * yi - xi * yj;
      signedArea += a;
      cx += (xj + xi) * a;
      cy += (yj + yi) * a;
    }
    if (signedArea.abs() < 1e-9) {
      final mlat = pts.fold<double>(
          0, (s, p) => s + p.latitude) /
          pts.length;
      final mlng = pts.fold<double>(
          0, (s, p) => s + p.longitude) /
          pts.length;
      return LatLng(mlat, mlng);
    }
    signedArea *= 0.5;
    cx /= (6 * signedArea);
    cy /= (6 * signedArea);
    return LatLng(cy, cx);
  }

  /// Bounds de todas as feições (para fitCamera do mapa)
  static LatLngBounds boundsFromFeatures(
      List<SigMineData> features) {
    if (features.isEmpty) {
      return LatLngBounds(
        const LatLng(0, 0),
        const LatLng(0, 0),
      );
    }
    double minLat = double.infinity,
        maxLat = -double.infinity;
    double minLng = double.infinity,
        maxLng = -double.infinity;

    for (final f in features) {
      for (final p in f.polygon.points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
    }
    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }
}
