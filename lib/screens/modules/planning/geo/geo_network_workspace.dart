part of 'geo_network_view.dart';

extension _GeoNetworkWorkspace on _GeoNetworkViewState {
  Object _workspaceItemToken(WorkspaceData item) {
    return Object.hash(
      item.id,
      item.title,
      item.type,
      item.offset,
      item.size,
      item.properties.length,
      Object.hashAll(
        item.properties.map(
              (p) => Object.hash(
            p.key,
            p.type,
            p.textValue,
            p.numberValue,
            p.selectedValue,
            p.bindingValue?.sourceId,
            p.bindingValue?.fieldName,
            p.bindingValue?.aggregation,
            p.bindingValue?.fieldValue,
            Object.hashAll(p.bindingValue?.fieldValues ?? const []),
          ),
        ),
      ),
    );
  }

  Object _workspaceItemsToken() {
    final scope = _currentWorkspaceScope;
    final items = _workspaceItems;

    if (identical(_lastWorkspaceItemsRef, items) &&
        _lastWorkspaceItemsToken != null) {
      return Object.hash(
        _workspaceScopeKey(scope),
        _lastWorkspaceItemsToken,
      );
    }

    final token = Object.hashAll(items.map(_workspaceItemToken));

    _lastWorkspaceItemsRef = items;
    _lastWorkspaceItemsToken = token;

    return Object.hash(
      _workspaceScopeKey(scope),
      token,
    );
  }


  Object _selectedWorkspaceItemToken() {
    final item = _selectedWorkspaceItem;
    return item?.id ?? 'no_selected_workspace_item';
  }

  void _handleCatalogItemTap(CatalogData item) {
    _workspacePanelKey.currentState?.placeCatalogItemAutomatically(item);

    setState(() {
      _pendingCatalogPlacement = null;
    });

    _showSnack(
      context,
      '"${item.title}" adicionado à área de trabalho',
    );
  }

  void _handleWorkspaceSelectionCatalogChanged(String? catalogItemId) {
    setState(() {
      if (_selectedWorkspaceItem != null) {
        _selectedCatalogItemId = _selectedWorkspaceItem!.catalogItemId;
        return;
      }

      if (_pendingCatalogPlacement != null) {
        _selectedCatalogItemId = _pendingCatalogPlacement!.id;
        return;
      }

      _selectedCatalogItemId = catalogItemId;
    });
  }

  void _handleWorkspaceItemSelected(WorkspaceData? item) {
    final nextWorkspaceId = item?.id;
    final nextCatalogId = item?.catalogItemId;

    if (_selectedWorkspaceItemId == nextWorkspaceId &&
        _selectedCatalogItemId == nextCatalogId &&
        _pendingCatalogPlacement == null) {
      return;
    }

    setState(() {
      _selectedWorkspaceItemId = nextWorkspaceId;
      _selectedCatalogItemId = nextCatalogId;
      _pendingCatalogPlacement = null;
    });
  }

  void _handleWorkspacePropertyChanged(
      String itemId,
      CatalogData property,
      ) {
    _workspacePanelKey.currentState?.updateItemProperty(itemId, property);
  }

  Future<void> _handleWorkspaceBindingDropped(
      String itemId,
      String propertyKey,
      AttributeData data,
      List<LayerData> currentTree,
      ) async {
    await _workspacePanelKey.currentState?.applyBinding(
      itemId,
      propertyKey,
      data,
      currentTree,
    );
  }
}