// lib/_services/map/map_box/mapbox_3d_web.dart
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';

import 'package:sipged/_services/map/map_box/mapbox_html_builder.dart';
import 'package:sipged/_services/map/map_box/mapbox_3d_view_web.dart' as mapbox_web;
import 'package:sipged/_services/map/map_box/mapbox_data.dart';

/// Message bus estático para receber mensagens do iframe
class MapboxWebMessageBus {
  static final Map<String, void Function(MapboxMarkerTapEvent)> _listeners = {};
  static bool _initialized = false;

  static void _ensureInit() {
    if (_initialized) return;
    _initialized = true;

    html.window.onMessage.listen((event) {
      final data = event.data;
      if (data is! Map) return;

      if (data['type'] == 'markerClick') {
        final viewId = data['viewId'] as String? ?? "";
        final handler = _listeners[viewId];
        if (handler == null) return;

        final lonNum = data['lon'];
        final latNum = data['lat'];

        handler(
          MapboxMarkerTapEvent(
            viewId: viewId,
            idExtra: data['idExtra'] as String?,
            label: data['label'] as String?,
            lon: lonNum is num ? lonNum.toDouble() : 0.0,
            lat: latNum is num ? latNum.toDouble() : 0.0,
          ),
        );
      }
    });
  }

  static void register(
      String viewId,
      void Function(MapboxMarkerTapEvent) handler,
      ) {
    _ensureInit();
    _listeners[viewId] = handler;
  }

  static void unregister(String viewId) {
    _listeners.remove(viewId);
  }
}

/// Controller que o Flutter usa para controlar câmera/estilo do Mapbox.
class Mapbox3DController {
  String? _viewId;

  void attachView(String viewId) {
    _viewId = viewId;
  }

  bool get isAttached => _viewId != null;

  void setCamera({
    double? bearing,
    double? pitch,
    double? zoom,
    int durationMs = 300,
  }) {
    if (_viewId == null) return;

    mapbox_web.MapboxWebViewRegistry.postMessage(_viewId!, {
      'type': 'cameraControl',
      'method': 'setCamera',
      'params': {
        'bearing': bearing,
        'pitch': pitch,
        'zoom': zoom,
        'durationMs': durationMs,
      },
    });
  }

  void cameraDelta({
    double dBearing = 0,
    double dPitch = 0,
    double dZoom = 0,
    int durationMs = 0,
  }) {
    if (_viewId == null) return;

    mapbox_web.MapboxWebViewRegistry.postMessage(_viewId!, {
      'type': 'cameraControl',
      'method': 'deltaCamera',
      'params': {
        'dBearing': dBearing,
        'dPitch': dPitch,
        'dZoom': dZoom,
        'durationMs': durationMs,
      },
    });
  }

  void setStyle(String styleUrl) {
    if (_viewId == null) return;

    mapbox_web.MapboxWebViewRegistry.postMessage(_viewId!, {
      'type': 'cameraControl',
      'method': 'setStyle',
      'params': {
        'styleUrl': styleUrl,
      },
    });
  }
}

class Mapbox3DView extends StatefulWidget {
  final MapboxMapConfig config;
  final Mapbox3DController controller;
  final void Function(MapboxMarkerTapEvent evt)? onMarkerTap;

  const Mapbox3DView({
    super.key,
    required this.config,
    required this.controller,
    this.onMarkerTap,
  });

  @override
  State<Mapbox3DView> createState() => _Mapbox3DViewState();
}

class _Mapbox3DViewState extends State<Mapbox3DView> {
  late final String _viewId;
  late final String _dataUrl;

  @override
  void initState() {
    super.initState();

    _viewId = "mapbox-${DateTime.now().microsecondsSinceEpoch}";

    final htmlStr = buildMapboxHtml(widget.config, viewId: _viewId);
    _dataUrl = "data:text/html;base64,${base64Encode(utf8.encode(htmlStr))}";

    widget.controller.attachView(_viewId);

    MapboxWebMessageBus.register(_viewId, (evt) {
      if (!mounted) return;
      widget.onMarkerTap?.call(evt);
    });
  }

  @override
  void didUpdateWidget(covariant Mapbox3DView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final markersJson =
    widget.config.markers.map((m) => m.toJson()).toList();

    mapbox_web.MapboxWebViewRegistry.postMessage(_viewId, {
      "type": "updateMarkers",
      "markers": markersJson,
    });
  }

  @override
  void dispose() {
    MapboxWebMessageBus.unregister(_viewId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return mapbox_web.Mapbox3DView(
      htmlUrl: _dataUrl,
      viewId: _viewId,
    );
  }
}
