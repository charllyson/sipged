import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/planning/geo/attributes_table/attributes_table_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/productive_units/energy_plants/energy_plants_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/railways/railways_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_estadual/roads_state_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_federal/roads_federal_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/transportes/roads_municipal/roads_municipal_cubit.dart';
import 'package:sipged/_widgets/geo/attributes_table/attributes_table_dialog.dart';
import 'package:sipged/_widgets/geo/layer/layer_registry.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layer_db_status_cubit.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layers_controller.dart';

class GeoNetworkLayerActions {
  const GeoNetworkLayerActions._();

  static Future<void> openImportDialog(
      BuildContext context, {
        required LayerRegistryEntry entry,
      }) async {
    final importCubit = context.read<AttributesTableCubit>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: importCubit,
        child: AttributesTableDialog(
          mode: AttributesTableMode.importFile,
          collectionPath: entry.collectionPath,
          targetFields: entry.targetFields,
          title: entry.importTitle,
          description: entry.description,
        ),
      ),
    );
  }

  static Future<void> openFirestoreTable(
      BuildContext context, {
        required LayerRegistryEntry entry,
      }) async {
    final importCubit = context.read<AttributesTableCubit>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: importCubit,
        child: AttributesTableDialog(
          mode: AttributesTableMode.firestore,
          collectionPath: entry.collectionPath,
          targetFields: const [],
          title: entry.firestoreTitle,
          description:
          'Visualização Firestore: cada documento é uma linha. Você pode filtrar, selecionar e excluir documentos.',
        ),
      ),
    );
  }

  static Future<void> reloadLayerAfterImport(
      BuildContext context, {
        required String layerId,
        required String currentUF,
        required double zoom,
        required LayersController layersController,
        required Set<String> loadedOnce,
      }) async {
    final normalizedId = LayerRegistry.normalizeLayerId(layerId);

    context.read<LayerDbStatusCubit>().refreshAll(uf: currentUF);

    switch (normalizedId) {
      case 'federal_road':
        if (layersController.activeLayerIds.contains(normalizedId)) {
          loadedOnce.add(normalizedId);
          final bucket = RoadsFederalCubit.bucketForZoom(zoom);
          context.read<RoadsFederalCubit>().loadByUF(currentUF, bucket: bucket);
        }
        break;

      case 'state_road':
        if (layersController.activeLayerIds.contains(normalizedId)) {
          loadedOnce.add(normalizedId);
          final bucket = RoadsStateCubit.bucketForZoom(zoom);
          context.read<RoadsStateCubit>().loadByUF(currentUF, bucket: bucket);
        }
        break;

      case 'municipal_road':
        if (layersController.activeLayerIds.contains(normalizedId)) {
          loadedOnce.add(normalizedId);
          final bucket = RoadsMunicipalCubit.bucketForZoom(zoom);
          context
              .read<RoadsMunicipalCubit>()
              .loadByUF(currentUF, bucket: bucket);
        }
        break;

      case 'railways':
        if (layersController.activeLayerIds.contains(normalizedId)) {
          loadedOnce.add(normalizedId);
          final bucket = RailwaysCubit.bucketForZoom(zoom);
          context.read<RailwaysCubit>().loadByUF(
            currentUF,
            zoom: zoom,
            bucket: bucket,
          );
        }
        break;

      case 'units_energy':
        if (layersController.activeLayerIds.contains(normalizedId)) {
          loadedOnce.add(normalizedId);
          context.read<EnergyPlantsCubit>().loadByUF(currentUF);
        }
        break;
    }
  }

  static Future<void> handleConnectLayer(
      BuildContext context, {
        required String rawId,
        required String currentUF,
        required double zoom,
        required LayersController layersController,
        required Set<String> loadedOnce,
      }) async {
    final id = LayerRegistry.normalizeLayerId(rawId);
    final entry = LayerRegistry.entryFor(id);
    if (entry == null) return;

    final hasDbByLayer = context.read<LayerDbStatusCubit>().state.hasDbByLayer;
    final hasDb = hasDbByLayer[id] == true;

    if (hasDb) {
      await openFirestoreTable(context, entry: entry);
      return;
    }

    await openImportDialog(context, entry: entry);
    await reloadLayerAfterImport(
      context,
      layerId: id,
      currentUF: currentUF,
      zoom: zoom,
      layersController: layersController,
      loadedOnce: loadedOnce,
    );
  }
}