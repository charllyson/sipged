import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:sipged/_services/files/ifc/ifc_viewer_data.dart';
import 'package:sipged/_services/files/ifc/ifc_viewer_html_builder.dart';
import 'package:sipged/_widgets/ifc/ifc_3d_view.dart';

class ActiveOaesIfcViewerPage extends StatefulWidget {
  final String fileName;
  final Uint8List bytes;
  final String? oaeId;

  const ActiveOaesIfcViewerPage({
    super.key,
    required this.fileName,
    required this.bytes,
    this.oaeId,
  });

  @override
  State<ActiveOaesIfcViewerPage> createState() =>
      _ActiveOaesIfcViewerPageState();
}

class _ActiveOaesIfcViewerPageState extends State<ActiveOaesIfcViewerPage> {
  late final IfcViewerConfig _config;
  late final String _html;

  @override
  void initState() {
    super.initState();

    _config = IfcViewerConfig(
      viewId: 'IFC_OAE_VIEW_${DateTime.now().millisecondsSinceEpoch}',
      backgroundColorHex: '#111111',
    );

    final base64Str = base64Encode(widget.bytes);
    final safeName = widget.fileName.replaceAll("'", "_");

    _html = buildIfcViewerHtml(
      _config,
      initialIfcBase64: base64Str,
      initialFileName: safeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = 'IFC - ${widget.fileName}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Ifc3DView(
        htmlContent: _html,
        viewId: _config.viewId, // hoje o viewId não é usado no JS, mas já fica pronto
      ),
    );
  }
}
