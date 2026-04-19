// lib/_services/map/cesium/cesium_controller_web.dart
import 'dart:js_interop';
import 'package:web/web.dart' as web;

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
    final viewId = _viewId;
    if (viewId == null) return;

    final message = <String, Object?>{
      'type': 'camera',
      'method': 'flyTo',
      'viewId': viewId,
      'lon': lon,
      'lat': lat,
      'height': height,
      'duration': duration,
    };

    web.window.postMessage(
      message.jsify() as JSAny,
      '*'.toJS,
    );
  }
}