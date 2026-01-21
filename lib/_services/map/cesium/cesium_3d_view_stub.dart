// lib/_services/map/cesium/cesium_3d_view_stub.dart
import 'package:flutter/material.dart';
import 'package:siged/_services/map/cesium/cesium_map_config.dart';
import 'package:siged/_services/map/cesium/cesium_controller.dart';

class Cesium3DView extends StatelessWidget {
  final CesiumMapConfig config;
  final Cesium3DController controller;

  const Cesium3DView({
    super.key,
    required this.config,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('CesiumJS disponível apenas no Flutter Web.'),
    );
  }
}
