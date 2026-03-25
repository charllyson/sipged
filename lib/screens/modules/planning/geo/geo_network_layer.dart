import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/planning/geo/attributes/geo_attributes_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/attributes/attributes_table.dart';

class GeoNetworkLayer {
  const GeoNetworkLayer._();

  static Future<void> openImportDialog(
      BuildContext context, {
        required GeoLayersData layer,
      }) async {
    final importCubit = context.read<GeoAttributesCubit>();
    final path = layer.effectiveCollectionPath ?? '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: importCubit,
        child: AttributesTable(
          mode: AttributesTableMode.importFile,
          collectionPath: path,
          targetFields: const [],
          title: 'Importar ${layer.title}',
          description:
          'Importe GeoJSON / KML / KMZ. Após salvar, as feições desta camada serão gravadas no Firebase dentro da coleção principal geo e poderão ser desenhadas dinamicamente no mapa.',
        ),
      ),
    );
  }

  static Future<void> openFirestoreTable(
      BuildContext context, {
        required GeoLayersData layer,
      }) async {
    final importCubit = context.read<GeoAttributesCubit>();
    final path = layer.effectiveCollectionPath ?? '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: importCubit,
        child: AttributesTable(
          mode: AttributesTableMode.firestore,
          collectionPath: path,
          targetFields: const [],
          title: 'Tabela de atributos - ${layer.title}',
          description:
          'Visualização dinâmica do Firebase. Cada documento é uma feição geográfica desta camada.',
        ),
      ),
    );
  }

  static Future<void> reloadLayerAfterImport(
      BuildContext context, {
        required GeoLayersData layer,
        required bool shouldLoadOnMap,
      }) async {
    await context.read<GeoLayersCubit>().refreshLayerData(
      layer,
      force: true,
    );

    if (shouldLoadOnMap) {
      await context.read<GeoFeatureCubit>().reloadLayer(layer);
    }
  }

  static Future<void> handleConnectLayer(
      BuildContext context, {
        required GeoLayersData layer,
        required bool shouldLoadOnMap,
      }) async {
    if (layer.isGroup || !layer.supportsConnect) return;

    final path = (layer.effectiveCollectionPath ?? '').trim();
    if (path.isEmpty) return;

    final hasDataByLayer = context.read<GeoLayersCubit>().state.hasDataByLayer;
    final hasData = hasDataByLayer[layer.id] == true;

    if (hasData) {
      await openFirestoreTable(context, layer: layer);
      return;
    }

    await openImportDialog(context, layer: layer);

    await reloadLayerAfterImport(
      context,
      layer: layer,
      shouldLoadOnMap: shouldLoadOnMap,
    );
  }
}