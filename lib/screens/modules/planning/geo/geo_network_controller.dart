import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';

class GeoNetworkController {
  GeoNetworkController({
    required List<GeoLayersData> initialTree,
    int initialGroupSequence = 1,
    int initialLayerSequence = 1,
  })  : _layersTree = _cloneLayersTreeStatic(initialTree),
        _groupSequence = initialGroupSequence,
        _layerSequence = initialLayerSequence;

  List<GeoLayersData> _layersTree;
  int _groupSequence;
  int _layerSequence;

  List<GeoLayersData> get layersTree => _layersTree;

  void resetFrom(List<GeoLayersData> source) {
    _layersTree = _cloneLayersTreeStatic(source);
    _groupSequence = 1;
    _layerSequence = 1;
  }

  static List<GeoLayersData> _cloneLayersTreeStatic(List<GeoLayersData> source) {
    return source.map((item) {
      return item.copyWith(
        children: _cloneLayersTreeStatic(item.children),
      );
    }).toList(growable: true);
  }

  List<int>? findPathById(
      List<GeoLayersData> nodes,
      String id, [
        List<int> current = const [],
      ]) {
    for (int i = 0; i < nodes.length; i++) {
      final path = [...current, i];
      final node = nodes[i];

      if (node.id == id) return path;

      if (node.isGroup && node.children.isNotEmpty) {
        final found = findPathById(node.children, id, path);
        if (found != null) return found;
      }
    }
    return null;
  }

  GeoLayersData? getNodeByPath(List<int> path) {
    if (path.isEmpty) return null;

    List<GeoLayersData> current = _layersTree;
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

  List<GeoLayersData> getListByParentPath(List<int> parentPath) {
    if (parentPath.isEmpty) return _layersTree;
    final node = getNodeByPath(parentPath);
    return node?.children ?? _layersTree;
  }

  bool pathStartsWith(List<int> full, List<int> prefix) {
    if (prefix.length > full.length) return false;
    for (int i = 0; i < prefix.length; i++) {
      if (full[i] != prefix[i]) return false;
    }
    return true;
  }

  GeoLayersData? findNodeById(List<GeoLayersData> nodes, String id) {
    for (final item in nodes) {
      if (item.id == id) return item;

      if (item.isGroup && item.children.isNotEmpty) {
        final found = findNodeById(item.children, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  bool updateNodeById(
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
        final updated = updateNodeById(item.children, id, updater);
        if (updated) return true;
      }
    }
    return false;
  }

  bool removeNodeById(String id) {
    return _removeNodeRecursive(_layersTree, id);
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

  bool addNewLayer({
    String? parentId,
    int? targetIndex,
  }) {
    final id = 'layer_${DateTime.now().microsecondsSinceEpoch}';
    final layer = GeoLayersData.temporaryLayer(
      id: id,
      sequence: _layerSequence++,
    );

    if (parentId == null) {
      final index = targetIndex?.clamp(0, _layersTree.length) ?? _layersTree.length;
      _layersTree.insert(index, layer);
      return true;
    }

    final path = findPathById(_layersTree, parentId);
    if (path == null) return false;

    final parent = getNodeByPath(path);
    if (parent == null || !parent.isGroup) return false;

    final list = parent.children;
    final index = targetIndex?.clamp(0, list.length) ?? list.length;
    list.insert(index, layer);
    return true;
  }

  bool createGroupFromSelected(String selectedId) {
    final path = findPathById(_layersTree, selectedId);
    if (path == null || path.isEmpty) return false;

    final parentPath = path.sublist(0, path.length - 1);
    final index = path.last;
    final list = getListByParentPath(parentPath);

    if (index < 0 || index >= list.length) return false;

    final selectedNode = list.removeAt(index);

    final newGroup = GeoLayersData.temporaryGroup(
      id: 'group_${DateTime.now().microsecondsSinceEpoch}',
      sequence: _groupSequence++,
      children: [selectedNode],
    );

    list.insert(index, newGroup);
    return true;
  }

  bool createEmptyGroup({
    String? parentId,
    int? targetIndex,
  }) {
    final newGroup = GeoLayersData.temporaryGroup(
      id: 'group_${DateTime.now().microsecondsSinceEpoch}',
      sequence: _groupSequence++,
    );

    if (parentId == null) {
      final index = targetIndex?.clamp(0, _layersTree.length) ?? _layersTree.length;
      _layersTree.insert(index, newGroup);
      return true;
    }

    final path = findPathById(_layersTree, parentId);
    if (path == null) return false;

    final parent = getNodeByPath(path);
    if (parent == null || !parent.isGroup) return false;

    final list = parent.children;
    final index = targetIndex?.clamp(0, list.length) ?? list.length;
    list.insert(index, newGroup);
    return true;
  }

  bool moveLayerUp(String id) {
    final path = findPathById(_layersTree, id);
    if (path == null || path.isEmpty) return false;

    final parentPath = path.sublist(0, path.length - 1);
    final currentIndex = path.last;
    final list = getListByParentPath(parentPath);
    final newIndex = currentIndex - 1;

    if (newIndex < 0 || newIndex >= list.length) return false;

    final item = list.removeAt(currentIndex);
    list.insert(newIndex, item);
    return true;
  }

  bool moveLayerDown(String id) {
    final path = findPathById(_layersTree, id);
    if (path == null || path.isEmpty) return false;

    final parentPath = path.sublist(0, path.length - 1);
    final currentIndex = path.last;
    final list = getListByParentPath(parentPath);
    final newIndex = currentIndex + 1;

    if (newIndex < 0 || newIndex >= list.length) return false;

    final item = list.removeAt(currentIndex);
    list.insert(newIndex, item);
    return true;
  }

  bool dropItem(String draggedId, String? targetParentId, int targetIndex) {
    final draggedPath = findPathById(_layersTree, draggedId);
    if (draggedPath == null || draggedPath.isEmpty) return false;

    final oldParentPath = draggedPath.sublist(0, draggedPath.length - 1);
    final oldParentNode =
    oldParentPath.isEmpty ? null : getNodeByPath(oldParentPath);
    final oldParentId = oldParentNode?.id;
    final oldIndex = draggedPath.last;

    if (targetParentId == draggedId) return false;

    if (targetParentId != null) {
      final targetParentPathBeforeRemoval =
      findPathById(_layersTree, targetParentId);

      if (targetParentPathBeforeRemoval != null &&
          pathStartsWith(targetParentPathBeforeRemoval, draggedPath)) {
        return false;
      }
    }

    final sourceList = getListByParentPath(oldParentPath);
    if (oldIndex < 0 || oldIndex >= sourceList.length) return false;

    final draggedNode = sourceList.removeAt(oldIndex);

    List<GeoLayersData> targetList;
    if (targetParentId == null) {
      targetList = _layersTree;
    } else {
      final targetParentPathAfterRemoval =
      findPathById(_layersTree, targetParentId);

      if (targetParentPathAfterRemoval == null) {
        sourceList.insert(oldIndex, draggedNode);
        return false;
      }

      final targetParentNode = getNodeByPath(targetParentPathAfterRemoval);
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

  List<String> flattenOrderedLeafIds(List<GeoLayersData> nodes) {
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

    walk(nodes);
    return out;
  }

  List<GeoLayersData> flattenAllNodes(List<GeoLayersData> nodes) {
    final out = <GeoLayersData>[];

    void walk(List<GeoLayersData> list) {
      for (final item in list) {
        out.add(item);
        if (item.isGroup && item.children.isNotEmpty) {
          walk(item.children);
        }
      }
    }

    walk(nodes);
    return out;
  }
}