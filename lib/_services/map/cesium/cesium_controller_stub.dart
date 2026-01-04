// lib/_services/map/cesium/cesium_controller_stub.dart

class Cesium3DController {
  String? _viewId;

  void attach(String id) {
    _viewId = id;
  }

  bool get attached => _viewId != null;

  void flyTo({
    double? lon,
    double? lat,
    double? height,
    double duration = 1.5,
  }) {
    // No-op em plataformas sem Web / Cesium
  }
}
