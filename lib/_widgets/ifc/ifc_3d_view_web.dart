import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

// lib/_widgets/ifc/ifc_3d_view_web.dart
class IfcWebViewRegistry {
  static final Map<String, web.HTMLIFrameElement> _iframes = {};
  static final Map<String, List<Object?>> _pendingMessages = {};

  static JSAny _toJsMessage(Object? message) {
    final jsified = message?.jsify();
    return jsified ?? <String, Object?>{}.jsify()!;
  }

  static void registerIframe(String id, web.HTMLIFrameElement iframe) {
    _iframes[id] = iframe;

    final pendings = _pendingMessages.remove(id);
    if (pendings != null) {
      for (final msg in pendings) {
        iframe.contentWindow?.postMessage(_toJsMessage(msg), '*'.toJS);
      }
    }
  }

  static void postMessage(String id, Object message) {
    final frame = _iframes[id];
    if (frame == null) {
      (_pendingMessages[id] ??= <Object?>[]).add(message);
      return;
    }

    frame.contentWindow?.postMessage(_toJsMessage(message), '*'.toJS);
  }
}

class Ifc3DView extends StatelessWidget {
  final String htmlContent;
  final String viewId;

  const Ifc3DView({
    super.key,
    required this.htmlContent,
    required this.viewId,
  });

  static final Set<String> _registered = <String>{};

  @override
  Widget build(BuildContext context) {
    assert(kIsWeb, 'Ifc3DView web só deve ser usado na Web');

    final viewType = viewId;

    if (!_registered.contains(viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
            (int _) {
          final iframe = web.HTMLIFrameElement()
            ..srcdoc = htmlContent.toJS
            ..style.border = 'none'
            ..style.height = '100%'
            ..style.width = '100%';

          IfcWebViewRegistry.registerIframe(viewId, iframe);
          return iframe;
        },
      );
      _registered.add(viewType);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: HtmlElementView(viewType: viewType),
    );
  }
}