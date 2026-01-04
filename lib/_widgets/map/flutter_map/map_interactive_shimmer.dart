// lib/_widgets/map/shimmer/overview_dashboard_map_shimmer.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Shimmer usado no card do "Mapa das Regionais" da OverviewDashboardPage.
///
/// Não depende de nenhum pacote externo (tipo shimmer), usa apenas
/// ShaderMask + AnimationController.
class OverviewDashboardMapShimmer extends StatefulWidget {
  final double? height;

  const OverviewDashboardMapShimmer({
    super.key,
    this.height = 320,
  });

  @override
  State<OverviewDashboardMapShimmer> createState() =>
      _OverviewDashboardMapShimmerState();
}

class _OverviewDashboardMapShimmerState
    extends State<OverviewDashboardMapShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient _buildShimmerGradient(double t) {
    // t vai de 0 a 1 → deslocamos o highlight no eixo X
    final begin = Alignment(-1.0 - 0.5 + t * 2.0, 0.0);
    final end = Alignment(1.0 + 0.5 + t * 2.0, 0.0);

    return LinearGradient(
      begin: begin,
      end: end,
      colors: const [
        Color(0xFFE8ECFF),
        Color(0xFFF8F9FF),
        Color(0xFFE8ECFF),
      ],
      stops: const [0.1, 0.5, 0.9],
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = const Color(0xFFF5F3FF); // fundo lilás bem claro
    final borderRadius = BorderRadius.circular(16);

    return SizedBox(
      height: widget.height ?? 320,
      width: double.infinity,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        clipBehavior: Clip.antiAlias,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final gradient = _buildShimmerGradient(t);

            return ShaderMask(
              shaderCallback: (rect) {
                return gradient.createShader(rect);
              },
              blendMode: BlendMode.srcATop,
              child: Container(
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: borderRadius,
                ),
                child: _buildMapSkeleton(),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Pequenos "blocos" sugerindo o conteúdo do mapa e bordas.
  Widget _buildMapSkeleton() {
    return CustomPaint(
      painter: _MapSkeletonPainter(),
      child: const SizedBox.expand(),
    );
  }
}

/// Desenha alguns retângulos irregulares para dar sensação de polígonos/rodovias.
class _MapSkeletonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDBE0FF)
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = const Color(0xFFC3C8E8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Área central simulando o "bloco" de municípios
    final rectMain = Rect.fromLTWH(w * 0.25, h * 0.1, w * 0.5, h * 0.8);
    final rMain = RRect.fromRectAndRadius(rectMain, const Radius.circular(8));
    canvas.drawRRect(rMain, paint);
    canvas.drawRRect(rMain, border);

    // Alguns retângulos menores dentro, como se fossem polígonos
    void drawBlock(double x, double y, double ww, double hh) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, ww, hh),
        const Radius.circular(4),
      );
      canvas.drawRRect(r, paint);
      canvas.drawRRect(r, border);
    }

    final cols = 4;
    final rows = 3;
    final padX = rectMain.width * 0.04;
    final padY = rectMain.height * 0.06;
    final cellW = (rectMain.width - padX * (cols + 1)) / cols;
    final cellH = (rectMain.height - padY * (rows + 1)) / rows;

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        final jitterX = (i.isEven ? 0.0 : cellW * 0.12);
        final jitterY = (j.isOdd ? cellH * 0.08 : 0.0);

        final x = rectMain.left + padX * (i + 1) + cellW * i + jitterX;
        final y = rectMain.top + padY * (j + 1) + cellH * j + jitterY;
        final ww = cellW * (0.8 + (i % 2) * 0.2);
        final hh = cellH * (0.75 + (j % 2) * 0.2);

        drawBlock(
          math.min(x, rectMain.right - ww - padX),
          math.min(y, rectMain.bottom - hh - padY),
          ww,
          hh,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapSkeletonPainter oldDelegate) => false;
}
