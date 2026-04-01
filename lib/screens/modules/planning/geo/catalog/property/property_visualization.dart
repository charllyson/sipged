import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/attribute/attribute_data_drag.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/property/component_data_property.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/property/property_binding.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/property/property_field.dart';

class PropertyVisualization extends StatelessWidget {
  const PropertyVisualization({
    super.key,
    required this.item,
    required this.property,
    required this.onPropertyChanged,
    required this.onBindingDropped,
  });

  final WorkspaceData item;
  final ComponentDataProperty property;
  final ValueChanged<ComponentDataProperty> onPropertyChanged;
  final ValueChanged<AttributeDataDrag> onBindingDropped;

  @override
  Widget build(BuildContext context) {
    final Widget content = property.type == ComponentPropertyType.binding
        ? PropertyBinding(
      key: ValueKey('binding_${property.key}'),
      property: property,
      onBindingDropped: onBindingDropped,
    )
        : PropertyField(
      key: ValueKey('field_${property.key}_${property.type.name}'),
      property: property,
      onPropertyChanged: onPropertyChanged,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                property.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: content),
        ],
      ),
    );
  }
}