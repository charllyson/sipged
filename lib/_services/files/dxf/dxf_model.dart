import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';

class DxfModel {
  final List<DxfLine> lines;
  final List<DxfPolyline> polylines;
  final List<DxfCircle> circles;
  final List<DxfArc> arcs;

  DxfModel({
    required this.lines,
    required this.polylines,
    required this.circles,
    required this.arcs,
  });

  bool get isEmpty =>
      lines.isEmpty && polylines.isEmpty && circles.isEmpty && arcs.isEmpty;

  /// Bounds **preciso** por amostragem (evita áreas vazias enormes).
  Rect bounds() {
    Rect? r;

    void addPt(Offset p) {
      r = (r == null)
          ? Rect.fromLTWH(p.dx, p.dy, 0, 0)
          : r!.expandToInclude(Rect.fromLTWH(p.dx, p.dy, 0, 0));
    }

    for (final l in lines) {
      addPt(l.a); addPt(l.b);
    }

    for (final pl in polylines) {
      for (final p in pl.points) {
        addPt(p);
      }
    }

    // círculos: amostra 64 pontos
    for (final c in circles) {
      const n = 64;
      for (int i = 0; i < n; i++) {
        final t = (2 * math.pi) * (i / n);
        addPt(c.center + Offset.fromDirection(t, c.r));
      }
    }

    // arcos: amostra baseada no sweep
    for (final a in arcs) {
      final sweep = a.sweepRadians.abs();
      final n = math.max(16, (a.r * sweep / 5).round()); // suficiente p/ bounds
      for (int i = 0; i <= n; i++) {
        final t = a.startRadians + a.sweepRadians * (i / n);
        addPt(a.center + Offset.fromDirection(t, a.r));
      }
    }

    r ??= const Rect.fromLTWH(0, 0, 1, 1);
    return r!;
  }

  void drawOn(Canvas canvas, Paint stroke) {
    for (final l in lines) {
      canvas.drawLine(l.a, l.b, stroke);
    }
    for (final pl in polylines) {
      final p = Path()..addPolygon(pl.points, pl.closed);
      canvas.drawPath(p, stroke);
    }
    for (final c in circles) {
      canvas.drawCircle(c.center, c.r, stroke);
    }
    for (final a in arcs) {
      final segs = math.max(12, (a.r * (a.sweepRadians).abs() / 5).round());
      final pts = <Offset>[];
      for (int i = 0; i <= segs; i++) {
        final t = a.startRadians + a.sweepRadians * (i / segs);
        pts.add(a.center + Offset.fromDirection(t, a.r));
      }
      final p = Path()..addPolygon(pts, false);
      canvas.drawPath(p, stroke);
    }
  }

  static DxfModel parseAscii(String text) {
    final lines = const LineSplitter().convert(text);
    final n = lines.length;

    bool inEntities = false;
    String currType = '';
    final model = DxfModel(lines: [], polylines: [], circles: [], arcs: []);

    Offset? l10; Offset? l11;
    List<Offset> plPts = []; bool plClosed = false;
    Offset? cCenter; double cR = 0;
    Offset? aCenter; double aR = 0, aStart = 0, aEnd = 0;

    String secName = '';

    String val(int i) => (i < n) ? lines[i] : '';
    int toInt(String s) => int.tryParse(s.trim()) ?? 0;
    double toD(String s) => double.tryParse(s.trim()) ?? 0;

    for (int i = 0; i + 1 < n; i += 2) {
      final code = toInt(val(i));
      final v = val(i + 1).trim();

      if (code == 0) {
        // flush entidade anterior
        if (inEntities && currType.isNotEmpty) {
          switch (currType) {
            case 'LINE':
              if (l10 != null && l11 != null) model.lines.add(DxfLine(l10, l11));
              break;
            case 'LWPOLYLINE':
            case 'POLYLINE':
              if (plPts.isNotEmpty) model.polylines.add(DxfPolyline(List.of(plPts), plClosed));
              break;
            case 'CIRCLE':
              if (cCenter != null && cR > 0) model.circles.add(DxfCircle(cCenter, cR));
              break;
            case 'ARC':
              if (aCenter != null && aR > 0) model.arcs.add(DxfArc(aCenter, aR, aStart, aEnd));
              break;
          }
        }

        // nova entidade/section
        currType = '';
        if (v == 'SECTION') {
          secName = '';
        } else if (v == 'ENDSEC') {
          inEntities = false;
        } else if (v == 'EOF') {
          break;
        } else if (v == 'LINE' || v == 'LWPOLYLINE' || v == 'POLYLINE' || v == 'CIRCLE' || v == 'ARC') {
          currType = v;
          l10 = l11 = null;
          plPts = [];
          plClosed = false;
          cCenter = null; cR = 0;
          aCenter = null; aR = 0; aStart = 0; aEnd = 0;
        }
        continue;
      }

      if (code == 2) {
        if (secName.isEmpty) {
          secName = v.toUpperCase();
          inEntities = (secName == 'ENTITIES');
        }
      }
      if (!inEntities || currType.isEmpty) continue;

      switch (currType) {
        case 'LINE':
          if (code == 10) { final x = toD(v); final y = toD(val(i + 3)); l10 = Offset(x, y); }
          else if (code == 11) { final x = toD(v); final y = toD(val(i + 3)); l11 = Offset(x, y); }
          break;
        case 'LWPOLYLINE':
        case 'POLYLINE':
          if (code == 10) { final x = toD(v); final y = toD(val(i + 3)); plPts.add(Offset(x, y)); }
          else if (code == 70) { final flags = toInt(v); plClosed = (flags & 1) != 0; }
          break;
        case 'CIRCLE':
          if (code == 10) { final x = toD(v); final y = toD(val(i + 3)); cCenter = Offset(x, y); }
          else if (code == 40) { cR = toD(v); }
          break;
        case 'ARC':
          if (code == 10) { final x = toD(v); final y = toD(val(i + 3)); aCenter = Offset(x, y); }
          else if (code == 40) { aR = toD(v); }
          else if (code == 50) { aStart = toD(v); }
          else if (code == 51) { aEnd = toD(v); }
          break;
      }
    }

    // flush final
    if (inEntities && currType.isNotEmpty) {
      switch (currType) {
        case 'LINE':
          if (l10 != null && l11 != null) model.lines.add(DxfLine(l10, l11));
          break;
        case 'LWPOLYLINE':
        case 'POLYLINE':
          if (plPts.isNotEmpty) model.polylines.add(DxfPolyline(List.of(plPts), plClosed));
          break;
        case 'CIRCLE':
          if (cCenter != null && cR > 0) model.circles.add(DxfCircle(cCenter, cR));
          break;
        case 'ARC':
          if (aCenter != null && aR > 0) model.arcs.add(DxfArc(aCenter, aR, aStart, aEnd));
          break;
      }
    }

    return model;
  }

  static String tryDecode(Uint8List bytes) {
    try {
      return const Utf8Decoder(allowMalformed: true).convert(bytes);
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }
}

class DxfLine { final Offset a, b; DxfLine(this.a, this.b); }
class DxfPolyline { final List<Offset> points; final bool closed; DxfPolyline(this.points, this.closed); }
class DxfCircle { final Offset center; final double r; DxfCircle(this.center, this.r); }
class DxfArc {
  final Offset center; final double r; final double start; final double end;
  DxfArc(this.center, this.r, this.start, this.end);
  double get startRadians => start * math.pi / 180.0;
  double get endRadians => end * math.pi / 180.0;
  double get sweepRadians {
    double s = (end - start) * math.pi / 180.0;
    while (s > math.pi * 2) {
      s -= math.pi * 2;
    }
    while (s < -math.pi * 2) {
      s += math.pi * 2;
    }
    return s;
  }
}
