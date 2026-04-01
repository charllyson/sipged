import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/attribute/attribute_data_drag.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/property/component_data_property.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/property/property_visualization.dart';

class PropertyPanel extends StatelessWidget {
  const PropertyPanel({
    super.key,
    required this.selectedItem,
    required this.onPropertyChanged,
    required this.onBindingDropped,
  });

  final WorkspaceData? selectedItem;
  final void Function(String itemId, ComponentDataProperty property)
  onPropertyChanged;
  final void Function(
      String itemId,
      String propertyKey,
      AttributeDataDrag data,
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

          return PropertyVisualization(
            key: ValueKey('${item.id}_${property.key}'),
            item: item,
            property: property,
            onPropertyChanged: (updated) {
              onPropertyChanged(item.id, updated);
            },
            onBindingDropped: (data) {
              onBindingDropped(item.id, property.key, data);
            },
          );
        },
      ),
    );
  }
}