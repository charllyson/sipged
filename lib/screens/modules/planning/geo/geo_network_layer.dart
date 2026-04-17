part of 'geo_network_view.dart';

extension _GeoNetworkLayer on _GeoNetworkViewState {
  Future<LayerData?> _askEditLayerData({
    required BuildContext context,
    required LayerData current,
  }) async {
    final geoFeatureCubit = context.read<FeatureCubit>();
    final availableFields = await geoFeatureCubit.ensureLayerFieldNames(current);

    if (!context.mounted) return null;

    return LayerPropertiesDialog.show(
      context,
      current: current,
      availableRuleFields: availableFields,
    );
  }

  Future<void> _editSelectedItem(
      String id,
      List<LayerData> currentTree,
      ) async {
    final layersCubit = context.read<LayerCubit>();
    final node = layersCubit.findNodeById(id, tree: currentTree);
    if (node == null) return;

    final edited = await _askEditLayerData(
      context: context,
      current: node,
    );

    if (!mounted || edited == null) return;
    if (edited.title.trim().isEmpty) return;
    if (edited == node) return;

    await layersCubit.updateNodeById(id, (_) => edited);
  }

  Future<void> _openImportDialog(
      BuildContext context, {
        required LayerData layer,
      }) async {
    final featureCubit = context.read<FeatureCubit>();
    final path = layer.effectiveCollectionPath ?? '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: featureCubit,
        child: AttributePage(
          mode: AttributeMode.importFile,
          collectionPath: path,
          targetFields: const [],
          title: 'Importar ${layer.title}',
          description:
          'Importe GeoJSON / KML / KMZ. Após salvar, as feições desta camada serão gravadas no Firebase dentro da coleção principal geo e poderão ser desenhadas dinamicamente no mapa.',
        ),
      ),
    );
  }

  Future<void> _openFirestoreTableDialog(
      BuildContext context, {
        required LayerData layer,
      }) async {
    final featureCubit = context.read<FeatureCubit>();
    final path = layer.effectiveCollectionPath ?? '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: featureCubit,
        child: AttributePage(
          mode: AttributeMode.firestore,
          collectionPath: path,
          sourceLayerId: layer.id,
          targetFields: const [],
          title: 'Tabela de atributos - ${layer.title}',
          description:
          'Visualização dinâmica do Firebase. Cada documento é uma feição geográfica desta camada.',
        ),
      ),
    );
  }

  Future<void> _reloadLayerAfterImport(
      BuildContext context, {
        required LayerData layer,
        required bool shouldLoadOnMap,
      }) async {
    await context.read<LayerCubit>().refreshLayerData(
      layer,
      force: true,
    );

    if (shouldLoadOnMap) {
      await context.read<FeatureCubit>().reloadLayer(layer);
    }
  }

  Future<void> _handleConnectLayer(
      String rawId,
      List<LayerData> currentTree,
      ) async {
    final layersCubit = context.read<LayerCubit>();
    final featureCubit = context.read<FeatureCubit>();

    final layer = layersCubit.findNodeById(rawId, tree: currentTree);

    if (layer == null || layer.isGroup || !layer.supportsConnect) return;

    final path = (layer.effectiveCollectionPath ?? '').trim();
    if (path.isEmpty) return;

    final isAlreadyActive = layersCubit.state.activeLayerIds.contains(layer.id);
    final hasData = layersCubit.state.hasDataByLayer[layer.id] == true;

    if (hasData) {
      await _openFirestoreTableDialog(
        context,
        layer: layer,
      );
      return;
    }

    await _openImportDialog(
      context,
      layer: layer,
    );

    if (!mounted) return;

    await _reloadLayerAfterImport(
      context,
      layer: layer,
      shouldLoadOnMap: isAlreadyActive,
    );

    if (!mounted) return;

    await layersCubit.refreshLayerData(layer, force: true);

    final hasDataNow = layersCubit.state.hasDataByLayer[layer.id] == true;
    if (!hasDataNow) return;

    if (!layersCubit.state.activeLayerIds.contains(layer.id)) {
      layersCubit.toggleLayer(layer.id, true);
    }

    await featureCubit.ensureLayerLoaded(layer, force: true);
    await featureCubit.ensureLayerFieldNames(
      layer,
      force: true,
    );
  }

  Future<void> _openLayerTable(
      BuildContext context,
      String id,
      List<LayerData> currentTree,
      ) async {
    final layersCubit = context.read<LayerCubit>();
    final editorCubit = context.read<MapCubit>();
    final featureCubit = context.read<FeatureCubit>();

    final layer = layersCubit.findNodeById(id, tree: currentTree);
    if (layer == null || layer.isGroup) return;

    editorCubit.selectLayerPanelItem(layer.id);

    if (!layersCubit.state.activeLayerIds.contains(layer.id)) {
      layersCubit.toggleLayer(layer.id, true);
    }

    await featureCubit.ensureLayerLoaded(
      layer,
      force: true,
    );

    await featureCubit.ensureLayerFieldNames(
      layer,
      force: false,
    );

    if (!mounted) return;

    await _openFirestoreTableDialog(
      context,
      layer: layer,
    );
  }
}