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
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolbarIconButton(
              icon: Icons.add,
              tooltip: 'Criar camada',
              onTap: onCreateLayer,
            ),
            _toolbarIconButton(
              icon: Icons.remove_circle_outline,
              tooltip: 'Remover item',
              onTap: selectedId == null ? null : () => onRemoveSelected?.call(selectedId!),
            ),
            _toolbarIconButton(
              icon: Icons.create_new_folder_outlined,
              tooltip: 'Criar grupo',
              onTap: onCreateEmptyGroup,
            ),
            _toolbarIconButton(
              icon: Icons.edit_outlined,
              tooltip: 'Editar',
              onTap: selectedId == null ? null : () => onRenameSelected?.call(selectedId!),
            ),
            _toolbarIconButton(
              icon: Icons.arrow_downward_outlined,
              tooltip: 'Mover para baixo',
              onTap: selectedId == null ? null : () => onMoveDown?.call(selectedId!),
            ),
            _toolbarIconButton(
              icon: Icons.arrow_upward_outlined,
              tooltip: 'Mover para cima',
              onTap: selectedId == null ? null : () => onMoveUp?.call(selectedId!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarIconButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
  }) {
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
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ),
    );
  }
}