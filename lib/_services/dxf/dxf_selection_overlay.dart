// lib/_widgets/archives/dxf/widgets/dxf_selection_overlay.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:siged/_services/dxf/dxf_hit_tester.dart';
import 'package:siged/_services/dxf/dxf_model.dart';

class DxfSelectionOverlay extends StatelessWidget {
  final DxfModel? model;
  final DxfPick? pick;
  final Matrix4? modelToImage;
  final double screenScale; // ⬅️ novo

  const DxfSelectionOverlay({
    super.key,
    this.model,
    this.pick,
    this.modelToImage,
    this.screenScale = 1.0, // default
  });

  @override
  Widget build(BuildContext context) {
    if (model == null || pick == null || modelToImage == null) {
      return const SizedBox.shrink();
    }
    return CustomPaint(
      painter: _SelPainter(model!, pick!, modelToImage!, screenScale),
    );
  }
}


class _SelPainter extends CustomPainter {
  final DxfModel model;
  final DxfPick pick;
  final Matrix4 m2i;
  final double screenScale; // ⬅️ novo

  _SelPainter(this.model, this.pick, this.m2i, this.screenScale);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(m2i.storage);

    const desiredPx = 0.05; // ⬅️ quanto você quer na TELA
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.red
      ..strokeWidth = (desiredPx / (screenScale == 0 ? 1.0 : screenScale))
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (pick.kind) {
      case DxfEntityKind.line:
        final l = model.lines[pick.index];
        canvas.drawLine(l.a, l.b, paint);
        break;
      case DxfEntityKind.polyline:
        final pl = model.polylines[pick.index];
        final path = Path()..addPolygon(pl.points, pl.closed);
        canvas.drawPath(path, paint);
        break;
      case DxfEntityKind.circle:
        final c = model.circles[pick.index];
        canvas.drawCircle(c.center, c.r, paint);
        break;
      case DxfEntityKind.arc:
        final a = model.arcs[pick.index];
        final segs = math.max(12, (a.r * a.sweepRadians.abs() / 5).round());
        final pts = <Offset>[];
        for (int i = 0; i <= segs; i++) {
          final t = a.startRadians + a.sweepRadians * (i / segs);
          pts.add(a.center + Offset.fromDirection(t, a.r));
        }
        final path = Path()..addPolygon(pts, false);
        canvas.drawPath(path, paint);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SelPainter old) =>
      old.pick != pick || old.model != model || old.m2i != m2i || old.screenScale != screenScale;
}
