import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/planning/geo/attributes_table/attributes_table_cubit.dart';
import 'package:sipged/_widgets/geo/attributes_table/attributes_table_dialog.dart';
import 'package:sipged/_blocs/modules/planning/geo/db/layer_db_status_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/generic/geo_feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';

class GeoNetworkLayer {
  const GeoNetworkLayer._();

  static Future<void> openImportDialog(
      BuildContext context, {
        required GeoLayersData layer,
      }) async {
    final importCubit = context.read<AttributesTableCubit>();
    final path = layer.effectiveCollectionPath ?? '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: importCubit,
        child: AttributesTableDialog(
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
    final importCubit = context.read<AttributesTableCubit>();
    final path = layer.effectiveCollectionPath ?? '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: importCubit,
        child: AttributesTableDialog(
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
    await context.read<LayerDbStatusCubit>().refreshLayer(layer, force: true);

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

    final hasDbByLayer = context.read<LayerDbStatusCubit>().state.hasDbByLayer;
    final hasDb = hasDbByLayer[layer.id] == true;

    if (hasDb) {
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