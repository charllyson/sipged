import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/toolbox_state.dart';
import 'package:sipged/_widgets/map/controllers/map_state.dart';
import 'package:sipged/screens/modules/planning/geo/status/status_bar.dart';

class GeoNetworkStatusOverlay extends StatelessWidget {
  const GeoNetworkStatusOverlay({
    super.key,
    required this.visible,
    required this.editorState,
    required this.measurementState,
    required this.activePointLayer,
    required this.activeLineLayer,
    required this.activePolygonLayer,
    required this.onUndoDistanceMeasurementPoint,
    required this.onClearDistanceMeasurement,
    required this.onFinishDistanceMeasurement,
    required this.onFinalizeCurrentPointEditing,
    required this.onCancelCurrentPointEditing,
    required this.onFinalizeCurrentLineEditing,
    required this.onCancelCurrentLineEditing,
    required this.onFinalizeCurrentPolygonEditing,
    required this.onCancelCurrentPolygonEditing,
    required this.onClose,
  });

  final bool visible;

  final MapState editorState;
  final ToolboxState measurementState;

  final LayerData? activePointLayer;
  final LayerData? activeLineLayer;
  final LayerData? activePolygonLayer;

  final VoidCallback onUndoDistanceMeasurementPoint;
  final VoidCallback onClearDistanceMeasurement;
  final VoidCallback onFinishDistanceMeasurement;

  final Future<bool> Function() onFinalizeCurrentPointEditing;
  final Future<void> Function() onCancelCurrentPointEditing;

  final Future<bool> Function() onFinalizeCurrentLineEditing;
  final Future<void> Function() onCancelCurrentLineEditing;

  final Future<bool> Function() onFinalizeCurrentPolygonEditing;
  final Future<void> Function() onCancelCurrentPolygonEditing;

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Positioned(
      top: 10,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: IgnorePointer(
          ignoring: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: StatusBar(
                  editorState: editorState,
                  measurementState: measurementState,
                  activePointLayer: activePointLayer,
                  activeLineLayer: activeLineLayer,
                  activePolygonLayer: activePolygonLayer,
                  onUndoDistanceMeasurementPoint:
                  onUndoDistanceMeasurementPoint,
                  onClearDistanceMeasurement: onClearDistanceMeasurement,
                  onFinishDistanceMeasurement: onFinishDistanceMeasurement,
                  onFinalizeCurrentPointEditing:
                  onFinalizeCurrentPointEditing,
                  onCancelCurrentPointEditing: onCancelCurrentPointEditing,
                  onFinalizeCurrentLineEditing:
                  onFinalizeCurrentLineEditing,
                  onCancelCurrentLineEditing: onCancelCurrentLineEditing,
                  onFinalizeCurrentPolygonEditing:
                  onFinalizeCurrentPolygonEditing,
                  onCancelCurrentPolygonEditing:
                  onCancelCurrentPolygonEditing,
                  onClose: onClose,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}