import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_state.dart';
import 'package:sipged/_widgets/geo/workspace/positioned_workspace_item.dart';

class GeoWorkspaceItem extends StatelessWidget {
  const GeoWorkspaceItem({super.key,
    required this.onItemChanged,
    required this.onItemRemoved,
  });

  final void Function(String itemId, Offset newOffset, Size newSize) onItemChanged;
  final void Function(String itemId) onItemRemoved;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GeoWorkspaceCubit, GeoWorkspaceState, List<String>>(
      selector: (state) => state.itemIds,
      builder: (context, itemIds) {
        return Stack(
          children: itemIds
              .map(
                (itemId) => PositionedWorkspaceItem(
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
