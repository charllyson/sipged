import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MapboxWebViewRegistry {
  static final Map<String, web.HTMLIFrameElement> _iframes =
  <String, web.HTMLIFrameElement>{};

  static void registerViewFactory(String viewId, String htmlUrl) {
    if (!kIsWeb) return;
    if (_iframes.containsKey(viewId)) return;

    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
          (int _) {
        final iframe = web.HTMLIFrameElement()
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
    iframe?.contentWindow?.postMessage(
      message.jsify() as JSAny,
      '*'.toJS,
    );
  }
}

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