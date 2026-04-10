import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_state.dart';
import 'package:sipged/_widgets/resize/resize_change.dart';
import 'package:sipged/_widgets/resize/resize_handle.dart';
import 'package:sipged/screens/modules/planning/geo/workspace/workspace_widgets.dart';

class WorkspaceItem extends StatelessWidget {
  const WorkspaceItem({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WorkspaceCubit, WorkspaceState, List<String>>(
      selector: (state) => state.itemIds,
      builder: (context, itemIds) {
        return Stack(
          children: itemIds
              .map(
                (itemId) => _WorkspaceItemNode(
              key: ValueKey(itemId),
              itemId: itemId,
            ),
          )
              .toList(growable: false),
        );
      },
    );
  }
}

class _WorkspaceItemNode extends StatelessWidget {
  const _WorkspaceItemNode({
    super.key,
    required this.itemId,
  });

  final String itemId;

  Object _buildVisualContentToken(WorkspaceData item, int dataVersion) {
    return Object.hash(
      item.id,
      item.title,
      item.type,
      dataVersion,

      item.resolvedTitle,
      item.resolvedSubtitle,
      item.resolvedLabel,
      item.resolvedValue,

      Object.hashAll(item.resolvedLabels ?? const <String>[]),
      Object.hashAll(item.resolvedValues ?? const <double>[]),

      item.properties.length,
      Object.hashAll(
        item.properties.map(
              (p) => Object.hash(
            p.key,
            p.type,
            p.textValue,
            p.numberValue,
            p.selectedValue,
            p.bindingValue?.sourceId,
            p.bindingValue?.sourceLabel,
            p.bindingValue?.fieldName,
            p.bindingValue?.aggregation,
            p.bindingValue?.fieldValue,
            Object.hashAll(p.bindingValue?.fieldValues ?? const []),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WorkspaceCubit, WorkspaceState, _WorkspaceItemView?>(
      selector: (state) {
        final item = state.itemByIdOrNull(itemId);
        if (item == null) return null;

        return _WorkspaceItemView(
          item: item,
          selected: state.isSelected(itemId),
          dataVersion: state.dataVersion,
        );
      },
      builder: (context, view) {
        if (view == null) return const SizedBox.shrink();

        final item = view.item;
        final cubit = context.read<WorkspaceCubit>();

        // Importante:
        // muda quando o conteúdo visual muda,
        // mas NÃO muda por offset/size durante o drag.
        final contentKey =
        _buildVisualContentToken(item, view.dataVersion).toString();

        return Positioned(
          left: item.offset.dx,
          top: item.offset.dy,
          width: item.size.width,
          height: item.size.height,
          child: RepaintBoundary(
            child: ResizeChange(
              offset: item.offset,
              size: item.size,
              selected: view.selected,
              contentKey: contentKey,
              allowDiagonalResize: false,
              child: WorkspaceWidgets(
                item: item,
                size: item.size,
              ),
              onSelected: () {
                cubit.selectItem(item.id);
              },
              onMoveLive: (desiredRect) {
                cubit.moveItemLive(
                  itemId: item.id,
                  desiredRect: desiredRect,
                );
              },
              onMoveEnd: (finalRect) {
                cubit.moveItemCommit(
                  itemId: item.id,
                  desiredRect: finalRect,
                );
              },
              onResizeLive: (ResizeHandle handle, Rect desiredRect) {
                cubit.resizeItemLive(
                  itemId: item.id,
                  desiredRect: desiredRect,
                  handle: handle,
                );
              },
              onResizeEnd: (ResizeHandle handle, Rect finalRect) {
                cubit.resizeItemCommit(
                  itemId: item.id,
                  desiredRect: finalRect,
                  handle: handle,
                );
              },
              onRemove: () {
                cubit.removeItem(item.id);
              },
            ),
          ),
        );
      },
    );
  }
}

@immutable
class _WorkspaceItemView {
  final WorkspaceData item;
  final bool selected;
  final int dataVersion;

  const _WorkspaceItemView({
    required this.item,
    required this.selected,
    required this.dataVersion,
  });

  @override
  bool operator ==(Object other) {
    return other is _WorkspaceItemView &&
        other.item == item &&
        other.selected == selected &&
        other.dataVersion == dataVersion;
  }

  @override
  int get hashCode => Object.hash(item, selected, dataVersion);
}