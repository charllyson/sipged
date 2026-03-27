import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_field.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_property.dart';
import 'package:sipged/_widgets/geo/visualizations/property/tab_property_visualization.dart';

class TabPropertyPanel extends StatelessWidget {
  const TabPropertyPanel({
    super.key,
    required this.selectedItem,
    required this.featuresByLayer,
    required this.onPropertyChanged,
    required this.onBindingDropped,
  });

  final GeoWorkspaceData? selectedItem;
  final Map<String, List<GeoFeatureData>> featuresByLayer;
  final void Function(String itemId, GeoWorkspaceDataProperty property)
  onPropertyChanged;
  final void Function(
      String itemId,
      String propertyKey,
      GeoWorkspaceDataFieldDrag data,
      ) onBindingDropped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedItem == null) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Text(
            'Selecione um widget na área de trabalho para editar seus dados.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.black.withValues(alpha: 0.60),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final item = selectedItem!;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(10),
      child: ListView.separated(
        itemCount: item.properties.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final property = item.properties[index];

          return TabPropertyVisualization(
            key: ValueKey('${item.id}_${property.key}'),
            itemId: item.id,
            property: property,
            featuresByLayer: featuresByLayer,
            item: item,
            onPropertyChanged: (updated) =>
                onPropertyChanged(item.id, updated),
            onBindingDropped: (data) =>
                onBindingDropped(item.id, property.key, data),
          );
        },
      ),
    );
  }
}
