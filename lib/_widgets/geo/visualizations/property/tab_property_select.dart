import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_property.dart';

class TabPropertySelect extends StatelessWidget {
  const TabPropertySelect({
    super.key,
    required this.property,
    required this.onChanged,
  });

  final GeoWorkspaceDataProperty property;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = property.options ?? const <String>[];
    final selected =
    options.contains(property.selectedValue) ? property.selectedValue : null;

    return DropdownButtonFormField<String>(
      value: selected,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      items: options
          .map(
            (e) => DropdownMenuItem<String>(
          value: e,
          child: Text(e),
        ),
      )
          .toList(growable: false),
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}

