import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Mapbox3DView extends StatefulWidget {
  final String htmlUrl;
  final String viewId; // compat

  const Mapbox3DView({
    super.key,
    required this.htmlUrl,
    required this.viewId,
  });

  @override
  State<Mapbox3DView> createState() => _Mapbox3DViewState();
}

class _Mapbox3DViewState extends State<Mapbox3DView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.htmlUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: WebViewWidget(controller: _controller),
        ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
