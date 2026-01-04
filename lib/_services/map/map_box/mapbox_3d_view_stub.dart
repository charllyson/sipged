// lib/_services/map/map_box/mapbox_3d_view_stub.dart
import 'package:flutter/material.dart';

class Mapbox3DView extends StatelessWidget {
  const Mapbox3DView({
    super.key,
    this.initialCenter,
    this.initialZoom,
  });

  final List<double>? initialCenter;
  final double? initialZoom;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Visualização 3D disponível apenas na versão Web.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
