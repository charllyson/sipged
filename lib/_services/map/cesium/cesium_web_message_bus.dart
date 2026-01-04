import 'dart:html' as html;

class CesiumMarkerTapEvent {
  final String viewId;
  final String? idExtra;
  final String? label;
  final double lon;
  final double lat;

  CesiumMarkerTapEvent({
    required this.viewId,
    this.idExtra,
    this.label,
    required this.lon,
    required this.lat,
  });
}

class CesiumWebMessageBus {
  static final Map<String, void Function(CesiumMarkerTapEvent)> _listeners = {};
  static bool _initialized = false;

  static void _ensureInit() {
    if (_initialized) return;
    _initialized = true;

    html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is! Map) return;

      if (data["type"] == "markerClick") {
        final handler = _listeners[data["viewId"]];
        if (handler == null) return;

        handler(
          CesiumMarkerTapEvent(
            viewId: data["viewId"],
            idExtra: data["idExtra"],
            label: data["label"],
            lon: (data["lon"] as num).toDouble(),
            lat: (data["lat"] as num).toDouble(),
          ),
        );
      }
    });
  }

  static void register(String id, void Function(CesiumMarkerTapEvent) onTap) {
    _ensureInit();
    _listeners[id] = onTap;
  }

  static void unregister(String id) {
    _listeners.remove(id);
  }
}
