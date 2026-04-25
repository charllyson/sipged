import 'package:flutter/material.dart';
import 'package:sipged/_widgets/buttons/icon_button_changed.dart';

class LayerToolbar extends StatelessWidget {
  final String? selectedId;
  final VoidCallback? onCreateLayer;
  final VoidCallback? onCreateEmptyGroup;
  final void Function(String id)? onRemoveSelected;
  final void Function(String id)? onRenameSelected;
  final void Function(String id)? onMoveDown;
  final void Function(String id)? onMoveUp;

  const LayerToolbar({
    super.key,
    required this.selectedId,
    this.onCreateLayer,
    this.onCreateEmptyGroup,
    this.onRemoveSelected,
    this.onRenameSelected,
    this.onMoveDown,
    this.onMoveUp,
  });

  @override
  Widget build(BuildContext context) {
    final currentSelectedId = selectedId;

    final actions = <Widget>[
      IconButtonChanged(
        icon: Icons.add,
        tooltip: 'Criar camada',
        selected: false,
        size: 34,
        iconSize: 18,
        enabled: onCreateLayer != null,
        onTap: onCreateLayer,
      ),
      IconButtonChanged(
        icon: Icons.remove_circle_outline,
        tooltip: 'Remover item',
        selected: false,
        size: 34,
        iconSize: 18,
        enabled: currentSelectedId != null && onRemoveSelected != null,
        onTap: currentSelectedId == null
            ? null
            : () => onRemoveSelected?.call(currentSelectedId),
      ),
      IconButtonChanged(
        icon: Icons.create_new_folder_outlined,
        tooltip: 'Criar grupo',
        selected: false,
        size: 34,
        iconSize: 18,
        enabled: onCreateEmptyGroup != null,
        onTap: onCreateEmptyGroup,
      ),
      IconButtonChanged(
        icon: Icons.settings,
        tooltip: 'Configurações',
        selected: false,
        size: 34,
        iconSize: 18,
        enabled: currentSelectedId != null && onRenameSelected != null,
        onTap: currentSelectedId == null
            ? null
            : () => onRenameSelected?.call(currentSelectedId),
      ),
      IconButtonChanged(
        icon: Icons.arrow_downward_outlined,
        tooltip: 'Mover para baixo',
        selected: false,
        size: 34,
        iconSize: 18,
        enabled: currentSelectedId != null && onMoveDown != null,
        onTap: currentSelectedId == null
            ? null
            : () => onMoveDown?.call(currentSelectedId),
      ),
      IconButtonChanged(
        icon: Icons.arrow_upward_outlined,
        tooltip: 'Mover para cima',
        selected: false,
        size: 34,
        iconSize: 18,
        enabled: currentSelectedId != null && onMoveUp != null,
        onTap: currentSelectedId == null
            ? null
            : () => onMoveUp?.call(currentSelectedId),
      ),
    ];

    return SizedBox(
      height: 34,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  actions[i],
                  if (i < actions.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}