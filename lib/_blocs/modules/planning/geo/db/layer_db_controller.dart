import 'dart:collection';

class LayerDbController {
  LayerDbController([Set<String>? initialIds])
      : _activeLayerIds = {...?initialIds};

  final Set<String> _activeLayerIds;

  UnmodifiableSetView<String> get activeLayerIds =>
      UnmodifiableSetView(_activeLayerIds);

  bool isActive(String id) => _activeLayerIds.contains(id);

  void toggleLayer(String id, bool isActive) {
    if (isActive) {
      _activeLayerIds.add(id);
    } else {
      _activeLayerIds.remove(id);
    }
  }

  void removeLayer(String id) {
    _activeLayerIds.remove(id);
  }

  void syncWithExistingTreeIds(Set<String> existingIds) {
    _activeLayerIds.removeWhere((id) => !existingIds.contains(id));
  }
}