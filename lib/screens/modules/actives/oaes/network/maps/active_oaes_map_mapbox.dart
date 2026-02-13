// lib/screens/modules/actives/oaes/active_oaes_map_cesium.dart
import 'package:flutter/material.dart';
import 'package:sipged/_widgets/background/background_cleaner.dart';

import 'package:sipged/_widgets/map/map_box/map_box_changed.dart';
import 'package:sipged/_services/map/map_box/mapbox_data.dart';
import 'package:sipged/_widgets/map/markers/tagged_marker.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_state.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';

class ActiveOaesMapMapbox extends StatelessWidget {
  const ActiveOaesMapMapbox({
    super.key,
    required this.state,
    this.onOpenDetails,
  });

  final ActiveOaesState state;
  final void Function(TaggedChangedMarker<ActiveOaesData> marker)? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == ActiveOaesLoadStatus.loading &&
        !state.initialized) {
      return Stack(
        children: [
          BackgroundClean(),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    final taggedMarkers = state.filteredAll
        .map((o) => o.toTaggedMarker())
        .whereType<TaggedChangedMarker<ActiveOaesData>>()
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
      final colorHex =
          '#${notaColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';

      return MapboxData(
        lon: m.point.longitude,
        lat: m.point.latitude,
        colorHex: colorHex,
        label: d.identificationName ?? '',
        idExtra: d.id,
      );
    }).toList(growable: false);

    TaggedChangedMarker<ActiveOaesData>? findMarkerById(String id) {
      for (final m in taggedMarkers) {
        if (m.data.id == id) return m;
      }
      return null;
    }

    return Stack(
      children: [
        BackgroundClean(),
        MapBoxChanged(
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
        ),
      ],
    );
  }
}
