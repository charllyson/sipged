// lib/_services/map/map_box/mapbox_3d_view_web.dart
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Registry que encapsula o HtmlElementView + iframe do Mapbox.
class MapboxWebViewRegistry {
  static final Map<String, html.IFrameElement> _iframes =
  <String, html.IFrameElement>{};

  static void registerViewFactory(String viewId, String htmlUrl) {
    if (!kIsWeb) return;
    if (_iframes.containsKey(viewId)) return;

    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
          (int _) {
        final iframe = html.IFrameElement()
          ..src = htmlUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';

        _iframes[viewId] = iframe;
        return iframe;
      },
    );
  }

  static void postMessage(String viewId, Object message) {
    final iframe = _iframes[viewId];
    iframe?.contentWindow?.postMessage(message, '*');
  }
}

/// Widget que rende o HtmlElementView do Mapbox.
class Mapbox3DView extends StatelessWidget {
  final String htmlUrl;
  final String viewId;

  const Mapbox3DView({
    super.key,
    required this.htmlUrl,
    required this.viewId,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Center(
        child: Text('Mapbox 3D disponível apenas na Web.'),
      );
    }

    MapboxWebViewRegistry.registerViewFactory(viewId, htmlUrl);

    return HtmlElementView(viewType: viewId);
  }
}
