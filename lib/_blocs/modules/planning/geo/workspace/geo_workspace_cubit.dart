import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_card.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_chart.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_field.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_table.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_state.dart';
import 'package:sipged/_widgets/overlays/guides_lines/guide_lines_data.dart';
import 'package:sipged/_widgets/resize/resize_data.dart';

class GeoWorkspaceCubit extends Cubit<GeoWorkspaceState> {
  GeoWorkspaceCubit({
    required List<ResizeData> initialItems,
    required Map<String, List<GeoFeatureData>> initialFeaturesByLayer,
    required this.repository,
    this.snapThreshold = 10.0,
    this.panelPadding = 0.0,
  }) : super(
    GeoWorkspaceState.initial(
      items: initialItems,
      featuresByLayer: initialFeaturesByLayer,
    ),
  );

  final GeoWorkspaceRepository repository;
  final double snapThreshold;
  final double panelPadding;

  void syncExternalItems(List<ResizeData> items) {
    final normalized = _normalizeItemsForPanel(items, state.panelSize);

    if (listEquals(normalized, state.items)) return;

    final selectedId = state.selectedItemId;
    final stillExists =
        selectedId != null && normalized.any((item) => item.id == selectedId);

    emit(
      state.copyWith(
        items: normalized,
        clearSelectedItem: !stillExists,
      ),
    );
  }

  void syncExternalFeatures(Map<String, List<GeoFeatureData>> featuresByLayer) {
    if (_sameFeaturesMap(state.featuresByLayer, featuresByLayer)) return;

    emit(
      state.copyWith(
        featuresByLayer: Map<String, List<GeoFeatureData>>.from(featuresByLayer),
        dataVersion: state.dataVersion + 1,
      ),
    );
  }

  void setPanelSize(Size size) {
    if (size == state.panelSize) return;

    final normalizedItems = _normalizeItemsForPanel(state.items, size);

    emit(
      state.copyWith(
        panelSize: size,
        items: normalizedItems,
      ),
    );
  }

  void selectItem(String itemId) {
    if (state.selectedItemId == itemId) return;
    emit(state.copyWith(selectedItemId: itemId));
  }

  void clearSelection() {
    if (state.selectedItemId == null && state.guides == null) return;
    emit(
      state.copyWith(
        clearSelectedItem: true,
        clearGuides: true,
      ),
    );
  }

  void clearGuides() {
    if (state.guides == null) return;
    emit(state.copyWith(clearGuides: true));
  }

  void removeItemLocal(String itemId) {
    final nextItems =
    state.items.where((item) => item.id != itemId).toList(growable: false);

    final wasSelected = state.selectedItemId == itemId;

    emit(
      state.copyWith(
        items: nextItems,
        clearSelectedItem: wasSelected,
        clearGuides: true,
      ),
    );
  }

  GuideLinesResolvedRect moveItemLive({
    required String itemId,
    required Rect desiredRect,
  }) {
    final resolved = _resolveMoveSnap(
      itemId: itemId,
      desiredRect: desiredRect,
    );

    _updateItemRectLocal(
      itemId: itemId,
      rect: resolved.rect,
      guides: resolved.guides,
    );

    return resolved;
  }

  GuideLinesResolvedRect moveItemCommit({
    required String itemId,
    required Rect desiredRect,
  }) {
    final resolved = _resolveMoveSnap(
      itemId: itemId,
      desiredRect: desiredRect,
    );

    _updateItemRectLocal(
      itemId: itemId,
      rect: resolved.rect,
      guides: null,
    );

    return resolved;
  }

  GuideLinesResolvedRect resizeItemLive({
    required String itemId,
    required Rect desiredRect,
    required ResizeHandle handle,
  }) {
    final resolved = _resolveResizeSnap(
      itemId: itemId,
      desiredRect: desiredRect,
      handle: handle,
    );

    _updateItemRectLocal(
      itemId: itemId,
      rect: resolved.rect,
      guides: resolved.guides,
    );

    return resolved;
  }

  GuideLinesResolvedRect resizeItemCommit({
    required String itemId,
    required Rect desiredRect,
    required ResizeHandle handle,
  }) {
    final resolved = _resolveResizeSnap(
      itemId: itemId,
      desiredRect: desiredRect,
      handle: handle,
    );

    _updateItemRectLocal(
      itemId: itemId,
      rect: resolved.rect,
      guides: null,
    );

    return resolved;
  }

  GeoWorkspaceDataChart resolveBarVertical(ResizeData item) {
    return _resolveGroupedChart(
      item: item,
      titleKey: 'chartTitle',
    );
  }

  GeoWorkspaceDataChart resolveDonut(ResizeData item) {
    return _resolveGroupedChart(
      item: item,
      titleKey: 'chartTitle',
    );
  }

  GeoWorkspaceDataChart resolveLine(ResizeData item) {
    return _resolveGroupedChart(
      item: item,
      titleKey: 'chartTitle',
      fallbackSort: 'labelAZ',
    );
  }

  GeoWorkspaceDataCard resolveCard(ResizeData item) {
    return _resolveMetricCard(
      item: item,
      titleKey: 'title',
      subtitleKey: 'subtitle',
    );
  }

  GeoWorkspaceDataTable resolveTable(ResizeData item) {
    final sourceBinding = item.getBindingProperty('source');

    final sourceLayerId = _resolveSourceLayerId(
      sourceBinding: sourceBinding,
      bindings:
      item.properties.map((e) => e.bindingValue).toList(growable: false),
    );

    final title = item.getNullableTextProperty('title');
    final columns =
        item.getNullableStringListProperty('columns') ?? const <String>[];

    if (sourceLayerId == null || sourceLayerId.isEmpty) {
      return GeoWorkspaceDataTable(
        title: title,
        columns: columns,
        rows: const [],
      );
    }

    final features =
        state.featuresByLayer[sourceLayerId] ?? const <GeoFeatureData>[];
    if (features.isEmpty || columns.isEmpty) {
      return GeoWorkspaceDataTable(
        title: title,
        columns: columns,
        rows: const [],
      );
    }

    final rows = <Map<String, String>>[];

    for (final feature in features.take(100)) {
      final map = <String, String>{};

      for (final column in columns) {
        final raw = _featureValue(feature, column);
        final text = raw?.toString().trim();

        map[column] = (text != null && text.isNotEmpty) ? text : '-';
      }

      rows.add(map);
    }

    return GeoWorkspaceDataTable(
      title: title,
      columns: columns,
      rows: rows,
    );
  }

  void _updateItemRectLocal({
    required String itemId,
    required Rect rect,
    required GuideLinesData? guides,
  }) {
    var changed = false;

    final nextItems = state.items.map((item) {
      if (item.id != itemId) return item;

      final updated = item.copyWith(
        offset: rect.topLeft,
        size: rect.size,
      );

      if (updated != item) changed = true;
      return updated;
    }).toList(growable: false);

    final guidesChanged = state.guides != guides;

    if (!changed && !guidesChanged) return;

    emit(
      state.copyWith(
        items: nextItems,
        guides: guides,
        clearGuides: guides == null,
      ),
    );
  }

  List<ResizeData> _normalizeItemsForPanel(
      List<ResizeData> items,
      Size panelSize,
      ) {
    if (panelSize.isEmpty) {
      return List<ResizeData>.from(items);
    }

    return items.map((item) {
      final rect = clampRect(
        rect: Rect.fromLTWH(
          item.offset.dx,
          item.offset.dy,
          item.size.width,
          item.size.height,
        ),
        panelSize: panelSize,
      );

      return item.copyWith(
        offset: rect.topLeft,
        size: rect.size,
      );
    }).toList(growable: false);
  }

  bool _sameFeaturesMap(
      Map<String, List<GeoFeatureData>> a,
      Map<String, List<GeoFeatureData>> b,
      ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      final listA = a[key];
      final listB = b[key];
      if (listB == null) return false;
      if (!listEquals(listA, listB)) return false;
    }

    return true;
  }

  GuideLinesResolvedRect _resolveMoveSnap({
    required String itemId,
    required Rect desiredRect,
  }) {
    final panelSize = state.panelSize;

    final candidatesX = <double>{
      panelPadding,
      panelSize.width / 2,
      math.max(panelPadding, panelSize.width - panelPadding),
    };

    final candidatesY = <double>{
      panelPadding,
      panelSize.height / 2,
      math.max(panelPadding, panelSize.height - panelPadding),
    };

    for (final item in state.items) {
      if (item.id == itemId) continue;

      final rect = Rect.fromLTWH(
        item.offset.dx,
        item.offset.dy,
        item.size.width,
        item.size.height,
      );

      candidatesX.addAll([rect.left, rect.center.dx, rect.right]);
      candidatesY.addAll([rect.top, rect.center.dy, rect.bottom]);
    }

    double left = desiredRect.left;
    double top = desiredRect.top;
    final width = desiredRect.width;
    final height = desiredRect.height;

    final itemXPoints = {
      GeoWorkspaceSnapEdge.left: desiredRect.left,
      GeoWorkspaceSnapEdge.centerX: desiredRect.center.dx,
      GeoWorkspaceSnapEdge.right: desiredRect.right,
    };

    final itemYPoints = {
      GeoWorkspaceSnapEdge.top: desiredRect.top,
      GeoWorkspaceSnapEdge.centerY: desiredRect.center.dy,
      GeoWorkspaceSnapEdge.bottom: desiredRect.bottom,
    };

    double? snappedGuideX;
    double? snappedGuideY;
    double bestDx = snapThreshold + 1;
    double bestDy = snapThreshold + 1;

    for (final entry in itemXPoints.entries) {
      for (final candidate in candidatesX) {
        final diff = (entry.value - candidate).abs();
        if (diff < bestDx && diff <= snapThreshold) {
          bestDx = diff;
          snappedGuideX = candidate;

          switch (entry.key) {
            case GeoWorkspaceSnapEdge.left:
              left = candidate;
              break;
            case GeoWorkspaceSnapEdge.centerX:
              left = candidate - (width / 2);
              break;
            case GeoWorkspaceSnapEdge.right:
              left = candidate - width;
              break;
            case GeoWorkspaceSnapEdge.top:
            case GeoWorkspaceSnapEdge.centerY:
            case GeoWorkspaceSnapEdge.bottom:
              break;
          }
        }
      }
    }

    for (final entry in itemYPoints.entries) {
      for (final candidate in candidatesY) {
        final diff = (entry.value - candidate).abs();
        if (diff < bestDy && diff <= snapThreshold) {
          bestDy = diff;
          snappedGuideY = candidate;

          switch (entry.key) {
            case GeoWorkspaceSnapEdge.top:
              top = candidate;
              break;
            case GeoWorkspaceSnapEdge.centerY:
              top = candidate - (height / 2);
              break;
            case GeoWorkspaceSnapEdge.bottom:
              top = candidate - height;
              break;
            case GeoWorkspaceSnapEdge.left:
            case GeoWorkspaceSnapEdge.centerX:
            case GeoWorkspaceSnapEdge.right:
              break;
          }
        }
      }
    }

    final clamped = clampRect(
      rect: Rect.fromLTWH(left, top, width, height),
      panelSize: panelSize,
    );

    return GuideLinesResolvedRect(
      rect: clamped,
      guides: (snappedGuideX != null || snappedGuideY != null)
          ? GuideLinesData(
        vertical: snappedGuideX,
        horizontal: snappedGuideY,
      )
          : null,
    );
  }

  GuideLinesResolvedRect _resolveResizeSnap({
    required String itemId,
    required Rect desiredRect,
    required ResizeHandle handle,
  }) {
    final panelSize = state.panelSize;

    final candidatesX = <double>{
      panelPadding,
      panelSize.width / 2,
      math.max(panelPadding, panelSize.width - panelPadding),
    };

    final candidatesY = <double>{
      panelPadding,
      panelSize.height / 2,
      math.max(panelPadding, panelSize.height - panelPadding),
    };

    for (final item in state.items) {
      if (item.id == itemId) continue;

      final rect = Rect.fromLTWH(
        item.offset.dx,
        item.offset.dy,
        item.size.width,
        item.size.height,
      );

      candidatesX.addAll([rect.left, rect.center.dx, rect.right]);
      candidatesY.addAll([rect.top, rect.center.dy, rect.bottom]);
    }

    double left = desiredRect.left;
    double top = desiredRect.top;
    double right = desiredRect.right;
    double bottom = desiredRect.bottom;

    double? snappedGuideX;
    double? snappedGuideY;

    void snapX(bool useLeft, bool useCenter, bool useRight) {
      double best = snapThreshold + 1;

      if (useLeft) {
        for (final candidate in candidatesX) {
          final diff = (left - candidate).abs();
          if (diff < best && diff <= snapThreshold) {
            best = diff;
            left = candidate;
            snappedGuideX = candidate;
          }
        }
      }

      if (useCenter) {
        final center = (left + right) / 2;
        for (final candidate in candidatesX) {
          final diff = (center - candidate).abs();
          if (diff < best && diff <= snapThreshold) {
            best = diff;
            final half = (right - left) / 2;
            left = candidate - half;
            right = candidate + half;
            snappedGuideX = candidate;
          }
        }
      }

      if (useRight) {
        for (final candidate in candidatesX) {
          final diff = (right - candidate).abs();
          if (diff < best && diff <= snapThreshold) {
            best = diff;
            right = candidate;
            snappedGuideX = candidate;
          }
        }
      }
    }

    void snapY(bool useTop, bool useCenter, bool useBottom) {
      double best = snapThreshold + 1;

      if (useTop) {
        for (final candidate in candidatesY) {
          final diff = (top - candidate).abs();
          if (diff < best && diff <= snapThreshold) {
            best = diff;
            top = candidate;
            snappedGuideY = candidate;
          }
        }
      }

      if (useCenter) {
        final center = (top + bottom) / 2;
        for (final candidate in candidatesY) {
          final diff = (center - candidate).abs();
          if (diff < best && diff <= snapThreshold) {
            best = diff;
            final half = (bottom - top) / 2;
            top = candidate - half;
            bottom = candidate + half;
            snappedGuideY = candidate;
          }
        }
      }

      if (useBottom) {
        for (final candidate in candidatesY) {
          final diff = (bottom - candidate).abs();
          if (diff < best && diff <= snapThreshold) {
            best = diff;
            bottom = candidate;
            snappedGuideY = candidate;
          }
        }
      }
    }

    switch (handle) {
      case ResizeHandle.right:
        snapX(false, false, true);
        break;
      case ResizeHandle.bottom:
        snapY(false, false, true);
        break;
      case ResizeHandle.bottomRight:
        snapX(false, false, true);
        snapY(false, false, true);
        break;
      case ResizeHandle.left:
        snapX(true, false, false);
        break;
      case ResizeHandle.top:
        snapY(true, false, false);
        break;
      case ResizeHandle.topLeft:
        snapX(true, false, false);
        snapY(true, false, false);
        break;
      case ResizeHandle.topRight:
        snapX(false, false, true);
        snapY(true, false, false);
        break;
      case ResizeHandle.bottomLeft:
        snapX(true, false, false);
        snapY(false, false, true);
        break;
    }

    final normalized = normalizeResizeRect(
      rect: Rect.fromLTRB(left, top, right, bottom),
      panelSize: panelSize,
    );

    return GuideLinesResolvedRect(
      rect: normalized,
      guides: (snappedGuideX != null || snappedGuideY != null)
          ? GuideLinesData(
        vertical: snappedGuideX,
        horizontal: snappedGuideY,
      )
          : null,
    );
  }

  Rect normalizeResizeRect({
    required Rect rect,
    required Size panelSize,
  }) {
    double left = rect.left;
    double top = rect.top;
    double right = rect.right;
    double bottom = rect.bottom;

    if (right < left) {
      final tmp = left;
      left = right;
      right = tmp;
    }

    if (bottom < top) {
      final tmp = top;
      top = bottom;
      bottom = tmp;
    }

    final minW = ResizeData.minSize.width;
    final minH = ResizeData.minSize.height;

    if ((right - left) < minW) {
      right = left + minW;
    }

    if ((bottom - top) < minH) {
      bottom = top + minH;
    }

    left = left.clamp(
      panelPadding,
      math.max(panelPadding, panelSize.width - minW),
    );
    top = top.clamp(
      panelPadding,
      math.max(panelPadding, panelSize.height - minH),
    );

    right = right.clamp(left + minW, panelSize.width);
    bottom = bottom.clamp(top + minH, panelSize.height);

    return Rect.fromLTRB(left, top, right, bottom);
  }

  Rect clampRect({
    required Rect rect,
    required Size panelSize,
  }) {
    final width = rect.width.clamp(
      ResizeData.minSize.width,
      math.max(ResizeData.minSize.width, panelSize.width),
    );
    final height = rect.height.clamp(
      ResizeData.minSize.height,
      math.max(ResizeData.minSize.height, panelSize.height),
    );

    final maxX = math.max(panelPadding, panelSize.width - width);
    final maxY = math.max(panelPadding, panelSize.height - height);

    return Rect.fromLTWH(
      rect.left.clamp(panelPadding, maxX).toDouble(),
      rect.top.clamp(panelPadding, maxY).toDouble(),
      width.toDouble(),
      height.toDouble(),
    );
  }

  GeoWorkspaceDataChart _resolveGroupedChart({
    required ResizeData item,
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
      return GeoWorkspaceDataChart(
        title: title,
        labels: null,
        values: null,
      );
    }

    final features =
        state.featuresByLayer[sourceLayerId] ?? const <GeoFeatureData>[];
    if (features.isEmpty) {
      return GeoWorkspaceDataChart(
        title: title,
        labels: null,
        values: null,
      );
    }

    final labelField = labelBinding?.fieldName?.trim();
    final valueField = valueBinding?.fieldName?.trim();
    final aggregation =
        item.getNullableSelectedProperty('aggregation') ?? 'Soma';
    final sortType = item.getNullableSelectedProperty('sortType') ?? fallbackSort;

    if (labelField == null || labelField.isEmpty) {
      return GeoWorkspaceDataChart(
        title: title,
        labels: null,
        values: null,
      );
    }

    if (aggregation != 'Contagem' &&
        (valueField == null || valueField.isEmpty)) {
      return GeoWorkspaceDataChart(
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
      return GeoWorkspaceDataChart(
        title: title,
        labels: null,
        values: null,
      );
    }

    final sorted = _sortRows(rows, sortType);

    return GeoWorkspaceDataChart(
      title: title,
      labels: sorted.map((e) => e.label).toList(growable: false),
      values: sorted.map((e) => e.value).toList(growable: false),
    );
  }

  GeoWorkspaceDataCard _resolveMetricCard({
    required ResizeData item,
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
      return GeoWorkspaceDataCard(
        title: item.getNullableTextProperty(titleKey),
        subtitle: item.getNullableTextProperty(subtitleKey),
        label: null,
        value: null,
      );
    }

    final features =
        state.featuresByLayer[sourceLayerId] ?? const <GeoFeatureData>[];
    if (features.isEmpty) {
      return GeoWorkspaceDataCard(
        title: item.getNullableTextProperty(titleKey),
        subtitle: item.getNullableTextProperty(subtitleKey),
        label: null,
        value: null,
      );
    }

    final labelField = labelBinding?.fieldName?.trim();
    final valueField = valueBinding?.fieldName?.trim();
    final aggregation =
        item.getNullableSelectedProperty('aggregation') ?? 'Contagem';

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

    return GeoWorkspaceDataCard(
      title: item.getNullableTextProperty(titleKey),
      subtitle: item.getNullableTextProperty(subtitleKey),
      label: resolvedLabel,
      value: resolvedValue,
    );
  }

  String? _resolveSourceLayerId({
    GeoWorkspaceFieldData? sourceBinding,
    required List<GeoWorkspaceFieldData?> bindings,
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

  List<_GroupedRow> _groupAndAggregate({
    required List<GeoFeatureData> features,
    required String labelField,
    required String? valueField,
    required String aggregation,
  }) {
    final grouped = <String, List<double>>{};

    for (final feature in features) {
      final rawLabel = _featureValue(feature, labelField);
      final label = _normalizeLabel(rawLabel);

      if (aggregation == 'Contagem') {
        grouped.putIfAbsent(label, () => <double>[]);
        grouped[label]!.add(1);
        continue;
      }

      if (valueField == null || valueField.isEmpty) continue;

      final value = _toDouble(_featureValue(feature, valueField));
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

  List<_GroupedRow> _sortRows(List<_GroupedRow> rows, String sortType) {
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

  String? _aggregateSingleField({
    required List<GeoFeatureData> features,
    required String valueField,
    required String aggregation,
  }) {
    if (aggregation == 'Contagem') {
      return features.length.toString();
    }

    final values = features
        .map((feature) => _toDouble(_featureValue(feature, valueField)))
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

  String? _firstNonEmptyValue(
      List<GeoFeatureData> features,
      String field,
      ) {
    for (final feature in features) {
      final raw = _featureValue(feature, field);
      if (raw == null) continue;

      final text = raw.toString().trim();
      if (text.isNotEmpty) return text;
    }

    return null;
  }

  dynamic _featureValue(GeoFeatureData feature, String field) {
    if (feature.editedProperties.containsKey(field)) {
      return feature.editedProperties[field];
    }
    return feature.originalProperties[field];
  }

  String _normalizeLabel(dynamic raw) {
    final text = raw?.toString().trim() ?? '';
    return text.isEmpty ? 'Sem rótulo' : text;
  }

  double? _toDouble(dynamic value) {
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