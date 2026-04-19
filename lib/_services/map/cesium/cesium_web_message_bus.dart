import 'dart:js_interop';
import 'package:web/web.dart' as web;

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

    web.window.addEventListener(
      'message',
      ((web.Event event) {
        final msgEvent = event as web.MessageEvent;
        final data = msgEvent.data.dartify();

        if (data is! Map) return;
        if (data['type'] != 'markerClick') return;

        final viewId = (data['viewId'] ?? '').toString();
        final handler = _listeners[viewId];
        if (handler == null) return;

        final lonRaw = data['lon'];
        final latRaw = data['lat'];

        handler(
          CesiumMarkerTapEvent(
            viewId: viewId,
            idExtra: data['idExtra']?.toString(),
            label: data['label']?.toString(),
            lon: lonRaw is num ? lonRaw.toDouble() : 0.0,
            lat: latRaw is num ? latRaw.toDouble() : 0.0,
          ),
        );
      }).toJS,
    );
  }

  static void register(String id, void Function(CesiumMarkerTapEvent) onTap) {
    _ensureInit();
    _listeners[id] = onTap;
  }

  static void unregister(String id) {
    _listeners.remove(id);
  }
}