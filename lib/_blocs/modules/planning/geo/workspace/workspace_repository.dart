import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_filter.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_scope_data.dart';

class WorkspaceRepository {
  WorkspaceRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> get _workspaceRootDoc =>
      _firestore.collection('geo').doc('workspace');

  DocumentReference<Map<String, dynamic>> _scopeDocRef(
      WorkspaceScopeData scope,
      ) {
    return _workspaceRootDoc
        .collection(scope.collectionName)
        .doc(scope.documentId);
  }

  String _scopePath(WorkspaceScopeData scope) {
    return 'geo/workspace/${scope.collectionName}/${scope.documentId}';
  }

  Future<List<WorkspaceData>> loadWorkspace({
    required WorkspaceScopeData scope,
  }) async {
    final snap = await _scopeDocRef(scope).get();
    if (!snap.exists) return const <WorkspaceData>[];

    final data = snap.data() ?? const <String, dynamic>{};
    final rawItems = (data['items'] as List?) ?? const [];

    return rawItems
        .whereType<Map>()
        .map((e) => WorkspaceData.fromMap(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<void> saveWorkspace({
    required WorkspaceScopeData scope,
    required List<WorkspaceData> items,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    final scopeRef = _scopeDocRef(scope);
    final rootRef = _workspaceRootDoc;

    final cleanItems = items
        .map((e) => e.copyWithoutResolvedData().toMap())
        .toList(growable: false);

    await _firestore.runTransaction((transaction) async {
      final rootSnap = await transaction.get(rootRef);
      final scopeSnap = await transaction.get(scopeRef);

      final rootData = rootSnap.data() ?? const <String, dynamic>{};

      final totalGeneralScopes =
          (rootData['totalGeneralScopes'] as num?)?.toInt() ?? 0;
      final totalLayerScopes =
          (rootData['totalLayerScopes'] as num?)?.toInt() ?? 0;
      final totalGroupScopes =
          (rootData['totalGroupScopes'] as num?)?.toInt() ?? 0;

      var nextGeneral = totalGeneralScopes;
      var nextLayer = totalLayerScopes;
      var nextGroup = totalGroupScopes;

      final isNewScopeDoc = !scopeSnap.exists;

      if (isNewScopeDoc) {
        switch (scope.type) {
          case WorkspaceScopeType.general:
            nextGeneral += 1;
            break;
          case WorkspaceScopeType.layer:
            nextLayer += 1;
            break;
          case WorkspaceScopeType.group:
            nextGroup += 1;
            break;
        }
      }

      final totalScopes = nextGeneral + nextLayer + nextGroup;

      final rootPayload = <String, dynamic>{
        'module': 'geo_workspace',
        'version': 1,
        'structureVersion': 1,
        'description':
        'Metadados e auditoria das áreas de trabalho do módulo GEO.',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
        'lastScopeType': scope.type.name,
        'lastScopeId': scope.documentId,
        'lastScopePath': _scopePath(scope),
        'totalScopes': totalScopes,
        'totalGeneralScopes': nextGeneral,
        'totalLayerScopes': nextLayer,
        'totalGroupScopes': nextGroup,
      };

      if (!rootSnap.exists) {
        rootPayload['createdAt'] = FieldValue.serverTimestamp();
        rootPayload['createdBy'] = uid;
      }

      transaction.set(
        rootRef,
        rootPayload,
        SetOptions(merge: true),
      );

      final scopePayload = <String, dynamic>{
        'scope': scope.toMap(),
        'scopeType': scope.type.name,
        'scopeId': scope.documentId,
        'scopePath': _scopePath(scope),
        'itemCount': cleanItems.length,
        'items': cleanItems,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      };

      if (!scopeSnap.exists) {
        scopePayload['createdAt'] = FieldValue.serverTimestamp();
        scopePayload['createdBy'] = uid;
      }

      transaction.set(
        scopeRef,
        scopePayload,
        SetOptions(merge: true),
      );
    });
  }

  List<WorkspaceData> resolveAllItems({
    required List<WorkspaceData> items,
    required Map<String, List<FeatureData>> featuresByLayer,
    WorkspaceFilter? activeFilter,
  }) {
    if (items.isEmpty) return const <WorkspaceData>[];

    return items
        .map(
          (item) => resolveItem(
        item: item,
        featuresByLayer: featuresByLayer,
        activeFilter: activeFilter,
      ),
    )
        .toList(growable: false);
  }

  WorkspaceData resolveItem({
    required WorkspaceData item,
    required Map<String, List<FeatureData>> featuresByLayer,
    WorkspaceFilter? activeFilter,
  }) {
    switch (item.type) {
      case CatalogType.barVertical:
        return _resolveGroupedChart(
          item: item,
          featuresByLayer: featuresByLayer,
          activeFilter: activeFilter,
          titleKey: 'chartTitle',
        );

      case CatalogType.donut:
        return _resolveGroupedChart(
          item: item,
          featuresByLayer: featuresByLayer,
          activeFilter: activeFilter,
          titleKey: 'chartTitle',
        );

      case CatalogType.line:
        return _resolveGroupedChart(
          item: item,
          featuresByLayer: featuresByLayer,
          activeFilter: activeFilter,
          titleKey: 'chartTitle',
          fallbackSort: 'labelAZ',
        );

      case CatalogType.card:
        return _resolveMetricCard(
          item: item,
          featuresByLayer: featuresByLayer,
          activeFilter: activeFilter,
          titleKey: 'title',
          subtitleKey: 'subtitle',
        );
    }
  }

  WorkspaceFilter? toggleBarFilter({
    required WorkspaceData item,
    required String label,
    required double? value,
    WorkspaceFilter? currentFilter,
  }) {
    final sourceLayerId = item.sourceLayerId;
    final sourceField = item.getBindingFieldName('labelField');

    if (sourceLayerId == null || sourceLayerId.isEmpty) {
      return currentFilter;
    }

    if (sourceField == null || sourceField.isEmpty) {
      return currentFilter;
    }

    final normalizedLabel = _normalizeLabel(label);

    final isSameFilter = currentFilter != null &&
        currentFilter.sourceItemId == item.id &&
        currentFilter.sourceLayerId == sourceLayerId &&
        currentFilter.sourceField == sourceField &&
        currentFilter.label == normalizedLabel;

    if (isSameFilter) {
      return null;
    }

    return WorkspaceFilter(
      sourceItemId: item.id,
      sourceLayerId: sourceLayerId,
      sourceField: sourceField,
      label: normalizedLabel,
      value: value,
    );
  }

  List<FeatureData> applyFilterToItemFeatures({
    required WorkspaceData item,
    required List<FeatureData> features,
    WorkspaceFilter? activeFilter,
  }) {
    if (activeFilter == null) return features;

    final itemSourceLayerId = item.sourceLayerId;
    if (itemSourceLayerId == null || itemSourceLayerId.isEmpty) {
      return features;
    }

    if (item.id == activeFilter.sourceItemId) {
      return features;
    }

    if (itemSourceLayerId != activeFilter.sourceLayerId) {
      return features;
    }

    return features.where((feature) {
      final raw = _featureValue(feature, activeFilter.sourceField);
      final current = _normalizeLabel(raw);
      return current == activeFilter.label;
    }).toList(growable: false);
  }

  WorkspaceData _resolveGroupedChart({
    required WorkspaceData item,
    required Map<String, List<FeatureData>> featuresByLayer,
    required WorkspaceFilter? activeFilter,
    required String titleKey,
    String fallbackSort = 'none',
  }) {
    final sourceLayerId = item.sourceLayerId;
    final title = item.getNullableTextProperty(titleKey);

    if (sourceLayerId == null || sourceLayerId.isEmpty) {
      return item.copyWithResolvedData(
        title: title,
        labels: null,
        values: null,
      );
    }

    final allFeatures = featuresByLayer[sourceLayerId] ?? const <FeatureData>[];
    if (allFeatures.isEmpty) {
      return item.copyWithResolvedData(
        title: title,
        labels: null,
        values: null,
      );
    }

    final filteredFeatures = applyFilterToItemFeatures(
      item: item,
      features: allFeatures,
      activeFilter: activeFilter,
    );

    if (filteredFeatures.isEmpty) {
      return item.copyWithResolvedData(
        title: title,
        labels: const <String>[],
        values: const <double>[],
      );
    }

    final labelField = item.getBindingFieldName('labelField');
    final valueField = item.getBindingFieldName('valueField');
    final aggregation = item.getNullableSelectedProperty('aggregation') ?? 'Soma';
    final sortType = item.getNullableSelectedProperty('sortType') ?? fallbackSort;

    if (labelField == null || labelField.isEmpty) {
      return item.copyWithResolvedData(
        title: title,
        labels: null,
        values: null,
      );
    }

    if (aggregation != 'Contagem' && (valueField == null || valueField.isEmpty)) {
      return item.copyWithResolvedData(
        title: title,
        labels: null,
        values: null,
      );
    }

    final rows = _groupAndAggregate(
      features: filteredFeatures,
      labelField: labelField,
      valueField: valueField,
      aggregation: aggregation,
    );

    if (rows.isEmpty) {
      return item.copyWithResolvedData(
        title: title,
        labels: const <String>[],
        values: const <double>[],
      );
    }

    final sorted = _sortRows(rows, sortType);

    return item.copyWithResolvedData(
      title: title,
      labels: sorted.map((e) => e.label).toList(growable: false),
      values: sorted.map((e) => e.value).toList(growable: false),
    );
  }

  WorkspaceData _resolveMetricCard({
    required WorkspaceData item,
    required Map<String, List<FeatureData>> featuresByLayer,
    required WorkspaceFilter? activeFilter,
    required String titleKey,
    required String subtitleKey,
  }) {
    final sourceLayerId = item.sourceLayerId;
    final title = item.getNullableTextProperty(titleKey);
    final baseSubtitle = item.getNullableTextProperty(subtitleKey);

    if (sourceLayerId == null || sourceLayerId.isEmpty) {
      return item.copyWithResolvedData(
        title: title,
        subtitle: baseSubtitle,
        label: null,
        value: null,
      );
    }

    final allFeatures = featuresByLayer[sourceLayerId] ?? const <FeatureData>[];
    if (allFeatures.isEmpty) {
      return item.copyWithResolvedData(
        title: title,
        subtitle: baseSubtitle,
        label: null,
        value: null,
      );
    }

    final filteredFeatures = applyFilterToItemFeatures(
      item: item,
      features: allFeatures,
      activeFilter: activeFilter,
    );

    final labelField = item.getBindingFieldName('label');
    final valueField = item.getBindingFieldName('value');
    final aggregation =
        item.getNullableSelectedProperty('aggregation') ?? 'Contagem';

    String? resolvedLabel;
    if (labelField != null && labelField.isNotEmpty) {
      resolvedLabel = _firstNonEmptyValue(filteredFeatures, labelField);
    }

    String? resolvedValue;
    if (aggregation == 'Contagem') {
      resolvedValue = filteredFeatures.length.toString();
    } else if (valueField != null && valueField.isNotEmpty) {
      resolvedValue = _aggregateSingleField(
        features: filteredFeatures,
        valueField: valueField,
        aggregation: aggregation,
      );
    }

    String? subtitle = baseSubtitle;
    if (activeFilter != null &&
        item.id != activeFilter.sourceItemId &&
        item.sourceLayerId == activeFilter.sourceLayerId) {
      final info = 'Filtro: ${activeFilter.label}';
      subtitle = (baseSubtitle == null || baseSubtitle.trim().isEmpty)
          ? info
          : '$baseSubtitle • $info';
    }

    return item.copyWithResolvedData(
      title: title,
      subtitle: subtitle,
      label: resolvedLabel,
      value: resolvedValue,
    );
  }

  List<_GroupedRow> _groupAndAggregate({
    required List<FeatureData> features,
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
    required List<FeatureData> features,
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
      List<FeatureData> features,
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

  dynamic _featureValue(FeatureData feature, String field) {
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