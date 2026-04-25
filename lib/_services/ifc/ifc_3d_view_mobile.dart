// lib/_widgets/ifc/ifc_3d_view_mobile.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Ifc3DView extends StatefulWidget {
  final String htmlContent;
  final String viewId;

  const Ifc3DView({
    super.key,
    required this.htmlContent,
    required this.viewId,
  });

  @override
  State<Ifc3DView> createState() => _Ifc3DViewState();
}

class _Ifc3DViewState extends State<Ifc3DView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
