// lib/_widgets/charts/linear_bar/horizontal_bar_chart_row.dart
import 'package:flutter/material.dart';

import 'package:siged/_widgets/charts/linear_bar/hatched_fill_light.dart';
import 'package:siged/_widgets/charts/linear_bar/range_overlay.dart';
import 'package:siged/_widgets/charts/linear_bar/range_overlay_config.dart';
import 'package:siged/_widgets/charts/linear_bar/slice_hatch_config.dart';

import 'types.dart';

class HorizontalChartBar extends StatelessWidget {
  final int rowIndex;
  final String label;
  final List<double> values;
  final List<Color> colors;
  final List<String>? groupLegendLabels;

  final double globalMax;
  final double barHeight;
  final double labelWidth;
  final double gapLabelToBar;
  final LabelLocation sliceLabelLocation;
  final bool isDark;

  final int? selectedRowIndex;
  final int? selectedSliceIndex;
  final bool isExternalControlled;

  final int Function(double) flexFromValue;

  final void Function(int rowIndex, int sliceIndex)? onInternalToggleSelection;
  final void Function(
      int rowIndex,
      int sliceIndex,
      String rowLabel,
      String? sliceLabel,
      )? onSliceTapExternal;

  /// ✅ Config opcional de hachura por fatia
  final SliceHatchConfig? hatch;

  /// ✅ Overlay (faixa) start/end com tracejado
  final RangeOverlayConfig? rangeOverlay;

  const HorizontalChartBar({
    super.key,
    required this.rowIndex,
    required this.label,
    required this.values,
    required this.colors,
    required this.globalMax,
    required this.barHeight,
    required this.labelWidth,
    required this.gapLabelToBar,
    required this.sliceLabelLocation,
    required this.isDark,
    required this.selectedRowIndex,
    required this.selectedSliceIndex,
    required this.isExternalControlled,
    required this.flexFromValue,
    this.groupLegendLabels,
    this.onInternalToggleSelection,
    this.onSliceTapExternal,
    this.hatch,
    this.rangeOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final bool rowHasSelection =
        selectedRowIndex != null && selectedRowIndex == rowIndex;

    Widget _wrapSlice(int sliceIndex, Widget child) {
      final String? sliceLabel =
      (groupLegendLabels != null && sliceIndex < groupLegendLabels!.length)
          ? groupLegendLabels![sliceIndex]
          : null;

      return MouseRegion(
        cursor: (isExternalControlled && onSliceTapExternal == null)
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (isExternalControlled) {
              onSliceTapExternal?.call(rowIndex, sliceIndex, label, sliceLabel);
            } else {
              onInternalToggleSelection?.call(rowIndex, sliceIndex);
            }
          },
          child: child,
        ),
      );
    }

    Widget _buildSliceLabelsAboveBar() {
      if (sliceLabelLocation != LabelLocation.aboveBar ||
          groupLegendLabels == null ||
          groupLegendLabels!.isEmpty) {
        return const SizedBox.shrink();
      }

      return Row(
        children: [
          SizedBox(width: labelWidth + gapLabelToBar),
          Expanded(
            child: Row(
              children: List.generate(values.length, (i) {
                final sliceValue = values[i];
                final flex = flexFromValue(sliceValue);
                final labelText =
                i < groupLegendLabels!.length ? groupLegendLabels![i] : '';

                return Expanded(
                  flex: flex,
                  child: _wrapSlice(
                    i,
                    Center(
                      child: Text(
                        labelText,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      );
    }

    Widget _buildLabelAndBarRow() {
      final double overflow = rangeOverlay?.overlayOverflow ?? 0;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            height: barHeight,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ),
          SizedBox(width: gapLabelToBar),
          Expanded(
            child: SizedBox(
              height: barHeight + (overflow * 2),
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // TRACK + SLICES CENTRALIZADOS
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: barHeight,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          // Fundo (track)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : Colors.grey.shade100,
                                  isDark
                                      ? Colors.white.withOpacity(0.03)
                                      : Colors.grey.shade200,
                                ],
                              ),
                            ),
                          ),

                          // Slices (clipadas)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              children: List.generate(values.length, (i) {
                                final sliceValue = values[i];
                                final flexTotal = flexFromValue(sliceValue);
                                final baseColor = colors[i % colors.length];

                                final bool isSelectedSlice =
                                    selectedRowIndex != null &&
                                        selectedSliceIndex != null &&
                                        selectedRowIndex == rowIndex &&
                                        selectedSliceIndex == i;

                                final String? sliceLabel =
                                (groupLegendLabels != null &&
                                    i < (groupLegendLabels?.length ?? 0))
                                    ? groupLegendLabels![i]
                                    : null;

                                // ✅ resolve hatch específico por fatia
                                final SliceHatchStyle? hatchStyle =
                                hatch?.resolve(
                                  sliceIndex: i,
                                  sliceLabel: sliceLabel,
                                );

                                final bool shouldHatch = hatchStyle != null;

                                Color resolveBaseColor() {
                                  if (sliceValue <= 0) {
                                    return baseColor.withOpacity(0.20);
                                  }
                                  if (isSelectedSlice) return Colors.orange;
                                  if (rowHasSelection) {
                                    return baseColor.withOpacity(0.10);
                                  }
                                  return baseColor;
                                }

                                final Color sliceColor = resolveBaseColor();

                                if (sliceValue <= 0 && !isSelectedSlice) {
                                  return Expanded(
                                    flex: 1,
                                    child: _wrapSlice(
                                      i,
                                      ColoredBox(color: sliceColor),
                                    ),
                                  );
                                }

                                // ✅ Hatch por fatia:
                                // - cor da linha: hatchStyle.lineColor (informada)
                                // - cor do fundo: mesma cor, com opacidade (para combinar)
                                if (shouldHatch && !isSelectedSlice) {
                                  final bg = hatchStyle.backgroundColor();
                                  final lc = hatchStyle.lineColor;

                                  return Expanded(
                                    flex: flexTotal,
                                    child: _wrapSlice(
                                      i,
                                      ClipRect(
                                        child: HatchedFillLight(
                                          backgroundColor: bg,
                                          lineColor: lc,
                                          strokeWidth: hatchStyle.strokeWidth,
                                          spacing: hatchStyle.spacing,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final double alpha = sliceColor.opacity;
                                final Color start =
                                sliceColor.withOpacity(alpha);
                                final Color end = sliceColor.withOpacity(
                                  (alpha * 0.9).clamp(0.0, 1.0),
                                );

                                return Expanded(
                                  flex: flexTotal,
                                  child: _wrapSlice(
                                    i,
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [start, end],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // OVERLAY “VAZANDO”
                  if (rangeOverlay != null && rangeOverlay!.isValid)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -overflow,
                      bottom: -overflow,
                      child: IgnorePointer(
                        ignoring: true,
                        child: RangeOverlay(
                          config: rangeOverlay!,
                          isDark: isDark,
                          fallbackMax: globalMax,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: (selectedRowIndex != null && selectedRowIndex == rowIndex)
            ? (isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.blueGrey.withOpacity(0.03))
            : Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sliceLabelLocation == LabelLocation.aboveBar &&
                groupLegendLabels != null &&
                groupLegendLabels!.isNotEmpty)
              _buildSliceLabelsAboveBar(),
            if (sliceLabelLocation == LabelLocation.aboveBar &&
                groupLegendLabels != null &&
                groupLegendLabels!.isNotEmpty)
              const SizedBox(height: 4),
            _buildLabelAndBarRow(),
          ],
        ),
      ),
    );
  }
}
