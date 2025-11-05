import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SigmineFeature {
  final String processo;
  final String? fase;
  final String? substancia;
  final String? titular;

  // 🔎 Campos extras para o painel
  final String? uso;
  final double? areaHa;
  final String? uf;
  final String? ultimoEvento; // texto completo do último evento
  final String? dataUltEvento; // data isolada, se vier separada
  final String? situacao;

  /// Polígono bruto (sem estilo; a cor será definida na camada de UI)
  final Polygon polygon;

  /// Ponto para ancorar tooltip/label
  final LatLng labelPoint;

  SigmineFeature({
    required this.processo,
    required this.polygon,
    required this.labelPoint,
    this.fase,
    this.substancia,
    this.titular,
    this.uso,
    this.areaHa,
    this.uf,
    this.ultimoEvento,
    this.dataUltEvento,
    this.situacao,
  });
}

class SigmineService {
  static const _base =
      'https://geo.anm.gov.br/arcgis/rest/services/SIGMINE/dados_anm/MapServer/0/query';

  // -------------------- Consultas --------------------

  static Future<List<SigmineFeature>> fetchByUF(String uf) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'where': "UF='${uf.toUpperCase()}'",
      'outFields': '*',
      'returnGeometry': 'true',
      'outSR': '4326',
      'f': 'json',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Erro SIGMINE ${res.statusCode}');
    }
    return _parseFeatures(jsonDecode(res.body));
  }

  static Future<List<SigmineFeature>> fetchByNumeroAno(int numero, int ano) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'where': 'NUMERO=$numero AND ANO=$ano',
      'outFields': '*',
      'returnGeometry': 'true',
      'outSR': '4326',
      'f': 'json',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Erro SIGMINE ${res.statusCode}');
    }
    return _parseFeatures(jsonDecode(res.body));
  }

  static Future<List<SigmineFeature>> fetchByProcesso(String processo) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      "where": "PROCESSO='${processo.replaceAll("'", "''")}'",
      'outFields': '*',
      'returnGeometry': 'true',
      'outSR': '4326',
      'f': 'json',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Erro SIGMINE ${res.statusCode}');
    }
    return _parseFeatures(jsonDecode(res.body));
  }

  // -------------------- Parser --------------------

  static List<SigmineFeature> _parseFeatures(Map<String, dynamic> data) {
    final feats = (data['features'] as List?) ?? [];
    final result = <SigmineFeature>[];

    for (final f in feats) {
      final attr = (f['attributes'] as Map?) ?? {};
      final geom = f['geometry'];
      final rings = (geom?['rings'] as List?) ?? [];
      if (rings.isEmpty) continue;

      // helpers de leitura robusta (campos podem variar)
      String? _s(Iterable keys) {
        for (final k in keys) {
          final v = attr[k];
          if (v == null) continue;
          final s = v.toString().trim();
          if (s.isNotEmpty) return s;
        }
        return null;
      }

      double? _d(Iterable keys) {
        final s = _s(keys);
        if (s == null) return null;
        final ss = s.replaceAll(',', '.');
        return double.tryParse(ss);
      }

      final processo = _s(['PROCESSO']) ?? 'DESCONHECIDO';
      final fase = _s(['FASE', 'SITUACAO_FASE', 'SIT_FASE']);
      final subs = _s(['SUBS', 'SUBSTANCIA']);
      final titular = _s(['NOME', 'TITULAR']);
      final uso = _s(['USO', 'CLASSE_USO', 'CLASSE']);
      final uf = _s(['UF']);
      final areaHa = _d(['AREA_HA', 'AREA_HA_DEC', 'AREA_HA_TXT', 'AREA']);
      final ultimoEvento = _s(['ULT_EVENTO', 'ULTIMO_EVENTO', 'EVENTO_DESCR']);
      final dataUltEvento = _s(['DATA', 'DT_EVENTO', 'DATA_ULT_EVENTO']);
      final situacao = _s(['SITUACAO', 'STATUS']);

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
          SigmineFeature(
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

  // -------------------- Utilidades --------------------

  static LatLng _centroidOf(List<LatLng> pts) {
    double signedArea = 0, cx = 0, cy = 0;
    for (int i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      final xi = pts[i].longitude, yi = pts[i].latitude;
      final xj = pts[j].longitude, yj = pts[j].latitude;
      final a = xj * yi - xi * yj;
      signedArea += a;
      cx += (xj + xi) * a;
      cy += (yj + yi) * a;
    }
    if (signedArea.abs() < 1e-9) {
      final mlat = pts.fold<double>(0, (s, p) => s + p.latitude) / pts.length;
      final mlng = pts.fold<double>(0, (s, p) => s + p.longitude) / pts.length;
      return LatLng(mlat, mlng);
    }
    signedArea *= 0.5;
    cx /= (6 * signedArea);
    cy /= (6 * signedArea);
    return LatLng(cy, cx);
  }

  static LatLngBounds boundsFromFeatures(List<SigmineFeature> features) {
    if (features.isEmpty) {
      return LatLngBounds(const LatLng(0, 0), const LatLng(0, 0));
    }
    double minLat = double.infinity, maxLat = -double.infinity;
    double minLng = double.infinity, maxLng = -double.infinity;

    for (final f in features) {
      for (final p in f.polygon.points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
    }
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }
}
