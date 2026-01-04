// lib/_widgets/charts/treemap/treemap_chart_changed.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:siged/_widgets/charts/treemap/treemap_class.dart';
import 'package:siged/_widgets/charts/treemap/treemap_painter.dart';
import 'package:siged/_widgets/charts/treemap/treemap_shimmer.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_widgets/cards/basic/basic_card.dart';

class TreemapChartChanged extends StatefulWidget {
  /// Itens do Treemap – o **value** de cada item representa o VALOR TOTAL (FULL)
  /// e será usado para definir a área do retângulo.
  final List<TreemapItem> items;

  /// Valores **FILTRADOS** alinhados por índice com [items].
  /// (se null ou de tamanho diferente, todo mundo é tratado como 100% filtrado).
  final List<double?>? filteredValues;

  /// Altura do canvas do treemap (como no BarChart).
  final double heightGraphic;

  /// Mantida por compatibilidade, mas o layout sempre respeita o maxWidth do pai.
  final bool expandToMaxWidth;

  /// Tamanho alvo por célula (apenas para cálculo de largura em casos sem bound).
  final double targetCellSide;

  /// Callback ao selecionar um item (label) – null limpa a seleção.
  final void Function(String? label)? onItemSelected;

  const TreemapChartChanged({
    super.key,
    required this.items,
    this.filteredValues,
    this.heightGraphic = 300,
    this.expandToMaxWidth = false,
    this.targetCellSide = 120,
    this.onItemSelected,
  });

  @override
  State<TreemapChartChanged> createState() => _TreemapChartChangedState();
}

class _TreemapChartChangedState extends State<TreemapChartChanged> {
  final Map<TreemapItem, Rect> _rects = {};
  TreemapItem? _selected;

  /// intensidade/“opacidade lógica” 0..1 p/ cada item,
  /// calculada a partir de filteredValues / value.
  Map<TreemapItem, double> _intensityByItem = {};

  // Tooltip infra
  OverlayEntry? _overlay;
  final ValueNotifier<Offset?> _tooltipPos = ValueNotifier<Offset?>(null);
  final ValueNotifier<TreemapItem?> _tooltipItem =
  ValueNotifier<TreemapItem?>(null);

  /// key só para hit-test e coordenadas do canvas
  final GlobalKey _paintKey = GlobalKey();

  @override
  void dispose() {
    _removeOverlay();
    _tooltipPos.dispose();
    _tooltipItem.dispose();
    super.dispose();
  }

  // ========================= TOOLTIP =========================

  void _ensureOverlay() {
    if (_overlay != null || !mounted) return;
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;

    _overlay = OverlayEntry(
      builder: (context) {
        return ValueListenableBuilder<TreemapItem?>(
          valueListenable: _tooltipItem,
          builder: (_, item, __) {
            if (item == null) return const SizedBox.shrink();
            return ValueListenableBuilder<Offset?>(
              valueListenable: _tooltipPos,
              builder: (_, pos, __) {
                if (pos == null) return const SizedBox.shrink();

                return Positioned(
                  left: pos.dx - 160,
                  top: pos.dy + 12,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Investido: ${priceToString(item.value)}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    overlayState.insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _hideTooltip() {
    _tooltipItem.value = null;
    _tooltipPos.value = null;
  }

  void _showTooltip(TreemapItem item, Offset globalPos) {
    _ensureOverlay();
    _tooltipItem.value = item;
    _tooltipPos.value = globalPos;
  }

  // ========================= HIT TEST =========================

  TreemapItem? _hit(Offset local) {
    for (final e in _rects.entries) {
      if (e.value.contains(local)) return e.key;
    }
    return null;
  }

  RenderBox? _renderBox() {
    final ctx = _paintKey.currentContext;
    if (ctx == null) return null;
    final ro = ctx.findRenderObject();
    return ro is RenderBox ? ro : null;
  }

  // ========================= INTENSIDADE =========================

  void _buildIntensityMap() {
    _intensityByItem = {};

    final f = widget.filteredValues;

    final hasValidFilter = f != null &&
        f.length == widget.items.length &&
        f.any((v) => (v ?? 0) > 0);

    if (!hasValidFilter) {
      for (final item in widget.items) {
        _intensityByItem[item] = 1.0;
      }
      return;
    }

    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final base = item.value;
      final filtered = f[i] ?? 0.0;

      double factor;
      if (base <= 0) {
        factor = filtered > 0 ? 1.0 : 0.0;
      } else {
        factor = (filtered / base).clamp(0.0, 1.0);
      }

      _intensityByItem[item] = factor;
    }
  }

  // ========================= TAMANHO =========================

  Size _resolveSize(BoxConstraints c) {
    double width;
    if (c.hasBoundedWidth && c.maxWidth.isFinite) {
      // Caso normal: estamos dentro de um layout com largura fixa.
      width = c.maxWidth;
    } else {
      // Caso raro (sem bound explícito): estima uma largura finita.
      final n = math.max(1, widget.items.length);
      final gridSide = math.sqrt(n);
      width =
          (gridSide * widget.targetCellSide).clamp(300.0, 1200.0).toDouble();
    }

    double height = widget.heightGraphic;
    if (c.hasBoundedHeight && c.maxHeight.isFinite) {
      height = math.min(height, c.maxHeight);
    }
    height = height.clamp(150.0, 3000.0);

    return Size(width, height);
  }

  // ========================= BUILD =========================

  @override
  Widget build(BuildContext context) {
    _buildIntensityMap();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool noData =
        widget.items.isEmpty || widget.items.every((e) => e.value <= 0);

    return LayoutBuilder(
      builder: (_, constraints) {
        final size = _resolveSize(constraints);

        // ============ CASO: SHIMMER ============
        if (noData) {
          return BasicCard(
            isDark: isDark,
            width: size.width.isFinite ? size.width : null,
            padding: const EdgeInsets.all(8),
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

        // ============ CASO: TREEMAP REAL ============
        final treemapCanvas = SizedBox(
          width: size.width,
          height: size.height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final box = _renderBox();
              if (box == null) return;

              final local = box.globalToLocal(d.globalPosition);
              final item = _hit(local);

              if (item == null) {
                setState(() => _selected = null);
                widget.onItemSelected?.call(null);
                _hideTooltip();
                return;
              }

              final same = _selected?.label == item.label;

              setState(() => _selected = same ? null : item);
              widget.onItemSelected?.call(same ? null : item.label);

              same ? _hideTooltip() : _showTooltip(item, d.globalPosition);
            },
            child: MouseRegion(
              onHover: (e) {
                final box = _renderBox();
                if (box == null) return;

                final local = box.globalToLocal(e.position);
                final item = _hit(local);

                if (item == null) {
                  _hideTooltip();
                } else {
                  _showTooltip(item, e.position);
                }
              },
              onExit: (_) => _hideTooltip(),
              child: ClipRect(
                // garante que nada “vaze” para fora do card
                child: CustomPaint(
                  key: _paintKey,
                  painter: TreemapPainter(
                    widget.items,
                    outRects: _rects,
                    selected: _selected,
                    intensityByItem: _intensityByItem,
                  ),
                ),
              ),
            ),
          ),
        );

        return BasicCard(
          isDark: isDark,
          width: size.width.isFinite ? size.width : null,
          padding: const EdgeInsets.all(8),
          child: treemapCanvas,
        );
      },
    );
  }
}
