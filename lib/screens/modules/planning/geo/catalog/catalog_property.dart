import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data_binding.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/catalog_binding.dart';
import 'package:sipged/screens/modules/planning/geo/catalog/catalog_field.dart';

class CatalogProperty extends StatelessWidget {
  const CatalogProperty({
    super.key,
    required this.item,
    required this.property,
    required this.onPropertyChanged,
    required this.onBindingDropped,
  });

  final WorkspaceData item;
  final CatalogData property;
  final ValueChanged<CatalogData> onPropertyChanged;
  final ValueChanged<FeatureDataBinding> onBindingDropped;

  @override
  Widget build(BuildContext context) {
    final propertyKey = property.key ?? '';
    final label = property.label ?? '';

    final Widget content = property.type == CatalogPropertyType.binding
        ? CatalogBinding(
      key: ValueKey('binding_$propertyKey'),
      property: property,
      onBindingDropped: onBindingDropped,
    )
        : CatalogField(
      key: ValueKey('field_${propertyKey}_${property.type}'),
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
                label,
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