import 'dart:math' as math;

import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_item_data.dart';

class GeoWorkspaceResolvedChartData {
  final String? title;
  final List<String>? labels;
  final List<double>? values;

  const GeoWorkspaceResolvedChartData({
    this.title,
    this.labels,
    this.values,
  });

  bool get hasData =>
      labels != null &&
          values != null &&
          labels!.isNotEmpty &&
          values!.isNotEmpty &&
          labels!.length == values!.length;
}

class GeoWorkspaceResolvedCardData {
  final String? title;
  final String? subtitle;
  final String? label;
  final String? value;

  const GeoWorkspaceResolvedCardData({
    this.title,
    this.subtitle,
    this.label,
    this.value,
  });

  bool get hasData =>
      (value?.trim().isNotEmpty ?? false) || (label?.trim().isNotEmpty ?? false);
}

class GeoWorkspaceResolvedTableData {
  final String? title;
  final List<String> columns;
  final List<Map<String, String>> rows;

  const GeoWorkspaceResolvedTableData({
    this.title,
    this.columns = const [],
    this.rows = const [],
  });

  bool get hasData => columns.isNotEmpty && rows.isNotEmpty;
}

class GeoWorkspaceDataResolver {
  const GeoWorkspaceDataResolver._();

  static GeoWorkspaceResolvedChartData resolveBarVertical({
    required GeoWorkspaceItemData item,
    required Map<String, List<GeoFeatureData>> featuresByLayer,
  }) {
    return _resolveGroupedChart(
      item: item,
      featuresByLayer: featuresByLayer,
      titleKey: 'chartTitle',
    );
  }

  static GeoWorkspaceResolvedChartData resolveDonut({
    required GeoWorkspaceItemData item,
    required Map<String, List<GeoFeatureData>> featuresByLayer,
  }) {
    return _resolveGroupedChart(
      item: item,
      featuresByLayer: featuresByLayer,
      titleKey: 'chartTitle',
    );
  }

  static GeoWorkspaceResolvedChartData resolveLine({
    required GeoWorkspaceItemData item,
    required Map<String, List<GeoFeatureData>> featuresByLayer,
  }) {
    return _resolveGroupedChart(
      item: item,
      featuresByLayer: featuresByLayer,
      titleKey: 'chartTitle',
      fallbackSort: 'labelAZ',
    );
  }

  static GeoWorkspaceResolvedCardData resolveCard({
    required GeoWorkspaceItemData item,
    required Map<String, List<GeoFeatureData>> featuresByLayer,
  }) {
    return _resolveMetricCard(
      item: item,
      featuresByLayer: featuresByLayer,
      titleKey: 'title',
      subtitleKey: 'subtitle',
    );
  }

  static GeoWorkspaceResolvedCardData resolveKpi({
    required GeoWorkspaceItemData item,
    required Map<String, List<GeoFeatureData>> featuresByLayer,
  }) {
    return _resolveMetricCard(
      item: item,
      featuresByLayer: featuresByLayer,
      titleKey: 'title',
      subtitleKey: 'variation',
    );
  }

  static GeoWorkspaceResolvedTableData resolveTable({
    required GeoWorkspaceItemData item,
    required Map<String, List<GeoFeatureData>> featuresByLayer,
  }) {
    final sourceBinding = item.getBindingProperty('source');

    final sourceLayerId = _resolveSourceLayerId(
      sourceBinding: sourceBinding,
      bindings: item.properties.map((e) => e.bindingValue).toList(growable: false),
    );

    final title = item.getNullableTextProperty('title');
    final columns = item.getNullableStringListProperty('columns') ?? const <String>[];

    if (sourceLayerId == null || sourceLayerId.isEmpty) {
      return GeoWorkspaceResolvedTableData(title: title, columns: columns, rows: const []);
    }

    final features = featuresByLayer[sourceLayerId] ?? const <GeoFeatureData>[];
    if (features.isEmpty || columns.isEmpty) {
      return GeoWorkspaceResolvedTableData(title: title, columns: columns, rows: const []);
    }

    final rows = <Map<String, String>>[];

    for (final feature in features.take(100)) {
      final map = <String, String>{};
      for (final column in columns) {
        final raw = feature.properties[column];
        map[column] = raw?.toString().trim().isNotEmpty == true
            ? raw.toString().trim()
            : '-';
      }
      rows.add(map);
    }

    return GeoWorkspaceResolvedTableData(
      title: title,
      columns: columns,
      rows: rows,
    );
  }

  static GeoWorkspaceResolvedChartData _resolveGroupedChart({
    required GeoWorkspaceItemData item,
    required Map<String, List<GeoFeatureData>> featuresByLayer,
    required String titleKey,
    String fallbackSort = 'none',
  }) {
    final sourceBinding = item.getBindingProperty('source');
    final labelBinding = item.getBindingProperty('labelField');
    final valueBinding = item.getBindingProperty('valueField');

    final sourceLayerId = _resolveSourceLayerId(
      sourceBinding: sourceBinding,
      bindings: [labelBinding, valueBinding],
    );

    final title = item.getNullableTextProperty(titleKey);

    if (sourceLayerId == null) {
      return GeoWorkspaceResolvedChartData(
        title: title,
        labels: null,
        values: null,
      );
    }

    final features = featuresByLayer[sourceLayerId] ?? const <GeoFeatureData>[];
    if (features.isEmpty) {
      return GeoWorkspaceResolvedChartData(
        title: title,
        labels: null,
        values: null,
      );
    }

    final labelField = labelBinding?.fieldName?.trim();
    final valueField = valueBinding?.fieldName?.trim();
    final aggregation = item.getNullableSelectedProperty('aggregation') ?? 'Soma';
    final sortType = item.getNullableSelectedProperty('sortType') ?? fallbackSort;

    if (labelField == null || labelField.isEmpty) {
      return GeoWorkspaceResolvedChartData(
        title: title,
        labels: null,
        values: null,
      );
    }

    if (aggregation != 'Contagem' && (valueField == null || valueField.isEmpty)) {
      return GeoWorkspaceResolvedChartData(
        title: title,
        labels: null,
        values: null,
      );
    }

    final rows = _groupAndAggregate(
      features: features,
      labelField: labelField,
      valueField: valueField,
      aggregation: aggregation,
    );

    if (rows.isEmpty) {
      return GeoWorkspaceResolvedChartData(
        title: title,
        labels: null,
        values: null,
      );
    }

    final sorted = _sortRows(rows, sortType);

    return GeoWorkspaceResolvedChartData(
      title: title,
      labels: sorted.map((e) => e.label).toList(growable: false),
      values: sorted.map((e) => e.value).toList(growable: false),
    );
  }

  static GeoWorkspaceResolvedCardData _resolveMetricCard({
    required GeoWorkspaceItemData item,
    required Map<String, List<GeoFeatureData>> featuresByLayer,
    required String titleKey,
    required String subtitleKey,
  }) {
    final sourceBinding = item.getBindingProperty('source');
    final labelBinding = item.getBindingProperty('label');
    final valueBinding = item.getBindingProperty('value');

    final sourceLayerId = _resolveSourceLayerId(
      sourceBinding: sourceBinding,
      bindings: [labelBinding, valueBinding],
    );

    if (sourceLayerId == null) {
      return GeoWorkspaceResolvedCardData(
        title: item.getNullableTextProperty(titleKey),
        subtitle: item.getNullableTextProperty(subtitleKey),
        label: null,
        value: null,
      );
    }

    final features = featuresByLayer[sourceLayerId] ?? const <GeoFeatureData>[];
    if (features.isEmpty) {
      return GeoWorkspaceResolvedCardData(
        title: item.getNullableTextProperty(titleKey),
        subtitle: item.getNullableTextProperty(subtitleKey),
        label: null,
        value: null,
      );
    }

    final labelField = labelBinding?.fieldName?.trim();
    final valueField = valueBinding?.fieldName?.trim();
    final aggregation = item.getNullableSelectedProperty('aggregation') ?? 'Contagem';

    String? resolvedLabel;
    if (labelField != null && labelField.isNotEmpty) {
      resolvedLabel = _firstNonEmptyValue(features, labelField);
    }

    String? resolvedValue;
    if (aggregation == 'Contagem') {
      resolvedValue = features.length.toString();
    } else if (valueField != null && valueField.isNotEmpty) {
      resolvedValue = _aggregateSingleField(
        features: features,
        valueField: valueField,
        aggregation: aggregation,
      );
    }

    return GeoWorkspaceResolvedCardData(
      title: item.getNullableTextProperty(titleKey),
      subtitle: item.getNullableTextProperty(subtitleKey),
      label: resolvedLabel,
      value: resolvedValue,
    );
  }

  static String? _resolveSourceLayerId({
    GeoWorkspaceFieldBinding? sourceBinding,
    required List<GeoWorkspaceFieldBinding?> bindings,
  }) {
    final sourceId = sourceBinding?.sourceId?.trim();
    if (sourceId != null && sourceId.isNotEmpty) {
      return sourceId;
    }

    for (final binding in bindings) {
      final candidate = binding?.sourceId?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }

    return null;
  }

  static List<_GroupedRow> _groupAndAggregate({
    required List<GeoFeatureData> features,
    required String labelField,
    required String? valueField,
    required String aggregation,
  }) {
    final grouped = <String, List<double>>{};

    for (final feature in features) {
      final rawLabel = feature.properties[labelField];
      final label = _normalizeLabel(rawLabel);

      if (aggregation == 'Contagem') {
        grouped.putIfAbsent(label, () => <double>[]);
        grouped[label]!.add(1);
        continue;
      }

      if (valueField == null || valueField.isEmpty) continue;

      final value = _toDouble(feature.properties[valueField]);
      if (value == null) continue;

      grouped.putIfAbsent(label, () => <double>[]);
      grouped[label]!.add(value);
    }

    final result = <_GroupedRow>[];

    grouped.forEach((label, values) {
      if (values.isEmpty) return;

      final resolvedValue = switch (aggregation) {
        'Média' => values.reduce((a, b) => a + b) / values.length,
        'Máximo' => values.reduce(math.max),
        'Mínimo' => values.reduce(math.min),
        'Contagem' => values.length.toDouble(),
        _ => values.reduce((a, b) => a + b),
      };

      result.add(_GroupedRow(label: label, value: resolvedValue));
    });

    return result;
  }

  static List<_GroupedRow> _sortRows(List<_GroupedRow> rows, String sortType) {
    final next = List<_GroupedRow>.from(rows);

    switch (sortType) {
      case 'ascending':
        next.sort((a, b) => a.value.compareTo(b.value));
        break;
      case 'descending':
        next.sort((a, b) => b.value.compareTo(a.value));
        break;
      case 'labelAZ':
        next.sort((a, b) => a.label.compareTo(b.label));
        break;
      case 'labelZA':
        next.sort((a, b) => b.label.compareTo(a.label));
        break;
      case 'none':
      default:
        break;
    }

    return next;
  }

  static String? _aggregateSingleField({
    required List<GeoFeatureData> features,
    required String valueField,
    required String aggregation,
  }) {
    if (aggregation == 'Contagem') {
      return features.length.toString();
    }

    final values = features
        .map((e) => _toDouble(e.properties[valueField]))
        .whereType<double>()
        .toList(growable: false);

    if (values.isEmpty) return null;

    final result = switch (aggregation) {
      'Média' => values.reduce((a, b) => a + b) / values.length,
      'Máximo' => values.reduce(math.max),
      'Mínimo' => values.reduce(math.min),
      _ => values.reduce((a, b) => a + b),
    };

    final isInteger = result == result.truncateToDouble();
    return isInteger ? result.toStringAsFixed(0) : result.toStringAsFixed(2);
  }

  static String? _firstNonEmptyValue(
      List<GeoFeatureData> features,
      String field,
      ) {
    for (final feature in features) {
      final raw = feature.properties[field];
      if (raw == null) continue;

      final text = raw.toString().trim();
      if (text.isNotEmpty) return text;
    }

    return null;
  }

  static String _normalizeLabel(dynamic raw) {
    final text = raw?.toString().trim() ?? '';
    return text.isEmpty ? 'Sem rótulo' : text;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return double.tryParse(text.replaceAll(',', '.'));
  }
}

class _GroupedRow {
  final String label;
  final double value;

  const _GroupedRow({
    required this.label,
    required this.value,
  });
}