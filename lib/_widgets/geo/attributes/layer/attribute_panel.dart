import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_field.dart';
import 'package:sipged/_widgets/geo/attributes/layer/attribute_tile.dart';
import 'package:sipged/_widgets/geo/attributes/layer/attribute_layer_title.dart';
import 'package:sipged/_widgets/geo/attributes/layer/attribute_property_title.dart';

class AttributePanel extends StatelessWidget {
  final GeoFeatureState genericState;
  final Map<String, GeoLayersData> layersById;
  final String? selectedLayerId;
  final Map<String, List<String>> availableFieldsByLayer;

  const AttributePanel({
    super.key,
    required this.genericState,
    required this.layersById,
    required this.selectedLayerId,
    required this.availableFieldsByLayer,
  });

  @override
  Widget build(BuildContext context) {
    final featureSelection = genericState.selected;
    final selectedLayer =
    selectedLayerId == null ? null : layersById[selectedLayerId!];

    if (featureSelection != null) {
      final layer = layersById[featureSelection.layerId];
      final feature = featureSelection.feature;

      final entries = feature.properties.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      return RepaintBoundary(
        child: AttributeLayerTitle(
          headerTitle: layer?.title ?? 'Camada',
          headerColor: (layer?.color ?? Colors.blue).withValues(alpha: 0.10),
          emptyText: 'Esta feição não possui atributos.',
          children: [
            for (final entry in entries)
              AttributeTile(
                label: entry.key,
                value: entry.value == null ? '' : entry.value.toString(),
                dragData: GeoWorkspaceDataFieldDrag(
                  sourceId: featureSelection.layerId,
                  sourceLabel: layer?.title ?? 'Camada',
                  fieldName: entry.key,
                  fieldValue: entry.value,
                ),
              ),
          ],
        ),
      );
    }

    if (selectedLayer != null) {
      final fields = List<String>.from(
        availableFieldsByLayer[selectedLayer.id] ?? const <String>[],
      )..sort((a, b) => a.compareTo(b));

      return RepaintBoundary(
        child: AttributeLayerTitle(
          headerTitle: selectedLayer.title,
          headerColor: selectedLayer.color.withValues(alpha: 0.10),
          emptyText: 'Esta camada ainda não possui campos identificados.',
          children: [
            for (final field in fields)
              AttributePropertyTitle(
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
}
