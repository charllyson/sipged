// lib/_widgets/ifc/ifc_3d_view_stub.dart
import 'package:flutter/material.dart';

class Ifc3DView extends StatelessWidget {
  final String htmlContent;
  final String viewId;

  const Ifc3DView({
    super.key,
    required this.htmlContent,
    required this.viewId,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('IFC 3D viewer não suportado nesta plataforma.'),
    );
  }
}
