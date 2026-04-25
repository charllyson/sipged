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

  Widget _buildPendingWidget(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? subtitle,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return ColoredBox(
      color: isDark ? const Color(0xFF121212) : Colors.white,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 42,
                    color: primary.withValues(alpha: 0.90),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle ?? 'Componente em implementação',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
                  values:
                  item.resolvedValues?.cast<double?>() ?? const <double?>[],
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
              child: SimpleCard(
                isDark: isDark,
                primary: primary,
                title: item.resolvedTitle?.trim(),
                value: item.resolvedValue?.trim(),
                label: _resolveCardLabel(activeFilter),
              ),
            );

          case CatalogType.costRuler:
            return _buildPendingWidget(
              context,
              icon: Icons.straighten_rounded,
              title: item.resolvedTitle?.trim().isNotEmpty == true
                  ? item.resolvedTitle!.trim()
                  : 'Régua de custo',
            );

          case CatalogType.gauge:
            return _buildPendingWidget(
              context,
              icon: Icons.speed_rounded,
              title: item.resolvedTitle?.trim().isNotEmpty == true
                  ? item.resolvedTitle!.trim()
                  : 'Gauge',
            );

          case CatalogType.horizontalBars:
            return _buildPendingWidget(
              context,
              icon: Icons.view_stream_rounded,
              title: item.resolvedTitle?.trim().isNotEmpty == true
                  ? item.resolvedTitle!.trim()
                  : 'Barras horizontais',
            );

          case CatalogType.radar:
            return _buildPendingWidget(
              context,
              icon: Icons.radar_rounded,
              title: item.resolvedTitle?.trim().isNotEmpty == true
                  ? item.resolvedTitle!.trim()
                  : 'Radar',
            );

          case CatalogType.treemap:
            return _buildPendingWidget(
              context,
              icon: Icons.grid_view_rounded,
              title: item.resolvedTitle?.trim().isNotEmpty == true
                  ? item.resolvedTitle!.trim()
                  : 'Treemap',
            );

          case CatalogType.selectorDates:
            return _buildPendingWidget(
              context,
              icon: Icons.date_range_rounded,
              title: item.resolvedTitle?.trim().isNotEmpty == true
                  ? item.resolvedTitle!.trim()
                  : 'Seletor de datas',
            );

          case CatalogType.dateField:
            return _buildPendingWidget(
              context,
              icon: Icons.event_rounded,
              title: item.resolvedTitle?.trim().isNotEmpty == true
                  ? item.resolvedTitle!.trim()
                  : 'Campo de data',
            );

          case CatalogType.switcher:
            return _buildPendingWidget(
              context,
              icon: Icons.toggle_on_rounded,
              title: item.resolvedTitle?.trim().isNotEmpty == true
                  ? item.resolvedTitle!.trim()
                  : 'Switch',
            );

          case CatalogType.textField:
            return _buildPendingWidget(
              context,
              icon: Icons.text_fields_rounded,
              title: item.resolvedTitle?.trim().isNotEmpty == true
                  ? item.resolvedTitle!.trim()
                  : 'Campo de texto',
            );

          case CatalogType.pagedTable:
            return _buildPendingWidget(
              context,
              icon: Icons.table_rows_rounded,
              title: item.resolvedTitle?.trim().isNotEmpty == true
                  ? item.resolvedTitle!.trim()
                  : 'Tabela paginada',
            );
        }
      },
    );
  }
}