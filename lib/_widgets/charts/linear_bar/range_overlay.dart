// lib/_widgets/charts/linear_bar/range_overlay.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/charts/linear_bar/dashed_vertical_lines_painter.dart';
import 'package:sipged/_widgets/charts/linear_bar/range_overlay_config.dart';

/// ✅ Overlay: faixa translúcida entre start/end + linhas verticais tracejadas + labels.
class RangeOverlay extends StatelessWidget {
  final RangeOverlayConfig config;
  final bool isDark;

  /// Se config.maxValue == null, usamos este valor (globalMax do gráfico).
  final double fallbackMax;

  const RangeOverlay({
    super.key,
    required this.config,
    required this.isDark,
    required this.fallbackMax,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final maxV = (config.maxValue ?? fallbackMax);
        if (maxV <= 0) return const SizedBox.shrink();

        final startPx =
            (config.startValue / maxV).clamp(0.0, 1.0) * c.maxWidth;
        final endPx = (config.endValue / maxV).clamp(0.0, 1.0) * c.maxWidth;

        final left = math.min(startPx, endPx);
        final right = math.max(startPx, endPx);

        if ((right - left) <= 1) return const SizedBox.shrink();

        final textStyle = config.labelStyle ??
            TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black.withValues(alpha: 0.95),
              shadows: const [
                Shadow(
                  blurRadius: 6,
                  offset: Offset(0, 1),
                  color: Color(0x66000000),
                )
              ],
            );

        return Stack(
          children: [
            // Faixa
            Positioned(
              left: left,
              width: right - left,
              top: 0,
              bottom: 0,
              child: Container(color: config.fillColor),
            ),

            // Linhas tracejadas
            Positioned.fill(
              child: CustomPaint(
                painter: DashedVerticalLinesPainter(
                  x1: left,
                  x2: right,
                  color: config.dashedLineColor,
                  strokeWidth: config.dashedStrokeWidth,
                  dashWidth: config.dashWidth,
                  dashGap: config.dashGap,
                ),
              ),
            ),

            // Labels (opcional)
            if (config.showLabels)
              Positioned(
                left: (left + 2).clamp(0.0, c.maxWidth),
                top: 0,
                child: Padding(
                  padding: config.labelPadding,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: (right - left - 4).clamp(0.0, c.maxWidth),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: Text(
                      config.format(config.startValue),
                      style: textStyle,
                    ),
                  ),
                ),
              ),
            if (config.showLabels)
              Positioned(
                left: (right - 2).clamp(0.0, c.maxWidth),
                top: 0,
                child: Transform.translate(
                  offset: const Offset(-1, 0),
                  child: Padding(
                    padding: config.labelPadding,
                    child: Text(
                      config.format(config.endValue),
                      style: textStyle,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
