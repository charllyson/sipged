part of 'geo_network_view.dart';

extension _GeoNetworkBuilders on _GeoNetworkViewState {
  DockPanelData? _findWorkspaceGroup(MapState state) {
    for (final group in state.panelGroups) {
      if (group.id == _GeoNetworkViewState._workspaceGroupId) return group;
    }
    return null;
  }

  bool _isWorkspaceVisible(MapState state) {
    return _findWorkspaceGroup(state)?.visible ?? false;
  }

  void _showSnack(BuildContext context, String message) {
    final text = message.trim();
    if (text.isEmpty) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: 'Aviso',
        subtitle: text,
        type: NotificationStatus.info,
      ),
    );
  }

  String _buildStatusIdentity({
    required MapState editorState,
    required ToolboxState measurementState,
    required LayerData? activePointLayer,
    required LayerData? activeLineLayer,
    required LayerData? activePolygonLayer,
  }) {
    if (editorState.isMeasureDistanceToolSelected || !measurementState.isEmpty) {
      return 'measure_${measurementState.points.length}'
          '_${measurementState.segmentDistancesMeters.length}'
          '_${measurementState.totalDistanceLabel}';
    }

    if (activePointLayer != null) {
      final count =
          editorState.draftPointLayers[activePointLayer.id]?.length ?? 0;
      return 'point_${activePointLayer.id}_$count';
    }

    if (activeLineLayer != null) {
      final count =
          editorState.draftLineLayers[activeLineLayer.id]?.length ?? 0;
      return 'line_${activeLineLayer.id}_$count';
    }

    if (activePolygonLayer != null) {
      final count =
          editorState.draftPolygonLayers[activePolygonLayer.id]?.length ?? 0;
      return 'polygon_${activePolygonLayer.id}_$count';
    }

    return 'idle';
  }

  Object _featuresByLayerToken(Map<String, List<FeatureData>> featuresByLayer) {
    final keys = featuresByLayer.keys.toList()..sort();

    return Object.hashAll(
      keys.map((layerId) {
        final features = featuresByLayer[layerId] ?? const <FeatureData>[];

        return Object.hash(
          layerId,
          features.length,
          Object.hashAll(
            features.map((f) {
              return Object.hash(
                f.id,
                f.layerId,
                f.originalProperties.length,
                f.editedProperties.length,
                Object.hashAll(
                  f.originalProperties.entries.map(
                        (e) => Object.hash(e.key, e.value),
                  ),
                ),
                Object.hashAll(
                  f.editedProperties.entries.map(
                        (e) => Object.hash(e.key, e.value),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  List<DockPanelData> _composeWorkspaceDockGroups({
    required MapState editorState,
    required FeatureState genericState,
  }) {
    final existing = editorState.panelGroups
        .where((group) => group.id == _GeoNetworkViewState._workspaceGroupId)
        .toList(growable: false);

    final base = existing.isNotEmpty
        ? existing.first
        : const DockPanelData(
      id: _GeoNetworkViewState._workspaceGroupId,
      title: 'Área de trabalho',
      area: DockArea.bottom,
      crossSpan: DockCrossSpan.full,

      // Inicia a área de trabalho fechada.
      visible: false,

      dockExtent: 260,
      dockWeight: 1.0,
      icon: Icons.space_dashboard_outlined,
      shrinkWrapOnMainAxis: false,
      items: [
        DockPanelData(
          id: 'workspace_area_main',
          title: 'Área de trabalho',
          icon: Icons.space_dashboard_outlined,
          contentPadding: EdgeInsets.zero,
          child: SizedBox.shrink(),
        ),
      ],
      activeItemId: 'workspace_area_main',
    );

    final scope = _currentWorkspaceScope;
    final scopeKey = _workspaceScopeKey(scope);
    final featuresToken =
    _featuresByLayerToken(genericState.featuresByLayer).toString();

    final headerInfo = _buildWorkspaceHeaderInfo(
      scope: scope,
      genericState: genericState,
    );

    return [
      base.copyWith(
        title: headerInfo.plainTitle,
        titleBuilder: headerInfo.breadcrumbBuilder,
        shrinkWrapOnMainAxis: false,
        items: [
          DockPanelData(
            id: 'workspace_area_main',
            title: headerInfo.plainTitle,
            icon: Icons.space_dashboard_outlined,
            contentToken: 'workspace_area_main_${scopeKey}_$featuresToken',
            contentPadding: EdgeInsets.zero,
            child: RepaintBoundary(
              child: WorkspacePanel(
                key: _workspacePanelKey,
                scope: scope,
                featuresByLayer: genericState.featuresByLayer,
                pendingCatalogItem: _pendingCatalogPlacement,
                selectedWorkspaceItemId: _selectedWorkspaceItemId,
                onSelectedCatalogItemChanged:
                _handleWorkspaceSelectionCatalogChanged,
                onSelectedWorkspaceItemChanged: _handleWorkspaceItemSelected,
                onPanelSizeChanged: _handleWorkspacePanelSizeChanged,
                onItemsChanged: _handleWorkspaceItemsChangedFromPanel,
                onActiveFilterChanged:
                context.read<MapCubit>().setWorkspaceFilter,
              ),
            ),
          ),
        ],
        activeItemId: 'workspace_area_main',
      ),
    ];
  }

  /// Monta o título (texto simples, usado para detecção de mudança de
  /// layout) e o "builder" de breadcrumb navegável (raiz "/" > camada/grupo
  /// > feição) exibidos no cabeçalho do painel Área de trabalho, de acordo
  /// com o escopo atualmente selecionado.
  _WorkspaceHeaderInfo _buildWorkspaceHeaderInfo({
    required WorkspaceScopeData scope,
    required FeatureState genericState,
  }) {
    if (scope.isGeneral) {
      return const _WorkspaceHeaderInfo(plainTitle: 'Área de trabalho');
    }

    final layersCubit = context.read<LayerCubit>();

    String? layerId;
    String? featureTitle;

    if (scope.isFeature) {
      final selected = genericState.selected;
      layerId = selected?.layerId;
      featureTitle = selected == null
          ? null
          : _resolveDisplaySafeFeatureTitle(selected.feature);
    } else {
      layerId = scope.id;
    }

    final layerNode = (layerId != null && layerId.trim().isNotEmpty)
        ? layersCubit.findNodeById(layerId)
        : null;

    // Nunca cai para o id bruto do documento/camada — se não houver um
    // título amigável, usa um rótulo genérico em vez de expor o id.
    final rawLayerTitle = layerNode?.title.trim();
    final layerTitle = (rawLayerTitle != null && rawLayerTitle.isNotEmpty)
        ? rawLayerTitle
        : 'Camada';

    final resolvedFeatureTitle =
        (featureTitle != null && featureTitle.trim().isNotEmpty)
            ? featureTitle.trim()
            : 'Feição sem título';

    final pathSegments = [
      layerTitle,
      if (scope.isFeature) resolvedFeatureTitle,
    ];

    final plainTitle = 'Área de trabalho / ${pathSegments.join(' / ')}';

    final items = <BreadcrumbItem>[
      BreadcrumbItem(
        label: layerTitle,
        onTap: scope.isFeature
            ? () => context.read<FeatureCubit>().clearSelection()
            : null,
      ),
      if (scope.isFeature) BreadcrumbItem(label: resolvedFeatureTitle),
    ];

    Widget breadcrumbBuilder(BuildContext context, TextStyle style) {
      return PanelBreadcrumb(
        style: style,
        onRootTap: () {
          context.read<FeatureCubit>().clearSelection();
          context.read<MapCubit>().selectLayerPanelItem('');
        },
        items: items,
      );
    }

    return _WorkspaceHeaderInfo(
      plainTitle: plainTitle,
      breadcrumbBuilder: breadcrumbBuilder,
    );
  }

  /// Mesma busca por um campo "amigável" que [FeatureData.title] faz, mas
  /// sem o fallback final para o id bruto do documento — usado apenas para
  /// texto exibido ao usuário (ex.: o breadcrumb do painel Área de
  /// trabalho), onde nunca queremos vazar o id interno do Firestore.
  String? _resolveDisplaySafeFeatureTitle(FeatureData feature) {
    const candidateKeys = [
      'title',
      'titulo',
      'name',
      'nome',
      'label',
      'descricao',
      'description',
      'codigo',
      'processo',
    ];

    for (final key in candidateKeys) {
      final value =
          feature.editedProperties[key] ?? feature.originalProperties[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return null;
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required bool active,
    required VoidCallback onTap,
  }) {
    return CircleButtonChange(
      icon: icon,
      tooltip: tooltip,
      radius: 19,
      outlined: true,
      onPressed: onTap,
      backgroundColor:
      active ? Colors.white : Colors.grey.withValues(alpha: 0.1),
      iconColor: active ? const Color(0xFF3F3F46) : Colors.grey,
      borderColor: active ? Colors.white : Colors.grey,
    );
  }

  List<Widget> _buildAppBarActions(MapState editorState) {
    final workspaceVisible = _isWorkspaceVisible(editorState);

    return [
      _buildActionButton(
        icon: Icons.space_dashboard_outlined,
        tooltip: workspaceVisible
            ? 'Ocultar Área de trabalho'
            : 'Mostrar Área de trabalho',
        active: workspaceVisible,
        onTap: () => _toggleWorkspaceVisibility(context),
      ),
      _buildActionButton(
        icon: Icons.handyman_outlined,
        tooltip: 'Ferramentas',
        active: _isPushPanelOpen(_GeoNetworkViewState._panelFerramentasId),
        onTap: () => _togglePushPanel(_GeoNetworkViewState._panelFerramentasId),
      ),
      _buildActionButton(
        icon: Icons.dashboard_customize_outlined,
        tooltip: 'Catálogo',
        active: _isPushPanelOpen(_GeoNetworkViewState._panelVisualizacoesId),
        onTap: () =>
            _togglePushPanel(_GeoNetworkViewState._panelVisualizacoesId),
      ),
      _buildActionButton(
        icon: Icons.info_outline,
        tooltip: 'Atributos',
        active: _isPushPanelOpen(_GeoNetworkViewState._panelAtributosId),
        onTap: () => _togglePushPanel(_GeoNetworkViewState._panelAtributosId),
      ),
    ];
  }
}

/// Resultado de [_GeoNetworkBuilders._buildWorkspaceHeaderInfo]: o texto
/// simples (usado para detectar mudança de layout do dock) e, quando
/// aplicável, um builder de breadcrumb navegável para o cabeçalho.
class _WorkspaceHeaderInfo {
  final String plainTitle;
  final Widget Function(BuildContext context, TextStyle style)?
  breadcrumbBuilder;

  const _WorkspaceHeaderInfo({
    required this.plainTitle,
    this.breadcrumbBuilder,
  });
}