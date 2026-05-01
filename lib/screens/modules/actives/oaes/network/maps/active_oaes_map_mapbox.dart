import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_state.dart';
import 'package:sipged/_services/map/map_box/mapbox_data.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/map/base/mapbox/map_mapbox_layer.dart';

class ActiveOaesMapMapbox extends StatelessWidget {
  const ActiveOaesMapMapbox({
    super.key,
    required this.state,
    this.onOpenDetails,
  });

  final ActiveOaesState state;
  final void Function(ActiveOaesData data)? onOpenDetails;

  String _colorToHex(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == ActiveOaesLoadStatus.loading &&
        !state.initialized) {
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

    final oaes = state.filteredAll
        .where((o) => o.latitude != null && o.longitude != null)
        .toList(growable: false);

    if (oaes.isEmpty) {
      return const Stack(
        children: [
          BackgroundChange(),
          Center(
            child: Text('Nenhuma OAE encontrada para os filtros atuais.'),
          ),
        ],
      );
    }

    final mapboxMarkers = oaes.map((d) {
      final nota = d.score?.toDouble() ?? 0;
      final notaColor = ActiveOaesData.getColorByNota(nota);

      return MapboxData(
        lon: d.longitude!,
        lat: d.latitude!,
        colorHex: _colorToHex(notaColor),
        label: d.identificationName ?? '',
        idExtra: d.id,
      );
    }).toList(growable: false);

    ActiveOaesData? findDataById(String id) {
      for (final d in oaes) {
        if (d.id == id) return d;
      }
      return null;
    }

    return Stack(
      children: [
        const BackgroundChange(),
        MapBoxChanged(
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
        ),
      ],
    );
  }
}