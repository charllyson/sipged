import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/buttons/geo_action_button.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/form/form_symbology_layers.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/preview/axis_preview.dart';

class SingleListPanel extends StatelessWidget {
  final LayerGeometryKind geometryKind;
  final List<LayerSimpleSymbolData> layers;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onDuplicate;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const SingleListPanel({
    super.key,
    required this.geometryKind,
    required this.layers,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
    required this.onRemove,
    required this.onDuplicate,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  List<Widget> _buildActionButtons() {
    return [
      GeoActionButton(
        icon: Icons.add,
        color: Colors.green.shade600,
        tooltip: 'Adicionar símbolo',
        onTap: onAdd,
      ),
      GeoActionButton(
        icon: Icons.arrow_upward,
        color: Colors.blue.shade700,
        tooltip: 'Mover para cima',
        onTap: onMoveUp,
      ),
      GeoActionButton(
        icon: Icons.remove,
        color: Colors.red.shade600,
        tooltip: 'Remover símbolo',
        onTap: onRemove,
      ),
      GeoActionButton(
        icon: Icons.arrow_downward,
        color: Colors.grey.shade700,
        tooltip: 'Mover para baixo',
        onTap: onMoveDown,
      ),
      GeoActionButton(
        icon: Icons.copy_outlined,
        color: Colors.orange.shade700,
        tooltip: 'Duplicar símbolo',
        onTap: onDuplicate,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final buttons = _buildActionButtons();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 760;

        if (isNarrow) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 120,
                  child: RepaintBoundary(
                    child: AxisPreview(
                      geometryKind: geometryKind,
                      layers: layers,
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                SizedBox(
                  height: 120,
                  child: FormSymbologyLayers(
                    geometryKind: geometryKind,
                    layers: layers,
                    selectedIndex: selectedIndex,
                    onSelect: onSelect,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: buttons,
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 254,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 220,
                  child: RepaintBoundary(
                    child: AxisPreview(
                      geometryKind: geometryKind,
                      layers: layers,
                    ),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: FormSymbologyLayers(
                    geometryKind: geometryKind,
                    layers: layers,
                    selectedIndex: selectedIndex,
                    onSelect: onSelect,
                  ),
                ),
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < buttons.length; i++) ...[
                        buttons[i],
                        if (i != buttons.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}