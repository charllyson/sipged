import 'package:latlong2/latlong.dart';

class SanitizedGeometry {
  /// Segmentos prontos para salvar: cada segmento é um LineString.
  final List<List<LatLng>> segments;

  /// Métricas úteis pra logs/UI.
  final int forwardLongJumps;
  final int reverseLongJumps;
  final double forwardBadJumpKmSum;
  final double reverseBadJumpKmSum;

  SanitizedGeometry({
    required this.segments,
    required this.forwardLongJumps,
    required this.reverseLongJumps,
    required this.forwardBadJumpKmSum,
    required this.reverseBadJumpKmSum,
  });
}

final Distance _dist = const Distance();

double _km(LatLng a, LatLng b) => _dist.as(LengthUnit.Kilometer, a, b);
double _m(LatLng a, LatLng b) => _dist(a, b); // metros

/// Ordena por vizinho mais próximo (greedy). Opcionalmente aceita um ponto inicial.
List<LatLng> _nearestNeighborOrder(List<LatLng> pts, {LatLng? start}) {
  if (pts.isEmpty) return const [];
  final naoVisitados = List<LatLng>.from(pts);
  final ordered = <LatLng>[];

  LatLng atual = start != null
      ? naoVisitados.reduce((best, p) => _m(start, p) < _m(start, best) ? p : best)
      : naoVisitados.first;

  naoVisitados.remove(atual);
  ordered.add(atual);

  while (naoVisitados.isNotEmpty) {
    naoVisitados.sort((a, b) => _m(atual, a).compareTo(_m(atual, b)));
    atual = naoVisitados.removeAt(0);
    ordered.add(atual);
  }
  return ordered;
}

/// Conta saltos > [maxJumpKm] em uma sequência já ordenada
/// e soma os tamanhos (apenas dos saltos ruins).
({int jumps, double sumKm}) _countLongJumps(
    List<LatLng> ordered, {
      required double maxJumpKm,
    }) {
  int jumps = 0;
  double sum = 0;
  for (var i = 0; i < ordered.length - 1; i++) {
    final d = _km(ordered[i], ordered[i + 1]);
    if (d > maxJumpKm) {
      jumps++;
      sum += d;
    }
  }
  return (jumps: jumps, sumKm: sum);
}

/// Quebra uma sequência ordenada em segmentos sempre que houver salto > [maxJumpMeters].
List<List<LatLng>> _splitByJump(
    List<LatLng> ordered, {
      required double maxJumpMeters,
    }) {
  if (ordered.isEmpty) return const [];
  final segs = <List<LatLng>>[];
  var atual = <LatLng>[ordered.first];

  for (var i = 0; i < ordered.length - 1; i++) {
    final p = ordered[i];
    final q = ordered[i + 1];
    final d = _m(p, q);
    if (d <= maxJumpMeters) {
      atual.add(q);
    } else {
      if (atual.length >= 2) segs.add(atual);
      atual = <LatLng>[q];
    }
  }
  if (atual.length >= 2) segs.add(atual);
  return segs;
}

/// Saneia uma polyline crua:
/// 1) Ordena por vizinho mais próximo.
/// 2) Compara ida (forward) vs volta (reverse) e escolhe a que tem MENOS saltos longos
///    (empate: menor soma de km dos saltos).
/// 3) Segmenta onde ainda sobrar salto > [maxJumpKm] (em km).
SanitizedGeometry sanitizePolyline({
  required List<LatLng> raw,
  double maxJumpKm = 2.0,
}) {
  if (raw.length < 2) {
    return SanitizedGeometry(
      segments: raw.length < 2 ? const [] : [raw],
      forwardLongJumps: 0,
      reverseLongJumps: 0,
      forwardBadJumpKmSum: 0,
      reverseBadJumpKmSum: 0,
    );
  }

  final nn = _nearestNeighborOrder(raw);      // ordem base (forward)
  final nnRev = nn.reversed.toList();         // ordem invertida (reverse)

  final f = _countLongJumps(nn, maxJumpKm: maxJumpKm);
  final r = _countLongJumps(nnRev, maxJumpKm: maxJumpKm);

  final useReverse = (r.jumps < f.jumps) || (r.jumps == f.jumps && r.sumKm < f.sumKm);
  final chosen = useReverse ? nnRev : nn;

  final segments = _splitByJump(chosen, maxJumpMeters: maxJumpKm * 1000.0);

  return SanitizedGeometry(
    segments: segments,
    forwardLongJumps: f.jumps,
    reverseLongJumps: r.jumps,
    forwardBadJumpKmSum: double.parse(f.sumKm.toStringAsFixed(3)),
    reverseBadJumpKmSum: double.parse(r.sumKm.toStringAsFixed(3)),
  );
}
