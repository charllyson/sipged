import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_map.dart';
import 'package:sipged/_blocs/system/map/map_cubit.dart';
import 'package:sipged/_blocs/system/map/map_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/toolbox_state.dart';
import 'package:sipged/screens/modules/planning/geo/toolbox/toolbox_content.dart';

class GeoFerramentasPanel extends StatelessWidget {
  const GeoFerramentasPanel({
    super.key,
    required this.mapData,
    required this.editorState,
    required this.measurementState,
    required this.onShowMessage,
  });

  final LayerDataMap mapData;
  final MapState editorState;
  final ToolboxState measurementState;
  final ValueChanged<String> onShowMessage;

  @override
  Widget build(BuildContext context) {
    final editorCubit = context.read<MapCubit>();

    return RepaintBoundary(
      child: ToolboxContent(
        key: ValueKey(
          'toolbox_content_'
              '${editorState.selectedLayerPanelItemId ?? 'none'}_'
              '${editorState.selectedToolId ?? 'none'}_'
              '${editorState.activeEditingPointLayerId ?? 'none'}_'
              '${editorState.activeEditingLineLayerId ?? 'none'}_'
              '${editorState.activeEditingPolygonLayerId ?? 'none'}_'
              '${measurementState.points.length}',
        ),
        onToolSelected: onShowMessage,
        selectedToolId: editorState.selectedToolId,
        onSelectedTool: (id) async {
          final error = await editorCubit.selectTool(id);
          if (!context.mounted || error == null) return;
          onShowMessage(error);
        },
        selectedLayerGeometryKind:
        editorCubit.selectedLayerGeometryKind(mapData.currentTree),
        selectedItemIsGroup:
        editorCubit.selectedItemIsGroup(mapData.currentTree),
        pointEditingActive: editorState.activeEditingPointLayerId != null,
        lineEditingActive: editorState.activeEditingLineLayerId != null,
        polygonEditingActive: editorState.activeEditingPolygonLayerId != null,
      ),
    );
  }
}