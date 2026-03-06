import 'package:flutter/material.dart';
import 'package:sipged/screens/modules/planning/geo/layer/layers_geo.dart';

class GeoNetworkTreeController {
  GeoNetworkTreeController({
    required List<LayersGeo> initialTree,
    int initialGroupSequence = 1,
  })  : _layersTree = _cloneLayersTreeStatic(initialTree),
        _groupSequence = initialGroupSequence;

  List<LayersGeo> _layersTree;
  int _groupSequence;

  List<LayersGeo> get layersTree => _layersTree;

  void resetFrom(List<LayersGeo> source) {
    _layersTree = _cloneLayersTreeStatic(source);
    _groupSequence = 1;
  }

  static List<LayersGeo> _cloneLayersTreeStatic(List<LayersGeo> source) {
    return source.map((item) {
      return LayersGeo(
        id: item.id,
        title: item.title,
        icon: item.icon,
        color: item.color,
        defaultVisible: item.defaultVisible,
        isGroup: item.isGroup,
        children: _cloneLayersTreeStatic(item.children),
      );
    }).toList();
  }

  List<int>? findPathById(
      List<LayersGeo> nodes,
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

  LayersGeo? getNodeByPath(List<int> path) {
    if (path.isEmpty) return null;

    List<LayersGeo> current = _layersTree;
    LayersGeo? node;

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

  List<LayersGeo> getListByParentPath(List<int> parentPath) {
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

  bool createGroupFromSelected(String selectedId) {
    final path = findPathById(_layersTree, selectedId);
    if (path == null || path.isEmpty) return false;

    final parentPath = path.sublist(0, path.length - 1);
    final index = path.last;
    final list = getListByParentPath(parentPath);

    if (index < 0 || index >= list.length) return false;

    final selectedNode = list.removeAt(index);

    final newGroup = LayersGeo(
      id: 'custom_group_${DateTime.now().microsecondsSinceEpoch}',
      title: 'NOVO GRUPO ${_groupSequence++}',
      icon: Icons.folder_open_outlined,
      color: const Color(0xFF374151),
      defaultVisible: false,
      isGroup: true,
      children: [selectedNode],
    );

    list.insert(index, newGroup);
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

    List<LayersGeo> targetList;
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
      if (targetParentNode == null) {
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

  List<String> flattenOrderedLeafIds(List<LayersGeo> nodes) {
    final out = <String>[];

    void walk(List<LayersGeo> list) {
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

  LayersGeo? findNodeById(List<LayersGeo> nodes, String id) {
    for (final item in nodes) {
      if (item.id == id) return item;

      if (item.isGroup && item.children.isNotEmpty) {
        final found = findNodeById(item.children, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  bool renameNodeById(List<LayersGeo> nodes, String id, String newTitle) {
    for (int i = 0; i < nodes.length; i++) {
      final item = nodes[i];

      if (item.id == id) {
        nodes[i] = LayersGeo(
          id: item.id,
          title: newTitle,
          icon: item.icon,
          color: item.color,
          defaultVisible: item.defaultVisible,
          isGroup: item.isGroup,
          children: item.children,
        );
        return true;
      }

      if (item.isGroup && item.children.isNotEmpty) {
        final renamed = renameNodeById(item.children, id, newTitle);
        if (renamed) return true;
      }
    }

    return false;
  }
}