import 'package:flutter/material.dart';
import 'package:sipged/_widgets/buttons/geo_action_button.dart';

class RuleActionButtons extends StatelessWidget {
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onDuplicate;

  final String addTooltip;
  final String removeTooltip;
  final String duplicateTooltip;

  const RuleActionButtons({
    super.key,
    this.onAdd,
    this.onRemove,
    this.onDuplicate,
    this.addTooltip = 'Adicionar regra',
    this.removeTooltip = 'Remover regra',
    this.duplicateTooltip = 'Duplicar regra',
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
          icon: Icons.remove,
          color: Colors.red.shade600,
          tooltip: removeTooltip,
          onTap: onRemove,
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