import 'package:flutter/material.dart';
import 'package:sipged/_widgets/buttons/icon_button_changed.dart';

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
      spacing: 4,
      runSpacing: 4,
      children: [
        IconButtonChanged(
          icon: Icons.add,
          tooltip: addTooltip,
          selected: false,
          size: 32,
          iconSize: 18,
          enabled: onAdd != null,
          onTap: onAdd,
        ),
        IconButtonChanged(
          icon: Icons.arrow_upward,
          tooltip: moveUpTooltip,
          selected: false,
          size: 32,
          iconSize: 18,
          enabled: onMoveUp != null,
          onTap: onMoveUp,
        ),
        IconButtonChanged(
          icon: Icons.remove,
          tooltip: removeTooltip,
          selected: false,
          size: 32,
          iconSize: 18,
          enabled: onRemove != null,
          onTap: onRemove,
        ),
        IconButtonChanged(
          icon: Icons.arrow_downward,
          tooltip: moveDownTooltip,
          selected: false,
          size: 32,
          iconSize: 18,
          enabled: onMoveDown != null,
          onTap: onMoveDown,
        ),
        IconButtonChanged(
          icon: Icons.copy_outlined,
          tooltip: duplicateTooltip,
          selected: false,
          size: 32,
          iconSize: 18,
          enabled: onDuplicate != null,
          onTap: onDuplicate,
        ),
      ],
    );
  }
}