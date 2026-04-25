import 'package:flutter/material.dart';
import 'package:sipged/_widgets/buttons/icon_button_changed.dart';

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
          icon: Icons.remove,
          tooltip: removeTooltip,
          selected: false,
          size: 32,
          iconSize: 18,
          enabled: onRemove != null,
          onTap: onRemove,
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