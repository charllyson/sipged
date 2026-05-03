// lib/screens/modules/actives/oaes/network/maps/active_oaes_map_mapbox.dart

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_state.dart';
import 'package:sipged/_services/map/map_box/mapbox_data.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/map/base/mapbox/map_mapbox_layer.dart';

class ActiveOaesMapMapbox extends StatefulWidget {
  const ActiveOaesMapMapbox({
    super.key,
    required this.state,
    this.onOpenDetails,
  });

  final ActiveOaesState state;
  final void Function(ActiveOaesData data)? onOpenDetails;

  @override
  State<ActiveOaesMapMapbox> createState() => _ActiveOaesMapMapboxState();
}

class _ActiveOaesMapMapboxState extends State<ActiveOaesMapMapbox>
    with AutomaticKeepAliveClientMixin {
  static const ValueKey<String> _mapKey = ValueKey<String>(
    'active_oaes_mapbox_fixed_instance',
  );

  String? _lastSignature;
  List<ActiveOaesData> _cachedOaes = const <ActiveOaesData>[];
  List<MapboxData> _cachedMarkers = const <MapboxData>[];
  Widget? _cachedMapWidget;

  @override
  bool get wantKeepAlive => true;

  String _colorToHex(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2)}';
  }

  bool _hasValidCoordinate(ActiveOaesData data) {
    final lat = data.latitude;
    final lon = data.longitude;

    if (lat == null || lon == null) return false;
    if (lat.isNaN || lon.isNaN) return false;
    if (lat.isInfinite || lon.isInfinite) return false;

    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }

  String _coordKey(ActiveOaesData data) {
    return '${data.latitude!.toStringAsFixed(6)},${data.longitude!.toStringAsFixed(6)}';
  }

  String _buildSignature(List<ActiveOaesData> oaes) {
    final buffer = StringBuffer();

    buffer
      ..write('status=')
      ..write(widget.state.loadStatus.name)
      ..write('|initialized=')
      ..write(widget.state.initialized)
      ..write('|pie=')
      ..write(widget.state.selectedPieIndexFilter)
      ..write('|region=')
      ..write(widget.state.selectedRegionFilter)
      ..write('|count=')
      ..write(oaes.length)
      ..write('|');

    for (final d in oaes) {
      buffer
        ..write(d.id ?? '')
        ..write(',')
        ..write(d.latitude?.toStringAsFixed(7) ?? 'null')
        ..write(',')
        ..write(d.longitude?.toStringAsFixed(7) ?? 'null')
        ..write(',')
        ..write(d.score?.toStringAsFixed(2) ?? 'null')
        ..write(';');
    }

    return buffer.toString();
  }

  _ShiftedCoordinate _shiftCoordinateIfOverlapped({
    required double lat,
    required double lon,
    required int index,
  }) {
    if (index <= 0) {
      return _ShiftedCoordinate(lat: lat, lon: lon);
    }

    const baseRadius = 0.00018;

    final ring = ((index - 1) ~/ 8) + 1;
    final position = (index - 1) % 8;

    final angle = position * (math.pi / 4);
    final radius = baseRadius * ring;

    return _ShiftedCoordinate(
      lat: lat + math.sin(angle) * radius,
      lon: lon + math.cos(angle) * radius,
    );
  }

  List<MapboxData> _buildMarkers(List<ActiveOaesData> oaes) {
    final markers = <MapboxData>[];
    final countByCoord = <String, int>{};

    for (final data in oaes) {
      if (!_hasValidCoordinate(data)) continue;

      final key = _coordKey(data);
      final currentIndex = countByCoord[key] ?? 0;
      countByCoord[key] = currentIndex + 1;

      final shifted = _shiftCoordinateIfOverlapped(
        lat: data.latitude!,
        lon: data.longitude!,
        index: currentIndex,
      );

      final nota = data.score?.toDouble() ?? 0;
      final notaColor = ActiveOaesData.getColorByNota(nota);

      markers.add(
        MapboxData(
          lon: shifted.lon,
          lat: shifted.lat,
          colorHex: _colorToHex(notaColor),
          label: data.identificationName ?? data.id ?? '',
          idExtra: data.id,
        ),
      );
    }

    if (kDebugMode) {
      final invalidCount = oaes.length - markers.length;
      final uniqueCoords = countByCoord.length;
      final overlappedCoords = countByCoord.values.where((v) => v > 1).length;

      debugPrint('========== ActiveOaesMapMapbox ==========');
      debugPrint('OAEs filtradas: ${oaes.length}');
      debugPrint('No mapa: ${markers.length}');
      debugPrint('Sem coordenada válida: $invalidCount');
      debugPrint('Coordenadas únicas: $uniqueCoords');
      debugPrint('Coordenadas sobrepostas: $overlappedCoords');
      debugPrint('=========================================');
    }

    return markers;
  }

  ActiveOaesData? _findDataById(List<ActiveOaesData> list, String id) {
    for (final item in list) {
      if (item.id == id) return item;
    }

    return null;
  }

  Widget _buildStableMapWidget({
    required List<ActiveOaesData> oaes,
    required List<MapboxData> markers,
  }) {
    return MapBoxChanged(
      key: _mapKey,
      markers: markers,

      // Evite null aqui se seu MapBoxChanged ainda usa double não-null.
      // Se você já alterou MapBoxChanged para aceitar zoom nullable/autofit,
      // pode voltar para zoom: null.
      zoom: 5.2,

      pitch: 0,
      bearing: 0,
      onMarkerTap: (evt) {
        final callback = widget.onOpenDetails;
        if (callback == null) return;

        final idExtra = evt.idExtra;
        if (idExtra == null || idExtra.isEmpty) return;

        final data = _findDataById(_cachedOaes, idExtra);

        if (data != null) {
          callback(data);
        }
      },
    );
  }

  void _refreshCacheIfNeeded() {
    final oaes = widget.state.filteredAll.toList(growable: false);
    final signature = _buildSignature(oaes);

    if (_lastSignature == signature && _cachedMapWidget != null) {
      return;
    }

    final markers = _buildMarkers(oaes);

    _lastSignature = signature;
    _cachedOaes = oaes;
    _cachedMarkers = markers;

    if (markers.isEmpty) {
      _cachedMapWidget = null;
      return;
    }

    _cachedMapWidget = _buildStableMapWidget(
      oaes: oaes,
      markers: markers,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.state.loadStatus == ActiveOaesLoadStatus.loading &&
        !widget.state.initialized) {
      return const Stack(
        children: [
          BackgroundChange(),
          Center(
            child: LoadingTreeDots(
              size: 32,
              strokeWidth: 3,
            ),
          ),
        ],
      );
    }

    _refreshCacheIfNeeded();

    if (_cachedMarkers.isEmpty || _cachedMapWidget == null) {
      return const Stack(
        children: [
          BackgroundChange(),
          Center(
            child: Text(
              'Nenhuma OAE com coordenada válida para os filtros atuais.',
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        const BackgroundChange(),

        // Importante:
        // este widget fica cacheado e só é recriado quando os dados do mapa mudam.
        _cachedMapWidget!,

      ],
    );
  }
}

class _ShiftedCoordinate {
  const _ShiftedCoordinate({
    required this.lat,
    required this.lon,
  });

  final double lat;
  final double lon;
}