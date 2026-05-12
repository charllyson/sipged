import 'dart:math' as math;

import 'package:flutter/material.dart';

enum TreemapShimDirection {
  vertical,
  horizontal,
}

class TreemapShimmer extends StatelessWidget {
  const TreemapShimmer({
    super.key,
    this.altura = 295.0,
    this.cardWidth,
    this.legendItems = 8,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.all(12),
    this.direction = TreemapShimDirection.horizontal,
    this.expandToMaxWidth = false,
    this.targetCellSide = 140,
    this.extraWidthFactor = 1.0,
  });

  final double altura;
  final double? cardWidth;
  final int legendItems;

  final double borderRadius;
  final EdgeInsets padding;

  final TreemapShimDirection direction;

  final bool expandToMaxWidth;

  final double targetCellSide;
  final double extraWidthFactor;

  double get _safeHeight {
    if (!altura.isFinite || altura.isNaN || altura <= 0) {
      return 295.0;
    }

    return altura.clamp(150.0, 3000.0).toDouble();
  }

  double? get _safeWidth {
    final width = cardWidth;

    if (width == null) {
      return null;
    }

    if (!width.isFinite || width.isNaN || width <= 0) {
      return null;
    }

    return width;
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: direction == TreemapShimDirection.horizontal
          ? _buildHorizontal(context)
          : _buildVertical(context),
    );

    return SizedBox(
      width: _safeWidth ?? double.infinity,
      child: content,
    );
  }

  Widget _buildHorizontal(BuildContext context) {
    return SizedBox(
      height: _safeHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;

          final viewportWidth =
          maxWidth.isFinite && !maxWidth.isNaN && maxWidth > 0
              ? maxWidth
              : (_safeWidth ?? 600.0);

          final safeExtraWidthFactor =
          extraWidthFactor.isFinite && !extraWidthFactor.isNaN
              ? extraWidthFactor.clamp(1.0, 4.0).toDouble()
              : 1.0;

          final baseWidth = expandToMaxWidth
              ? viewportWidth
              : math
              .max(
            viewportWidth,
            viewportWidth * safeExtraWidthFactor,
          )
              .clamp(
            viewportWidth,
            2600.0,
          )
              .toDouble();

          final grid = _Shimmer(
            child: CustomPaint(
              painter: _TreemapSkeletonPainter(
                base: _base(context),
                borderRadius: borderRadius,
              ),
              child: const SizedBox.expand(),
            ),
          );

          if (baseWidth <= viewportWidth + 1) {
            return SizedBox(
              width: viewportWidth,
              height: _safeHeight,
              child: grid,
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: baseWidth,
              height: _safeHeight,
              child: grid,
            ),
          );
        },
      ),
    );
  }

  Widget _buildVertical(BuildContext context) {
    final grid = _Shimmer(
      child: CustomPaint(
        painter: _TreemapSkeletonPainter(
          base: _base(context),
          borderRadius: borderRadius,
        ),
        child: const SizedBox.expand(),
      ),
    );

    return SizedBox(
      height: _safeHeight,
      width: double.infinity,
      child: grid,
    );
  }

  Color _base(BuildContext context) {
    return Colors.grey.shade300;
  }
}

class _TreemapSkeletonPainter extends CustomPainter {
  _TreemapSkeletonPainter({
    required this.base,
    required this.borderRadius,
  });

  final Color base;
  final double borderRadius;

  static const double _gap = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (!_isValidSize(size)) {
      return;
    }

    final paint = Paint()
      ..color = base
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final rects = _buildTreemapRects(size);

    for (final rect in rects) {
      final safeRect = _safeDeflate(rect, _gap / 2);

      if (!_isValidRect(safeRect)) {
        continue;
      }

      final radius = Radius.circular(
        math.min(
          borderRadius,
          math.min(safeRect.width, safeRect.height) / 3,
        ),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          safeRect,
          radius,
        ),
        paint,
      );
    }
  }

  List<Rect> _buildTreemapRects(Size size) {
    final width = size.width;
    final height = size.height;

    final rects = <Rect>[];

    final leftW = width * 0.36;
    final middleW = width * 0.27;
    final rightW = width * 0.30;
    final sideW = width - leftW - middleW - rightW;

    final leftX = 0.0;
    final middleX = leftW;
    final rightX = leftW + middleW;
    final sideX = leftW + middleW + rightW;

    rects.add(
      Rect.fromLTWH(
        leftX,
        0,
        leftW,
        height * 0.55,
      ),
    );

    rects.add(
      Rect.fromLTWH(
        leftX,
        height * 0.55,
        leftW,
        height * 0.45,
      ),
    );

    rects.add(
      Rect.fromLTWH(
        middleX,
        0,
        middleW,
        height * 0.55,
      ),
    );

    rects.add(
      Rect.fromLTWH(
        middleX,
        height * 0.55,
        middleW,
        height * 0.45,
      ),
    );

    rects.add(
      Rect.fromLTWH(
        rightX,
        0,
        rightW,
        height * 0.28,
      ),
    );

    rects.add(
      Rect.fromLTWH(
        rightX,
        height * 0.28,
        rightW,
        height * 0.24,
      ),
    );

    rects.add(
      Rect.fromLTWH(
        rightX,
        height * 0.52,
        rightW,
        height * 0.22,
      ),
    );

    rects.add(
      Rect.fromLTWH(
        rightX,
        height * 0.74,
        rightW * 0.76,
        height * 0.26,
      ),
    );

    rects.add(
      Rect.fromLTWH(
        rightX + rightW * 0.76,
        height * 0.74,
        rightW * 0.24,
        height * 0.26,
      ),
    );

    if (sideW > 26) {
      rects.addAll(
        _buildSideColumnRects(
          x: sideX,
          width: sideW,
          height: height,
        ),
      );
    }

    return rects.where(_isValidRect).toList(growable: false);
  }

  List<Rect> _buildSideColumnRects({
    required double x,
    required double width,
    required double height,
  }) {
    final rects = <Rect>[];

    final heights = <double>[
      0.22,
      0.17,
      0.16,
      0.12,
      0.11,
      0.07,
      0.06,
      0.05,
      0.04,
    ];

    var currentY = 0.0;

    for (final factor in heights) {
      final h = height * factor;

      rects.add(
        Rect.fromLTWH(
          x,
          currentY,
          width,
          h,
        ),
      );

      currentY += h;
    }

    if (currentY < height) {
      rects.add(
        Rect.fromLTWH(
          x,
          currentY,
          width,
          height - currentY,
        ),
      );
    }

    return rects;
  }

  Rect _safeDeflate(Rect rect, double value) {
    if (!_isValidRect(rect)) {
      return Rect.zero;
    }

    final safeValue = math.min(
      value,
      math.min(rect.width, rect.height) / 4,
    );

    if (!safeValue.isFinite || safeValue.isNaN || safeValue < 0) {
      return rect;
    }

    return rect.deflate(safeValue);
  }

  bool _isValidSize(Size size) {
    return size.width > 0 &&
        size.height > 0 &&
        size.width.isFinite &&
        size.height.isFinite &&
        !size.width.isNaN &&
        !size.height.isNaN;
  }

  static bool _isValidRect(Rect rect) {
    return !rect.isEmpty &&
        rect.width > 0 &&
        rect.height > 0 &&
        rect.left.isFinite &&
        rect.top.isFinite &&
        rect.right.isFinite &&
        rect.bottom.isFinite &&
        rect.width.isFinite &&
        rect.height.isFinite &&
        !rect.width.isNaN &&
        !rect.height.isNaN;
  }

  @override
  bool shouldRepaint(covariant _TreemapSkeletonPainter oldDelegate) {
    return oldDelegate.base != base || oldDelegate.borderRadius != borderRadius;
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({
    required this.child,
  });

  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController.unbounded(
      vsync: this,
    )..repeat(
      min: 0,
      max: 1,
      period: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final gradient = LinearGradient(
          begin: Alignment(-1 + 2 * _controller.value, 0),
          end: Alignment(1 + 2 * _controller.value, 0),
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [
            0.25,
            0.50,
            0.75,
          ],
        );

        return ShaderMask(
          shaderCallback: (bounds) {
            return gradient.createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}