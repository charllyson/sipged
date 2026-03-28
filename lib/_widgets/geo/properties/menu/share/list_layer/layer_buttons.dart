import 'package:flutter/material.dart';
import 'package:sipged/_widgets/buttons/geo_action_button.dart';

class LayerButtons extends StatelessWidget {
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onDuplicate;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  final String addTooltip;
  final String removeTooltip;
  final String duplicateTooltip;
  final String moveUpTooltip;
  final String moveDownTooltip;

  const LayerButtons({
    super.key,
    this.onAdd,
    this.onRemove,
    this.onDuplicate,
    this.onMoveUp,
    this.onMoveDown,
    this.addTooltip = 'Adicionar',
    this.removeTooltip = 'Remover',
    this.duplicateTooltip = 'Duplicar',
    this.moveUpTooltip = 'Mover para cima',
    this.moveDownTooltip = 'Mover para baixo',
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        GeoActionButton(
          icon: Icons.add,
          color: Colors.green.shade600,
          tooltip: addTooltip,
          onTap: onAdd,
        ),
        GeoActionButton(
          icon: Icons.arrow_upward,
          color: Colors.blue.shade700,
          tooltip: moveUpTooltip,
          onTap: onMoveUp,
        ),
        GeoActionButton(
          icon: Icons.remove,
          color: Colors.red.shade600,
          tooltip: removeTooltip,
          onTap: onRemove,
        ),
        GeoActionButton(
          icon: Icons.arrow_downward,
          color: Colors.grey.shade700,
          tooltip: moveDownTooltip,
          onTap: onMoveDown,
        ),
        GeoActionButton(
          icon: Icons.copy_outlined,
          color: Colors.orange.shade700,
          tooltip: duplicateTooltip,
          onTap: onDuplicate,
        ),
      ],
    );
  }
}