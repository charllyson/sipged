// lib/_widgets/charts/gauge/gauge_circular_percent_shimmer.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class GaugeCircularPercentShimmer extends StatelessWidget {
  final double radius;
  final double? centerFontSize;
  final double? footerFontSize;

  const GaugeCircularPercentShimmer({
    super.key,
    this.radius = 60.0,
    this.centerFontSize,
    this.footerFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;

    final double circleSize = radius * 2 + 40;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Header fake
        Container(
          height: 14,
          width: 120,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 16),
        // Círculo com shimmer
        Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: SizedBox(
            width: circleSize,
            height: circleSize,
            child: CustomPaint(
              painter: _GaugeCircleSkeletonPainter(
                trackColor: base,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Footer fake
        Container(
          height: 14,
          width: 100,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}

class _GaugeCircleSkeletonPainter extends CustomPainter {
  final Color trackColor;

  _GaugeCircleSkeletonPainter({required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide / 2) - 10;

    // trilho (background) grosso
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    // arco (quase completo)
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -3.14 / 2,
      3.14 * 1.7, // um pouco menos que o círculo total
      false,
      trackPaint,
    );

    // círculo central sugerindo o "valor" no meio
    final innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.35, innerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant _GaugeCircleSkeletonPainter oldDelegate) =>
      oldDelegate.trackColor != trackColor;
}
