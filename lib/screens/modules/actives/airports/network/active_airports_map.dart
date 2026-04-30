// lib/screens/modules/actives/oaes/network/maps/active_oaes_map_mapbox.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_state.dart';
import 'package:sipged/_services/map/map_box/mapbox_data.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots_grey.dart';
import 'package:sipged/_widgets/map/base/mapbox/map_mapbox_layer.dart';

class ActiveOaesMapMapbox extends StatelessWidget {
  const ActiveOaesMapMapbox({
    super.key,
    required this.state,
    this.onOpenDetails,
  });

  final ActiveOaesState state;

  /// Agora retorna o dado direto, sem MarkerData.
  final void Function(ActiveOaesData data)? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == ActiveOaesLoadStatus.loading &&
        !state.initialized) {
      return const Center(
        child: LoadingTreeDots(size: 110),
      );
    }

    final items = state.filteredAll
        .where((o) => o.latitude != null && o.longitude != null)
        .toList(growable: false);

    if (items.isEmpty) {
      return const Center(
        child: Text('Nenhuma OAE encontrada para os filtros atuais.'),
      );
    }

    final mapboxMarkers = items.map((d) {
      final nota = d.score?.toDouble() ?? 0.0;
      final notaColor = ActiveOaesData.getColorByNota(nota);

      final red = (notaColor.r * 255).round().clamp(0, 255);
      final green = (notaColor.g * 255).round().clamp(0, 255);
      final blue = (notaColor.b * 255).round().clamp(0, 255);

      final colorHex =
          '#${red.toRadixString(16).padLeft(2, '0')}'
          '${green.toRadixString(16).padLeft(2, '0')}'
          '${blue.toRadixString(16).padLeft(2, '0')}';

      return MapboxData(
        lon: d.longitude!,
        lat: d.latitude!,
        colorHex: colorHex,
        label: d.identificationName ?? '',
        idExtra: d.id,
      );
    }).toList(growable: false);

    ActiveOaesData? findDataById(String id) {
      for (final item in items) {
        if (item.id == id) return item;
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

        final data = findDataById(idExtra);
        if (data != null) {
          onOpenDetails!(data);
        }
      },
    );
  }
}