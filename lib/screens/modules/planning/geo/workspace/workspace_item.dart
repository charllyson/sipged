import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_state.dart';
import 'package:sipged/_utils/debug/sipged_perf.dart';
import 'package:sipged/_widgets/resize/resize_change.dart';

class WorkspaceItem extends StatelessWidget {
  const WorkspaceItem({
    super.key,
    required this.itemId,
    required this.onItemChanged,
    required this.onItemRemoved,
  });

  final String itemId;
  final void Function(String itemId, Offset newOffset, Size newSize)
  onItemChanged;
  final void Function(String itemId) onItemRemoved;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WorkspaceCubit, WorkspaceState, _WorkspaceItemState?>(
      selector: (state) {
        final item = state.itemByIdOrNull(itemId);
        if (item == null) return null;

        return _WorkspaceItemState(
          item: item,
          selected: state.isSelected(itemId),
          dataVersion: state.dataVersion,
        );
      },
      builder: (context, view) {
        return SipgedPerf.traceSync(
          'WorkspaceItem.build',
              () {
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
                    context.read<WorkspaceCubit>().selectItem(item.id);
                  },
                  onMoveLive: (desiredRect) {
                    context.read<WorkspaceCubit>().moveItemLive(
                      itemId: item.id,
                      desiredRect: desiredRect,
                    );
                  },
                  onMoveEnd: (finalRect) {
                    final resolved =
                    context.read<WorkspaceCubit>().moveItemCommit(
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
                    context.read<WorkspaceCubit>().resizeItemLive(
                      itemId: item.id,
                      desiredRect: desiredRect,
                      handle: handle,
                    );
                  },
                  onResizeEnd: (handle, finalRect) {
                    final resolved =
                    context.read<WorkspaceCubit>().resizeItemCommit(
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
                    context.read<WorkspaceCubit>().removeItemLocal(item.id);
                    onItemRemoved(item.id);
                  },
                ),
              ),
            );
          },
          warnMs: 8,
          data: {
            'itemId': itemId,
            'hasView': view != null,
            'selected': view?.selected,
            'dataVersion': view?.dataVersion,
          },
        );
      },
    );
  }
}

@immutable
class _WorkspaceItemState {
  final WorkspaceData item;
  final bool selected;
  final int dataVersion;

  const _WorkspaceItemState({
    required this.item,
    required this.selected,
    required this.dataVersion,
  });

  @override
  bool operator ==(Object other) {
    return other is _WorkspaceItemState &&
        other.item == item &&
        other.selected == selected &&
        other.dataVersion == dataVersion;
  }

  @override
  int get hashCode => Object.hash(item, selected, dataVersion);
}