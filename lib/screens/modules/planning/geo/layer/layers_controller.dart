// lib/screens/modules/planning/geo/layers_controller.dart
class LayersController {
  final Set<String> _activeLayerIds;
  String? _activeBaseLayerId;

  LayersController(Set<String> initialIds)
      : _activeLayerIds = {...initialIds} {
    const baseMapIds = {'base_normal', 'base_satellite'};

    for (final id in _activeLayerIds) {
      if (baseMapIds.contains(id)) {
        _activeBaseLayerId = id;
        break;
      }
    }

    _activeBaseLayerId ??= 'base_normal';
    _activeLayerIds.add(_activeBaseLayerId!);
  }

  Set<String> get activeLayerIds => _activeLayerIds;
  String? get activeBaseLayerId => _activeBaseLayerId;

  bool get isSigMineVisible => _activeLayerIds.contains('sigmine');
  bool get isIbgeVisible => _activeLayerIds.contains('ibge_cities');

  void toggleLayer(String id, bool isActive) {
    const baseMapIds = {'base_normal', 'base_satellite'};

    if (baseMapIds.contains(id)) {
      if (isActive) {
        _activeLayerIds.removeAll(baseMapIds);
        _activeLayerIds.add(id);
        _activeBaseLayerId = id;
      } else {
        _activeLayerIds.remove(id);
        _activeBaseLayerId = 'base_normal';
        _activeLayerIds.add(_activeBaseLayerId!);
      }
      return;
    }

    if (isActive) {
      _activeLayerIds.add(id);
    } else {
      _activeLayerIds.remove(id);
    }
  }
}
