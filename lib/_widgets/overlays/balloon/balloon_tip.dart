import 'package:flutter/material.dart';

enum BalloonTipSide {
  top,
  bottom,
  left,
  right,
}

class BalloonTip extends CustomPainter {
  const BalloonTip({
    required this.color,
    required this.shadowColor,
    this.side = BalloonTipSide.top,
  });

  final Color color;
  final Color shadowColor;
  final BalloonTipSide side;

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPath = _buildPath(size);
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        2,
      );

    canvas.drawPath(
      shadowPath.shift(_shadowOffset),
      shadowPaint,
    );

    final path = _buildPath(size);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  Offset get _shadowOffset {
    switch (side) {
      case BalloonTipSide.top:
        return const Offset(0, 1);
      case BalloonTipSide.bottom:
        return const Offset(0, -1);
      case BalloonTipSide.left:
        return const Offset(1, 0);
      case BalloonTipSide.right:
        return const Offset(-1, 0);
    }
  }

  Path _buildPath(Size size) {
    switch (side) {
      case BalloonTipSide.top:
        return Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

      case BalloonTipSide.bottom:
        return Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width / 2, size.height)
          ..close();

      case BalloonTipSide.left:
        return Path()
          ..moveTo(0, size.height / 2)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, size.height)
          ..close();

      case BalloonTipSide.right:
        return Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(0, size.height)
          ..close();
    }
  }

  @override
  bool shouldRepaint(covariant BalloonTip oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.side != side;
  }
}