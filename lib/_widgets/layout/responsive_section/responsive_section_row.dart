import 'dart:math' as math;
import 'package:flutter/material.dart';

class ResponsiveSectionRow extends StatelessWidget {
  final List<Widget Function(BuildContext context, ResponsiveSectionMetrics m, int index)>
  children;

  final double smallBreakpoint;
  final double sidePadding;
  final double gap;
  final double verticalGap;

  final List<double?>? fixedWidths;

  final bool enableScrollOnSmall;
  final bool Function(int index)? scrollNeededForIndex;
  final double Function(int index, double availableWidth)? minScrollWidthForIndex;

  const ResponsiveSectionRow({
    super.key,
    required this.children,
    this.smallBreakpoint = 900,
    this.sidePadding = 12,
    this.gap = 12,
    this.verticalGap = 12,
    this.fixedWidths,
    this.enableScrollOnSmall = true,
    this.scrollNeededForIndex,
    this.minScrollWidthForIndex,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < smallBreakpoint;
        final double availableWidth =
        math.max(0, constraints.maxWidth - (2 * sidePadding));

        final baseMetrics = ResponsiveSectionMetrics(
          maxWidth: constraints.maxWidth,
          availableWidth: availableWidth,
          isSmall: isSmall,
          sidePadding: sidePadding,
          gap: gap,
          itemWidths: const [],
          currentItemWidth: null,
        );

        // ============================
        // MOBILE: Column (1 por linha)
        // ============================
        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // ✅ força expansão
            children: [
              SizedBox(height: verticalGap),
              for (int i = 0; i < children.length; i++) ...[
                _buildSmallItem(context, baseMetrics, i),
                if (i != children.length - 1) SizedBox(height: verticalGap),
              ],
            ],
          );
        }

        // ============================
        // DESKTOP/TABLET: Row
        // ============================
        final widths = _computeRowItemWidths(
          maxWidth: constraints.maxWidth,
          count: children.length,
          fixedWidths: fixedWidths,
          sidePadding: sidePadding,
          gap: gap,
        );

        final rowMetrics = baseMetrics.copyWith(itemWidths: widths);

        return Row(
          children: [
            SizedBox(width: sidePadding),
            for (int i = 0; i < children.length; i++) ...[
              SizedBox(
                width: widths[i],
                child: children[i](
                  context,
                  rowMetrics.copyWith(currentItemWidth: widths[i]),
                  i,
                ),
              ),
              if (i != children.length - 1) SizedBox(width: gap),
            ],
            SizedBox(width: sidePadding),
          ],
        );
      },
    );
  }

  Widget _buildSmallItem(BuildContext context, ResponsiveSectionMetrics base, int index) {
    final bool needScroll =
        enableScrollOnSmall && (scrollNeededForIndex?.call(index) ?? false);

    if (!needScroll) {
      // ✅ padding + largura total
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: sidePadding),
        child: SizedBox(
          width: double.infinity, // ✅ garante que o filho expanda
          child: children[index](
            context,
            base.copyWith(currentItemWidth: base.availableWidth),
            index,
          ),
        ),
      );
    }

    final double minW =
        minScrollWidthForIndex?.call(index, base.availableWidth) ??
            base.availableWidth;

    final double width = math.max(minW, base.availableWidth);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: sidePadding),
        child: SizedBox(
          width: width,
          child: children[index](
            context,
            base.copyWith(currentItemWidth: width),
            index,
          ),
        ),
      ),
    );
  }

  List<double> _computeRowItemWidths({
    required double maxWidth,
    required int count,
    required List<double?>? fixedWidths,
    required double sidePadding,
    required double gap,
  }) {
    final double inner =
    math.max(0, maxWidth - (2 * sidePadding) - (gap * math.max(0, count - 1)));

    final List<double?> fixed = List<double?>.generate(
      count,
          (i) => (fixedWidths != null && i < fixedWidths.length) ? fixedWidths[i] : null,
    );

    double fixedSum = 0;
    int flexCount = 0;

    for (final w in fixed) {
      if (w == null) {
        flexCount++;
      } else {
        fixedSum += w;
      }
    }

    final double remaining = math.max(0, inner - fixedSum);
    final double flexWidth = flexCount > 0 ? (remaining / flexCount) : 0;

    return List<double>.generate(count, (i) {
      final w = fixed[i] ?? flexWidth;
      return math.max(0, w);
    });
  }
}

class ResponsiveSectionMetrics {
  final double maxWidth;
  final double availableWidth;
  final bool isSmall;
  final double sidePadding;
  final double gap;

  final List<double> itemWidths;
  final double? currentItemWidth;

  const ResponsiveSectionMetrics({
    required this.maxWidth,
    required this.availableWidth,
    required this.isSmall,
    required this.sidePadding,
    required this.gap,
    required this.itemWidths,
    required this.currentItemWidth,
  });

  ResponsiveSectionMetrics copyWith({
    double? maxWidth,
    double? availableWidth,
    bool? isSmall,
    double? sidePadding,
    double? gap,
    List<double>? itemWidths,
    double? currentItemWidth,
  }) {
    return ResponsiveSectionMetrics(
      maxWidth: maxWidth ?? this.maxWidth,
      availableWidth: availableWidth ?? this.availableWidth,
      isSmall: isSmall ?? this.isSmall,
      sidePadding: sidePadding ?? this.sidePadding,
      gap: gap ?? this.gap,
      itemWidths: itemWidths ?? this.itemWidths,
      currentItemWidth: currentItemWidth ?? this.currentItemWidth,
    );
  }
}
