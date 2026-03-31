import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_state.dart';
import 'package:sipged/_widgets/resize/resize_change.dart';
import 'package:sipged/_widgets/geo/workspace/geo_workspace_item_view.dart';

class PositionedWorkspaceItem extends StatelessWidget {
  const PositionedWorkspaceItem({
    super.key,
    required this.itemId,
    required this.onItemChanged,
    required this.onItemRemoved,
  });

  final String itemId;
  final void Function(String itemId, Offset newOffset, Size newSize) onItemChanged;
  final void Function(String itemId) onItemRemoved;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GeoWorkspaceCubit, GeoWorkspaceState, GeoWorkspaceItemView?>(
      selector: (state) {
        final item = state.itemByIdOrNull(itemId);
        if (item == null) return null;

        return GeoWorkspaceItemView(
          item: item,
          selected: state.isSelected(itemId),
          dataVersion: state.dataVersion,
        );
      },
      builder: (context, view) {
        if (view == null) return const SizedBox.shrink();

        final item = view.item;

        return Positioned(
          left: item.offset.dx,
          top: item.offset.dy,
          width: item.size.width,
          height: item.size.height,
          child: RepaintBoundary(
            child: ResizeChange(
              item: item,
              dataVersion: view.dataVersion,
              selected: view.selected,
              onSelected: () {
                context.read<GeoWorkspaceCubit>().selectItem(item.id);
              },
              onMoveLive: (desiredRect) {
                context.read<GeoWorkspaceCubit>().moveItemLive(
                  itemId: item.id,
                  desiredRect: desiredRect,
                );
              },
              onMoveEnd: (finalRect) {
                final resolved =
                context.read<GeoWorkspaceCubit>().moveItemCommit(
                  itemId: item.id,
                  desiredRect: finalRect,
                );

                onItemChanged(
                  item.id,
                  resolved.rect.topLeft,
                  resolved.rect.size,
                );
              },
              onResizeLive: (handle, desiredRect) {
                context.read<GeoWorkspaceCubit>().resizeItemLive(
                  itemId: item.id,
                  desiredRect: desiredRect,
                  handle: handle,
                );
              },
              onResizeEnd: (handle, finalRect) {
                final resolved =
                context.read<GeoWorkspaceCubit>().resizeItemCommit(
                  itemId: item.id,
                  desiredRect: finalRect,
                  handle: handle,
                );

                onItemChanged(
                  item.id,
                  resolved.rect.topLeft,
                  resolved.rect.size,
                );
              },
              onRemove: () {
                context.read<GeoWorkspaceCubit>().removeItemLocal(item.id);
                onItemRemoved(item.id);
              },
            ),
          ),
        );
      },
    );
  }
}
