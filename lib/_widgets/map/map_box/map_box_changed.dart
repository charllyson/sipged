// lib/_widgets/map/map_box/map_box_changed.dart
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import 'package:siged/_services/map/map_box/mapbox_3d.dart';
import 'package:siged/_widgets/map/map_box/mapbox_3d_panel.dart';
import 'package:siged/_services/map/map_box/mapbox_data.dart';
import 'package:siged/_services/map/map_box/mapbox_key_service.dart';

class MapBoxChanged extends StatefulWidget {
  const MapBoxChanged({
    super.key,
    required this.markers,
    this.centerLat,
    this.centerLon,
    this.zoom = 2,
    this.pitch = 0,
    this.bearing = 0,
    this.onMarkerTap,
  });

  final List<MapboxData> markers;
  final double? centerLat;
  final double? centerLon;
  final double zoom;
  final double pitch;
  final double bearing;
  final void Function(MapboxMarkerTapEvent evt)? onMarkerTap;

  @override
  State<MapBoxChanged> createState() => _MapBoxChangedState();
}

class _MapBoxChangedState extends State<MapBoxChanged> {
  late final Mapbox3DController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Mapbox3DController();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.markers.isEmpty) {
      return const Center(
        child: Text('Nenhum marcador disponível.'),
      );
    }

    final lat = widget.centerLat ??
        widget.markers.map((m) => m.lat).reduce((a, b) => a + b) /
            widget.markers.length;

    final lon = widget.centerLon ??
        widget.markers.map((m) => m.lon).reduce((a, b) => a + b) /
            widget.markers.length;

    final config = MapboxMapConfig(
      accessToken: MapboxKeyService.accessToken,
      centerLon: lon,
      centerLat: lat,
      zoom: widget.zoom,
      pitch: widget.pitch,
      bearing: widget.bearing,
      markers: widget.markers,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: Mapbox3DView(
            config: config,
            controller: _controller,
            onMarkerTap: widget.onMarkerTap,
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: PointerInterceptor(
            child: Mapbox3DPanel(
              controller: _controller,
              styles: config.alternateStyles.isNotEmpty
                  ? config.alternateStyles
                  : const [
                MapboxStyleOption(
                  id: 'streets',
                  name: 'Ruas',
                  styleUrl: 'mapbox://styles/mapbox/streets-v12',
                ),
                MapboxStyleOption(
                  id: 'outdoors',
                  name: 'Outdoor',
                  styleUrl: 'mapbox://styles/mapbox/outdoors-v12',
                ),
                MapboxStyleOption(
                  id: 'satellite',
                  name: 'Satélite',
                  styleUrl:
                  'mapbox://styles/mapbox/satellite-streets-v12',
                ),
              ],
              initialStyleIndex: config.initialStyleIndex,
            ),
          ),
        ),
      ],
    );
  }
}
