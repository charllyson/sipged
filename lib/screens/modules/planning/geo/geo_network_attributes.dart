import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';

class GeoNetworkAttributes extends StatelessWidget {
  final GeoFeatureState genericState;
  final Map<String, GeoLayersData> layersById;

  const GeoNetworkAttributes({
    super.key,
    required this.genericState,
    required this.layersById,
  });

  @override
  Widget build(BuildContext context) {
    final selection = genericState.selected;

    if (selection == null) {
      return const Center(
        child: Text(
          'Selecione uma feição no mapa para visualizar os atributos.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final layer = layersById[selection.layerId];
    final feature = selection.feature;

    final entries = feature.properties.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return RepaintBoundary(
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: (layer?.color ?? Colors.blue).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    layer?.title ?? 'Camada',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                child: Text('Esta feição não possui atributos.'),
              )
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 5),
                itemCount: entries.length,
                separatorBuilder: (_, __) => Container(height: 10),
                itemBuilder: (_, index) {
                  final e = entries[index];
                  return CustomTextField(
                    enabled: false,
                    readOnly: true,
                    labelText: e.key,
                    initialValue: e.value == null ? '' : e.value.toString(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}