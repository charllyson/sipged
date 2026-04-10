import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_filter.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_state.dart';
import 'package:sipged/_widgets/cards/simple/simple_card.dart';
import 'package:sipged/_widgets/charts/bars/bar_chart_changed.dart';
import 'package:sipged/_widgets/charts/donut/donut_chart_changed.dart';
import 'package:sipged/_widgets/charts/lines/line_chart_changed.dart';

class WorkspaceWidgets extends StatelessWidget {
  const WorkspaceWidgets({
    super.key,
    required this.item,
    required this.size,
  });

  final WorkspaceData item;
  final Size size;

  int? _selectedBarIndex(WorkspaceFilter? filter) {
    if (filter == null) return null;
    if (filter.sourceItemId != item.id) return null;

    final labels = item.resolvedLabels ?? const <String>[];
    final index = labels.indexOf(filter.label);
    return index >= 0 ? index : null;
  }

  double? _resolveTappedValue(String label) {
    final labels = item.resolvedLabels ?? const <String>[];
    final values = item.resolvedValues ?? const <double>[];

    final index = labels.indexOf(label);
    if (index < 0) return null;
    if (index >= values.length) return null;
    return values[index];
  }

  String? _resolveCardLabel(WorkspaceFilter? filter) {
    final base = item.resolvedLabel?.trim();
    final sameLayer =
        filter != null && item.sourceLayerId == filter.sourceLayerId;
    final isExternal =
        filter != null && filter.sourceItemId != item.id && sameLayer;

    if (!isExternal) {
      return (base?.isNotEmpty ?? false) ? base : null;
    }

    if (base != null && base.isNotEmpty) {
      return '$base • Filtro: ${filter.label}';
    }

    return 'Filtro: ${filter.label}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return BlocSelector<WorkspaceCubit, WorkspaceState, WorkspaceFilter?>(
      selector: (state) => state.activeFilter,
      builder: (context, activeFilter) {
        final selectedBarIndex = _selectedBarIndex(activeFilter);

        switch (item.type) {
          case CatalogType.barVertical:
            return ColoredBox(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              child: RepaintBoundary(
                child: BarChartChanged(
                  selectedIndex: selectedBarIndex,
                  onBarTap: (label) {
                    context.read<WorkspaceCubit>().toggleBarFilter(
                      itemId: item.id,
                      label: label,
                      value: _resolveTappedValue(label),
                    );
                  },
                  chartTitle: item.resolvedTitle,
                  labels: item.resolvedLabels ?? const <String>[],
                  values: item.resolvedValues?.cast<double?>() ??
                      const <double?>[],
                  expandToMaxWidth: true,
                  widthGraphic: size.width,
                  heightGraphic: size.height,
                  widthBar: item.getNullableNumberProperty('widthBar') ?? 34,
                  widthTitleBar:
                  item.getNullableNumberProperty('widthTitleBar') ?? 60,
                ),
              ),
            );

          case CatalogType.donut:
            return ColoredBox(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              child: Center(
                child: RepaintBoundary(
                  child: DonutChartChanged(
                    labels: item.resolvedLabels ?? const <String>[],
                    values: item.resolvedValues ?? const <double>[],
                    widthGraphic: size.width,
                    heightGraphic: size.height,
                    valueFormatType: ValueFormatType.decimal,
                    legendPosition: size.width >= 520
                        ? DonutLegendPosition.right
                        : DonutLegendPosition.bottom,
                  ),
                ),
              ),
            );

          case CatalogType.line:
            return ColoredBox(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              child: Center(
                child: RepaintBoundary(
                  child: LineChartChanged(
                    labels: item.resolvedLabels ?? const <String>[],
                    values: item.resolvedValues ?? const <double>[],
                    larguraGrafico: size.width,
                    alturaGrafico: size.height,
                    headerTitle: item.resolvedTitle,
                    headerSubtitle: 'Evolução no tempo',
                    headerIcon: Icons.show_chart_rounded,
                    showLegend: false,
                  ),
                ),
              ),
            );

          case CatalogType.card:
            return ColoredBox(
              color: isDark ? const Color(0xFF121212) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SimpleCard(
                  isDark: isDark,
                  primary: primary,
                  title: item.resolvedTitle?.trim(),
                  value: item.resolvedValue?.trim(),
                  label: _resolveCardLabel(activeFilter),
                ),
              ),
            );
        }
      },
    );
  }
}