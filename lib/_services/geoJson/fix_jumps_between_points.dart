import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import 'sanitizer_geometry.dart';

/// Verifica todos os docs de uma coleção com campo `points` e
/// corrige ordem/segmentação quando necessário.
/// Esquema esperado: points: [ {latitude, longitude} ]  (ou GeoPoint)
Future<void> fixJumpsBetweenPoints({
  required String collectionPath,
  double maxJumpKm = 2.0,
}) async {
  final col = FirebaseFirestore.instance.collection(collectionPath);
  final snap = await col.get();

  for (final doc in snap.docs) {
    final data = doc.data();
    final raw = data['points'];
    if (raw == null || raw is! List || raw.length < 2) continue;

    final pts = <LatLng>[];
    for (final p in raw) {
      if (p is GeoPoint) {
        pts.add(LatLng(p.latitude, p.longitude));
      } else if (p is Map && p['latitude'] != null && p['longitude'] != null) {
        pts.add(LatLng(
          (p['latitude'] as num).toDouble(),
          (p['longitude'] as num).toDouble(),
        ));
      }
    }
    if (pts.length < 2) continue;

    final sanitized = sanitizePolyline(raw: pts, maxJumpKm: maxJumpKm);

    // Estratégia: pega o MAIOR segmento resultante e sobrescreve `points`.
    if (sanitized.segments.isEmpty) continue;
    sanitized.segments.sort((a, b) => b.length.compareTo(a.length));
    final maior = sanitized.segments.first;

    final novo = maior
        .map((p) => {'latitude': p.latitude, 'longitude': p.longitude})
        .toList();

    await doc.reference.update({'points': novo});
  }
}
