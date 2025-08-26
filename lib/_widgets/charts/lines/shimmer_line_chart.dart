import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer para o LineChart (estilo do seu BarChartShimmerWidget)
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LineChartShimmerWidget extends StatelessWidget {
  final int pointsCount;
  final double height;
  final String? chartTitle;

  const LineChartShimmerWidget({
    super.key,
    required this.pointsCount,
    this.height = 240,
    this.chartTitle,
  });

  @override
  Widget build(BuildContext context) {
    final gridColor = Colors.grey.shade200;
    final bg = Colors.white;
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;

    // pontos falsos (reprodutíveis)
    final rnd = Random(11);
    final fakeYs = List<double>.generate(pointsCount, (_) {
      return 0.2 + rnd.nextDouble() * 0.65; // 20%..85% da altura útil
    });

    // mesma lógica do LineChart real: ~50px por ponto, mínimo = largura da tela
    final larguraMinima = MediaQuery.of(context).size.width;
    final larguraTotal = max(pointsCount * 50.0, larguraMinima);

    return Card(
      color: bg,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chartTitle != null) ...[
              Center(
                child: Container(
                  height: 18,
                  width: 160,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                height: height,
                width: larguraTotal,
                child: Stack(
                  children: [
                    // grid horizontal
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          5,
                              (_) => Container(height: 1, color: gridColor),
                        ),
                      ),
                    ),
                    // eixo Y fake (ticks)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            5,
                                (_) => Container(
                              height: 10,
                              width: 34,
                              decoration: BoxDecoration(
                                color: base,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // curva/área/pontos com shimmer
                    Positioned.fill(
                      left: 42, // espaço do eixo Y falso
                      child: Shimmer.fromColors(
                        baseColor: base,
                        highlightColor: highlight,
                        child: CustomPaint(
                          painter: _LineSkeletonPainter(
                            fakeYs: fakeYs,
                            baseColor: base,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineSkeletonPainter extends CustomPainter {
  _LineSkeletonPainter({
    required this.fakeYs,
    required this.baseColor,
  });

  final List<double> fakeYs; // valores normalizados [0..1]
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (fakeYs.length < 2) return;

    const leftPad = 8.0;
    const rightPad = 8.0;
    const topPad = 12.0;
    const bottomPad = 24.0;

    final chart = Rect.fromLTWH(
      leftPad,
      topPad,
      size.width - leftPad - rightPad,
      size.height - topPad - bottomPad,
    );

    // pontos ao longo do eixo X
    final stepX = chart.width / (fakeYs.length - 1);
    final pts = <Offset>[];
    for (var i = 0; i < fakeYs.length; i++) {
      final x = chart.left + i * stepX;
      final y = chart.bottom - fakeYs[i].clamp(0.0, 1.0) * chart.height;
      pts.add(Offset(x, y));
    }

    // área
    final area = Path()..moveTo(pts.first.dx, chart.bottom);
    for (final p in pts) {
      area.lineTo(p.dx, p.dy);
    }
    area.lineTo(pts.last.dx, chart.bottom);
    area.close();

    final areaPaint = Paint()
      ..color = baseColor.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawPath(area, areaPaint);

    // linha
    final linePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      line.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(line, linePaint);

    // pontos espaçados
    final dotFill = Paint()..color = Colors.white;
    final dotStroke = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final step = max(1, (pts.length / 12).floor());
    for (var i = 0; i < pts.length; i += step) {
      canvas.drawCircle(pts[i], 3.5, dotFill);
      canvas.drawCircle(pts[i], 3.5, dotStroke);
      canvas.drawCircle(pts[i], 2.2, Paint()..color = baseColor);
    }
  }

  @override
  bool shouldRepaint(covariant _LineSkeletonPainter oldDelegate) {
    return oldDelegate.fakeYs != fakeYs ||
        oldDelegate.baseColor != baseColor;
  }
}
