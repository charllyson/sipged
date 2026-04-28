import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';

class MapLayerTreeHelper {
  const MapLayerTreeHelper._();

  static List<LayerData> insertNewLayerRespectingSelection({
    required List<LayerData> tree,
    required LayerData newLayer,
    required String? selectedId,
    required LayerData? selectedNode,
  }) {
    if (selectedId == null) return [...tree, newLayer];
    if (selectedNode == null) return [...tree, newLayer];

    if (selectedNode.isGroup) {
      final updated = insertIntoGroup(tree, selectedNode.id, newLayer);
      return updated ?? [...tree, newLayer];
    }

    final updated = insertAfterSelected(tree, selectedNode.id, newLayer);
    return updated ?? [...tree, newLayer];
  }

  static List<LayerData>? insertIntoGroup(
      List<LayerData> source,
      String groupId,
      LayerData newLayer,
      ) {
    for (int i = 0; i < source.length; i++) {
      final item = source[i];

      if (item.id == groupId && item.isGroup) {
        final next = List<LayerData>.from(source);
        next[i] = item.copyWith(
          children: [...item.children, newLayer],
        );
        return next;
      }

      if (item.isGroup && item.children.isNotEmpty) {
        final updatedChildren = insertIntoGroup(
          item.children,
          groupId,
          newLayer,
        );

        if (updatedChildren != null) {
          final next = List<LayerData>.from(source);
          next[i] = item.copyWith(children: updatedChildren);
          return next;
        }
      }
    }

    return null;
  }

  static List<LayerData>? insertAfterSelected(
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
        final updatedChildren = insertAfterSelected(
          item.children,
          selectedId,
          newLayer,
        );

        if (updatedChildren != null) {
          final next = List<LayerData>.from(source);
          next[i] = item.copyWith(children: updatedChildren);
          return next;
        }
      }
    }

    return null;
  }
}