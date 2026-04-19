import 'package:flutter/material.dart';

import 'package:sipged/_widgets/map/map_box/map_mapbox_layer.dart';
import 'package:sipged/_services/map/map_box/mapbox_data.dart';
import 'package:sipged/_widgets/map/markers/marker_changed_data.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_state.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';

class ActiveOaesMapMapbox extends StatelessWidget {
  const ActiveOaesMapMapbox({
    super.key,
    required this.state,
    this.onOpenDetails,
  });

  final ActiveOaesState state;
  final void Function(MarkerChangedData<ActiveOaesData> marker)? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == ActiveOaesLoadStatus.loading &&
        !state.initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final taggedMarkers = state.filteredAll
        .map((o) => o.toTaggedMarker())
        .whereType<MarkerChangedData<ActiveOaesData>>()
        .toList(growable: false);

    if (taggedMarkers.isEmpty) {
      return const Center(
        child: Text('Nenhuma OAE encontrada para os filtros atuais.'),
      );
    }

    final mapboxMarkers = taggedMarkers.map((m) {
      final d = m.data;
      final nota = d.score?.toDouble() ?? 0;
      final Color notaColor = ActiveOaesData.getColorByNota(nota);

      final red = (notaColor.r * 255).round().clamp(0, 255);
      final green = (notaColor.g * 255).round().clamp(0, 255);
      final blue = (notaColor.b * 255).round().clamp(0, 255);

      final colorHex =
          '#${red.toRadixString(16).padLeft(2, '0')}'
          '${green.toRadixString(16).padLeft(2, '0')}'
          '${blue.toRadixString(16).padLeft(2, '0')}';

      return MapboxData(
        lon: m.point.longitude,
        lat: m.point.latitude,
        colorHex: colorHex,
        label: d.identificationName ?? '',
        idExtra: d.id,
      );
    }).toList(growable: false);

    MarkerChangedData<ActiveOaesData>? findMarkerById(String id) {
      for (final m in taggedMarkers) {
        if (m.data.id == id) return m;
      }
      return null;
    }

    return MapBoxChanged(
      markers: mapboxMarkers,
      zoom: 1.7,
      pitch: 0,
      bearing: 0,
      onMarkerTap: (evt) {
        if (onOpenDetails == null) return;

        final idExtra = evt.idExtra;
        if (idExtra == null || idExtra.isEmpty) return;

        final marker = findMarkerById(idExtra);
        if (marker != null) {
          onOpenDetails!(marker);
        }
      },
    );
  }
}