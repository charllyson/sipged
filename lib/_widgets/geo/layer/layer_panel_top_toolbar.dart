import 'package:flutter/material.dart';
import 'package:sipged/_widgets/buttons/toolbar_icon_button.dart';

class LayerPanelTopToolbar extends StatelessWidget {
  final String? selectedId;
  final VoidCallback? onCreateLayer;
  final VoidCallback? onCreateEmptyGroup;
  final void Function(String id)? onRemoveSelected;
  final void Function(String id)? onRenameSelected;
  final void Function(String id)? onMoveDown;
  final void Function(String id)? onMoveUp;

  const LayerPanelTopToolbar({
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
    final selectedId = this.selectedId;

    return SizedBox(
      height: 46,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ToolbarIconButton(
                  icon: Icons.add,
                  tooltip: 'Criar camada',
                  onTap: onCreateLayer,
                ),
                ToolbarIconButton(
                  icon: Icons.remove_circle_outline,
                  tooltip: 'Remover item',
                  onTap: selectedId == null
                      ? null
                      : () => onRemoveSelected?.call(selectedId),
                ),
                ToolbarIconButton(
                  icon: Icons.create_new_folder_outlined,
                  tooltip: 'Criar grupo',
                  onTap: onCreateEmptyGroup,
                ),
                ToolbarIconButton(
                  icon: Icons.settings,
                  tooltip: 'Configurações',
                  onTap: selectedId == null
                      ? null
                      : () => onRenameSelected?.call(selectedId),
                ),
                ToolbarIconButton(
                  icon: Icons.arrow_downward_outlined,
                  tooltip: 'Mover para baixo',
                  onTap: selectedId == null
                      ? null
                      : () => onMoveDown?.call(selectedId),
                ),
                ToolbarIconButton(
                  icon: Icons.arrow_upward_outlined,
                  tooltip: 'Mover para cima',
                  onTap: selectedId == null
                      ? null
                      : () => onMoveUp?.call(selectedId),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}