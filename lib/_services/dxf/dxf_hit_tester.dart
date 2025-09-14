import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dxf_model.dart';

enum DxfEntityKind { line, polyline, circle, arc }

class DxfPick {
  final DxfEntityKind kind;
  final int index;
  final double distance; // em unidades do MODELO
  const DxfPick(this.kind, this.index, this.distance);
}

class DxfHitTester {
  final DxfModel model;
  DxfHitTester(this.model);

  static double _distPointToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a, ap = p - a;
    final ab2 = ab.dx*ab.dx + ab.dy*ab.dy;
    if (ab2 == 0) return (p - a).distance;
    final t = (ap.dx*ab.dx + ap.dy*ab.dy) / ab2;
    if (t <= 0) return (p - a).distance;
    if (t >= 1) return (p - b).distance;
    final proj = Offset(a.dx + t*ab.dx, a.dy + t*ab.dy);
    return (p - proj).distance;
  }

  static Iterable<List<Offset>> _arcSegments(DxfArc a) sync* {
    final sweep = a.sweepRadians.abs();
    final n = math.max(12, (a.r * sweep / 5).round());
    Offset pt(double t) => a.center + Offset.fromDirection(t, a.r);
    double t0 = a.startRadians;
    for (int i = 0; i < n; i++) {
      final t1 = a.startRadians + a.sweepRadians * ((i + 1) / n);
      yield [pt(t0), pt(t1)];
      t0 = t1;
    }
  }

  DxfPick? pickFirst(Offset modelPoint, {required double tolModel}) {
    DxfPick? best;
    void consider(DxfEntityKind k, int idx, double d) {
      if (d <= tolModel && (best == null || d < best!.distance)) {
        best = DxfPick(k, idx, d);
      }
    }

    for (int i = 0; i < model.lines.length; i++) {
      final l = model.lines[i];
      consider(DxfEntityKind.line, i, _distPointToSegment(modelPoint, l.a, l.b));
    }

    for (int i = 0; i < model.polylines.length; i++) {
      final pl = model.polylines[i];
      final pts = pl.points;
      for (int j = 0; j < pts.length - 1; j++) {
        consider(DxfEntityKind.polyline, i, _distPointToSegment(modelPoint, pts[j], pts[j+1]));
      }
      if (pl.closed && pts.length > 2) {
        consider(DxfEntityKind.polyline, i, _distPointToSegment(modelPoint, pts.last, pts.first));
      }
    }

    for (int i = 0; i < model.circles.length; i++) {
      final c = model.circles[i];
      final d = ((modelPoint - c.center).distance - c.r).abs();
      consider(DxfEntityKind.circle, i, d);
    }

    for (int i = 0; i < model.arcs.length; i++) {
      final a = model.arcs[i];
      for (final seg in _arcSegments(a)) {
        consider(DxfEntityKind.arc, i, _distPointToSegment(modelPoint, seg[0], seg[1]));
      }
    }

    return best;
  }
}
