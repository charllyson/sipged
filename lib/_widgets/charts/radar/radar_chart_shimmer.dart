// lib/_widgets/charts/radar/radar_chart_shimmer.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shimmer genérico (sem dependências) usando ShaderMask.
class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child, this.speed = 1200});
  final Widget child;
  final int speed; // ms

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this)
      ..repeat(min: 0, max: 1, period: Duration(milliseconds: widget.speed));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final width = MediaQuery.of(context).size.width;
        final dx = (width * 2) * _ctrl.value - width;
        final gradient = LinearGradient(
          begin: Alignment(-1.0 + _ctrl.value * 2, 0),
          end: Alignment(1.0 + _ctrl.value * 2, 0),
          colors: [
            Colors.grey.shade400,
            Colors.grey.shade200,
            Colors.grey.shade400,
          ],
          stops: const [0.25, 0.5, 0.75],
        );
        return ShaderMask(
          shaderCallback: (bounds) =>
              gradient.createShader(bounds.shift(Offset(dx, 0))),
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Desenha a “teia” de radar (anéis + eixos) e a MOLDURA externa.
/// --- no painter: parâmetros de estilo ---
class _RadarSkeletonPainter extends CustomPainter {
  _RadarSkeletonPainter({
    required this.rings,
    required this.axes,
    required this.color,
    this.frameColor,
    this.frameStroke = 2.0,
    this.radiusFactor = 0.85,     // < novo: encurta o raio
    this.gridStroke = 1.0,        // < novo: traço da grade
    this.ringOpacity = 0.35,      // < novo: opacidade dos anéis
    this.axisOpacity = 0.55,      // < novo: opacidade dos eixos
  });

  final int rings;
  final int axes;
  final Color color;
  final Color? frameColor;
  final double frameStroke;

  final double radiusFactor;
  final double gridStroke;
  final double ringOpacity;
  final double axisOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 * radiusFactor;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = gridStroke
      ..color = color;

    // anéis
    for (var r = 1; r <= rings; r++) {
      final t = r / rings;
      final path = Path();
      for (var i = 0; i < axes; i++) {
        final ang = -math.pi / 2 + (2 * math.pi * i / axes);
        final px = center.dx + radius * t * math.cos(ang);
        final py = center.dy + radius * t * math.sin(ang);
        if (i == 0) path.moveTo(px, py); else path.lineTo(px, py);
      }
      path.close();
      canvas.drawPath(path, gridPaint..color = color.withOpacity(ringOpacity));
    }

    // eixos
    for (var i = 0; i < axes; i++) {
      final ang = -math.pi / 2 + (2 * math.pi * i / axes);
      final px = center.dx + radius * math.cos(ang);
      final py = center.dy + radius * math.sin(ang);
      canvas.drawLine(center, Offset(px, py),
          gridPaint..color = color.withOpacity(axisOpacity));
    }

    // moldura
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = frameStroke
      ..color = (frameColor ?? color.withOpacity(0.9));

    final framePath = Path();
    for (var i = 0; i < axes; i++) {
      final ang = -math.pi / 2 + (2 * math.pi * i / axes);
      final px = center.dx + radius * math.cos(ang);
      final py = center.dy + radius * math.sin(ang);
      if (i == 0) framePath.moveTo(px, py); else framePath.lineTo(px, py);
    }
    framePath.close();
    canvas.drawPath(framePath, framePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


/// Card com shimmer no estilo do RadarChartChanged
class RadarChartShimmer extends StatelessWidget {
  const RadarChartShimmer({
    super.key,
    this.altura = 260,
    this.largura,
    this.cardWidth,
    this.legendItems = 0,   // sem legenda no esqueleto do print
    this.axes = 6,          // hexágono como no print
    this.rings = 6,
  });

  final double altura;
  final double? largura;
  final double? cardWidth;
  final int legendItems;
  final int axes;
  final int rings;

  @override
  Widget build(BuildContext context) {
    final gridColor = Colors.grey.shade500;

    final chartSkeleton = CustomPaint(
      painter: _RadarSkeletonPainter(
        rings: rings,
        axes: axes,
        color: gridColor,
        frameColor: Colors.grey.shade500,
        radiusFactor: 0.86,
        gridStroke: 1.0,
        ringOpacity: 0.35,
        axisOpacity: 0.55,
      ),
      child: SizedBox(height: altura, width: largura ?? altura),
    );

    return SizedBox(
      width: cardWidth,
      child: Card(
        color: Colors.white,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _Shimmer(
            child: SizedBox(
              height: altura,
              width: largura ?? altura,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: chartSkeleton,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
