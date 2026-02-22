// lib/_widgets/map/flutter_map/layers/map_base_tile_layer.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class MapBaseTileLayer extends StatelessWidget {
  final TileProvider tileProvider;
  final String urlTemplate;

  const MapBaseTileLayer({
    super.key,
    required this.tileProvider,
    required this.urlTemplate,
  });

  @override
  Widget build(BuildContext context) {
    if (urlTemplate.isEmpty) return const SizedBox.shrink();

    return TileLayer(
      tileProvider: tileProvider,
      urlTemplate: urlTemplate,
      subdomains: const ['a', 'b', 'c'],
      userAgentPackageName: 'br.gov.al.siged',
      keepBuffer: 2,
      maxNativeZoom: 19,
      minNativeZoom: 0,
    );
  }
}
