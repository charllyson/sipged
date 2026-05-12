import 'dart:math' as math;

import 'package:flutter/material.dart';

class _Shimmer extends StatefulWidget {
  const _Shimmer({
    required this.child,
  });

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController.unbounded(vsync: this)
      ..repeat(
        min: 0,
        max: 1,
        period: const Duration(milliseconds: 1200),
      );
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
      child: widget.child,
      builder: (context, child) {
        final width = MediaQuery.of(context).size.width;
        final dx = (width * 2) * _ctrl.value - width;

        final gradient = LinearGradient(
          begin: Alignment(-1.0 + _ctrl.value * 2, 0),
          end: Alignment(1.0 + _ctrl.value * 2, 0),
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.25, 0.5, 0.75],
        );

        return ShaderMask(
          shaderCallback: (bounds) {
            return gradient.createShader(
              bounds.shift(Offset(dx, 0)),
            );
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

class _RadarSkeletonPainter extends CustomPainter {
  _RadarSkeletonPainter({
    required this.rings,
    required this.axes,
    required this.color,
    this.frameColor,
    this.radiusFactor = 0.85,
    this.gridStroke = 1.0,
    this.ringOpacity = 0.35,
    this.axisOpacity = 0.55,
  });

  final int rings;
  final int axes;
  final Color color;
  final Color? frameColor;

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

    for (var ring = 1; ring <= rings; ring++) {
      final t = ring / rings;
      final path = Path();

      for (var axis = 0; axis < axes; axis++) {
        final angle = -math.pi / 2 + (2 * math.pi * axis / axes);
        final px = center.dx + radius * t * math.cos(angle);
        final py = center.dy + radius * t * math.sin(angle);

        if (axis == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }

      path.close();

      canvas.drawPath(
        path,
        gridPaint..color = color.withValues(alpha: ringOpacity),
      );
    }

    for (var axis = 0; axis < axes; axis++) {
      final angle = -math.pi / 2 + (2 * math.pi * axis / axes);
      final px = center.dx + radius * math.cos(angle);
      final py = center.dy + radius * math.sin(angle);

      canvas.drawLine(
        center,
        Offset(px, py),
        gridPaint..color = color.withValues(alpha: axisOpacity),
      );
    }

    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = frameColor ?? color.withValues(alpha: 0.9);

    final framePath = Path();

    for (var axis = 0; axis < axes; axis++) {
      final angle = -math.pi / 2 + (2 * math.pi * axis / axes);
      final px = center.dx + radius * math.cos(angle);
      final py = center.dy + radius * math.sin(angle);

      if (axis == 0) {
        framePath.moveTo(px, py);
      } else {
        framePath.lineTo(px, py);
      }
    }

    framePath.close();
    canvas.drawPath(framePath, framePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarSkeletonPainter oldDelegate) {
    return oldDelegate.rings != rings ||
        oldDelegate.axes != axes ||
        oldDelegate.color != color ||
        oldDelegate.frameColor != frameColor ||
        oldDelegate.radiusFactor != radiusFactor ||
        oldDelegate.gridStroke != gridStroke ||
        oldDelegate.ringOpacity != ringOpacity ||
        oldDelegate.axisOpacity != axisOpacity;
  }
}

class RadarChartShimmer extends StatelessWidget {
  const RadarChartShimmer({
    super.key,
    required this.isDark,
    this.altura = 270,
    this.largura,
    this.legendItems = 0,
    this.axes = 6,
    this.rings = 6,
  });

  final bool isDark;
  final double altura;
  final double? largura;
  final int legendItems;
  final int axes;
  final int rings;

  @override
  Widget build(BuildContext context) {
    final gridColor = Colors.grey.shade400;
    final frameColor = Colors.grey.shade500;

    final int safeAxes = axes.clamp(3, 24);
    final int safeRings = rings.clamp(3, 12);

    final chartSkeleton = CustomPaint(
      painter: _RadarSkeletonPainter(
        rings: safeRings,
        axes: safeAxes,
        color: gridColor,
        frameColor: frameColor,
        radiusFactor: 0.86,
        gridStroke: 1.0,
        ringOpacity: 0.35,
        axisOpacity: 0.55,
      ),
      child: SizedBox(
        height: altura,
        width: largura ?? altura,
      ),
    );

    return _Shimmer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: chartSkeleton,
      ),
    );
  }
}