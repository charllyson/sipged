import 'package:flutter/material.dart';

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
                _ToolbarIconButton(
                  icon: Icons.add,
                  tooltip: 'Criar camada',
                  onTap: onCreateLayer,
                ),
                _ToolbarIconButton(
                  icon: Icons.remove_circle_outline,
                  tooltip: 'Remover item',
                  onTap: selectedId == null
                      ? null
                      : () => onRemoveSelected?.call(selectedId),
                ),
                _ToolbarIconButton(
                  icon: Icons.create_new_folder_outlined,
                  tooltip: 'Criar grupo',
                  onTap: onCreateEmptyGroup,
                ),
                _ToolbarIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Editar',
                  onTap: selectedId == null
                      ? null
                      : () => onRenameSelected?.call(selectedId),
                ),
                _ToolbarIconButton(
                  icon: Icons.arrow_downward_outlined,
                  tooltip: 'Mover para baixo',
                  onTap: selectedId == null
                      ? null
                      : () => onMoveDown?.call(selectedId),
                ),
                _ToolbarIconButton(
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

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? Colors.grey.shade400 : Colors.grey.shade800;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}