import 'dart:math' as math;
import 'package:flutter/material.dart';

class ScheduleCivilFitUtils {
  /// Centraliza e escala a imagem inteira para caber no viewport.
  static Matrix4 fitToViewportCentered({
    required Size imageSize,
    required Size viewportInner,
    double extraScale = 1.0,
  }) {
    final s0 = math.min(
      viewportInner.width / imageSize.width,
      viewportInner.height / imageSize.height,
    );
    final s = s0 * extraScale;

    final tx = (viewportInner.width - imageSize.width * s) / 2.0;
    final ty = (viewportInner.height - imageSize.height * s) / 2.0;

    return Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  /// Centraliza e escala um recorte (rect no espaço da imagem) para caber.
  static Matrix4 fitRectToViewport({
    required Rect rect,
    required Size viewportInner,
    double extraScale = 1.0,
  }) {
    final s0 = math.min(
      viewportInner.width / rect.width,
      viewportInner.height / rect.height,
    );
    final s = s0 * extraScale;

    final cx = (viewportInner.width - rect.width * s) / 2.0;
    final cy = (viewportInner.height - rect.height * s) / 2.0;
    final tx = cx - rect.left * s;
    final ty = cy - rect.top * s;

    return Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }
}