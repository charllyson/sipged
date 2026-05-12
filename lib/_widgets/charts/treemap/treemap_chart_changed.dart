import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sipged/_utils/formatters/sipged_format_money.dart';

import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/charts/treemap/treemap_class.dart';
import 'package:sipged/_widgets/charts/treemap/treemap_painter.dart';
import 'package:sipged/_widgets/charts/treemap/treemap_shimmer.dart';

import 'package:sipged/_widgets/overlays/balloon/balloon_body.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

class TreemapChartChanged extends StatefulWidget {
  /// Itens do Treemap.
  /// O value representa o valor total e define a área do retângulo.
  final List<TreemapItem> items;

  /// Valores filtrados alinhados por índice com [items].
  /// Se null ou de tamanho diferente, todo item é tratado como 100%.
  final List<double?>? filteredValues;

  /// Altura do canvas/card.
  final double heightGraphic;

  /// Mantido por compatibilidade.
  final bool expandToMaxWidth;

  /// Tamanho alvo por célula em caso de largura sem bound.
  final double targetCellSide;

  /// Callback ao selecionar item.
  /// null limpa a seleção.
  final void Function(String? label)? onItemSelected;

  const TreemapChartChanged({
    super.key,
    required this.items,
    this.filteredValues,
    this.heightGraphic = 295.0,
    this.expandToMaxWidth = false,
    this.targetCellSide = 120,
    this.onItemSelected,
  });

  @override
  State<TreemapChartChanged> createState() => _TreemapChartChangedState();
}

class _TreemapChartChangedState extends State<TreemapChartChanged> {
  final Map<TreemapItem, Rect> _rects = {};
  final GlobalKey _paintKey = GlobalKey();

  String? _selectedLabel;

  Map<TreemapItem, double> _intensityByItem = {};

  bool _anchorRebuildScheduled = false;

  static const Color _cardBackgroundColor = Colors.white;

  static const double _balloonPreferredWidth = 300;
  static const double _balloonMinWidth = 210;
  static const double _balloonMaxHeight = 170;
  static const double _balloonGap = 8;
  static const double _canvasMargin = 8;
  static const double _tipHeight = 10;
  static const double _tipHorizontalMargin = 20;

  @override
  void didUpdateWidget(covariant TreemapChartChanged oldWidget) {
    super.didUpdateWidget(oldWidget);

    final selectedLabel = _selectedLabel;

    if (selectedLabel == null) {
      return;
    }

    final stillExists = widget.items.any((item) {
      return item.label.trim() == selectedLabel;
    });

    if (!stillExists) {
      setState(() {
        _selectedLabel = null;
      });
      return;
    }

    _scheduleAnchorRebuild();
  }

  List<TreemapItem> get _validItems {
    return widget.items.where((item) {
      return item.label.trim().isNotEmpty &&
          item.value > 0 &&
          item.value.isFinite &&
          !item.value.isNaN;
    }).toList(growable: false);
  }

  TreemapItem? _selectedItemFrom(List<TreemapItem> validItems) {
    final selectedLabel = _selectedLabel;

    if (selectedLabel == null || selectedLabel.trim().isEmpty) {
      return null;
    }

    for (final item in validItems) {
      if (item.label.trim() == selectedLabel) {
        return item;
      }
    }

    return null;
  }

  Rect? _rectForSelectedLabel() {
    final selectedLabel = _selectedLabel;

    if (selectedLabel == null || selectedLabel.trim().isEmpty) {
      return null;
    }

    for (final entry in _rects.entries) {
      if (entry.key.label.trim() == selectedLabel && _isValidRect(entry.value)) {
        return entry.value;
      }
    }

    return null;
  }

  TreemapItem? _itemForSelectedLabel(List<TreemapItem> validItems) {
    final selectedLabel = _selectedLabel;

    if (selectedLabel == null || selectedLabel.trim().isEmpty) {
      return null;
    }

    for (final item in validItems) {
      if (item.label.trim() == selectedLabel) {
        return item;
      }
    }

    return null;
  }

  void _scheduleAnchorRebuild() {
    if (_anchorRebuildScheduled || !mounted) {
      return;
    }

    _anchorRebuildScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _anchorRebuildScheduled = false;

      if (!mounted) {
        return;
      }

      if (_selectedLabel == null) {
        return;
      }

      setState(() {});
    });
  }

  void _buildIntensityMap(List<TreemapItem> validItems) {
    _intensityByItem = {};

    final filteredValues = widget.filteredValues;

    final hasValidFilter = filteredValues != null &&
        filteredValues.length == widget.items.length &&
        filteredValues.any((value) {
          final clean = value ?? 0.0;
          return clean > 0 && clean.isFinite && !clean.isNaN;
        });

    if (!hasValidFilter) {
      for (final item in validItems) {
        _intensityByItem[item] = 1.0;
      }

      return;
    }

    for (final item in validItems) {
      final originalIndex = widget.items.indexOf(item);

      if (originalIndex < 0 || originalIndex >= filteredValues.length) {
        _intensityByItem[item] = 1.0;
        continue;
      }

      final base = item.value;
      final filtered = filteredValues[originalIndex] ?? 0.0;

      if (base <= 0 || !base.isFinite || base.isNaN) {
        _intensityByItem[item] = 0.0;
        continue;
      }

      if (!filtered.isFinite || filtered.isNaN || filtered <= 0) {
        _intensityByItem[item] = 0.0;
        continue;
      }

      _intensityByItem[item] = (filtered / base).clamp(0.0, 1.0);
    }
  }

  Size _resolveSize(BoxConstraints constraints) {
    double width;

    if (constraints.hasBoundedWidth &&
        constraints.maxWidth.isFinite &&
        constraints.maxWidth > 0) {
      width = constraints.maxWidth;
    } else {
      final count = math.max(1, widget.items.length);
      final gridSide = math.sqrt(count);

      width = (gridSide * widget.targetCellSide)
          .clamp(300.0, 1200.0)
          .toDouble();
    }

    double height = widget.heightGraphic;

    if (!height.isFinite || height.isNaN || height <= 0) {
      height = 295.0;
    }

    if (constraints.hasBoundedHeight &&
        constraints.maxHeight.isFinite &&
        constraints.maxHeight > 0) {
      height = math.min(height, constraints.maxHeight);
    }

    height = height.clamp(150.0, 3000.0).toDouble();

    return Size(width, height);
  }

  RenderBox? _renderBox() {
    final currentContext = _paintKey.currentContext;

    if (currentContext == null) {
      return null;
    }

    final renderObject = currentContext.findRenderObject();

    if (renderObject is RenderBox) {
      return renderObject;
    }

    return null;
  }

  TreemapItem? _hit(Offset local) {
    for (final entry in _rects.entries) {
      if (entry.value.contains(local)) {
        return entry.key;
      }
    }

    return null;
  }

  void _handleTapUp(TapUpDetails details) {
    final box = _renderBox();

    if (box == null) {
      return;
    }

    final local = box.globalToLocal(details.globalPosition);
    final item = _hit(local);

    if (item == null) {
      setState(() {
        _selectedLabel = null;
      });

      widget.onItemSelected?.call(null);
      return;
    }

    final label = item.label.trim();

    if (label.isEmpty) {
      setState(() {
        _selectedLabel = null;
      });

      widget.onItemSelected?.call(null);
      return;
    }

    final same = _selectedLabel == label;

    if (same) {
      setState(() {
        _selectedLabel = null;
      });

      widget.onItemSelected?.call(null);
      return;
    }

    setState(() {
      _selectedLabel = label;
    });

    widget.onItemSelected?.call(label);

    _scheduleAnchorRebuild();
  }

  String? _buildPercentualDetails(TreemapItem item) {
    final intensity = _intensityByItem[item];

    if (intensity == null || !intensity.isFinite || intensity.isNaN) {
      return null;
    }

    final percentual = (intensity * 100).clamp(0.0, 100.0);

    return 'Participação filtrada: ${percentual.toStringAsFixed(1)}%';
  }

  Widget? _buildSelectedBalloon({
    required Size canvasSize,
    required List<TreemapItem> validItems,
  }) {
    final selectedItem = _itemForSelectedLabel(validItems);

    if (selectedItem == null) {
      return null;
    }

    final rect = _rectForSelectedLabel();

    if (rect == null || !_isValidRect(rect)) {
      _scheduleAnchorRebuild();
      return null;
    }

    if (!_isValidSize(canvasSize)) {
      return null;
    }

    final anchor = rect.center;

    final width = _resolveBalloonWidth(canvasSize.width);

    if (width <= 0) {
      return null;
    }

    final position = _resolveBalloonPosition(
      canvasSize: canvasSize,
      anchor: anchor,
      width: width,
    );

    return Positioned(
      left: position.left,
      top: position.top,
      width: width,
      child: IgnorePointer(
        child: Material(
          type: MaterialType.transparency,
          child: BalloonBody(
            width: width,
            maxHeight: _balloonMaxHeight,
            tipSide: position.tipSide,
            tipCenterX: position.tipCenterX,
            title: 'Detalhes do investimento',
            headerIcon: Icons.account_tree_outlined,
            items: [
              BalloonTileData.simple(
                id: selectedItem.label,
                title: selectedItem.label,
                subtitle:
                'Investido: ${SipGedFormatMoney.doubleToText(selectedItem.value)}',
                details: _buildPercentualDetails(selectedItem),
                icon: Icons.paid_outlined,
                accentColor: selectedItem.color,
                highlighted: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _resolveBalloonWidth(double canvasWidth) {
    if (!canvasWidth.isFinite || canvasWidth.isNaN || canvasWidth <= 0) {
      return 0;
    }

    final availableWidth = canvasWidth - (_canvasMargin * 2);

    if (availableWidth <= 0) {
      return 0;
    }

    if (availableWidth < _balloonMinWidth) {
      return availableWidth;
    }

    return math.min(_balloonPreferredWidth, availableWidth);
  }

  _TreemapBalloonPosition _resolveBalloonPosition({
    required Size canvasSize,
    required Offset anchor,
    required double width,
  }) {
    final rawLeft = anchor.dx - (width / 2);
    final maxLeft = canvasSize.width - width - _canvasMargin;

    final left = _safeClamp(
      rawLeft,
      _canvasMargin,
      maxLeft,
    );

    final rawTipCenterX = anchor.dx - left;

    final tipCenterX = _safeClamp(
      rawTipCenterX,
      _tipHorizontalMargin,
      width - _tipHorizontalMargin,
    );

    final belowTop = anchor.dy + _balloonGap;
    final belowBottom = belowTop + _tipHeight + _balloonMaxHeight;

    if (belowBottom <= canvasSize.height) {
      return _TreemapBalloonPosition(
        left: left,
        top: belowTop,
        tipCenterX: tipCenterX,
        tipSide: BalloonTipSide.top,
      );
    }

    final rawAboveTop =
        anchor.dy - _balloonMaxHeight - _tipHeight - _balloonGap;

    final maxTop =
        canvasSize.height - _balloonMaxHeight - _tipHeight - _canvasMargin;

    final top = _safeClamp(
      rawAboveTop,
      _canvasMargin,
      maxTop,
    );

    return _TreemapBalloonPosition(
      left: left,
      top: top,
      tipCenterX: tipCenterX,
      tipSide: BalloonTipSide.bottom,
    );
  }

  double _safeClamp(
      double value,
      double min,
      double max,
      ) {
    if (!value.isFinite || value.isNaN) {
      return min;
    }

    if (!min.isFinite || min.isNaN) {
      min = 0;
    }

    if (!max.isFinite || max.isNaN) {
      max = min;
    }

    if (max < min) {
      return min;
    }

    return value.clamp(min, max).toDouble();
  }

  bool _isValidSize(Size size) {
    return size.width > 0 &&
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

  @override
  Widget build(BuildContext context) {
    final validItems = _validItems;
    _buildIntensityMap(validItems);

    final selectedItem = _selectedItemFrom(validItems);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (_, constraints) {
        final size = _resolveSize(constraints);

        if (validItems.isEmpty) {
          return BasicCard(
            isDark: isDark,
            width: size.width.isFinite ? size.width : null,
            height: size.height,
            padding: const EdgeInsets.all(8),
            backgroundColor: _cardBackgroundColor,
            gradient: null,
            enableShadow: true,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: TreemapShimmer(
                altura: size.height,
                cardWidth: size.width,
                legendItems: 8,
              ),
            ),
          );
        }

        final selectedBalloon = _buildSelectedBalloon(
          canvasSize: size,
          validItems: validItems,
        );

        final treemapCanvas = SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: _handleTapUp,
                  child: ClipRect(
                    child: CustomPaint(
                      key: _paintKey,
                      painter: TreemapPainter(
                        validItems,
                        outRects: _rects,
                        selected: selectedItem,
                        intensityByItem: _intensityByItem,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              ?selectedBalloon,
            ],
          ),
        );

        return BasicCard(
          isDark: isDark,
          width: size.width.isFinite ? size.width : null,
          height: size.height,
          padding: const EdgeInsets.all(8),
          backgroundColor: _cardBackgroundColor,
          gradient: null,
          enableShadow: true,
          child: treemapCanvas,
        );
      },
    );
  }
}

class _TreemapBalloonPosition {
  const _TreemapBalloonPosition({
    required this.left,
    required this.top,
    required this.tipCenterX,
    required this.tipSide,
  });

  final double left;
  final double top;
  final double tipCenterX;
  final BalloonTipSide tipSide;
}