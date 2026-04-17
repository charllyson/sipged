import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_state.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/screens/modules/planning/geo/attribute/table/attribute_page.dart';

class AttributeTopBar extends StatelessWidget {
  final AttributeMode mode;
  final String? description;
  final String tipo;
  final String selectedGeometryInfo;
  final TextEditingController searchCtrl;
  final FeatureState state;

  const AttributeTopBar({
    super.key,
    required this.mode,
    required this.description,
    required this.tipo,
    required this.selectedGeometryInfo,
    required this.searchCtrl,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != null && description!.trim().isNotEmpty) ...[
              Text(
                description!.trim(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.category_outlined),
                  label: Text('Geometria: $tipo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.polyline_outlined),
                  label: Text(selectedGeometryInfo),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 360,
                  child: CustomTextField(
                    controller: searchCtrl,
                    labelText: 'Filtrar',
                    suffix: searchCtrl.text.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => searchCtrl.clear(),
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}