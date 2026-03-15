import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_state.dart';

class GeoLayersCubit extends Cubit<GeoLayersState> {
  GeoLayersCubit({
    GeoLayersRepository? repository,
  })  : _repository = repository ?? GeoLayersRepository(),
        super(const GeoLayersState());

  final GeoLayersRepository _repository;

  final Map<String, bool> _hasDataCacheByPath = {};
  final Map<String, Future<bool>> _inFlightByPath = {};

  int _groupSequence = 1;
  int _layerSequence = 1;

  Future<void> load() async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
      ),
    );

    try {
      final tree = await _repository.loadTree();

      final syncedActiveIds = _syncActiveIdsWithTree(
        currentActiveIds: state.activeLayerIds,
        tree: tree,
      );

      emit(
        state.copyWith(
          tree: List<GeoLayersData>.unmodifiable(tree),
          activeLayerIds: Set<String>.unmodifiable(syncedActiveIds),
          isLoading: false,
          loaded: true,
          clearError: true,
        ),
      );

      await refreshAllLayerData(tree, force: false);
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> saveTree(List<GeoLayersData> tree) async {
    final syncedActiveIds = _syncActiveIdsWithTree(
      currentActiveIds: state.activeLayerIds,
      tree: tree,
    );

    emit(
      state.copyWith(
        tree: List<GeoLayersData>.unmodifiable(tree),
        activeLayerIds: Set<String>.unmodifiable(syncedActiveIds),
        isSaving: true,
        clearError: true,
      ),
    );

    try {
      await _repository.saveTree(tree);

      emit(
        state.copyWith(
          tree: List<GeoLayersData>.unmodifiable(tree),
          activeLayerIds: Set<String>.unmodifiable(syncedActiveIds),
          isSaving: false,
          loaded: true,
          clearError: true,
        ),
      );

      await refreshAllLayerData(tree, force: false);
    } catch (e) {
      emit(
        state.copyWith(
          tree: List<GeoLayersData>.unmodifiable(tree),
          activeLayerIds: Set<String>.unmodifiable(syncedActiveIds),
          isSaving: false,
          error: e.toString(),
        ),
      );
    }
  }

  void toggleLayer(String id, bool isActive) {
    final next = Set<String>.from(state.activeLayerIds);

    if (isActive) {
      next.add(id);
    } else {
      next.remove(id);
    }

    emit(
      state.copyWith(
        activeLayerIds: Set<String>.unmodifiable(next),
        clearError: true,
      ),
    );
  }

  void removeLayer(String id) {
    final nextActive = Set<String>.from(state.activeLayerIds)..remove(id);
    final nextHasData = Map<String, bool>.from(state.hasDataByLayer)..remove(id);

    emit(
      state.copyWith(
        activeLayerIds: Set<String>.unmodifiable(nextActive),
        hasDataByLayer: Map<String, bool>.unmodifiable(nextHasData),
        clearError: true,
      ),
    );
  }

  void syncWithExistingTreeIds(Set<String> existingIds) {
    final nextActive = Set<String>.from(state.activeLayerIds)
      ..removeWhere((id) => !existingIds.contains(id));

    final nextHasData = Map<String, bool>.from(state.hasDataByLayer)
      ..removeWhere((id, _) => !existingIds.contains(id));

    emit(
      state.copyWith(
        activeLayerIds: Set<String>.unmodifiable(nextActive),
        hasDataByLayer: Map<String, bool>.unmodifiable(nextHasData),
        clearError: true,
      ),
    );
  }

  Future<bool> hasDataForLayer(
      GeoLayersData layer, {
        bool force = false,
      }) async {
    final path = (layer.effectiveCollectionPath ?? '').trim();
    if (path.isEmpty) return false;

    return _resolvePath(path, force: force);
  }

  Future<Map<String, bool>> buildHasDataMap(
      List<GeoLayersData> tree, {
        bool force = false,
      }) async {
    final all = flattenAllNodes(tree: tree);

    final result = <String, bool>{};

    for (final node in all) {
      if (node.isGroup) continue;
      result[node.id] = await hasDataForLayer(node, force: force);
    }

    return Map<String, bool>.unmodifiable(result);
  }

  Future<void> refreshAllLayerData(
      List<GeoLayersData> tree, {
        bool force = false,
      }) async {
    emit(
      state.copyWith(
        isRefreshingLayerData: true,
        clearError: true,
      ),
    );

    try {
      final flattened = flattenAllNodes(tree: tree)
          .where((item) => !item.isGroup)
          .toList(growable: false);

      final next = <String, bool>{};

      final uniquePaths = <String>{};
      for (final layer in flattened) {
        final path = (layer.effectiveCollectionPath ?? '').trim();
        if (path.isNotEmpty) {
          uniquePaths.add(path);
        }
      }

      final resolvedByPath = <String, bool>{};

      await Future.wait(
        uniquePaths.map((path) async {
          resolvedByPath[path] = await _resolvePath(path, force: force);
        }),
      );

      for (final layer in flattened) {
        final path = (layer.effectiveCollectionPath ?? '').trim();
        next[layer.id] = path.isEmpty ? false : (resolvedByPath[path] ?? false);
      }

      emit(
        state.copyWith(
          hasDataByLayer: Map<String, bool>.unmodifiable(next),
          isRefreshingLayerData: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isRefreshingLayerData: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> refreshLayerData(
      GeoLayersData layer, {
        bool force = false,
      }) async {
    final path = (layer.effectiveCollectionPath ?? '').trim();

    if (path.isEmpty) {
      final current = Map<String, bool>.from(state.hasDataByLayer);
      current[layer.id] = false;

      emit(
        state.copyWith(
          hasDataByLayer: Map<String, bool>.unmodifiable(current),
          clearError: true,
        ),
      );
      return;
    }

    try {
      final current = Map<String, bool>.from(state.hasDataByLayer);
      current[layer.id] = await _resolvePath(path, force: force);

      emit(
        state.copyWith(
          hasDataByLayer: Map<String, bool>.unmodifiable(current),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: e.toString(),
        ),
      );
    }
  }

  GeoLayersData? findNodeById(
      String id, {
        List<GeoLayersData>? tree,
      }) {
    return _findNodeById(tree ?? state.tree, id);
  }

  List<GeoLayersData> flattenAllNodes({
    List<GeoLayersData>? tree,
  }) {
    final out = <GeoLayersData>[];

    void walk(List<GeoLayersData> list) {
      for (final item in list) {
        out.add(item);
        if (item.isGroup && item.children.isNotEmpty) {
          walk(item.children);
        }
      }
    }

    walk(tree ?? state.tree);
    return out;
  }

  List<String> flattenOrderedLeafIds({
    List<GeoLayersData>? tree,
  }) {
    final out = <String>[];

    void walk(List<GeoLayersData> list) {
      for (final item in list) {
        if (item.isGroup) {
          walk(item.children);
        } else {
          out.add(item.id);
        }
      }
    }

    walk(tree ?? state.tree);
    return out;
  }

  Future<void> updateNodeById(
      String id,
      GeoLayersData Function(GeoLayersData current) updater,
      ) async {
    final nextTree = _cloneTree(state.tree);
    final updated = _updateNodeById(nextTree, id, updater);
    if (!updated) return;
    await saveTree(nextTree);
  }

  Future<void> createLayer({
    String? parentId,
    int? targetIndex,
  }) async {
    final nextTree = _cloneTree(state.tree);
    final created = _addNewLayer(
      nextTree,
      parentId: parentId,
      targetIndex: targetIndex,
    );
    if (!created) return;
    await saveTree(nextTree);
  }

  Future<void> createEmptyGroup({
    String? parentId,
    int? targetIndex,
  }) async {
    final nextTree = _cloneTree(state.tree);
    final created = _createEmptyGroup(
      nextTree,
      parentId: parentId,
      targetIndex: targetIndex,
    );
    if (!created) return;
    await saveTree(nextTree);
  }

  Future<void> moveLayerUp(String id) async {
    final nextTree = _cloneTree(state.tree);
    final moved = _moveLayerUp(nextTree, id);
    if (!moved) return;
    await saveTree(nextTree);
  }

  Future<void> moveLayerDown(String id) async {
    final nextTree = _cloneTree(state.tree);
    final moved = _moveLayerDown(nextTree, id);
    if (!moved) return;
    await saveTree(nextTree);
  }

  Future<void> dropItem(
      String draggedId,
      String? targetParentId,
      int targetIndex,
      ) async {
    final nextTree = _cloneTree(state.tree);
    final moved = _dropItem(
      nextTree,
      draggedId,
      targetParentId,
      targetIndex,
    );
    if (!moved) return;
    await saveTree(nextTree);
  }

  Future<void> removeNode(String id) async {
    final nextTree = _cloneTree(state.tree);
    final removed = _removeNodeById(nextTree, id);
    if (!removed) return;

    final nextActive = Set<String>.from(state.activeLayerIds)..remove(id);
    final nextHasData = Map<String, bool>.from(state.hasDataByLayer)..remove(id);

    emit(
      state.copyWith(
        activeLayerIds: Set<String>.unmodifiable(nextActive),
        hasDataByLayer: Map<String, bool>.unmodifiable(nextHasData),
        clearError: true,
      ),
    );

    await saveTree(nextTree);
  }

  Future<bool> _resolvePath(String path, {bool force = false}) async {
    if (force) {
      _hasDataCacheByPath.remove(path);
      _inFlightByPath.remove(path);
    }

    final cached = _hasDataCacheByPath[path];
    if (cached != null) {
      return cached;
    }

    final existingInFlight = _inFlightByPath[path];
    if (existingInFlight != null) {
      return existingInFlight;
    }

    final future = _repository.hasData(collectionPath: path).whenComplete(() {
      _inFlightByPath.remove(path);
    });

    _inFlightByPath[path] = future;

    final value = await future;
    _hasDataCacheByPath[path] = value;
    return value;
  }

  Set<String> _syncActiveIdsWithTree({
    required Set<String> currentActiveIds,
    required List<GeoLayersData> tree,
  }) {
    final existingIds = flattenAllNodes(tree: tree)
        .where((e) => !e.isGroup)
        .map((e) => e.id)
        .toSet();

    return currentActiveIds.where(existingIds.contains).toSet();
  }

  List<GeoLayersData> _cloneTree(List<GeoLayersData> source) {
    return source.map((item) {
      return item.copyWith(
        children: _cloneTree(item.children),
      );
    }).toList(growable: true);
  }

  GeoLayersData? _findNodeById(List<GeoLayersData> nodes, String id) {
    for (final item in nodes) {
      if (item.id == id) return item;

      if (item.isGroup && item.children.isNotEmpty) {
        final found = _findNodeById(item.children, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  List<int>? _findPathById(
      List<GeoLayersData> nodes,
      String id, [
        List<int> current = const [],
      ]) {
    for (int i = 0; i < nodes.length; i++) {
      final path = [...current, i];
      final node = nodes[i];

      if (node.id == id) return path;

      if (node.isGroup && node.children.isNotEmpty) {
        final found = _findPathById(node.children, id, path);
        if (found != null) return found;
      }
    }
    return null;
  }

  GeoLayersData? _getNodeByPath(
      List<GeoLayersData> tree,
      List<int> path,
      ) {
    if (path.isEmpty) return null;

    List<GeoLayersData> current = tree;
    GeoLayersData? node;

    for (int i = 0; i < path.length; i++) {
      final index = path[i];
      if (index < 0 || index >= current.length) return null;

      node = current[index];
      if (i < path.length - 1) {
        current = node.children;
      }
    }

    return node;
  }

  List<GeoLayersData> _getListByParentPath(
      List<GeoLayersData> tree,
      List<int> parentPath,
      ) {
    if (parentPath.isEmpty) return tree;
    final node = _getNodeByPath(tree, parentPath);
    return node?.children ?? tree;
  }

  bool _pathStartsWith(List<int> full, List<int> prefix) {
    if (prefix.length > full.length) return false;
    for (int i = 0; i < prefix.length; i++) {
      if (full[i] != prefix[i]) return false;
    }
    return true;
  }

  bool _updateNodeById(
      List<GeoLayersData> nodes,
      String id,
      GeoLayersData Function(GeoLayersData current) updater,
      ) {
    for (int i = 0; i < nodes.length; i++) {
      final item = nodes[i];

      if (item.id == id) {
        nodes[i] = updater(item);
        return true;
      }

      if (item.isGroup && item.children.isNotEmpty) {
        final updated = _updateNodeById(item.children, id, updater);
        if (updated) return true;
      }
    }
    return false;
  }

  bool _removeNodeById(List<GeoLayersData> tree, String id) {
    return _removeNodeRecursive(tree, id);
  }

  bool _removeNodeRecursive(List<GeoLayersData> list, String id) {
    final index = list.indexWhere((e) => e.id == id);
    if (index >= 0) {
      list.removeAt(index);
      return true;
    }

    for (final item in list) {
      if (item.isGroup && item.children.isNotEmpty) {
        final removed = _removeNodeRecursive(item.children, id);
        if (removed) return true;
      }
    }
    return false;
  }

  bool _addNewLayer(
      List<GeoLayersData> tree, {
        String? parentId,
        int? targetIndex,
      }) {
    final id = 'layer_${DateTime.now().microsecondsSinceEpoch}';
    final layer = GeoLayersData.temporaryLayer(
      id: id,
      sequence: _layerSequence++,
    );

    if (parentId == null) {
      final index = targetIndex?.clamp(0, tree.length) ?? tree.length;
      tree.insert(index, layer);
      return true;
    }

    final path = _findPathById(tree, parentId);
    if (path == null) return false;

    final parent = _getNodeByPath(tree, path);
    if (parent == null || !parent.isGroup) return false;

    final list = parent.children;
    final index = targetIndex?.clamp(0, list.length) ?? list.length;
    list.insert(index, layer);
    return true;
  }

  bool _createEmptyGroup(
      List<GeoLayersData> tree, {
        String? parentId,
        int? targetIndex,
      }) {
    final newGroup = GeoLayersData.temporaryGroup(
      id: 'group_${DateTime.now().microsecondsSinceEpoch}',
      sequence: _groupSequence++,
    );

    if (parentId == null) {
      final index = targetIndex?.clamp(0, tree.length) ?? tree.length;
      tree.insert(index, newGroup);
      return true;
    }

    final path = _findPathById(tree, parentId);
    if (path == null) return false;

    final parent = _getNodeByPath(tree, path);
    if (parent == null || !parent.isGroup) return false;

    final list = parent.children;
    final index = targetIndex?.clamp(0, list.length) ?? list.length;
    list.insert(index, newGroup);
    return true;
  }

  bool _moveLayerUp(List<GeoLayersData> tree, String id) {
    final path = _findPathById(tree, id);
    if (path == null || path.isEmpty) return false;

    final parentPath = path.sublist(0, path.length - 1);
    final currentIndex = path.last;
    final list = _getListByParentPath(tree, parentPath);
    final newIndex = currentIndex - 1;

    if (newIndex < 0 || newIndex >= list.length) return false;

    final item = list.removeAt(currentIndex);
    list.insert(newIndex, item);
    return true;
  }

  bool _moveLayerDown(List<GeoLayersData> tree, String id) {
    final path = _findPathById(tree, id);
    if (path == null || path.isEmpty) return false;

    final parentPath = path.sublist(0, path.length - 1);
    final currentIndex = path.last;
    final list = _getListByParentPath(tree, parentPath);
    final newIndex = currentIndex + 1;

    if (newIndex < 0 || newIndex >= list.length) return false;

    final item = list.removeAt(currentIndex);
    list.insert(newIndex, item);
    return true;
  }

  bool _dropItem(
      List<GeoLayersData> tree,
      String draggedId,
      String? targetParentId,
      int targetIndex,
      ) {
    final draggedPath = _findPathById(tree, draggedId);
    if (draggedPath == null || draggedPath.isEmpty) return false;

    final oldParentPath = draggedPath.sublist(0, draggedPath.length - 1);
    final oldParentNode =
    oldParentPath.isEmpty ? null : _getNodeByPath(tree, oldParentPath);
    final oldParentId = oldParentNode?.id;
    final oldIndex = draggedPath.last;

    if (targetParentId == draggedId) return false;

    if (targetParentId != null) {
      final targetParentPathBeforeRemoval = _findPathById(tree, targetParentId);

      if (targetParentPathBeforeRemoval != null &&
          _pathStartsWith(targetParentPathBeforeRemoval, draggedPath)) {
        return false;
      }
    }

    final sourceList = _getListByParentPath(tree, oldParentPath);
    if (oldIndex < 0 || oldIndex >= sourceList.length) return false;

    final draggedNode = sourceList.removeAt(oldIndex);

    List<GeoLayersData> targetList;
    if (targetParentId == null) {
      targetList = tree;
    } else {
      final targetParentPathAfterRemoval = _findPathById(tree, targetParentId);

      if (targetParentPathAfterRemoval == null) {
        sourceList.insert(oldIndex, draggedNode);
        return false;
      }

      final targetParentNode = _getNodeByPath(tree, targetParentPathAfterRemoval);
      if (targetParentNode == null || !targetParentNode.isGroup) {
        sourceList.insert(oldIndex, draggedNode);
        return false;
      }

      targetList = targetParentNode.children;
    }

    var adjustedIndex = targetIndex;
    if (oldParentId == targetParentId && oldIndex < adjustedIndex) {
      adjustedIndex -= 1;
    }

    if (adjustedIndex < 0) adjustedIndex = 0;
    if (adjustedIndex > targetList.length) adjustedIndex = targetList.length;

    targetList.insert(adjustedIndex, draggedNode);
    return true;
  }
}