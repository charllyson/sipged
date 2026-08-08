import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_filter.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_scope_data.dart';

/// Lançada quando [WorkspaceRepository.saveWorkspace] é chamado com uma
/// versão esperada que não bate mais com a versão salva no Firestore — ou
/// seja, outra sessão/usuário alterou esse dashboard entre a última leitura
/// e esta escrita. Quem chama deve recarregar em vez de sobrescrever.
class WorkspaceConflictException implements Exception {
  const WorkspaceConflictException();

  @override
  String toString() =>
      'A área de trabalho foi alterada por outra sessão. Recarregue antes de salvar.';
}

class WorkspaceLoadResult {
  final List<WorkspaceData> items;
  final int version;

  const WorkspaceLoadResult({
    required this.items,
    required this.version,
  });
}

class WorkspaceRepository {
  WorkspaceRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> get _workspaceRootDoc {
    return _firestore.collection('geo').doc('workspace');
  }

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

  Future<WorkspaceLoadResult> loadWorkspace({
    required WorkspaceScopeData scope,
  }) async {
    final snap = await _scopeDocRef(scope).get();

    if (!snap.exists) {
      return const WorkspaceLoadResult(items: <WorkspaceData>[], version: 0);
    }

    final data = snap.data() ?? const <String, dynamic>{};
    final rawItems = (data['items'] as List?) ?? const [];
    final version = (data['version'] as num?)?.toInt() ?? 0;

    final items = rawItems
        .whereType<Map>()
        .map((e) => WorkspaceData.fromMap(Map<String, dynamic>.from(e)))
        .toList(growable: false);

    return WorkspaceLoadResult(items: items, version: version);
  }

  /// Salva o dashboard de forma otimista.
  ///
  /// Se [expectedVersion] for informado e não bater com a versão atual do
  /// documento de escopo no Firestore, a escrita é abortada e uma
  /// [WorkspaceConflictException] é lançada — em vez de sobrescrever
  /// silenciosamente uma mudança feita por outra sessão/usuário editando o
  /// mesmo dashboard. Passe `expectedVersion: null` apenas quando não houver
  /// uma leitura prévia para comparar.
  ///
  /// Retorna a nova versão salva.
  Future<int> saveWorkspace({
    required WorkspaceScopeData scope,
    required List<WorkspaceData> items,
    required int? expectedVersion,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    final scopeRef = _scopeDocRef(scope);
    final rootRef = _workspaceRootDoc;

    final cleanItems = items
        .map((e) => e.copyWithoutResolvedData().toMap())
        .toList(growable: false);

    return _firestore.runTransaction<int>((transaction) async {
      final rootSnap = await transaction.get(rootRef);
      final scopeSnap = await transaction.get(scopeRef);

      final currentVersion = scopeSnap.exists
          ? ((scopeSnap.data()?['version'] as num?)?.toInt() ?? 0)
          : 0;

      if (expectedVersion != null && currentVersion != expectedVersion) {
        throw const WorkspaceConflictException();
      }

      final nextVersion = currentVersion + 1;

      final rootData = rootSnap.data() ?? const <String, dynamic>{};

      final totalGeneralScopes =
          (rootData['totalGeneralScopes'] as num?)?.toInt() ?? 0;
      final totalLayerScopes =
          (rootData['totalLayerScopes'] as num?)?.toInt() ?? 0;
      final totalGroupScopes =
          (rootData['totalGroupScopes'] as num?)?.toInt() ?? 0;
      final totalFeatureScopes =
          (rootData['totalFeatureScopes'] as num?)?.toInt() ?? 0;

      var nextGeneral = totalGeneralScopes;
      var nextLayer = totalLayerScopes;
      var nextGroup = totalGroupScopes;
      var nextFeature = totalFeatureScopes;

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
          case WorkspaceScopeType.feature:
            nextFeature += 1;
            break;
        }
      }

      final totalScopes = nextGeneral + nextLayer + nextGroup + nextFeature;

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
        'totalFeatureScopes': nextFeature,
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
        'version': nextVersion,
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

      return nextVersion;
    });
  }

  List<WorkspaceData> resolveAllItems({
    required List<WorkspaceData> items,
    required Map<String, List<FeatureData>> featuresByLayer,
    WorkspaceFilter? activeFilter,
  }) {
    if (items.isEmpty) {
      return const <WorkspaceData>[];
    }

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

      case CatalogType.horizontalBars:
        return _resolveGroupedChart(
          item: item,
          featuresByLayer: featuresByLayer,
          activeFilter: activeFilter,
          titleKey: 'title',
          fallbackSort: 'descending',
        );

      case CatalogType.radar:
        return _resolveGroupedChart(
          item: item,
          featuresByLayer: featuresByLayer,
          activeFilter: activeFilter,
          titleKey: 'title',
        );

      case CatalogType.treemap:
        return _resolveGroupedChart(
          item: item,
          featuresByLayer: featuresByLayer,
          activeFilter: activeFilter,
          titleKey: 'title',
          fallbackSort: 'descending',
        );

      case CatalogType.selectorDates:
        return _resolveDateSelector(
          item: item,
          featuresByLayer: featuresByLayer,
          activeFilter: activeFilter,
          titleKey: 'title',
        );

      case CatalogType.dateField:
        return _resolveInputField(
          item: item,
          titleKey: 'labelText',
          fallbackTitle: 'Campo de data',
          subtitle: item.getNullableTextProperty('hintText'),
        );

      case CatalogType.timeField:
        return _resolveInputField(
          item: item,
          titleKey: 'labelText',
          fallbackTitle: 'Campo de hora',
          subtitle: item.getNullableTextProperty('hintText'),
        );

      case CatalogType.costRuler:
        return _resolveCostRulerItem(
          item: item,
          featuresByLayer: featuresByLayer,
          activeFilter: activeFilter,
        );

      case CatalogType.gauge:
        return _resolveGaugeItem(
          item: item,
          featuresByLayer: featuresByLayer,
          activeFilter: activeFilter,
        );

      case CatalogType.switcher:
        return _resolveInputField(
          item: item,
          titleKey: 'textOn',
          fallbackTitle: 'Switch',
          subtitle: item.getNullableTextProperty('textOff'),
        );

      case CatalogType.textField:
        return _resolveInputField(
          item: item,
          titleKey: 'labelText',
          fallbackTitle: 'Campo de texto',
          subtitle: item.getNullableTextProperty('hintText'),
        );

      case CatalogType.documents:
        return _resolveInputField(
          item: item,
          titleKey: 'title',
          fallbackTitle: 'Documentos',
        );
    }
  }

  WorkspaceFilter? toggleItemFilter({
    required WorkspaceData item,
    required String label,
    required double? value,
    WorkspaceFilter? currentFilter,
  }) {
    final sourceLayerId = item.sourceLayerId;
    final sourceField = _sourceFieldForFilter(item);

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

  WorkspaceFilter? toggleBarFilter({
    required WorkspaceData item,
    required String label,
    required double? value,
    WorkspaceFilter? currentFilter,
  }) {
    return toggleItemFilter(
      item: item,
      label: label,
      value: value,
      currentFilter: currentFilter,
    );
  }

  List<FeatureData> applyFilterToItemFeatures({
    required WorkspaceData item,
    required List<FeatureData> features,
    WorkspaceFilter? activeFilter,
  }) {
    if (activeFilter == null) {
      return features;
    }

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

      return _matchesFilterValue(
        raw: raw,
        filterLabel: activeFilter.label,
      );
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
    final aggregation =
        item.getNullableSelectedProperty('aggregation') ?? 'Soma';
    final sortType =
        item.getNullableSelectedProperty('sortType') ?? fallbackSort;

    if (labelField == null || labelField.isEmpty) {
      return item.copyWithResolvedData(
        title: title,
        labels: null,
        values: null,
      );
    }

    if (aggregation != 'Contagem' &&
        (valueField == null || valueField.isEmpty)) {
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

  WorkspaceData _resolveDateSelector({
    required WorkspaceData item,
    required Map<String, List<FeatureData>> featuresByLayer,
    required WorkspaceFilter? activeFilter,
    required String titleKey,
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

    final dateField = item.getBindingFieldName('dateField');

    if (dateField == null || dateField.isEmpty) {
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

    final groupedByDay = <String, double>{};

    for (final feature in filteredFeatures) {
      final raw = _featureValue(feature, dateField);
      final date = _toDate(raw);

      if (date == null) {
        continue;
      }

      final label = _formatDateLabel(date);

      groupedByDay[label] = (groupedByDay[label] ?? 0.0) + 1.0;
    }

    if (groupedByDay.isEmpty) {
      return item.copyWithResolvedData(
        title: title,
        labels: const <String>[],
        values: const <double>[],
      );
    }

    final rows = groupedByDay.entries
        .map(
          (entry) => _GroupedRow(
        label: entry.key,
        value: entry.value,
      ),
    )
        .toList(growable: false);

    rows.sort((a, b) {
      final da = _parseDateLabel(a.label);
      final db = _parseDateLabel(b.label);

      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;

      return da.compareTo(db);
    });

    return item.copyWithResolvedData(
      title: title,
      labels: rows.map((e) => e.label).toList(growable: false),
      values: rows.map((e) => e.value).toList(growable: false),
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

  WorkspaceData _resolveInputField({
    required WorkspaceData item,
    required String titleKey,
    required String fallbackTitle,
    String? subtitle,
  }) {
    final title = item.getNullableTextProperty(titleKey) ?? fallbackTitle;

    return item.copyWithResolvedData(
      title: title,
      subtitle: subtitle,
      label: null,
      value: null,
      labels: null,
      values: null,
    );
  }

  WorkspaceData _resolveGaugeItem({
    required WorkspaceData item,
    required Map<String, List<FeatureData>> featuresByLayer,
    required WorkspaceFilter? activeFilter,
  }) {
    final sourceLayerId = item.sourceLayerId;
    final title = item.getNullableTextProperty('headerLabel');
    final subtitle = item.getNullableTextProperty('footerLabel');

    if (sourceLayerId == null || sourceLayerId.isEmpty) {
      return item.copyWithResolvedData(
        title: title,
        subtitle: subtitle,
        label: null,
        value: null,
      );
    }

    final allFeatures = featuresByLayer[sourceLayerId] ?? const <FeatureData>[];

    if (allFeatures.isEmpty) {
      return item.copyWithResolvedData(
        title: title,
        subtitle: subtitle,
        label: null,
        value: null,
      );
    }

    final filteredFeatures = applyFilterToItemFeatures(
      item: item,
      features: allFeatures,
      activeFilter: activeFilter,
    );

    final valueField = item.getBindingFieldName('centerValue');

    if (valueField == null || valueField.isEmpty) {
      return item.copyWithResolvedData(
        title: title,
        subtitle: subtitle,
        label: null,
        value: null,
      );
    }

    // Percentual médio do campo vinculado entre as feições filtradas.
    final resolvedValue = _aggregateSingleField(
      features: filteredFeatures,
      valueField: valueField,
      aggregation: 'Média',
    );

    return item.copyWithResolvedData(
      title: title,
      subtitle: subtitle,
      label: null,
      value: resolvedValue,
    );
  }

  WorkspaceData _resolveCostRulerItem({
    required WorkspaceData item,
    required Map<String, List<FeatureData>> featuresByLayer,
    required WorkspaceFilter? activeFilter,
  }) {
    final sourceLayerId = item.sourceLayerId;
    final title = item.getNullableTextProperty('title');
    final unitLabel = item.getNullableTextProperty('unitLabel');

    if (sourceLayerId == null || sourceLayerId.isEmpty) {
      return item.copyWithResolvedData(
        title: title,
        subtitle: unitLabel,
        values: null,
      );
    }

    final allFeatures = featuresByLayer[sourceLayerId] ?? const <FeatureData>[];

    if (allFeatures.isEmpty) {
      return item.copyWithResolvedData(
        title: title,
        subtitle: unitLabel,
        values: null,
      );
    }

    final filteredFeatures = applyFilterToItemFeatures(
      item: item,
      features: allFeatures,
      activeFilter: activeFilter,
    );

    final valueField = item.getBindingFieldName('valueField');
    final divisorField = item.getBindingFieldName('divisorField');

    if (valueField == null ||
        valueField.isEmpty ||
        divisorField == null ||
        divisorField.isEmpty) {
      return item.copyWithResolvedData(
        title: title,
        subtitle: unitLabel,
        values: null,
      );
    }

    final rawValue = _aggregateSingleField(
      features: filteredFeatures,
      valueField: valueField,
      aggregation: 'Soma',
    );

    final rawDivisor = _aggregateSingleField(
      features: filteredFeatures,
      valueField: divisorField,
      aggregation: 'Soma',
    );

    final value = double.tryParse(rawValue ?? '');
    final divisor = double.tryParse(rawDivisor ?? '');

    if (value == null || divisor == null) {
      return item.copyWithResolvedData(
        title: title,
        subtitle: unitLabel,
        values: const <double>[],
      );
    }

    // Codifica valor e divisor como uma lista de 2 posições — reaproveita
    // o campo resolvedValues sem precisar de um novo campo no modelo.
    return item.copyWithResolvedData(
      title: title,
      subtitle: unitLabel,
      values: [value, divisor],
    );
  }

  String? _sourceFieldForFilter(WorkspaceData item) {
    switch (item.type) {
      case CatalogType.selectorDates:
        return item.getBindingFieldName('dateField');

      case CatalogType.dateField:
        return item.getBindingFieldName('dateField');

      case CatalogType.timeField:
        return item.getBindingFieldName('timeField');

      case CatalogType.card:
        return item.getBindingFieldName('label');

      case CatalogType.barVertical:
      case CatalogType.donut:
      case CatalogType.line:
      case CatalogType.horizontalBars:
      case CatalogType.treemap:
      case CatalogType.radar:
        return item.getBindingFieldName('labelField');

      case CatalogType.costRuler:
      case CatalogType.gauge:
      case CatalogType.switcher:
      case CatalogType.textField:
        return item.getBindingFieldName('labelField') ??
            item.getBindingFieldName('label') ??
            item.getBindingFieldName('dateField') ??
            item.getBindingFieldName('timeField');

      case CatalogType.documents:
        // Widget de arquivos: não tem binding com dados de feição.
        return null;
    }
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

      if (valueField == null || valueField.isEmpty) {
        continue;
      }

      final value = _toDouble(_featureValue(feature, valueField));

      if (value == null) {
        continue;
      }

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

      result.add(
        _GroupedRow(
          label: label,
          value: resolvedValue,
        ),
      );
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

    if (values.isEmpty) {
      return null;
    }

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

      if (raw == null) {
        continue;
      }

      final text = raw.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  dynamic _featureValue(FeatureData feature, String field) {
    if (feature.editedProperties.containsKey(field)) {
      return feature.editedProperties[field];
    }

    return feature.originalProperties[field];
  }

  bool _matchesFilterValue({
    required dynamic raw,
    required String filterLabel,
  }) {
    final rawNormalized = _normalizeLabel(raw);
    final filterNormalized = _normalizeLabel(filterLabel);

    if (rawNormalized == filterNormalized) {
      return true;
    }

    if (rawNormalized.toUpperCase() == filterNormalized.toUpperCase()) {
      return true;
    }

    final rawDate = _toDate(raw);
    final filterDate = _parseDateLabel(filterLabel);

    if (rawDate != null && filterDate != null) {
      return rawDate.year == filterDate.year &&
          rawDate.month == filterDate.month &&
          rawDate.day == filterDate.day;
    }

    final rawTime = _toTimeLabel(raw);
    final filterTime = _toTimeLabel(filterLabel);

    if (rawTime != null && filterTime != null) {
      return rawTime == filterTime;
    }

    return false;
  }

  String _normalizeLabel(dynamic raw) {
    final text = raw?.toString().trim() ?? '';
    return text.isEmpty ? 'Sem rótulo' : text;
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(text.replaceAll(',', '.'));
  }

  DateTime? _toDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }

      if (value > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }

    if (value is num) {
      final intValue = value.toInt();

      if (intValue > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(intValue);
      }

      if (intValue > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(intValue * 1000);
      }
    }

    return _parseDateLabel(value.toString());
  }

  DateTime? _parseDateLabel(String value) {
    final clean = value.trim();

    if (clean.isEmpty) {
      return null;
    }

    final iso = DateTime.tryParse(clean);

    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }

    final ddMmYyyy = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
    final ddMmYyyyMatch = ddMmYyyy.firstMatch(clean);

    if (ddMmYyyyMatch != null) {
      final day = int.tryParse(ddMmYyyyMatch.group(1) ?? '');
      final month = int.tryParse(ddMmYyyyMatch.group(2) ?? '');
      final year = int.tryParse(ddMmYyyyMatch.group(3) ?? '');

      return _safeDate(
        year: year,
        month: month,
        day: day,
      );
    }

    final mmYyyy = RegExp(r'^(\d{2})/(\d{4})$');
    final mmYyyyMatch = mmYyyy.firstMatch(clean);

    if (mmYyyyMatch != null) {
      final month = int.tryParse(mmYyyyMatch.group(1) ?? '');
      final year = int.tryParse(mmYyyyMatch.group(2) ?? '');

      return _safeDate(
        year: year,
        month: month,
        day: 1,
      );
    }

    final yyyyOnly = RegExp(r'^(\d{4})$');
    final yyyyOnlyMatch = yyyyOnly.firstMatch(clean);

    if (yyyyOnlyMatch != null) {
      final year = int.tryParse(yyyyOnlyMatch.group(1) ?? '');

      return _safeDate(
        year: year,
        month: 1,
        day: 1,
      );
    }

    return null;
  }

  DateTime? _safeDate({
    required int? year,
    required int? month,
    required int? day,
  }) {
    if (year == null || month == null || day == null) {
      return null;
    }

    if (year < 1900 || year > 3000) {
      return null;
    }

    if (month < 1 || month > 12) {
      return null;
    }

    if (day < 1 || day > 31) {
      return null;
    }

    try {
      final date = DateTime(year, month, day);

      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }

      return date;
    } catch (_) {
      return null;
    }
  }

  String _formatDateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');

    return '$day/$month/$year';
  }

  String? _toTimeLabel(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      final date = value.toDate();
      return _formatTimeLabel(date.hour, date.minute);
    }

    if (value is DateTime) {
      return _formatTimeLabel(value.hour, value.minute);
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(text);

    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');

    if (hour == null || minute == null) {
      return null;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return _formatTimeLabel(hour, minute);
  }

  String _formatTimeLabel(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
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