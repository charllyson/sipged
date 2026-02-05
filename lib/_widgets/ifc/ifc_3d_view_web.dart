// lib/_widgets/ifc/ifc_3d_view_web.dart
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Registry para enviar mensagens via postMessage ao iframe
class IfcWebViewRegistry {
  static final Map<String, html.IFrameElement> _iframes = {};
  static final Map<String, List<Object>> _pendingMessages = {};

  /// Registra o iframe com a chave [id] (usaremos SEMPRE o viewId aqui)
  static void registerIframe(String id, html.IFrameElement iframe) {
    _iframes[id] = iframe;

    // Se havia mensagens pendentes para esse ID, envia agora
    final pendings = _pendingMessages.remove(id);
    if (pendings != null) {
      for (final msg in pendings) {
        iframe.contentWindow?.postMessage(msg, '*');
      }
    }
  }

  /// Envia uma mensagem para o iframe identificado por [id] (viewId)
  static void postMessage(String id, Object message) {
    final frame = _iframes[id];
    if (frame == null) {
      // iframe ainda não foi registrado → guarda na fila
      (_pendingMessages[id] ??= <Object>[]).add(message);
      return;
    }

    frame.contentWindow?.postMessage(message, '*');
  }
}

class Ifc3DView extends StatelessWidget {
  final String htmlContent;

  /// ID estável dessa instância (usado tanto como viewType quanto como chave no registry)
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

    // 👉 Usamos o MESMO valor para viewType e para o registry
    final String viewType = viewId;

    if (!_registered.contains(viewType)) {
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        viewType,
            (int _) {
          final iframe = html.IFrameElement()
            ..srcdoc = htmlContent
            ..style.border = 'none'
            ..style.height = '100%'
            ..style.width = '100%';

          // Registramos o iframe usando o viewId (igual ao viewType)
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
