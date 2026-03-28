import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';

class MenuGeneral extends StatelessWidget {
  final TextEditingController nameController;
  final LayerGeometryKind geometryKind;
  final VoidCallback onSubmit;

  const MenuGeneral({
    super.key,
    required this.nameController,
    required this.geometryKind,
    required this.onSubmit,
  });

  String _geometryLabel(LayerGeometryKind kind) {
    switch (kind) {
      case LayerGeometryKind.point:
        return 'Ponto / Multiponto';
      case LayerGeometryKind.line:
        return 'Linha / Multilinha';
      case LayerGeometryKind.polygon:
        return 'Polígono / Multipolígono';
      case LayerGeometryKind.mixed:
        return 'Geometria mista';
      case LayerGeometryKind.unknown:
        return 'Geometria não identificada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKnownGeometry = geometryKind == LayerGeometryKind.point ||
        geometryKind == LayerGeometryKind.line ||
        geometryKind == LayerGeometryKind.polygon;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: RepaintBoundary(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: nameController,
                    labelText: 'Nome da camada',
                    onSubmitted: (_) => onSubmit(),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Geometria da camada: ${_geometryLabel(geometryKind)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!isKnownGeometry) ...[
                    const SizedBox(height: 10),
                    Text(
                      'A camada ainda está com geometria indefinida. O sistema assume comportamento básico até que o tipo real seja salvo na camada.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}