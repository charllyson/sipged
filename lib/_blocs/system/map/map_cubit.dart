import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/system/map/map_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/toolbox_cubit.dart';
import 'package:sipged/_blocs/system/panels/docking/dock_panel_data.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit({
    required LayerCubit layersCubit,
    required FeatureCubit featureCubit,
    required ToolboxCubit toolboxCubit,
  })  : _layersCubit = layersCubit,
        _featureCubit = featureCubit,
        _toolboxCubit = toolboxCubit,
        super(MapState.initial());

  static const String workspacePanelGroupId = 'group_area_trabalho';

  final LayerCubit _layersCubit;
  final FeatureCubit _featureCubit;
  final ToolboxCubit _toolboxCubit;

  void _emitIfChanged(MapState next) {
    if (next != state) emit(next);
  }

  Map<String, List<LatLng>> _freezeDrafts(Map<String, List<LatLng>> drafts) {
    return Map<String, List<LatLng>>.unmodifiable({
      for (final entry in drafts.entries)
        entry.key: List<LatLng>.unmodifiable(entry.value),
    });
  }

  Set<String> _freezeSet(Set<String> values) {
    return Set<String>.unmodifiable(values);
  }

  void updatePanels(List<DockPanelData> groups) {
    final immutable = List<DockPanelData>.unmodifiable(groups);
    _emitIfChanged(state.copyWith(panelGroups: immutable));
  }

  void _updatePanelGroupById(
      String groupId,
      DockPanelData Function(DockPanelData current) transform,
      ) {
    final index = state.panelGroups.indexWhere((g) => g.id == groupId);
    if (index < 0) return;

    final current = state.panelGroups[index];
    final updated = transform(current);

    if (updated == current) return;

    final next = List<DockPanelData>.from(state.panelGroups);
    next[index] = updated;

    _emitIfChanged(
      state.copyWith(
        panelGroups: List<DockPanelData>.unmodifiable(next),
      ),
    );
  }

  void setPanelVisibility(String groupId, bool visible) {
    _updatePanelGroupById(
      groupId,
          (group) => group.copyWith(
        visible: visible,
        minimized: !visible,
        collapsed: false,
      ),
    );
  }

  void togglePanelVisibility(String groupId) {
    final index = state.panelGroups.indexWhere((g) => g.id == groupId);
    if (index < 0) return;

    final group = state.panelGroups[index];
    setPanelVisibility(groupId, !group.visible);
  }

  void toggleWorkspacePanelVisibility() {
    togglePanelVisibility(workspacePanelGroupId);
  }

  void selectLayerPanelItem(String id) {
    if (state.selectedLayerPanelItemId == id) return;
    _emitIfChanged(state.copyWith(selectedLayerPanelItemId: id));
  }

  Future<String?> selectTool(String? id) async {
    if ((id == 'tool_measure_distance' || id == 'tool_measure_area') &&
        state.hasAnyVectorEditingInProgress) {
      return 'Conclua ou cancele a edição vetorial atual antes de iniciar uma medição.';
    }

    final tappedSameTool =
        state.selectedToolId != null && state.selectedToolId == id;

    if (tappedSameTool) {
      bool finalized = false;

      if (state.selectedToolId == 'tool_point') {
        finalized = await finalizeCurrentPointEditing();
      } else if (state.selectedToolId == 'tool_line') {
        finalized = await finalizeCurrentLineEditing();
      } else if (state.selectedToolId == 'tool_polygon') {
        finalized = await finalizeCurrentPolygonEditing();
      } else {
        finalized = true;
      }

      if (finalized) {
        if (state.selectedToolId == 'tool_measure_distance') {
          _toolboxCubit.clear();
        }
        _emitIfChanged(state.copyWith(clearSelectedTool: true));
      }
      return null;
    }

    if (state.selectedToolId == 'tool_measure_distance' &&
        id != 'tool_measure_distance') {
      _toolboxCubit.clear();
    }

    if (state.selectedToolId == id) return null;

    _emitIfChanged(state.copyWith(selectedToolId: id));
    return null;
  }

  LayerData? findNodeById(List<LayerData> tree, String? id) {
    if (id == null) return null;
    return _layersCubit.findNodeById(id, tree: tree);
  }

  LayerData? selectedTreeNode(List<LayerData> tree) {
    return findNodeById(tree, state.selectedLayerPanelItemId);
  }

  LayerData? selectedLeafLayer(List<LayerData> tree) {
    final node = selectedTreeNode(tree);
    if (node == null || node.isGroup) return null;
    return node;
  }

  bool selectedItemIsGroup(List<LayerData> tree) {
    final node = selectedTreeNode(tree);
    return node?.isGroup == true;
  }

  LayerGeometryKind? selectedLayerGeometryKind(List<LayerData> tree) {
    final node = selectedTreeNode(tree);
    if (node == null || node.isGroup) return null;
    return node.geometryKind;
  }

  LayerData? getActiveDraftPointLayer(List<LayerData> tree) {
    return findNodeById(tree, state.activeEditingPointLayerId);
  }

  LayerData? getActiveDraftLineLayer(List<LayerData> tree) {
    return findNodeById(tree, state.activeEditingLineLayerId);
  }

  LayerData? getActiveDraftPolygonLayer(List<LayerData> tree) {
    return findNodeById(tree, state.activeEditingPolygonLayerId);
  }

  Future<void> toggleLayer(
      String id,
      bool isActiveFromUI,
      List<LayerData> currentTree,
      ) async {
    final alreadyActive = _layersCubit.state.activeLayerIds.contains(id);
    if (alreadyActive == isActiveFromUI) return;

    _layersCubit.toggleLayer(id, isActiveFromUI);

    final layer = _layersCubit.findNodeById(id, tree: currentTree);
    if (layer == null || layer.isGroup) return;

    final hasPointDraft = state.draftPointLayers.containsKey(layer.id);
    final hasLineDraft = state.draftLineLayers.containsKey(layer.id);
    final hasPolygonDraft = state.draftPolygonLayers.containsKey(layer.id);

    if (isActiveFromUI) {
      if (!hasPointDraft && !hasLineDraft && !hasPolygonDraft) {
        await _featureCubit.ensureLayerLoaded(layer);
      }
    } else {
      _featureCubit.unloadLayer(id);
    }
  }

  Future<void> ensureLayerActiveForEditing(
      LayerData layer,
      List<LayerData> currentTree,
      ) async {
    if (!_layersCubit.state.activeLayerIds.contains(layer.id)) {
      _layersCubit.toggleLayer(layer.id, true);
    }

    if (layer.supportsConnect && !layer.isTemporary) {
      await _featureCubit.ensureLayerLoaded(layer);
    }
  }

  Future<void> persistTree(List<LayerData> tree) async {
    await _layersCubit.saveTree(tree);
  }

  int nextTemporaryLayerSequence(
      List<LayerData> tree,
      LayerGeometryKind kind,
      ) {
    final all = _layersCubit.flattenAllNodes(tree: tree);
    final count = all.where((e) => !e.isGroup && e.geometryKind == kind).length;
    return count + 1;
  }

  String generateTempLayerId(String prefix) {
    final ms = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$ms';
  }

  bool isSelectedLeafMatchingGeometry(
      List<LayerData> currentTree,
      LayerGeometryKind geometryKind,
      ) {
    final selected = selectedLeafLayer(currentTree);
    if (selected == null) return false;
    return selected.geometryKind == geometryKind;
  }

  List<LayerData> insertNewLayerRespectingSelection(
      List<LayerData> tree,
      LayerData newLayer,
      ) {
    final selectedId = state.selectedLayerPanelItemId;
    if (selectedId == null) return [...tree, newLayer];

    final selectedNode = selectedTreeNode(tree);
    if (selectedNode == null) return [...tree, newLayer];

    if (selectedNode.isGroup) {
      final updated = _insertIntoGroup(tree, selectedNode.id, newLayer);
      return updated ?? [...tree, newLayer];
    }

    final updated = _insertAfterSelected(tree, selectedNode.id, newLayer);
    return updated ?? [...tree, newLayer];
  }

  List<LayerData>? _insertIntoGroup(
      List<LayerData> source,
      String groupId,
      LayerData newLayer,
      ) {
    for (int i = 0; i < source.length; i++) {
      final item = source[i];

      if (item.id == groupId && item.isGroup) {
        final next = List<LayerData>.from(source);
        next[i] = item.copyWith(children: [...item.children, newLayer]);
        return next;
      }

      if (item.isGroup && item.children.isNotEmpty) {
        final updatedChildren = _insertIntoGroup(item.children, groupId, newLayer);
        if (updatedChildren != null) {
          final next = List<LayerData>.from(source);
          next[i] = item.copyWith(children: updatedChildren);
          return next;
        }
      }
    }
    return null;
  }

  List<LayerData>? _insertAfterSelected(
      List<LayerData> source,
      String selectedId,
      LayerData newLayer,
      ) {
    for (int i = 0; i < source.length; i++) {
      final item = source[i];

      if (item.id == selectedId && !item.isGroup) {
        final next = List<LayerData>.from(source);
        next.insert(i + 1, newLayer);
        return next;
      }

      if (item.isGroup && item.children.isNotEmpty) {
        final updatedChildren =
        _insertAfterSelected(item.children, selectedId, newLayer);
        if (updatedChildren != null) {
          final next = List<LayerData>.from(source);
          next[i] = item.copyWith(children: updatedChildren);
          return next;
        }
      }
    }

    return null;
  }

  String? _activeEditingLayerIdFor(LayerGeometryKind kind) {
    switch (kind) {
      case LayerGeometryKind.point:
        return state.activeEditingPointLayerId;
      case LayerGeometryKind.line:
        return state.activeEditingLineLayerId;
      case LayerGeometryKind.polygon:
        return state.activeEditingPolygonLayerId;
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return null;
    }
  }

  Map<String, List<LatLng>> _draftsFor(LayerGeometryKind kind) {
    switch (kind) {
      case LayerGeometryKind.point:
        return state.draftPointLayers;
      case LayerGeometryKind.line:
        return state.draftLineLayers;
      case LayerGeometryKind.polygon:
        return state.draftPolygonLayers;
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return const <String, List<LatLng>>{};
    }
  }

  MapState _copyWithDraftsFor(
      LayerGeometryKind kind,
      Map<String, List<LatLng>> drafts,
      ) {
    final frozen = _freezeDrafts(drafts);

    switch (kind) {
      case LayerGeometryKind.point:
        return state.copyWith(draftPointLayers: frozen);
      case LayerGeometryKind.line:
        return state.copyWith(draftLineLayers: frozen);
      case LayerGeometryKind.polygon:
        return state.copyWith(draftPolygonLayers: frozen);
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return state;
    }
  }

  LayerData _createTemporaryLayer(
      LayerGeometryKind kind,
      List<LayerData> currentTree,
      ) {
    switch (kind) {
      case LayerGeometryKind.point:
        return LayerData.temporaryPointLayer(
          id: generateTempLayerId('tmp_point_layer'),
          sequence: nextTemporaryLayerSequence(currentTree, kind),
        );
      case LayerGeometryKind.line:
        return LayerData.temporaryLineLayer(
          id: generateTempLayerId('tmp_line_layer'),
          sequence: nextTemporaryLayerSequence(currentTree, kind),
        );
      case LayerGeometryKind.polygon:
        return LayerData.temporaryPolygonLayer(
          id: generateTempLayerId('tmp_polygon_layer'),
          sequence: nextTemporaryLayerSequence(currentTree, kind),
        );
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        throw UnsupportedError('Geometria não suportada para edição.');
    }
  }

  Future<LayerData> _ensureEditableLayer(
      LayerGeometryKind kind,
      List<LayerData> currentTree,
      ) async {
    final activeId = _activeEditingLayerIdFor(kind);
    if (activeId != null) {
      final existing = _layersCubit.findNodeById(activeId, tree: currentTree);
      if (existing != null && !existing.isGroup) {
        if (state.selectedLayerPanelItemId != existing.id) {
          _emitIfChanged(state.copyWith(selectedLayerPanelItemId: existing.id));
        }
        return existing;
      }
    }

    if (isSelectedLeafMatchingGeometry(currentTree, kind)) {
      final selected = selectedLeafLayer(currentTree)!;

      final nextDrafts = Map<String, List<LatLng>>.from(_draftsFor(kind));
      nextDrafts.putIfAbsent(selected.id, () => <LatLng>[]);

      final nextOwned = Set<String>.from(state.draftOwnedTemporaryLayerIds)
        ..remove(selected.id);

      await ensureLayerActiveForEditing(selected, currentTree);

      var nextState = _copyWithDraftsFor(kind, nextDrafts);
      nextState = nextState.copyWith(
        draftOwnedTemporaryLayerIds: _freezeSet(nextOwned),
        selectedLayerPanelItemId: selected.id,
      );

      switch (kind) {
        case LayerGeometryKind.point:
          nextState = nextState.copyWith(activeEditingPointLayerId: selected.id);
          break;
        case LayerGeometryKind.line:
          nextState = nextState.copyWith(activeEditingLineLayerId: selected.id);
          break;
        case LayerGeometryKind.polygon:
          nextState = nextState.copyWith(activeEditingPolygonLayerId: selected.id);
          break;
        case LayerGeometryKind.mixed:
        case LayerGeometryKind.unknown:
          break;
      }

      _emitIfChanged(nextState);
      return selected;
    }

    final newLayer = _createTemporaryLayer(kind, currentTree);

    final nextTree = insertNewLayerRespectingSelection(currentTree, newLayer);
    await persistTree(nextTree);

    final nextDrafts = Map<String, List<LatLng>>.from(_draftsFor(kind))
      ..[newLayer.id] = <LatLng>[];

    final nextOwned = Set<String>.from(state.draftOwnedTemporaryLayerIds)
      ..add(newLayer.id);

    if (!_layersCubit.state.activeLayerIds.contains(newLayer.id)) {
      _layersCubit.toggleLayer(newLayer.id, true);
    }

    var nextState = _copyWithDraftsFor(kind, nextDrafts);
    nextState = nextState.copyWith(
      draftOwnedTemporaryLayerIds: _freezeSet(nextOwned),
      selectedLayerPanelItemId: newLayer.id,
    );

    switch (kind) {
      case LayerGeometryKind.point:
        nextState = nextState.copyWith(activeEditingPointLayerId: newLayer.id);
        break;
      case LayerGeometryKind.line:
        nextState = nextState.copyWith(activeEditingLineLayerId: newLayer.id);
        break;
      case LayerGeometryKind.polygon:
        nextState = nextState.copyWith(activeEditingPolygonLayerId: newLayer.id);
        break;
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        break;
    }

    _emitIfChanged(nextState);
    return newLayer;
  }

  void _appendDraftVertex(
      LayerGeometryKind kind,
      LayerData layer,
      LatLng latLng,
      ) {
    final nextDrafts = Map<String, List<LatLng>>.from(_draftsFor(kind));
    final list = List<LatLng>.from(nextDrafts[layer.id] ?? const []);
    list.add(latLng);
    nextDrafts[layer.id] = List<LatLng>.unmodifiable(list);

    final nextState = _copyWithDraftsFor(kind, nextDrafts).copyWith(
      selectedLayerPanelItemId: layer.id,
    );

    _emitIfChanged(nextState);
  }

  Future<LayerData> ensureEditablePointLayer(List<LayerData> currentTree) async {
    return _ensureEditableLayer(LayerGeometryKind.point, currentTree);
  }

  Future<LayerData> ensureEditableLineLayer(List<LayerData> currentTree) async {
    return _ensureEditableLayer(LayerGeometryKind.line, currentTree);
  }

  Future<LayerData> ensureEditablePolygonLayer(
      List<LayerData> currentTree,
      ) async {
    return _ensureEditableLayer(LayerGeometryKind.polygon, currentTree);
  }

  Future<String?> handleMapBackgroundTap(
      LatLng latLng,
      List<LayerData> currentTree,
      ) async {
    if (state.isMeasureDistanceToolSelected) {
      _toolboxCubit.addPoint(latLng);
      return null;
    }

    if (state.isMeasureAreaToolSelected) {
      return 'A medição de área será implementada na próxima etapa.';
    }

    if (state.isPointToolSelected) {
      if (state.hasLineDraftInProgress || state.hasPolygonDraftInProgress) {
        return 'Conclua ou cancele a edição atual antes de iniciar pontos.';
      }

      final editableLayer = await _ensureEditableLayer(
        LayerGeometryKind.point,
        currentTree,
      );
      _appendDraftVertex(LayerGeometryKind.point, editableLayer, latLng);
      return null;
    }

    if (state.isLineToolSelected) {
      if (state.hasPointDraftInProgress || state.hasPolygonDraftInProgress) {
        return 'Conclua ou cancele a edição atual antes de iniciar linhas.';
      }

      final editableLayer = await _ensureEditableLayer(
        LayerGeometryKind.line,
        currentTree,
      );
      _appendDraftVertex(LayerGeometryKind.line, editableLayer, latLng);
      return null;
    }

    if (state.isPolygonToolSelected) {
      if (state.hasPointDraftInProgress || state.hasLineDraftInProgress) {
        return 'Conclua ou cancele a edição atual antes de iniciar polígonos.';
      }

      final editableLayer = await _ensureEditableLayer(
        LayerGeometryKind.polygon,
        currentTree,
      );
      _appendDraftVertex(LayerGeometryKind.polygon, editableLayer, latLng);
      return null;
    }

    return null;
  }

  Future<bool> _finalizeCurrentEditing(LayerGeometryKind kind) async {
    final draftId = _activeEditingLayerIdFor(kind);
    if (draftId == null) return true;

    final drafts = _draftsFor(kind);
    final vertices = List<LatLng>.from(drafts[draftId] ?? const []);

    final minimumVertices = switch (kind) {
      LayerGeometryKind.point => 1,
      LayerGeometryKind.line => 2,
      LayerGeometryKind.polygon => 3,
      LayerGeometryKind.mixed || LayerGeometryKind.unknown => 999999,
    };

    if (vertices.length < minimumVertices) return false;

    final currentTree = _layersCubit.state.tree;
    final layer = _layersCubit.findNodeById(draftId, tree: currentTree);
    if (layer == null || layer.isGroup) return false;

    switch (kind) {
      case LayerGeometryKind.point:
        await _featureCubit.addPointFeaturesBatch(
          layer: layer,
          points: vertices,
          commonProperties: {'title': layer.title},
        );
        break;
      case LayerGeometryKind.line:
        await _featureCubit.addLineFeaturesBatch(
          layer: layer,
          lines: [vertices],
          commonProperties: {'title': layer.title},
        );
        break;
      case LayerGeometryKind.polygon:
        await _featureCubit.addPolygonFeaturesBatch(
          layer: layer,
          polygons: [vertices],
          commonProperties: {'title': layer.title},
        );
        break;
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return false;
    }

    if (state.draftOwnedTemporaryLayerIds.contains(layer.id)) {
      await _layersCubit.updateNodeById(
        layer.id,
            (old) => old.copyWith(isTemporary: false, supportsConnect: true),
      );

      await _layersCubit.refreshAllLayerData(
        _layersCubit.state.tree,
        force: true,
      );
    }

    final nextDrafts = Map<String, List<LatLng>>.from(drafts)..remove(draftId);
    final nextOwned = Set<String>.from(state.draftOwnedTemporaryLayerIds)
      ..remove(layer.id);

    MapState nextState;
    switch (kind) {
      case LayerGeometryKind.point:
        nextState = state.copyWith(
          draftPointLayers: _freezeDrafts(nextDrafts),
          draftOwnedTemporaryLayerIds: _freezeSet(nextOwned),
          selectedLayerPanelItemId: layer.id,
          clearActiveEditingPointLayerId: true,
        );
        break;
      case LayerGeometryKind.line:
        nextState = state.copyWith(
          draftLineLayers: _freezeDrafts(nextDrafts),
          draftOwnedTemporaryLayerIds: _freezeSet(nextOwned),
          selectedLayerPanelItemId: layer.id,
          clearActiveEditingLineLayerId: true,
        );
        break;
      case LayerGeometryKind.polygon:
        nextState = state.copyWith(
          draftPolygonLayers: _freezeDrafts(nextDrafts),
          draftOwnedTemporaryLayerIds: _freezeSet(nextOwned),
          selectedLayerPanelItemId: layer.id,
          clearActiveEditingPolygonLayerId: true,
        );
        break;
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return false;
    }

    _emitIfChanged(nextState);
    return true;
  }

  Future<bool> finalizeCurrentPointEditing() async {
    return _finalizeCurrentEditing(LayerGeometryKind.point);
  }

  Future<bool> finalizeCurrentLineEditing() async {
    return _finalizeCurrentEditing(LayerGeometryKind.line);
  }

  Future<bool> finalizeCurrentPolygonEditing() async {
    return _finalizeCurrentEditing(LayerGeometryKind.polygon);
  }

  Future<void> _cancelCurrentEditing(LayerGeometryKind kind) async {
    final draftId = _activeEditingLayerIdFor(kind);
    if (draftId == null) return;

    final wasTemporary = state.draftOwnedTemporaryLayerIds.contains(draftId);

    if (wasTemporary) {
      await _layersCubit.removeNode(draftId);
      _featureCubit.unloadLayer(draftId);
    }

    final nextDrafts = Map<String, List<LatLng>>.from(_draftsFor(kind))
      ..remove(draftId);

    final nextOwned = Set<String>.from(state.draftOwnedTemporaryLayerIds)
      ..remove(draftId);

    MapState nextState;
    switch (kind) {
      case LayerGeometryKind.point:
        nextState = state.copyWith(
          draftPointLayers: _freezeDrafts(nextDrafts),
          draftOwnedTemporaryLayerIds: _freezeSet(nextOwned),
          clearActiveEditingPointLayerId: true,
          clearSelectedLayerPanelItem:
          wasTemporary && state.selectedLayerPanelItemId == draftId,
        );
        break;
      case LayerGeometryKind.line:
        nextState = state.copyWith(
          draftLineLayers: _freezeDrafts(nextDrafts),
          draftOwnedTemporaryLayerIds: _freezeSet(nextOwned),
          clearActiveEditingLineLayerId: true,
          clearSelectedLayerPanelItem:
          wasTemporary && state.selectedLayerPanelItemId == draftId,
        );
        break;
      case LayerGeometryKind.polygon:
        nextState = state.copyWith(
          draftPolygonLayers: _freezeDrafts(nextDrafts),
          draftOwnedTemporaryLayerIds: _freezeSet(nextOwned),
          clearActiveEditingPolygonLayerId: true,
          clearSelectedLayerPanelItem:
          wasTemporary && state.selectedLayerPanelItemId == draftId,
        );
        break;
      case LayerGeometryKind.mixed:
      case LayerGeometryKind.unknown:
        return;
    }

    _emitIfChanged(nextState);
  }

  Future<void> cancelCurrentPointEditing() async {
    await _cancelCurrentEditing(LayerGeometryKind.point);
  }

  Future<void> cancelCurrentLineEditing() async {
    await _cancelCurrentEditing(LayerGeometryKind.line);
  }

  Future<void> cancelCurrentPolygonEditing() async {
    await _cancelCurrentEditing(LayerGeometryKind.polygon);
  }

  Future<void> createLayer(List<LayerData> currentTree) async {
    await _layersCubit.createLayer();
  }

  Future<void> createEmptyGroup(List<LayerData> currentTree) async {
    await _layersCubit.createEmptyGroup();
  }

  Future<void> moveLayerUp(String id, List<LayerData> currentTree) async {
    await _layersCubit.moveLayerUp(id);
  }

  Future<void> moveLayerDown(String id, List<LayerData> currentTree) async {
    await _layersCubit.moveLayerDown(id);
  }

  Future<void> dropItem(
      String draggedId,
      String? targetParentId,
      int targetIndex,
      List<LayerData> currentTree,
      ) async {
    await _layersCubit.dropItem(
      draggedId,
      targetParentId,
      targetIndex,
    );
  }

  Future<void> removeSelectedItem(
      String id,
      List<LayerData> currentTree,
      ) async {
    final node = _layersCubit.findNodeById(id, tree: currentTree);
    if (node == null || node.isSystem) return;

    await _layersCubit.removeNode(id);

    final nextPointDrafts = Map<String, List<LatLng>>.from(state.draftPointLayers)
      ..remove(id);
    final nextLineDrafts = Map<String, List<LatLng>>.from(state.draftLineLayers)
      ..remove(id);
    final nextPolygonDrafts =
    Map<String, List<LatLng>>.from(state.draftPolygonLayers)..remove(id);

    final nextOwned = Set<String>.from(state.draftOwnedTemporaryLayerIds)
      ..remove(id);

    _featureCubit.unloadLayer(id);

    _emitIfChanged(
      state.copyWith(
        draftPointLayers: _freezeDrafts(nextPointDrafts),
        draftLineLayers: _freezeDrafts(nextLineDrafts),
        draftPolygonLayers: _freezeDrafts(nextPolygonDrafts),
        draftOwnedTemporaryLayerIds: _freezeSet(nextOwned),
        clearActiveEditingPointLayerId: state.activeEditingPointLayerId == id,
        clearActiveEditingLineLayerId: state.activeEditingLineLayerId == id,
        clearActiveEditingPolygonLayerId:
        state.activeEditingPolygonLayerId == id,
        clearSelectedLayerPanelItem: state.selectedLayerPanelItemId == id,
      ),
    );
  }

  void syncWithTree(List<LayerData> tree) {
    final allNodes = _layersCubit.flattenAllNodes(tree: tree);

    final allNodeIds = allNodes.map((e) => e.id).toSet();
    final leafIds = allNodes.where((e) => !e.isGroup).map((e) => e.id).toSet();

    final nextPointDrafts = Map<String, List<LatLng>>.from(state.draftPointLayers)
      ..removeWhere((key, _) => !leafIds.contains(key));

    final nextLineDrafts = Map<String, List<LatLng>>.from(state.draftLineLayers)
      ..removeWhere((key, _) => !leafIds.contains(key));

    final nextPolygonDrafts =
    Map<String, List<LatLng>>.from(state.draftPolygonLayers)
      ..removeWhere((key, _) => !leafIds.contains(key));

    final nextOwned = Set<String>.from(state.draftOwnedTemporaryLayerIds)
      ..removeWhere((id) => !leafIds.contains(id));

    final nextState = state.copyWith(
      draftPointLayers: _freezeDrafts(nextPointDrafts),
      draftLineLayers: _freezeDrafts(nextLineDrafts),
      draftPolygonLayers: _freezeDrafts(nextPolygonDrafts),
      draftOwnedTemporaryLayerIds: _freezeSet(nextOwned),
      clearActiveEditingPointLayerId:
      state.activeEditingPointLayerId != null &&
          !leafIds.contains(state.activeEditingPointLayerId),
      clearActiveEditingLineLayerId:
      state.activeEditingLineLayerId != null &&
          !leafIds.contains(state.activeEditingLineLayerId),
      clearActiveEditingPolygonLayerId:
      state.activeEditingPolygonLayerId != null &&
          !leafIds.contains(state.activeEditingPolygonLayerId),
      clearSelectedLayerPanelItem: state.selectedLayerPanelItemId != null &&
          !allNodeIds.contains(state.selectedLayerPanelItemId),
    );

    _emitIfChanged(nextState);
  }

  Map<String, List<LatLng>> buildVisiblePointDrafts(Set<String> activeLayerIds) {
    return state.buildVisibleDrafts(LayerGeometryKind.point, activeLayerIds);
  }

  Map<String, List<LatLng>> buildVisibleLineDrafts(Set<String> activeLayerIds) {
    return state.buildVisibleDrafts(LayerGeometryKind.line, activeLayerIds);
  }

  Map<String, List<LatLng>> buildVisiblePolygonDrafts(
      Set<String> activeLayerIds,
      ) {
    return state.buildVisibleDrafts(LayerGeometryKind.polygon, activeLayerIds);
  }
}