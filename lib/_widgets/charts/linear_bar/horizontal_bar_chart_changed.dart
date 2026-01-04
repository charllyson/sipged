// lib/_widgets/charts/linear_bar/horizontal_bar_chart_changed.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/cards/basic/basic_card.dart';

import 'package:siged/_widgets/charts/linear_bar/range_overlay_config.dart';
import 'package:siged/_widgets/charts/linear_bar/slice_hatch_config.dart';

import 'types.dart';
import 'horizontal_bar_chart_bars.dart';

class HorizontalBarChanged extends StatefulWidget {
  final String label;
  final List<double> values;
  final List<double>? consumedValues;
  final List<Color>? sliceColors;
  final List<String>? groupLegendLabels;

  /// Se for 0 ou se `hideLabel == true`, o label NÃO aparece e a barra ocupa todo o espaço.
  final double labelWidth;

  final bool hideLabel;

  final double barHeight;
  final double gapLabelToBar;

  final LabelLocation sliceLabelLocation;
  final bool showSliceLabelsOnBar;

  final int? selectedRowIndex;
  final int? selectedSliceIndex;

  final void Function(
      int rowIndex,
      int sliceIndex,
      String rowLabel,
      String? sliceLabel,
      )? onSliceTap;

  final bool isLoading;

  final double? cardWidth;
  final double? cardHeight;

  /// ✅ Hatch opcional (POR FATIA)
  final SliceHatchConfig? hatch;

  /// ✅ Overlay start/end (intervalo)
  final RangeOverlayConfig? rangeOverlay;

  const HorizontalBarChanged({
    super.key,
    required this.label,
    required this.values,
    this.consumedValues,
    this.sliceColors,
    this.groupLegendLabels,
    this.labelWidth = 150,
    this.hideLabel = false,
    this.barHeight = 24,
    this.gapLabelToBar = 6,
    this.sliceLabelLocation = LabelLocation.aboveBar,
    this.showSliceLabelsOnBar = true,
    this.selectedRowIndex,
    this.selectedSliceIndex,
    this.onSliceTap,
    this.isLoading = false,
    this.cardWidth,
    this.cardHeight,
    this.hatch,
    this.rangeOverlay,
  });

  @override
  State<HorizontalBarChanged> createState() => _HorizontalBarChangedState();
}

class _HorizontalBarChangedState extends State<HorizontalBarChanged>
    with SingleTickerProviderStateMixin {
  int? _internalRow;
  int? _internalSlice;

  @override
  void didUpdateWidget(covariant HorizontalBarChanged oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSliceIndex != widget.selectedSliceIndex ||
        oldWidget.selectedRowIndex != widget.selectedRowIndex) {
      _internalRow = null;
      _internalSlice = null;
    }
  }

  bool get _isControlledExternally =>
      widget.onSliceTap != null ||
          widget.selectedRowIndex != null ||
          widget.selectedSliceIndex != null;

  void _toggleInternal(int row, int slice) {
    setState(() {
      if (_internalRow == row && _internalSlice == slice) {
        _internalRow = null;
        _internalSlice = null;
      } else {
        _internalRow = row;
        _internalSlice = slice;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.values.isEmpty && !widget.isLoading) {
      return _buildEmptyState(context);
    }

    final colors = widget.sliceColors ??
        [
          Colors.blueAccent,
          Colors.green,
          Colors.amber,
        ];

    final effectiveRow = widget.selectedRowIndex ?? _internalRow;
    final effectiveSlice = widget.selectedSliceIndex ?? _internalSlice;

    final Gradient cardGradient = isDark
        ? const LinearGradient(
      colors: [Color(0xFF101018), Color(0xFF171924)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : const LinearGradient(
      colors: [Colors.white, Color(0xFFF5F7FB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.isLoading
            ? _buildShimmer()
            : Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!widget.hideLabel && widget.labelWidth > 0)
              SizedBox(
                width: widget.labelWidth,
                child: Text(
                  widget.label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (!widget.hideLabel && widget.labelWidth > 0)
              SizedBox(width: widget.gapLabelToBar),
            Expanded(
              child: HorizontalStackedBarsBars(
                labels: const [''],
                values: <List<double>>[widget.values],
                groupLegendLabels: widget.showSliceLabelsOnBar
                    ? widget.groupLegendLabels
                    : null,
                colors: colors,
                globalMax: widget.values.fold<double>(0, (a, b) => a + b),
                barHeight: widget.barHeight,
                labelWidth: 0,
                gapLabelToBar: 0,
                sliceLabelLocation: widget.sliceLabelLocation,
                isDark: isDark,
                selectedRowIndex: effectiveRow,
                selectedSliceIndex: effectiveSlice,
                isExternalControlled: _isControlledExternally,
                hatch: widget.hatch,
                rangeOverlay: widget.rangeOverlay,
                onInternalToggleSelection: _toggleInternal,
                onSliceTapExternal: (row, slice, rowLabel, sliceLabel) {
                  if (_isControlledExternally) {
                    widget.onSliceTap
                        ?.call(row, slice, widget.label, sliceLabel);
                  } else {
                    _toggleInternal(row, slice);
                  }
                },
              ),
            ),
          ],
        )
      ],
    );

    Widget card = BasicCard(
      isDark: isDark,
      width: widget.cardWidth ?? double.infinity,
      height: widget.cardHeight,
      gradient: cardGradient,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enableShadow: true,
      child: content,
    );

    if (widget.cardWidth != null || widget.cardHeight != null) {
      card = SizedBox(
        width: widget.cardWidth ?? double.infinity,
        height: widget.cardHeight,
        child: card,
      );
    }

    return card;
  }

  Widget _buildShimmer() => Container(
    height: widget.barHeight,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(6),
    ),
  );

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return BasicCard(
      isDark: theme.brightness == Brightness.dark,
      padding: const EdgeInsets.all(16),
      enableShadow: false,
      child: Row(
        children: const [
          Icon(Icons.bar_chart, size: 18),
          SizedBox(width: 8),
          Text("Sem dados"),
        ],
      ),
    );
  }
}
