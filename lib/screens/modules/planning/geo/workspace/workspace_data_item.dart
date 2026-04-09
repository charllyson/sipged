import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_state.dart';
import 'package:sipged/screens/modules/planning/geo/workspace/workspace_item.dart';

class WorkspaceDataItem extends StatelessWidget {
  const WorkspaceDataItem({
    super.key,
    required this.onItemChanged,
    required this.onItemRemoved,
  });

  final void Function(String itemId, Offset newOffset, Size newSize)
  onItemChanged;
  final void Function(String itemId) onItemRemoved;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WorkspaceCubit, WorkspaceState, List<String>>(
      selector: (state) => state.itemIds,
      builder: (context, itemIds) {
        return Stack(
          children: itemIds
              .map(
                (itemId) => WorkspaceItem(
              key: ValueKey(itemId),
              itemId: itemId,
              onItemChanged: onItemChanged,
              onItemRemoved: onItemRemoved,
            ),
          )
              .toList(growable: false),
        );
      },
    );
  }
}