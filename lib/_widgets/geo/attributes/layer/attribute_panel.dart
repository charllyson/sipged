import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_field.dart';
import 'package:sipged/_widgets/geo/attributes/layer/attribute_import.dart';
import 'package:sipged/_widgets/geo/attributes/layer/attribute_layer.dart';
import 'package:sipged/_widgets/geo/attributes/layer/attribute_property.dart';
import 'package:sipged/_widgets/geo/attributes/layer/attribute_tile.dart';
import 'package:sipged/_widgets/buttons/header_icon_button.dart';

class AttributePanel extends StatelessWidget {
  final GeoFeatureState genericState;
  final Map<String, GeoLayersData> layersById;
  final String? selectedLayerId;
  final Map<String, List<String>> availableFieldsByLayer;
  final Map<String, bool> hasDataByLayer;
  final ValueChanged<GeoLayersData>? onImportLayer;
  final ValueChanged<GeoLayersData>? onOpenTable;

  const AttributePanel({
    super.key,
    required this.genericState,
    required this.layersById,
    required this.selectedLayerId,
    required this.availableFieldsByLayer,
    this.hasDataByLayer = const {},
    this.onImportLayer,
    this.onOpenTable,
  });

  @override
  Widget build(BuildContext context) {
    final featureSelection = genericState.selected;
    final selectedLayer =
    selectedLayerId == null ? null : layersById[selectedLayerId!];

    if (featureSelection != null) {
      final layer = layersById[featureSelection.layerId];
      final feature = featureSelection.feature;

      final keys = <String>{
        ...feature.originalProperties.keys,
        ...feature.editedProperties.keys,
      }.toList()
        ..sort((a, b) => a.compareTo(b));

      final hasData = layer != null ? _hasData(layer.id) : false;

      return RepaintBoundary(
        child: AttributeLayer(
          headerTitle: layer?.title ?? 'Camada',
          headerColor: (layer?.color ?? Colors.blue).withValues(alpha: 0.10),
          headerTrailing: (layer != null && hasData)
              ? AttributeOpenTable(
            tooltip: 'Abrir tabela de atributos',
            icon: Icons.table_view_rounded,
            onTap: () => onOpenTable?.call(layer),
          )
              : null,
          emptyText: 'Esta feição não possui atributos.',
          children: [
            for (final key in keys)
              AttributeTile(
                label: key,
                value: _featureValue(feature, key)?.toString() ?? '',
                dragData: GeoWorkspaceDataFieldDrag(
                  sourceId: featureSelection.layerId,
                  sourceLabel: layer?.title ?? 'Camada',
                  fieldName: key,
                  fieldValue: _featureValue(feature, key),
                ),
              ),
          ],
        ),
      );
    }

    if (selectedLayer != null) {
      final hasData = _hasData(selectedLayer.id);

      if (!hasData) {
        return RepaintBoundary(
          child: AttributeLayer(
            headerTitle: selectedLayer.title,
            headerColor: selectedLayer.color.withValues(alpha: 0.10),
            emptyText: '',
            body: AttributeImport(
              layerTitle: selectedLayer.title,
              onImport: () => onImportLayer?.call(selectedLayer),
            ),
          ),
        );
      }

      final fields = List<String>.from(
        availableFieldsByLayer[selectedLayer.id] ?? const <String>[],
      )..sort((a, b) => a.compareTo(b));

      return RepaintBoundary(
        child: AttributeLayer(
          headerTitle: selectedLayer.title,
          headerColor: selectedLayer.color.withValues(alpha: 0.10),
          headerTrailing: AttributeOpenTable(
            tooltip: 'Abrir tabela de atributos',
            icon: Icons.table_view_rounded,
            onTap: () => onOpenTable?.call(selectedLayer),
          ),
          emptyText: 'Esta camada ainda não possui campos identificados.',
          children: [
            for (final field in fields)
              AttributeProperty(
                label: field,
                dragData: GeoWorkspaceDataFieldDrag(
                  sourceId: selectedLayer.id,
                  sourceLabel: selectedLayer.title,
                  fieldName: field,
                ),
              ),
          ],
        ),
      );
    }

    return const Center(
      child: Text(
        'Selecione uma feição no mapa ou uma camada no painel para visualizar os atributos.',
        textAlign: TextAlign.center,
      ),
    );
  }

  bool _hasData(String layerId) => hasDataByLayer[layerId] == true;

  dynamic _featureValue(GeoFeatureData feature, String field) {
    if (feature.editedProperties.containsKey(field)) {
      return feature.editedProperties[field];
    }
    return feature.originalProperties[field];
  }
}