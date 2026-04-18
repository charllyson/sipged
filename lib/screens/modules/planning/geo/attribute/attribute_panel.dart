import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_binding.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_map.dart';
import 'package:sipged/_blocs/system/map/map_state.dart';
import 'package:sipged/_widgets/buttons/header_icon_button.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/attribute_import.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/attribute_layer.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/attribute_property.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/attribute_tile.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/table/attribute_page.dart';

class AttributePanel extends StatelessWidget {
  const AttributePanel({
    super.key,
    required this.mapData,
    required this.editorState,
    required this.genericState,
    required this.onOpenLayerTable,
  });

  final LayerDataMap mapData;
  final MapState editorState;
  final FeatureState genericState;
  final Future<void> Function(LayerData layer) onOpenLayerTable;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: KeyedSubtree(
          key: ValueKey(
            'attributes_panel_'
                '${genericState.selected?.feature.selectionKey ?? 'none'}_'
                '${editorState.selectedLayerPanelItemId ?? 'none'}_'
                '${Object.hashAll(genericState.availableFieldsByLayer.entries.map((e) => Object.hash(e.key, Object.hashAll(e.value))))}_'
                '${Object.hashAll(mapData.hasDataByLayer.entries.map((e) => Object.hash(e.key, e.value)))}',
          ),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final featureSelection = genericState.selected;
    final selectedLayerId = editorState.selectedLayerPanelItemId;
    final selectedLayer =
    selectedLayerId == null ? null : mapData.layersById[selectedLayerId];

    if (featureSelection != null) {
      final layer = mapData.layersById[featureSelection.layerId];
      final feature = featureSelection.feature;

      final keys = <String>{
        ...feature.originalProperties.keys,
        ...feature.editedProperties.keys,
      }.toList()
        ..sort((a, b) => a.compareTo(b));

      final hasData = layer != null ? _hasData(layer.id) : false;

      return AttributeLayer(
        headerTitle: layer?.title ?? 'Camada',
        headerColor: (layer?.color ?? Colors.blue).withValues(alpha: 0.10),
        headerTrailing: (layer != null && hasData)
            ? AttributeOpenTable(
          tooltip: 'Abrir tabela de atributos',
          icon: Icons.table_view_rounded,
          onTap: () => onOpenLayerTable(layer),
        )
            : null,
        emptyText: 'Esta feição não possui atributos.',
        children: [
          for (final key in keys)
            AttributeTile(
              label: key,
              value: _featureValue(feature, key)?.toString() ?? '',
              dragData: FeatureDataBinding(
                sourceId: featureSelection.layerId,
                sourceLabel: layer?.title ?? 'Camada',
                fieldName: key,
                fieldValue: _featureValue(feature, key),
              ),
            ),
        ],
      );
    }

    if (selectedLayer != null) {
      final hasData = _hasData(selectedLayer.id);

      if (!hasData) {
        return AttributeLayer(
          headerTitle: selectedLayer.title,
          headerColor: selectedLayer.color.withValues(alpha: 0.10),
          emptyText: '',
          body: AttributeImportView(
            layerTitle: selectedLayer.title,
            onImport: () => _handleImportLayer(context, selectedLayer),
          ),
        );
      }

      final fields = List<String>.from(
        genericState.availableFieldsByLayer[selectedLayer.id] ??
            const <String>[],
      )..sort((a, b) => a.compareTo(b));

      return AttributeLayer(
        headerTitle: selectedLayer.title,
        headerColor: selectedLayer.color.withValues(alpha: 0.10),
        headerTrailing: AttributeOpenTable(
          tooltip: 'Abrir tabela de atributos',
          icon: Icons.table_view_rounded,
          onTap: () => onOpenLayerTable(selectedLayer),
        ),
        emptyText: 'Esta camada ainda não possui campos identificados.',
        children: [
          for (final field in fields)
            AttributeProperty(
              label: field,
              dragData: FeatureDataBinding(
                sourceId: selectedLayer.id,
                sourceLabel: selectedLayer.title,
                fieldName: field,
              ),
            ),
        ],
      );
    }

    return const Center(
      child: Text(
        'Selecione uma feição no mapa ou uma camada no painel para visualizar os atributos.',
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _handleImportLayer(
      BuildContext context,
      LayerData layer,
      ) async {
    await _openImportDialog(
      context,
      layer: layer,
    );

    if (!context.mounted) return;

    final shouldLoadOnMap = mapData.activeLayerIds.contains(layer.id);

    await _reloadLayerAfterImport(
      context,
      layer: layer,
      shouldLoadOnMap: shouldLoadOnMap,
    );

    if (!context.mounted) return;

    await context.read<LayerCubit>().refreshLayerData(
      layer,
      force: true,
    );

    if (!context.mounted) return;

    await context.read<FeatureCubit>().ensureLayerFieldNames(
      layer,
      force: true,
    );

    if (!context.mounted) return;

    await context.read<FeatureCubit>().ensureLayerLoaded(
      layer,
      force: true,
    );
  }

  Future<void> _openImportDialog(
      BuildContext context, {
        required LayerData layer,
      }) async {
    final featureCubit = context.read<FeatureCubit>();
    final path = layer.effectiveCollectionPath ?? '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: featureCubit,
        child: AttributePage(
          mode: AttributeMode.importFile,
          collectionPath: path,
          targetFields: const [],
          title: 'Importar ${layer.title}',
          description:
          'Importe GeoJSON / KML / KMZ. Após salvar, as feições desta camada serão gravadas no Firebase dentro da coleção principal geo e poderão ser desenhadas dinamicamente no mapa.',
        ),
      ),
    );
  }

  Future<void> _reloadLayerAfterImport(
      BuildContext context, {
        required LayerData layer,
        required bool shouldLoadOnMap,
      }) async {
    await context.read<LayerCubit>().refreshLayerData(
      layer,
      force: true,
    );

    if (shouldLoadOnMap) {
      await context.read<FeatureCubit>().reloadLayer(layer);
    }
  }

  bool _hasData(String layerId) => mapData.hasDataByLayer[layerId] == true;

  dynamic _featureValue(FeatureData feature, String field) {
    if (feature.editedProperties.containsKey(field)) {
      return feature.editedProperties[field];
    }
    return feature.originalProperties[field];
  }
}