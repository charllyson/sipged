import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Verifica saltos de distância entre pontos/segmentos e retorna os IDs
/// dos documentos que apresentam algum salto maior que [distanciaMaxEmKm].
///
/// Suporta:
/// - Rodovias: campo `points` = List<GeoPoint|{latitude,longitude}|[lon,lat]>
/// - Ferrovias: campo `multiLine` = List<List<[lon,lat]>> (GeoJSON-like) ou
///              List<List<GeoPoint|{latitude,longitude}|[lon,lat]>>
Future<List<String>> checkJumpsBetweenPoints({
  required String collectionPath,
  double distanciaMaxEmKm = 2.0,
}) async {
  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection(collectionPath).get();

  final distance = const Distance();
  final List<String> documentosComSaltos = [];

  for (final doc in snapshot.docs) {
    final data = doc.data();

    // 1) Tenta como rodovia: campo "points"
    final rawPoints = data['points'];
    bool possuiSalto = false;

    if (rawPoints is List && rawPoints.length >= 2) {
      final pontos = _asLatLngList(rawPoints);
      if (pontos.length >= 2) {
        if (_temSalto(pontos, distanciaMaxEmKm, distance, doc.id, trechoCodigo: data['roadCode'])) {
          documentosComSaltos.add(doc.id);
          possuiSalto = true;
        }
      }
    }

    // 2) Se não achou em "points", tenta como ferrovia: campo "multiLine"
    if (!possuiSalto) {
      final rawMulti = data['multiLine'];
      if (rawMulti is List && rawMulti.isNotEmpty) {
        // Cada item deve ser um segmento (lista de pontos)
        for (int s = 0; s < rawMulti.length; s++) {
          final segmentRaw = rawMulti[s];
          if (segmentRaw is List && segmentRaw.length >= 2) {
            final seg = _asLatLngList(segmentRaw);
            if (seg.length >= 2) {
              final achou = _temSalto(seg, distanciaMaxEmKm, distance, doc.id,
                  segmentoIndex: s, trechoCodigo: data['codigo'] ?? data['roadCode']);
              if (achou) {
                documentosComSaltos.add(doc.id);
                possuiSalto = true;
                break; // basta um salto no doc para marcar
              }
            }
          }
        }
      }
    }
  }

  print('🔍 Total de documentos com saltos > $distanciaMaxEmKm km: ${documentosComSaltos.length}');
  print('🆔 IDs: $documentosComSaltos');
  return documentosComSaltos;
}

/// Converte uma lista heterogênea de pontos (GeoPoint | {latitude,longitude} | [lon,lat]) para List<LatLng>.
List<LatLng> _asLatLngList(List<dynamic> list) {
  final out = <LatLng>[];
  for (final p in list) {
    if (p is GeoPoint) {
      out.add(LatLng(p.latitude, p.longitude));
    } else if (p is Map) {
      // {latitude, longitude} ou {lat, lng}
      final hasLatLon = p.containsKey('latitude') && p.containsKey('longitude');
      final hasLatLng = p.containsKey('lat') && p.containsKey('lng');
      if (hasLatLon) {
        final lat = (p['latitude'] as num).toDouble();
        final lon = (p['longitude'] as num).toDouble();
        out.add(LatLng(lat, lon));
      } else if (hasLatLng) {
        final lat = (p['lat'] as num).toDouble();
        final lon = (p['lng'] as num).toDouble();
        out.add(LatLng(lat, lon));
      }
    } else if (p is List && p.length >= 2) {
      // [lon, lat] (GeoJSON)
      final lon = _asDoubleSafe(p[0]);
      final lat = _asDoubleSafe(p[1]);
      if (lat != null && lon != null) {
        out.add(LatLng(lat, lon));
      }
    }
  }
  return out;
}

/// Checa se existe salto > distanciaMaxEmKm na sequência.
bool _temSalto(
    List<LatLng> pts,
    double distanciaMaxEmKm,
    Distance distance,
    String docId, {
      int? segmentoIndex,
      Object? trechoCodigo,
    }) {
  for (int i = 0; i < pts.length - 1; i++) {
    final d = distance.as(LengthUnit.Kilometer, pts[i], pts[i + 1]);
    if (d > distanciaMaxEmKm) {
      final trecho = trechoCodigo ?? '--';
      final segTxt = (segmentoIndex == null) ? '' : ' [segmento $segmentoIndex]';
      print(
        '🚨 Doc $docId$segTxt (trecho $trecho) salto de ${d.toStringAsFixed(2)} km '
            'entre pontos $i e ${i + 1}',
      );
      return true;
    }
  }
  return false;
}

double? _asDoubleSafe(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.'));
  return null;
}
