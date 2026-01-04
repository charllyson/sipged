// lib/_services/map/cesium/cesium_controller_web.dart
import 'dart:html' as html;

class Cesium3DController {
  String? _viewId;

  void attach(String id) => _viewId = id;

  bool get attached => _viewId != null;

  void flyTo({
    double? lon,
    double? lat,
    double? height,
    double duration = 1.5,
  }) {
    if (_viewId == null) return;

    html.window.postMessage({
      'type': 'camera',
      'method': 'flyTo',
      'viewId': _viewId,
      'lon': lon,
      'lat': lat,
      'height': height,
      'duration': duration,
    }, '*');
  }
}
