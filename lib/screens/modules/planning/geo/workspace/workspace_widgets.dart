import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_filter.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_state.dart';

import 'package:sipged/_utils/theme/sipged_theme.dart';
import 'package:sipged/_widgets/DataTime/date_field_change.dart';
import 'package:sipged/_widgets/DataTime/selector/selector_dates.dart';
import 'package:sipged/_widgets/DataTime/time_field_change.dart';

import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/cards/simple/simple_card.dart';

import 'package:sipged/_widgets/charts/bars/bar_chart_changed.dart';
import 'package:sipged/_widgets/charts/donut/donut_chart_changed.dart';
import 'package:sipged/_widgets/charts/lines/line_chart_changed.dart';
import 'package:sipged/_widgets/charts/treemap/treemap_chart_changed.dart';
import 'package:sipged/_widgets/charts/treemap/treemap_class.dart';

class WorkspaceWidgets extends StatelessWidget {
  const WorkspaceWidgets({
    super.key,
    required this.item,
    required this.size,
  });

  final WorkspaceData item;
  final Size size;

  bool _isFilterFromThisItem(WorkspaceFilter? filter) {
    return filter != null && filter.sourceItemId == item.id;
  }

  bool _isSameSourceLayer(WorkspaceFilter? filter) {
    return filter != null &&
        item.sourceLayerId != null &&
        item.sourceLayerId == filter.sourceLayerId;
  }

  int? _selectedIndexFromFilter(WorkspaceFilter? filter) {
    if (!_isFilterFromThisItem(filter)) return null;

    final labels = item.resolvedLabels ?? const <String>[];
    final filterLabel = filter!.label.trim();

    for (var i = 0; i < labels.length; i++) {
      if (labels[i].trim().toUpperCase() == filterLabel.toUpperCase()) {
        return i;
      }
    }

    return null;
  }

  String? _selectedLabelFromFilter(WorkspaceFilter? filter) {
    if (!_isFilterFromThisItem(filter)) return null;
    return filter?.label;
  }

  double? _resolveTappedValue(String label) {
    final labels = item.resolvedLabels ?? const <String>[];
    final values = item.resolvedValues ?? const <double>[];

    for (var i = 0; i < labels.length; i++) {
      if (labels[i].trim().toUpperCase() == label.trim().toUpperCase()) {
        if (i >= values.length) return null;
        return values[i];
      }
    }

    return null;
  }

  String? _resolveCardLabel(WorkspaceFilter? filter) {
    final base = item.resolvedLabel?.trim();

    final isExternal = filter != null &&
        filter.sourceItemId != item.id &&
        _isSameSourceLayer(filter);

    if (!isExternal) {
      return (base?.isNotEmpty ?? false) ? base : null;
    }

    if (base != null && base.isNotEmpty) {
      return '$base • Filtro: ${filter.label}';
    }

    return 'Filtro: ${filter.label}';
  }

  void _handleInteractiveLabelSelection(
      BuildContext context,
      String? label,
      ) {
    final cubit = context.read<WorkspaceCubit>();

    if (label == null || label.trim().isEmpty) {
      cubit.clearFilter();
      return;
    }

    cubit.toggleItemFilter(
      itemId: item.id,
      label: label,
      value: _resolveTappedValue(label),
    );
  }

  List<double>? _resolveFilteredValuesForVisualHighlight(
      WorkspaceFilter? filter,
      ) {
    if (filter == null) return null;

    final labels = item.resolvedLabels ?? const <String>[];
    final values = item.resolvedValues ?? const <double>[];

    if (labels.isEmpty || values.isEmpty || labels.length != values.length) {
      return null;
    }

    if (!_isSameSourceLayer(filter)) {
      return null;
    }

    return List<double>.generate(
      labels.length,
          (index) {
        final label = labels[index].trim().toUpperCase();
        final selectedLabel = filter.label.trim().toUpperCase();

        if (label == selectedLabel) {
          return values[index];
        }

        return 0.0;
      },
      growable: false,
    );
  }

  List<TreemapItem> _buildTreemapItems() {
    final labels = item.resolvedLabels ?? const <String>[];
    final values = item.resolvedValues ?? const <double>[];

    if (labels.isEmpty || values.isEmpty || labels.length != values.length) {
      return const <TreemapItem>[];
    }

    return List<TreemapItem>.generate(
      labels.length,
          (index) {
        final label = labels[index].trim();
        final value = values[index];

        return TreemapItem(
          label: label.isEmpty ? 'Sem rótulo' : label,
          value: value,
          color: SipGedTheme.chartPaletteColors(index),
        );
      },
      growable: false,
    );
  }

  bool _boolProperty(String key, {bool fallback = false}) {
    for (final property in item.properties) {
      if (property.key != key) continue;

      final selected = property.selectedValue?.trim().toLowerCase();
      final text = property.textValue?.trim().toLowerCase();

      final raw = selected?.isNotEmpty == true ? selected : text;

      if (raw == 'true' || raw == 'sim' || raw == 'yes' || raw == '1') {
        return true;
      }

      if (raw == 'false' || raw == 'nao' || raw == 'não' || raw == 'no' || raw == '0') {
        return false;
      }
    }

    return fallback;
  }

  String? _textProperty(String key) {
    for (final property in item.properties) {
      if (property.key != key) continue;

      final text = property.textValue?.trim();
      final selected = property.selectedValue?.trim();

      if (text != null && text.isNotEmpty) return text;
      if (selected != null && selected.isNotEmpty) return selected;
    }

    return null;
  }

  List<_WorkspaceDatePoint> _buildDatePoints() {
    final labels = item.resolvedLabels ?? const <String>[];
    final values = item.resolvedValues ?? const <double>[];

    if (labels.isEmpty) {
      return const <_WorkspaceDatePoint>[];
    }

    return List<_WorkspaceDatePoint>.generate(
      labels.length,
          (index) {
        final label = labels[index].trim();
        final date = _parseDateLabel(label);

        return _WorkspaceDatePoint(
          label: label,
          date: date,
          value: index < values.length ? values[index] : null,
        );
      },
      growable: false,
    ).where((point) => point.date != null).toList(growable: false);
  }

  DateTime? _parseDateLabel(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return null;

    final formats = <DateFormat>[
      DateFormat('dd/MM/yyyy'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('MM/yyyy'),
      DateFormat('yyyy/MM'),
      DateFormat('yyyy'),
    ];

    for (final format in formats) {
      try {
        final parsed = format.parseStrict(clean);

        if (format.pattern == 'yyyy') {
          return DateTime(parsed.year);
        }

        if (format.pattern == 'MM/yyyy' || format.pattern == 'yyyy/MM') {
          return DateTime(parsed.year, parsed.month);
        }

        return DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {
        continue;
      }
    }

    final year = int.tryParse(clean);
    if (year != null && year >= 1900 && year <= 3000) {
      return DateTime(year);
    }

    return null;
  }

  String _dateSelectionLabel({
    required int? selectedYear,
    required int? selectedMonth,
    required int? selectedDay,
  }) {
    if (selectedYear == null) return '';

    if (selectedMonth == null) {
      return selectedYear.toString();
    }

    if (selectedDay == null) {
      return '${selectedMonth.toString().padLeft(2, '0')}/$selectedYear';
    }

    return '${selectedDay.toString().padLeft(2, '0')}/'
        '${selectedMonth.toString().padLeft(2, '0')}/'
        '$selectedYear';
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

  Widget _buildBarVertical(
      BuildContext context,
      WorkspaceFilter? activeFilter,
      ) {
    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF121212)
          : Colors.white,
      child: RepaintBoundary(
        child: BarChartChanged(
          selectedIndex: _selectedIndexFromFilter(activeFilter),
          onBarSelectionChanged: (label) {
            _handleInteractiveLabelSelection(context, label);
          },
          chartTitle: item.resolvedTitle,
          labels: item.resolvedLabels ?? const <String>[],
          values: item.resolvedValues?.cast<double?>() ?? const <double?>[],
          filteredValues: _resolveFilteredValuesForVisualHighlight(
            activeFilter,
          )?.cast<double?>(),
          expandToMaxWidth: true,
          widthGraphic: size.width,
          heightGraphic: size.height,
          widthBar: item.getNullableNumberProperty('widthBar') ?? 34,
          widthTitleBar: item.getNullableNumberProperty('widthTitleBar') ?? 60,
        ),
      ),
    );
  }

  Widget _buildDonut(
      BuildContext context,
      WorkspaceFilter? activeFilter,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: isDark ? const Color(0xFF121212) : Colors.white,
      child: Center(
        child: RepaintBoundary(
          child: DonutChartChanged(
            selectedIndex: _selectedIndexFromFilter(activeFilter),
            selectedLabel: _selectedLabelFromFilter(activeFilter),
            onTapLabel: (label) {
              _handleInteractiveLabelSelection(context, label);
            },
            labels: item.resolvedLabels ?? const <String>[],
            values: item.resolvedValues ?? const <double>[],
            filteredValues: _resolveFilteredValuesForVisualHighlight(
              activeFilter,
            ),
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
  }

  Widget _buildLine(
      BuildContext context,
      WorkspaceFilter? activeFilter,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            headerSubtitle:
            activeFilter != null && _isSameSourceLayer(activeFilter)
                ? 'Filtro: ${activeFilter.label}'
                : 'Evolução no tempo',
            headerIcon: Icons.show_chart_rounded,
            showLegend: false,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context,
      WorkspaceFilter? activeFilter,
      ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

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
  }

  Widget _buildTreemap(
      BuildContext context,
      WorkspaceFilter? activeFilter,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: isDark ? const Color(0xFF121212) : Colors.white,
      child: RepaintBoundary(
        child: TreemapChartChanged(
          items: _buildTreemapItems(),
          filteredValues: _resolveFilteredValuesForVisualHighlight(
            activeFilter,
          )?.cast<double?>(),
          heightGraphic: size.height,
          expandToMaxWidth: true,
          onItemSelected: (label) {
            _handleInteractiveLabelSelection(context, label);
          },
        ),
      ),
    );
  }

  Widget _buildSelectorDates(
      BuildContext context,
      WorkspaceFilter? activeFilter,
      ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final points = _buildDatePoints();
    final title = item.resolvedTitle?.trim();
    final enableDaySelection = _boolProperty('enableDaySelection');

    return ColoredBox(
      color: isDark ? const Color(0xFF121212) : Colors.white,
      child: BasicCard(
        isDark: isDark,
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(12),
        backgroundColor: Colors.white,
        enableShadow: true,
        child: points.isEmpty
            ? _buildPendingWidget(
          context,
          icon: Icons.date_range_rounded,
          title: title?.isNotEmpty == true ? title! : 'Seletor de datas',
          subtitle: 'Arraste um campo de data válido para usar o filtro.',
        )
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null && title.isNotEmpty) ...[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SelectorDates<_WorkspaceDatePoint>(
                items: points,
                getDate: (point) => point.date,
                getLabel: (point) => point.label,
                autoSelectInitial: false,
                enableDaySelection: enableDaySelection,
                sortByDate: true,
                sortDescending: false,
                onSelectionChanged: ({
                  required filteredItems,
                  selectedYear,
                  selectedMonth,
                  selectedDay,
                }) {
                  final label = _dateSelectionLabel(
                    selectedYear: selectedYear,
                    selectedMonth: selectedMonth,
                    selectedDay: selectedDay,
                  );

                  if (label.trim().isEmpty) {
                    context.read<WorkspaceCubit>().clearFilter();
                    return;
                  }

                  context.read<WorkspaceCubit>().toggleItemFilter(
                    itemId: item.id,
                    label: label,
                    value: filteredItems.fold<double>(
                      0.0,
                          (sum, point) => sum + (point.value ?? 0.0),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(
      BuildContext context,
      WorkspaceFilter? activeFilter,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: isDark ? const Color(0xFF121212) : Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _WorkspaceDateField(
            width: size.width - 24,
            labelText: _textProperty('labelText') ?? item.resolvedTitle ?? 'Data',
            hintText: _textProperty('hintText') ?? 'Selecione uma data',
            onChanged: (date) {
              if (date == null) {
                context.read<WorkspaceCubit>().clearFilter();
                return;
              }

              final label = DateFormat('dd/MM/yyyy').format(date);

              context.read<WorkspaceCubit>().toggleItemFilter(
                itemId: item.id,
                label: label,
                value: null,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField(
      BuildContext context,
      WorkspaceFilter? activeFilter,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: isDark ? const Color(0xFF121212) : Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _WorkspaceTimeField(
            labelText: _textProperty('labelText') ?? item.resolvedTitle ?? 'Hora',
            hintText: _textProperty('hintText') ?? 'Selecione uma hora',
            onChanged: (time) {
              if (time == null) {
                context.read<WorkspaceCubit>().clearFilter();
                return;
              }

              final label = DateFormat('HH:mm').format(time);

              context.read<WorkspaceCubit>().toggleItemFilter(
                itemId: item.id,
                label: label,
                value: null,
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WorkspaceCubit, WorkspaceState, WorkspaceFilter?>(
      selector: (state) => state.activeFilter,
      builder: (context, activeFilter) {
        switch (item.type) {
          case CatalogType.barVertical:
            return _buildBarVertical(context, activeFilter);

          case CatalogType.donut:
            return _buildDonut(context, activeFilter);

          case CatalogType.line:
            return _buildLine(context, activeFilter);

          case CatalogType.card:
            return _buildCard(context, activeFilter);

          case CatalogType.treemap:
            return _buildTreemap(context, activeFilter);

          case CatalogType.selectorDates:
            return _buildSelectorDates(context, activeFilter);

          case CatalogType.dateField:
            return _buildDateField(context, activeFilter);

          case CatalogType.timeField:
            return _buildTimeField(context, activeFilter);

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

class _WorkspaceDatePoint {
  const _WorkspaceDatePoint({
    required this.label,
    required this.date,
    required this.value,
  });

  final String label;
  final DateTime? date;
  final double? value;
}

class _WorkspaceDateField extends StatefulWidget {
  const _WorkspaceDateField({
    required this.labelText,
    required this.hintText,
    required this.onChanged,
    this.width,
  });

  final String labelText;
  final String hintText;
  final ValueChanged<DateTime?> onChanged;
  final double? width;

  @override
  State<_WorkspaceDateField> createState() => _WorkspaceDateFieldState();
}

class _WorkspaceDateFieldState extends State<_WorkspaceDateField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DateFieldChange(
      controller: _controller,
      width: widget.width,
      labelText: widget.labelText,
      hint: widget.hintText,
      enabled: true,
      onChanged: widget.onChanged,
    );
  }
}

class _WorkspaceTimeField extends StatefulWidget {
  const _WorkspaceTimeField({
    required this.labelText,
    required this.hintText,
    required this.onChanged,
  });

  final String labelText;
  final String hintText;
  final ValueChanged<DateTime?> onChanged;

  @override
  State<_WorkspaceTimeField> createState() => _WorkspaceTimeFieldState();
}

class _WorkspaceTimeFieldState extends State<_WorkspaceTimeField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TimeFieldChange(
      controller: _controller,
      labelText: widget.labelText,
      hint: widget.hintText,
      enabled: true,
      onChanged: widget.onChanged,
    );
  }
}