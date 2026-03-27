import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_field.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_property.dart';
import 'package:sipged/_widgets/geo/visualizations/property/tab_property_binding.dart';
import 'package:sipged/_widgets/geo/visualizations/property/tab_property_number_list.dart';
import 'package:sipged/_widgets/geo/visualizations/property/tab_property_number.dart';
import 'package:sipged/_widgets/geo/visualizations/property/tab_property_select.dart';
import 'package:sipged/_widgets/geo/visualizations/property/tab_property_string_list.dart';
import 'package:sipged/_widgets/geo/visualizations/property/tab_property_text.dart';

class TabPropertyVisualization extends StatelessWidget {
  const TabPropertyVisualization({
    super.key,
    required this.itemId,
    required this.item,
    required this.property,
    required this.featuresByLayer,
    required this.onPropertyChanged,
    required this.onBindingDropped,
  });

  final String itemId;
  final GeoWorkspaceData item;
  final GeoWorkspaceDataProperty property;
  final Map<String, List<GeoFeatureData>> featuresByLayer;
  final ValueChanged<GeoWorkspaceDataProperty> onPropertyChanged;
  final ValueChanged<GeoWorkspaceDataFieldDrag> onBindingDropped;

  @override
  Widget build(BuildContext context) {
    final content = switch (property.type) {
      GeoWorkspacePropertyType.text => TabPropertyText(
        key: ValueKey('text_${property.key}'),
        property: property,
        onChanged: (value) => onPropertyChanged(
          property.copyWith(textValue: value),
        ),
      ),
      GeoWorkspacePropertyType.number => TabPropertyNumber(
        key: ValueKey('number_${property.key}'),
        property: property,
        onChanged: (value) => onPropertyChanged(
          property.copyWith(numberValue: value),
        ),
      ),
      GeoWorkspacePropertyType.stringList => TabPropertyStringList(
        key: ValueKey('string_list_${property.key}'),
        property: property,
        onChanged: (value) => onPropertyChanged(
          property.copyWith(stringListValue: value),
        ),
      ),
      GeoWorkspacePropertyType.numberList => TabPropertyNumberList(
        key: ValueKey('number_list_${property.key}'),
        property: property,
        onChanged: (value) => onPropertyChanged(
          property.copyWith(numberListValue: value),
        ),
      ),
      GeoWorkspacePropertyType.select => TabPropertySelect(
        key: ValueKey('select_${property.key}'),
        property: property,
        onChanged: (value) => onPropertyChanged(
          property.copyWith(selectedValue: value),
        ),
      ),
      GeoWorkspacePropertyType.binding => TabPropertyBinding(
        key: ValueKey('binding_${property.key}'),
        item: item,
        property: property,
        featuresByLayer: featuresByLayer,
        onBindingDropped: onBindingDropped,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
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
