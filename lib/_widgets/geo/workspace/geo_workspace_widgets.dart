import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data.dart';
import 'package:sipged/_widgets/cards/simple/simple_card.dart';
import 'package:sipged/_widgets/charts/bars/bar_chart_changed.dart';
import 'package:sipged/_widgets/charts/donut/donut_chart_changed.dart';
import 'package:sipged/_widgets/charts/lines/line_chart_changed.dart';
import 'package:sipged/_widgets/geo/workspace/geo_table.dart';
import 'package:sipged/_widgets/resize/resize_data.dart';

class GeoWorkspaceWidgets extends StatelessWidget {
  const GeoWorkspaceWidgets({
    super.key,
    required this.item,
    required this.size,
  });

  final ResizeData item;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GeoWorkspaceCubit>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    switch (item.type) {
      case GeoWorkspaceWidgetType.barVertical:
        final resolved = cubit.resolveBarVertical(item);

        return ColoredBox(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          child: RepaintBoundary(
            child: BarChartChanged(
              chartTitle: resolved.title,
              labels: resolved.labels ?? const <String>[],
              values: resolved.values?.cast<double?>() ?? const <double?>[],
              expandToMaxWidth: true,
              widthGraphic: size.width,
              heightGraphic: size.height,
              widthBar: item.getNullableNumberProperty('widthBar') ?? 34,
              widthTitleBar:
              item.getNullableNumberProperty('widthTitleBar') ?? 60,
            ),
          ),
        );

      case GeoWorkspaceWidgetType.donut:
        final resolved = cubit.resolveDonut(item);

        return ColoredBox(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          child: Center(
            child: RepaintBoundary(
              child: DonutChartChanged(
                labels: resolved.labels ?? const <String>[],
                values: resolved.values ?? const <double>[],
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

      case GeoWorkspaceWidgetType.line:
        final resolved = cubit.resolveLine(item);

        return ColoredBox(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          child: Center(
            child: RepaintBoundary(
              child: LineChartChanged(
                labels: resolved.labels ?? const <String>[],
                values: resolved.values ?? const <double>[],
                larguraGrafico: size.width,
                alturaGrafico: size.height,
                headerTitle: resolved.title,
                headerSubtitle: 'Evolução no tempo',
                headerIcon: Icons.show_chart_rounded,
                showLegend: false,
              ),
            ),
          ),
        );

      case GeoWorkspaceWidgetType.card:
        final resolved = cubit.resolveCard(item);

        return ColoredBox(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SimpleCard(
              isDark: isDark,
              primary: primary,
              title: resolved.title,
              value: resolved.value?.trim(),
              label: resolved.label?.trim(),
            ),
          ),
        );

      case GeoWorkspaceWidgetType.table:
        final resolved = cubit.resolveTable(item);

        return GeoTable(
          title: resolved.title,
          columns: resolved.columns,
          rows: resolved.rows,
        );
    }
  }
}