import 'package:flutter/material.dart';
import 'package:sipged/_services/map/cesium/cesium_data.dart';
import 'package:sipged/_services/map/cesium/cesium_map_config.dart';
import 'package:sipged/_services/map/cesium/cesium_controller.dart';
import 'package:sipged/_services/map/cesium/cesium_3d_view.dart';
import 'package:sipged/_services/map/cesium/cesium_web_message_bus.dart';
import 'package:sipged/_services/map/cesium/cesium_key_service.dart';

class CesiumBoxChanged extends StatefulWidget {
  const CesiumBoxChanged({
    super.key,
    required this.markers,
    this.centerLat,
    this.centerLon,
    this.heightMeters = 1500,
    this.onMarkerTap,
  });

  final List<CesiumData> markers;
  final double? centerLat;
  final double? centerLon;
  final double heightMeters;
  final void Function(CesiumMarkerTapEvent evt)? onMarkerTap;

  @override
  State<CesiumBoxChanged> createState() => _CesiumBoxChangedState();
}

class _CesiumBoxChangedState extends State<CesiumBoxChanged> {
  late final Cesium3DController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Cesium3DController();
  }

  @override
  Widget build(BuildContext context) {
    final markers = widget.markers;
    if (markers.isEmpty) {
      return const Center(child: Text("Nenhum marcador disponível."));
    }

    final lat = widget.centerLat ??
        markers.map((m) => m.lat).reduce((a, b) => a + b) / markers.length;

    final lon = widget.centerLon ??
        markers.map((m) => m.lon).reduce((a, b) => a + b) / markers.length;

    final config = CesiumMapConfig(
      accessToken: CesiumKeyService.ionToken,
      lon: lon,
      lat: lat,
      height: widget.heightMeters,
      markers: markers,
    );

    return Cesium3DView(
      config: config,
      controller: _controller,
    );
  }
}
