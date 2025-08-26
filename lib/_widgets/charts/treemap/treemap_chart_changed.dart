import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sisged/_widgets/charts/treemap/treemap_shimmer.dart';
import 'package:sisged/_utils/formats/format_field.dart';

class TreemapItem {
  final String label;
  final double value;
  final Color color;

  TreemapItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

class TreemapChartChanged extends StatefulWidget {
  final List<TreemapItem> items;

  /// Altura do canvas do treemap (como no BarChart).
  final double heightGraphic;

  /// Quando true, ocupa toda a largura disponível do pai;
  /// quando false, calcula uma largura "base" e permite scroll horizontal.
  final bool expandToMaxWidth;

  /// Tamanho alvo por célula para estimar a largura base quando expandToMaxWidth=false.
  /// Não é por barra; é só um “tamanho médio” para não apertar demais.
  final double targetCellSide;

  const TreemapChartChanged({
    super.key,
    required this.items,
    this.heightGraphic = 300,
    this.expandToMaxWidth = false,
    this.targetCellSide = 120,
  });

  @override
  State<TreemapChartChanged> createState() => _TreemapChartChangedState();
}

class _TreemapChartChangedState extends State<TreemapChartChanged> {
  final Map<TreemapItem, Rect> _rects = {};
  TreemapItem? _selected;

  // Tooltip infra
  OverlayEntry? _overlay;
  final ValueNotifier<Offset?> _tooltipPos = ValueNotifier<Offset?>(null);
  final ValueNotifier<TreemapItem?> _tooltipItem = ValueNotifier<TreemapItem?>(null);

  @override
  void dispose() {
    _removeOverlay();
    _tooltipPos.dispose();
    _tooltipItem.dispose();
    super.dispose();
  }

  void _ensureOverlay() {
    if (_overlay != null || !mounted) return;
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;

    _overlay = OverlayEntry(
      builder: (context) {
        return ValueListenableBuilder<TreemapItem?>(
          valueListenable: _tooltipItem,
          builder: (context, item, _) {
            if (item == null) return const SizedBox.shrink();
            return ValueListenableBuilder<Offset?>(
              valueListenable: _tooltipPos,
              builder: (context, pos, __) {
                if (pos == null) return const SizedBox.shrink();
                return Positioned(
                  left: pos.dx - 160,
                  top: pos.dy + 12,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DefaultTextStyle(
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.label, style: const TextStyle(fontWeight: FontWeight.w700)),
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

  TreemapItem? _hit(Offset local) {
    for (final e in _rects.entries) {
      if (e.value.contains(local)) return e.key;
    }
    return null;
  }

  RenderBox? _renderBox() => context.findRenderObject() as RenderBox?;

  /// Calcula um tamanho **finito** para o treemap:
  /// - Se expandToMaxWidth=true: largura = maxWidth (se for limitada), senão usa baseWidth.
  /// - Se expandToMaxWidth=false: largura = baseWidth (pode exceder o maxWidth e habilitar scroll).
  /// Altura sempre finita (heightGraphic).
  Size _resolveTreemapSize(BoxConstraints c) {
    // largura base estimada pelo número de itens e um “lado alvo” por célula
    final n = math.max(1, widget.items.length);
    final gridSide = math.sqrt(n); // “colunas” ideais
    final baseWidth = (gridSide * widget.targetCellSide).clamp(300, 4000).toDouble();

    final boundedW = c.hasBoundedWidth ? c.maxWidth : null;

    double width;
    if (widget.expandToMaxWidth) {
      width = boundedW ?? baseWidth; // se não está limitado, cai na largura base
    } else {
      width = baseWidth; // pode ser > maxWidth → scroll horizontal
    }

    // Altura: se o pai limita, respeita; senão usa heightGraphic
    final boundedH = c.hasBoundedHeight ? c.maxHeight : null;
    final height = (boundedH ?? widget.heightGraphic).clamp(100, 4000).toDouble();

    return Size(width, height);
  }

  @override
  Widget build(BuildContext context) {
    final noData = widget.items.isEmpty || widget.items.every((e) => e.value <= 0);

    return LayoutBuilder(
      builder: (_, constraints) {
        final size = _resolveTreemapSize(constraints);

        if (noData) {
          final shimmer = TreemapShimmer(
            cardWidth: 700,
              altura: 265);

          // Se a largura base exceder o espaço visível, permita rolagem, igual ao BarChart
          final needScroll = size.width > (constraints.hasBoundedWidth ? constraints.maxWidth : size.width);
          return needScroll
              ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: shimmer,
          )
              : shimmer;
        }

        final canvas = SizedBox(
          width: size.width,
          height: size.height,
          child: MouseRegion(
            onHover: (event) {
              final box = _renderBox();
              if (box == null) return;
              final local = box.globalToLocal(event.position);
              final item = _hit(local);
              if (item != null) {
                _showTooltip(item, event.position);
              } else {
                _hideTooltip();
              }
            },
            onExit: (_) => _hideTooltip(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                final box = _renderBox();
                if (box == null) return;
                final local = box.globalToLocal(d.globalPosition);
                final item = _hit(local);
                if (item != null) {
                  setState(() => _selected = item);
                  _showTooltip(item, d.globalPosition);
                } else {
                  setState(() => _selected = null);
                  _hideTooltip();
                }
              },
              child: CustomPaint(
                painter: _TreemapPainter(
                  widget.items,
                  outRects: _rects,
                  selected: _selected,
                ),
                size: size, // sempre FINITO
              ),
            ),
          ),
        );

        // Se a largura base exceder o visível, adiciona rolagem (igual ao BarChart)
        final needScroll = size.width > (constraints.hasBoundedWidth ? constraints.maxWidth : size.width);

        final content = Card(
          color: Colors.white,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: canvas,
          ),
        );

        return needScroll
            ? SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: content,
        )
            : content;
      },
    );
  }
}

class _TreemapPainter extends CustomPainter {
  final List<TreemapItem> items;
  final Map<TreemapItem, Rect> outRects;
  final TreemapItem? selected;

  _TreemapPainter(
      this.items, {
        required this.outRects,
        required this.selected,
      });

  @override
  void paint(Canvas canvas, Size size) {
    outRects.clear();
    if (size.isEmpty) return;

    final total = items.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return;

    final rect = Offset.zero & size;
    _drawSquarify(canvas, rect, List.of(items), total);

    // Seleção sem cantos arredondados
    if (selected != null && outRects[selected] != null) {
      final r = outRects[selected]!;
      final paintGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = Colors.black.withOpacity(0.25);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withOpacity(0.9);
      canvas.drawRect(r.inflate(1.5), paintGlow);
      canvas.drawRect(r, paint);
    }
  }

  void _drawSquarify(Canvas canvas, Rect rect, List<TreemapItem> list, double total) {
    if (list.isEmpty || rect.isEmpty || total <= 0) return;

    if (list.length == 1) {
      final item = list.first;
      final paint = Paint()..color = item.color;

      // bloco folha (sem arredondamento)
      canvas.drawRect(rect, paint);

      // salva retângulo para hit-test
      outRects[item] = rect;

      // texto dinâmico
      final txtColor = (item.color.computeLuminance() > 0.5) ? Colors.black87 : Colors.white;
      final baseFontSize = (rect.shortestSide * 0.22).clamp(8.0, 18.0);

      final tp = TextPainter(
        text: TextSpan(
          text: item.label,
          style: TextStyle(
            color: txtColor,
            fontSize: baseFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: rect.width - 8);

      tp.paint(canvas, rect.topLeft + const Offset(4, 4));
      return;
    }

    // ordena desc (em cópia local)
    list.sort((a, b) => b.value.compareTo(a.value));

    // split simples
    final half = list.length ~/ 2;
    final first = list.sublist(0, half);
    final second = list.sublist(half);

    final firstTotal = first.fold<double>(0, (s, e) => s + e.value);
    final ratio = firstTotal <= 0 ? 0.0 : (firstTotal / total).clamp(0.0, 1.0);

    if (rect.width > rect.height) {
      final wLeft = rect.width * ratio;
      final left = Rect.fromLTWH(rect.left, rect.top, wLeft, rect.height);
      final right = Rect.fromLTWH(rect.left + wLeft, rect.top, rect.width - wLeft, rect.height);
      if (!left.isEmpty && firstTotal > 0) _drawSquarify(canvas, left, first, firstTotal);
      final secondTotal = total - firstTotal;
      if (!right.isEmpty && secondTotal > 0) _drawSquarify(canvas, right, second, secondTotal);
    } else {
      final hTop = rect.height * ratio;
      final top = Rect.fromLTWH(rect.left, rect.top, rect.width, hTop);
      final bottom = Rect.fromLTWH(rect.left, rect.top + hTop, rect.width, rect.height - hTop);
      if (!top.isEmpty && firstTotal > 0) _drawSquarify(canvas, top, first, firstTotal);
      final secondTotal = total - firstTotal;
      if (!bottom.isEmpty && secondTotal > 0) _drawSquarify(canvas, bottom, second, secondTotal);
    }
  }

  @override
  bool shouldRepaint(covariant _TreemapPainter old) =>
      old.items != items || old.selected != selected;
}
