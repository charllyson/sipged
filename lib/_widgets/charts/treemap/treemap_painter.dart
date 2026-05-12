import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/charts/treemap/treemap_class.dart';

class TreemapPainter extends CustomPainter {
  final List<TreemapItem> items;
  final Map<TreemapItem, Rect> outRects;
  final TreemapItem? selected;

  /// Intensidade 0..1 por item:
  /// 0 = mais apagado
  /// 1 = cor cheia
  final Map<TreemapItem, double>? intensityByItem;

  TreemapPainter(
      this.items, {
        required this.outRects,
        required this.selected,
        this.intensityByItem,
      });

  static const double _gutter = 1.5;
  static const double _textPadding = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    outRects.clear();

    if (!_isValidSize(size)) {
      return;
    }

    final validItems = items.where((item) {
      return item.label.trim().isNotEmpty &&
          item.value > 0 &&
          item.value.isFinite &&
          !item.value.isNaN;
    }).toList();

    if (validItems.isEmpty) {
      return;
    }

    final total = validItems.fold<double>(
      0.0,
          (sum, item) => sum + item.value,
    );

    if (total <= 0 || !total.isFinite || total.isNaN) {
      return;
    }

    final rect = Offset.zero & size;

    _drawSquarify(
      canvas,
      rect,
      List<TreemapItem>.from(validItems),
      total,
    );

    _drawSelection(canvas);
  }

  bool _isValidSize(Size size) {
    return !size.isEmpty &&
        size.width > 0 &&
        size.height > 0 &&
        size.width.isFinite &&
        size.height.isFinite &&
        !size.width.isNaN &&
        !size.height.isNaN;
  }

  bool _isValidRect(Rect rect) {
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

  Rect _safeRectFromLTWH({
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    final safeLeft = left.isFinite && !left.isNaN ? left : 0.0;
    final safeTop = top.isFinite && !top.isNaN ? top : 0.0;
    final safeWidth = width.isFinite && !width.isNaN && width > 0 ? width : 0.0;
    final safeHeight =
    height.isFinite && !height.isNaN && height > 0 ? height : 0.0;

    return Rect.fromLTWH(
      safeLeft,
      safeTop,
      safeWidth,
      safeHeight,
    );
  }

  void _drawSelection(Canvas canvas) {
    if (selected == null) {
      return;
    }

    final rect = outRects[selected];

    if (rect == null || !_isValidRect(rect)) {
      return;
    }

    final paintGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = Colors.black.withValues(alpha: 0.25);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withValues(alpha: 0.9);

    canvas.drawRect(rect.inflate(1.5), paintGlow);
    canvas.drawRect(rect, paint);
  }

  void _drawSquarify(
      Canvas canvas,
      Rect rect,
      List<TreemapItem> list,
      double total,
      ) {
    if (list.isEmpty || !_isValidRect(rect)) {
      return;
    }

    if (total <= 0 || !total.isFinite || total.isNaN) {
      return;
    }

    final validList = list.where((item) {
      return item.value > 0 && item.value.isFinite && !item.value.isNaN;
    }).toList();

    if (validList.isEmpty) {
      return;
    }

    if (validList.length == 1) {
      _drawLeaf(
        canvas,
        rect,
        validList.first,
      );
      return;
    }

    validList.sort((a, b) => b.value.compareTo(a.value));

    final half = math.max(1, validList.length ~/ 2);

    final first = validList.sublist(0, half);
    final second = validList.sublist(half);

    final firstTotal = first.fold<double>(
      0.0,
          (sum, item) => sum + item.value,
    );

    final secondTotal = second.fold<double>(
      0.0,
          (sum, item) => sum + item.value,
    );

    if (firstTotal <= 0 || secondTotal < 0) {
      return;
    }

    final ratio = (firstTotal / total).clamp(0.0, 1.0);

    if (!ratio.isFinite || ratio.isNaN) {
      return;
    }

    if (rect.width > rect.height) {
      final leftWidth = rect.width * ratio;

      final left = _safeRectFromLTWH(
        left: rect.left,
        top: rect.top,
        width: leftWidth,
        height: rect.height,
      );

      final right = _safeRectFromLTWH(
        left: rect.left + leftWidth,
        top: rect.top,
        width: rect.width - leftWidth,
        height: rect.height,
      );

      if (_isValidRect(left) && firstTotal > 0) {
        _drawSquarify(
          canvas,
          left,
          first,
          firstTotal,
        );
      }

      if (_isValidRect(right) && secondTotal > 0) {
        _drawSquarify(
          canvas,
          right,
          second,
          secondTotal,
        );
      }
    } else {
      final topHeight = rect.height * ratio;

      final top = _safeRectFromLTWH(
        left: rect.left,
        top: rect.top,
        width: rect.width,
        height: topHeight,
      );

      final bottom = _safeRectFromLTWH(
        left: rect.left,
        top: rect.top + topHeight,
        width: rect.width,
        height: rect.height - topHeight,
      );

      if (_isValidRect(top) && firstTotal > 0) {
        _drawSquarify(
          canvas,
          top,
          first,
          firstTotal,
        );
      }

      if (_isValidRect(bottom) && secondTotal > 0) {
        _drawSquarify(
          canvas,
          bottom,
          second,
          secondTotal,
        );
      }
    }
  }

  void _drawLeaf(
      Canvas canvas,
      Rect rect,
      TreemapItem item,
      ) {
    if (!_isValidRect(rect)) {
      return;
    }

    final drawRect = rect.deflate(
      math.min(
        _gutter,
        math.min(rect.width, rect.height) / 4,
      ),
    );

    if (!_isValidRect(drawRect)) {
      return;
    }

    double factor = 1.0;

    final intensity = intensityByItem?[item];

    if (intensity != null && intensity.isFinite && !intensity.isNaN) {
      factor = intensity.clamp(0.0, 1.0);
    }

    const minAlpha = 0.25;
    const maxAlpha = 1.0;

    final alphaFactor = minAlpha + (maxAlpha - minAlpha) * factor;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = item.color.withValues(alpha: alphaFactor);

    canvas.drawRect(drawRect, paint);

    outRects[item] = drawRect;

    _drawLabel(
      canvas,
      drawRect,
      item,
    );
  }

  void _drawLabel(
      Canvas canvas,
      Rect rect,
      TreemapItem item,
      ) {
    if (!_isValidRect(rect)) {
      return;
    }

    final availableWidth = rect.width - (_textPadding * 2);
    final availableHeight = rect.height - (_textPadding * 2);

    if (availableWidth <= 4 || availableHeight <= 8) {
      return;
    }

    if (!availableWidth.isFinite || availableWidth.isNaN) {
      return;
    }

    final txtColor =
    item.color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    final baseFontSize = math.min(
      18.0,
      math.max(
        8.0,
        rect.shortestSide * 0.22,
      ),
    );

    if (!baseFontSize.isFinite || baseFontSize.isNaN || baseFontSize <= 0) {
      return;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: item.label,
        style: TextStyle(
          color: txtColor,
          fontSize: baseFontSize,
          fontWeight: FontWeight.w600,
          height: 1.05,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: availableHeight >= 26 ? 2 : 1,
      ellipsis: '…',
    );

    final safeMaxWidth = math.max(0.0, availableWidth);

    if (!safeMaxWidth.isFinite || safeMaxWidth.isNaN || safeMaxWidth <= 2) {
      return;
    }

    textPainter.layout(
      minWidth: 0,
      maxWidth: safeMaxWidth,
    );

    final offset = Offset(
      rect.left + _textPadding,
      rect.top + _textPadding,
    );

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant TreemapPainter oldDelegate) {
    return oldDelegate.items != items ||
        oldDelegate.selected != selected ||
        oldDelegate.intensityByItem != intensityByItem;
  }
}