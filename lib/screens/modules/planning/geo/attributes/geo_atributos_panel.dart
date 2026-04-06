import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_map.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/map_state.dart';
import 'package:sipged/screens/modules/planning/geo/attributes/import/attribute_import_feature.dart';
import 'package:sipged/screens/modules/planning/geo/attributes/layer/attribute_panel.dart';

class GeoAtributosPanel extends StatelessWidget {
  const GeoAtributosPanel({
    super.key,
    required this.mapData,
    required this.editorState,
    required this.genericState,
    required this.onOpenLayerTable,
  });

  final LayerDataMap mapData;
  final MapState editorState;
  final GeoFeatureState genericState;
  final Future<void> Function(LayerData layer) onOpenLayerTable;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AttributePanel(
          key: ValueKey(
            'attributes_panel_'
                '${genericState.selected?.feature.selectionKey ?? 'none'}_'
                '${editorState.selectedLayerPanelItemId ?? 'none'}_'
                '${Object.hashAll(genericState.availableFieldsByLayer.entries.map((e) => Object.hash(e.key, Object.hashAll(e.value))))}_'
                '${Object.hashAll(mapData.hasDataByLayer.entries.map((e) => Object.hash(e.key, e.value)))}',
          ),
          genericState: genericState,
          layersById: mapData.layersById,
          selectedLayerId: editorState.selectedLayerPanelItemId,
          availableFieldsByLayer: genericState.availableFieldsByLayer,
          hasDataByLayer: mapData.hasDataByLayer,
          onImportLayer: (layer) async {
            await AttributeImportFeature.openImportDialog(
              context,
              layer: layer,
            );

            if (!context.mounted) return;

            final shouldLoadOnMap = mapData.activeLayerIds.contains(layer.id);

            await AttributeImportFeature.reloadLayerAfterImport(
              context,
              layer: layer,
              shouldLoadOnMap: shouldLoadOnMap,
            );

            if (!context.mounted) return;

            await context.read<LayerCubit>().refreshLayerData(
              layer,
              force: true,
            );

            if (!context.mounted) return;

            await context.read<GeoFeatureCubit>().ensureLayerFieldNames(
              layer,
              force: true,
            );

            await context.read<GeoFeatureCubit>().ensureLayerLoaded(
              layer,
              force: true,
            );
          },
          onOpenTable: onOpenLayerTable,
        ),
      ),
    );
  }
}