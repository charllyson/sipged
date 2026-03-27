import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data.dart';
import 'package:sipged/_widgets/charts/bars/bar_chart_changed.dart';

class GeoWorkspaceWidgets extends StatelessWidget {
  const GeoWorkspaceWidgets({
    super.key,
    required this.item,
    required this.size,
  });

  final GeoWorkspaceData item;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GeoWorkspaceCubit>();

    switch (item.type) {
      case GeoWorkspaceWidgetType.barVertical:
        final resolved = cubit.resolveBarVertical(item);

        if (!resolved.hasData) {
          return _WorkspaceEmptyState(
            title: resolved.title ?? 'Barra vertical',
            subtitle: 'Vincule Fonte, Campo label e Campo valor.',
          );
        }

        return ColoredBox(
          color: Colors.white,
          child: RepaintBoundary(
            child: BarChartChanged(
              chartTitle: resolved.title,
              labels: resolved.labels ?? const <String>[],
              values: resolved.values?.cast<double?>() ?? const <double?>[],
              expandToMaxWidth: true,
              widthGraphic: size.width,
              heightGraphic: size.height,
              widthBar: item.getNullableNumberProperty('widthBar') ?? 34,
              widthTitleBar: item.getNullableNumberProperty('widthTitleBar') ?? 60,
            ),
          ),
        );

      case GeoWorkspaceWidgetType.donut:
        final resolved = cubit.resolveDonut(item);

        if (!resolved.hasData) {
          return _WorkspaceEmptyState(
            title: resolved.title ?? 'Rosca',
            subtitle: 'Vincule Fonte, Campo label e Campo valor.',
          );
        }

        return _DonutChartWidget(
          title: resolved.title,
          labels: resolved.labels!,
          values: resolved.values!,
        );

      case GeoWorkspaceWidgetType.line:
        final resolved = cubit.resolveLine(item);

        if (!resolved.hasData) {
          return _WorkspaceEmptyState(
            title: resolved.title ?? 'Linha',
            subtitle: 'Vincule Fonte, Campo label e Campo valor.',
          );
        }

        return _LineChartWidget(
          title: resolved.title,
          labels: resolved.labels!,
          values: resolved.values!,
        );

      case GeoWorkspaceWidgetType.card:
        final resolved = cubit.resolveCard(item);

        return ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _CardBody(
                  title: resolved.title,
                  subtitle: resolved.subtitle,
                  label: resolved.label,
                  value: resolved.value,
                ),
              ),
            ),
          ),
        );

      case GeoWorkspaceWidgetType.kpi:
        final resolved = cubit.resolveKpi(item);

        return ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _KpiBody(
                  title: resolved.title,
                  variation: resolved.subtitle,
                  label: resolved.label,
                  value: resolved.value,
                ),
              ),
            ),
          ),
        );

      case GeoWorkspaceWidgetType.table:
        final resolved = cubit.resolveTable(item);

        if (!resolved.hasData) {
          return _WorkspaceEmptyState(
            title: resolved.title ?? 'Tabela',
            subtitle: 'Defina Fonte e Colunas.',
          );
        }

        return _TableWidget(
          title: resolved.title,
          columns: resolved.columns,
          rows: resolved.rows,
        );
    }
  }
}

class _WorkspaceEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _WorkspaceEmptyState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insights_outlined,
                size: 30,
                color: theme.colorScheme.primary.withValues(alpha: 0.75),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.black.withValues(alpha: 0.58),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.title,
    required this.subtitle,
    required this.label,
    required this.value,
  });

  final String? title;
  final String? subtitle;
  final String? label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final titleText = (title ?? '').trim().isEmpty ? 'Card resumo' : title!;
    final subtitleText = subtitle?.trim();
    final labelText = label?.trim();
    final valueText = value?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          titleText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitleText != null && subtitleText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitleText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.60),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          (valueText == null || valueText.isEmpty) ? '--' : valueText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          (labelText == null || labelText.isEmpty) ? 'Sem dados' : labelText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.68),
          ),
        ),
      ],
    );
  }
}

class _KpiBody extends StatelessWidget {
  const _KpiBody({
    required this.title,
    required this.variation,
    required this.label,
    required this.value,
  });

  final String? title;
  final String? variation;
  final String? label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final titleText = (title ?? '').trim().isEmpty ? 'KPI' : title!;
    final variationText = variation?.trim();
    final labelText = label?.trim();
    final valueText = value?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          (valueText == null || valueText.isEmpty) ? '--' : valueText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          (labelText == null || labelText.isEmpty) ? 'Sem label' : labelText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.65),
          ),
        ),
        if (variationText != null && variationText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            variationText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _DonutChartWidget extends StatelessWidget {
  final String? title;
  final List<String> labels;
  final List<double> values;

  const _DonutChartWidget({
    required this.title,
    required this.labels,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final total = values.fold<double>(0, (sum, item) => sum + item);

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if ((title ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 34,
                        sectionsSpace: 2,
                        sections: List.generate(labels.length, (index) {
                          final value = values[index];
                          final percent =
                          total <= 0 ? 0.0 : (value / total) * 100.0;

                          return PieChartSectionData(
                            value: value,
                            radius: 46,
                            title: '${percent.toStringAsFixed(0)}%',
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: ListView.separated(
                      itemCount: labels.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (_, index) {
                        return Text(
                          '${labels[index]} • ${values[index].toStringAsFixed(2)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  final String? title;
  final List<String> labels;
  final List<double> values;

  const _LineChartWidget({
    required this.title,
    required this.labels,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = values.isEmpty
        ? 10.0
        : values.reduce((a, b) => a > b ? a : b) * 1.15;

    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          children: [
            if ((title ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY <= 0 ? 10 : maxY,
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[index],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.10),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      spots: List.generate(
                        values.length,
                            (index) => FlSpot(index.toDouble(), values[index]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableWidget extends StatelessWidget {
  final String? title;
  final List<String> columns;
  final List<Map<String, String>> rows;

  const _TableWidget({
    required this.title,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          if ((title ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 38,
                  dataRowMinHeight: 34,
                  dataRowMaxHeight: 40,
                  columns: columns
                      .map(
                        (col) => DataColumn(
                      label: Text(
                        col,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                      .toList(growable: false),
                  rows: rows
                      .map(
                        (row) => DataRow(
                      cells: columns
                          .map(
                            (col) => DataCell(
                          Text(
                            row[col] ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                          .toList(growable: false),
                    ),
                  )
                      .toList(growable: false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}