part of 'geo_network_view.dart';

extension _GeoNetworkBuilders on _GeoNetworkViewState {
  DockPanelData? _findWorkspaceGroup(MapState state) {
    for (final group in state.panelGroups) {
      if (group.id == _GeoNetworkViewState._workspaceGroupId) return group;
    }
    return null;
  }

  bool _isWorkspaceVisible(MapState state) {
    return _findWorkspaceGroup(state)?.visible ?? true;
  }

  void _showSnack(BuildContext context, String message) {
    if (message.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
      final count = editorState.draftLineLayers[activeLineLayer.id]?.length ?? 0;
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
      visible: true,
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

    return [
      base.copyWith(
        shrinkWrapOnMainAxis: false,
        items: [
          DockPanelData(
            id: 'workspace_area_main',
            title: scope.isGeneral
                ? 'Área de trabalho - Geral'
                : 'Área de trabalho - ${scope.documentId}',
            icon: Icons.space_dashboard_outlined,

            // Estável para drag/resize, mas reativo à hidratação real dos dados
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
              ),
            ),
          ),
        ],
        activeItemId: 'workspace_area_main',
      ),
    ];
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required bool active,
    required VoidCallback onTap,
  }) {
    return BackCircleButton(
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