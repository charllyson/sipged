import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_services/map/cesium/cesium_controller.dart';
import 'package:sipged/_services/map/cesium/cesium_map_config.dart';

class Cesium3DView extends StatelessWidget {
  final CesiumMapConfig config;
  final Cesium3DController controller;
  final String? viewId;

  const Cesium3DView({
    super.key,
    required this.config,
    required this.controller,
    this.viewId,
  });

  static final Set<String> _registered = <String>{};

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Center(
        child: Text('CesiumJS disponível apenas no Flutter Web.'),
      );
    }

    final id = viewId ?? 'cesium-${DateTime.now().microsecondsSinceEpoch}';
    controller.attach(id);

    if (!_registered.contains(id)) {
      ui_web.platformViewRegistry.registerViewFactory(
        id,
            (int _) {
          final iframe = web.HTMLIFrameElement()
            ..src = '/cesium_view.html'
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%';

          iframe.sandbox.add('allow-scripts');
          iframe.sandbox.add('allow-same-origin');
          iframe.sandbox.add('allow-popups');

          iframe.onLoad.listen((_) {
            iframe.contentWindow?.postMessage(
              {
                'type': 'initCesium',
                'accessToken': config.accessToken,
                'lon': config.lon,
                'lat': config.lat,
                'height': config.height,
                'markers': config.markers
                    .map((m) => m.toJson())
                    .toList(growable: false),
              }.jsify() as JSAny,
              '*'.toJS,
            );
          });

          return iframe;
        },
      );
      _registered.add(id);
    }

    return HtmlElementView(viewType: id);
  }
}