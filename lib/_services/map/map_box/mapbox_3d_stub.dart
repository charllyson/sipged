// lib/_services/map/map_box/mapbox_3d_stub.dart
//
// Implementação usada quando NÃO estamos no Web (mobile/desktop).
// Usa webview_flutter para renderizar o HTML do Mapbox.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:siged/_services/map/map_box/mapbox_html_builder.dart';
import 'package:siged/_blocs/map/map_box/mapbox_data.dart';

/// Controller usado pelo Flutter para enviar comandos de câmera/estilo
/// para o WebView (via JavaScript).
class Mapbox3DController {
  WebViewController? _webViewController;

  /// Chamado pelo widget [Mapbox3DView] quando o WebView é criado.
  void attachWebViewController(WebViewController controller) {
    _webViewController = controller;
  }

  bool get isAttached => _webViewController != null;

  void _sendCameraMessage(Map<String, dynamic> msg) {
    final ctrl = _webViewController;
    if (ctrl == null) return;

    final js =
        'window.flutterMapboxCameraControl(${jsonEncode(msg)});';
    ctrl.runJavaScript(js);
  }

  void setCamera({
    double? bearing,
    double? pitch,
    double? zoom,
    int durationMs = 300,
  }) {
    _sendCameraMessage({
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
    _sendCameraMessage({
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
    _sendCameraMessage({
      'type': 'cameraControl',
      'method': 'setStyle',
      'params': {
        'styleUrl': styleUrl,
      },
    });
  }
}

/// View 3D usada no mobile (WebView).
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
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _viewId = 'mapbox-${DateTime.now().microsecondsSinceEpoch}';

    final htmlStr = buildMapboxHtml(widget.config, viewId: _viewId);

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'MapboxChannel',
        onMessageReceived: (msg) {
          if (widget.onMarkerTap == null) return;
          try {
            final data = jsonDecode(msg.message);
            if (data is! Map) return;
            if (data['type'] != 'markerClick') return;

            final lonNum = data['lon'];
            final latNum = data['lat'];

            widget.onMarkerTap!(
              MapboxMarkerTapEvent(
                viewId: _viewId,
                idExtra: data['idExtra'] as String?,
                label: data['label'] as String?,
                lon: lonNum is num ? lonNum.toDouble() : 0.0,
                lat: latNum is num ? latNum.toDouble() : 0.0,
              ),
            );
          } catch (_) {
            // ignora erros silenciosamente
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(
        Uri.dataFromString(
          htmlStr,
          mimeType: 'text/html',
          encoding: utf8,
        ),
      );

    widget.controller.attachWebViewController(_webViewController);
  }

  @override
  void didUpdateWidget(covariant Mapbox3DView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final markersJson =
    widget.config.markers.map((m) => m.toJson()).toList();

    final msg = {
      'type': 'updateMarkers',
      'markers': markersJson,
    };

    final js =
        'window.flutterMapboxUpdateMarkers(${jsonEncode(msg)});';

    _webViewController.runJavaScript(js);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: WebViewWidget(controller: _webViewController),
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
