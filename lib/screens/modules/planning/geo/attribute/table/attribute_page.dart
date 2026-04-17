import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_state.dart';
import 'package:sipged/_widgets/table/paged/paged_table_changed.dart';
import 'package:sipged/_widgets/table/paged/paged_table_metrics.dart';
import 'package:sipged/_widgets/windows/window_dialog.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/table/attribute_bottom_bar.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/table/attribute_content.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/table/attribute_error.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/table/attribute_form.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/table/attribute_overlay.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/table/attribute_row.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/table/attribute_top_bar.dart';

enum AttributeMode { importFile, firestore }

class AttributePage extends StatefulWidget {
  final String collectionPath;
  final List<String> targetFields;
  final String? title;
  final String? description;
  final AttributeMode mode;

  /// Camada real que está sendo editada quando a origem é Firestore.
  final String? sourceLayerId;

  const AttributePage({
    super.key,
    required this.collectionPath,
    required this.targetFields,
    this.title,
    this.description,
    this.mode = AttributeMode.importFile,
    this.sourceLayerId,
  });

  @override
  State<AttributePage> createState() => _AttributePageState();
}

class _AttributePageState extends State<AttributePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<String, TextEditingController> _fieldControllers = {};
  final ScrollController _pageScrollCtrl = ScrollController();

  PagedTableMetrics _tableMetrics = const PagedTableMetrics(
    totalRows: 0,
    visibleRows: 0,
    currentPage: 1,
    totalPages: 1,
    rowsPerPage: 25,
  );

  bool _updatingControllers = false;

  @override
  void initState() {
    super.initState();

    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    Future.microtask(() {
      final cubit = context.read<FeatureCubit>();

      if (widget.mode == AttributeMode.firestore) {
        cubit.startFromFirestore(
          widget.collectionPath,
          sourceLayerId: widget.sourceLayerId,
        );
      } else {
        cubit.startImport(widget.collectionPath);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _pageScrollCtrl.dispose();

    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogTitle = widget.title ??
        (widget.mode == AttributeMode.firestore
            ? 'Tabela de atributos (${widget.collectionPath})'
            : 'Importar (${widget.collectionPath})');

    return BlocListener<FeatureCubit, FeatureState>(
      listener: (context, state) {
        if (widget.mode == AttributeMode.importFile &&
            state.importStatus == FeatureImportStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      child: WindowDialog(
        title: dialogTitle,
        width: 1400,
        contentPadding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        onClose: () => Navigator.of(context).pop(false),
        child: SizedBox(
          height: 760,
          child: BlocBuilder<FeatureCubit, FeatureState>(
            builder: (context, state) {
              final isLoading =
                  state.importStatus == FeatureImportStatus.pickingFile ||
                      state.importStatus ==
                          FeatureImportStatus.loadingFirestore ||
                      state.importStatus == FeatureImportStatus.idle;

              if (isLoading) {
                return _center(
                  widget.mode == AttributeMode.firestore
                      ? 'Carregando feições do Firebase...'
                      : 'Carregando arquivo para pré-visualização...',
                );
              }

              if (state.importStatus == FeatureImportStatus.failure) {
                return AttributeError(
                  error: state.error,
                  onClose: () => Navigator.of(context).pop(false),
                );
              }

              if (state.importFeatures.isEmpty) {
                _syncFieldControllers(const []);
                _clearFormFields();

                return _center('Nenhuma feição encontrada.');
              }

              final columns = state.importColumns;

              final selectedColumnNames = columns
                  .where((c) => c.selected)
                  .map((c) => c.name)
                  .toList(growable: false);

              final columnsToShow = selectedColumnNames.isNotEmpty
                  ? selectedColumnNames
                  : columns.map((e) => e.name).toList(growable: false);

              _syncFieldControllers(columnsToShow);

              final filteredIndexes = _applySearchFilter(
                state: state,
                columnsForSearch: columnsToShow,
                query: _searchCtrl.text,
              );

              final filteredTotal = filteredIndexes.length;

              final rows = filteredIndexes
                  .map(
                    (featureIndex) => AttributeRow(
                  featureIndex: featureIndex,
                  feature: state.importFeatures[featureIndex],
                ),
              )
                  .toList(growable: false);

              final selectedFeature = _resolveSelectedFeature(state);
              final selectedKey = selectedFeature?.selectionKey;

              final geometryTypes = state.importFeatures
                  .map((e) => e.geometryTypeName.trim())
                  .where((e) => e.isNotEmpty && e != 'Unknown')
                  .toSet()
                  .toList()
                ..sort();

              final tipo = geometryTypes.isEmpty
                  ? 'Desconhecido'
                  : geometryTypes.length == 1
                  ? geometryTypes.first
                  : 'Misto (${geometryTypes.join(', ')})';

              _fillFormFields(
                columnsToShow: columnsToShow,
                feature: selectedFeature,
              );

              final selectedGeometryInfo =
              _buildSelectedGeometryInfo(selectedFeature);

              return Stack(
                children: [
                  Scrollbar(
                    controller: _pageScrollCtrl,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _pageScrollCtrl,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          AttributeForm(
                            columns: columnsToShow,
                            controllers: _fieldControllers,
                            hasSelection: selectedFeature != null,
                            onChangedField: _handleFieldChanged,
                          ),
                          AttributeTopBar(
                            mode: widget.mode,
                            description: widget.description,
                            state: state,
                            tipo: tipo,
                            selectedGeometryInfo: selectedGeometryInfo,
                            searchCtrl: _searchCtrl,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(1),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: ColoredBox(
                                  color: Colors.grey.shade50,
                                  child: AttributeContent(
                                    mode: widget.mode,
                                    state: state,
                                    tableColumns: columnsToShow,
                                    rows: rows,
                                    selectedKey: selectedKey,
                                    onMetricsChanged: (metrics) {
                                      if (_tableMetrics == metrics) return;
                                      if (!mounted) return;

                                      setState(() {
                                        _tableMetrics = metrics;
                                      });
                                    },
                                    onTapRow: (row) {
                                      _handleRowTap(
                                        row: row,
                                        state: state,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: AttributeBottomBar(
                              mode: widget.mode,
                              collectionPath: widget.collectionPath,
                              state: state,
                              filteredTotal: filteredTotal,
                              visibleRows: _tableMetrics.visibleRows,
                              totalRows: _tableMetrics.totalRows,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.importStatus == FeatureImportStatus.saving ||
                      state.importStatus == FeatureImportStatus.deleting)
                    AttributeOverlay(
                      status: state.importStatus,
                      progress: state.importProgress,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  FeatureData? _resolveSelectedFeature(FeatureState state) {
    final selected = state.selected;
    if (selected == null ||
        selected.layerId != FeatureCubit.importPreviewLayerId) {
      return null;
    }

    for (final feature in state.importFeatures) {
      if (feature.selectionKey == selected.feature.selectionKey) {
        return feature;
      }
    }

    return null;
  }

  void _handleRowTap({
    required AttributeRow row,
    required FeatureState state,
  }) {
    if (row.featureIndex < 0 || row.featureIndex >= state.importFeatures.length) {
      return;
    }

    final cubit = context.read<FeatureCubit>();
    final feature = state.importFeatures[row.featureIndex];
    cubit.selectImportFeature(feature);
  }

  void _handleFieldChanged(String field, String value) {
    if (_updatingControllers) return;
    context.read<FeatureCubit>().updateSelectedFeatureProperty(field, value);
  }

  List<int> _applySearchFilter({
    required FeatureState state,
    required List<String> columnsForSearch,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return List<int>.generate(
        state.importFeatures.length,
            (index) => index,
        growable: false,
      );
    }

    final result = <int>[];

    for (int i = 0; i < state.importFeatures.length; i++) {
      final feature = state.importFeatures[i];

      final matchesTitle =
      feature.title.toLowerCase().contains(normalizedQuery);
      if (matchesTitle) {
        result.add(i);
        continue;
      }

      bool matched = false;
      for (final field in columnsForSearch) {
        final value = feature.editedProperties[field];
        if (value != null &&
            value.toString().toLowerCase().contains(normalizedQuery)) {
          matched = true;
          break;
        }
      }

      if (matched) {
        result.add(i);
      }
    }

    return List<int>.unmodifiable(result);
  }

  void _syncFieldControllers(List<String> columns) {
    final desired = columns.toSet();

    final currentKeys = _fieldControllers.keys.toList(growable: false);
    for (final key in currentKeys) {
      if (!desired.contains(key)) {
        _fieldControllers.remove(key)?.dispose();
      }
    }

    for (final column in columns) {
      _fieldControllers.putIfAbsent(column, TextEditingController.new);
    }
  }

  void _clearFormFields() {
    _updatingControllers = true;
    try {
      for (final controller in _fieldControllers.values) {
        if (controller.text.isNotEmpty) {
          controller.text = '';
        }
      }
    } finally {
      _updatingControllers = false;
    }
  }

  void _fillFormFields({
    required List<String> columnsToShow,
    required FeatureData? feature,
  }) {
    _updatingControllers = true;
    try {
      for (final column in columnsToShow) {
        final controller = _fieldControllers[column];
        if (controller == null) continue;

        final nextText = feature == null
            ? ''
            : (feature.editedProperties[column]?.toString() ?? '');

        if (controller.text != nextText) {
          controller.text = nextText;
        }
      }
    } finally {
      _updatingControllers = false;
    }
  }

  String _buildSelectedGeometryInfo(FeatureData? feature) {
    if (feature == null) {
      return 'Nenhuma feição selecionada';
    }

    final parts = <String>[
      'Tipo: ${feature.geometryTypeName}',
    ];

    if (feature.markerPoints.isNotEmpty) {
      parts.add('Pontos: ${feature.markerPoints.length}');
    }

    if (feature.lineParts.isNotEmpty) {
      parts.add('Linhas: ${feature.lineParts.length}');
    }

    if (feature.polygonRings.isNotEmpty) {
      parts.add('Anéis: ${feature.polygonRings.length}');
    }

    final center = feature.center;
    if (center != null) {
      parts.add(
        'Centro: ${center.latitude.toStringAsFixed(6)}, ${center.longitude.toStringAsFixed(6)}',
      );
    }

    return parts.join(' • ');
  }

  Widget _center(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}