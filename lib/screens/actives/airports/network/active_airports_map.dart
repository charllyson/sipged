// lib/screens/actives/oaes/network/pages/active_airports_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/map/clusters/cluster_animated_marker_widget.dart';
import 'package:siged/_widgets/map/map_interactive.dart';
import 'package:siged/_widgets/map/shimmer/map_loading_shimmer.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_state.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_bloc.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_event.dart';

import '../../../../_blocs/actives/oaes/active_oaes_data.dart';
import '../../../../_blocs/actives/oaes/active_oaes_style.dart';

class ActiveAirportsMap extends StatelessWidget {
  const ActiveAirportsMap({super.key, required this.state});

  final ActiveOaesState state;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == ActiveOaesLoadStatus.loading && !state.initialized) {
      return const MapLoadingShimmer();
    }

    // Marcadores já APLICANDO os filtros atuais (região/nota)
    final markers = state.filteredAll
        .map((o) => o.toTaggedMarker())
        .whereType<TaggedChangedMarker<ActiveOaesData>>()
        .toList(growable: false);

    return MapInteractivePage<ActiveOaesData>(
      // --------- CLUSTER / MARCADORES ---------
      taggedMarkers: markers,
      clusterWidgetBuilder: (markers, selected, onSelect) {
        return ClusterAnimatedMarkerLayer<ActiveOaesData>(
          taggedMarkers: markers,
          selectedMarkerPosition: selected,
          onMarkerSelected: onSelect,
          markerBuilder: (context, tagged) {
            final nota  = tagged.data.score?.toDouble() ?? 0;
            final order = tagged.data.order?.toString() ?? '';
            return Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: OaesDataStyle.getColorByNota(nota),
                  width: 4,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                order,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            );
          },
          titleBuilder: (data) => data.identificationName ?? 'Sem nome',
          subTitleBuilder: (data) => data.state ?? 'Não identificado',
        );
      },

      // --------- REGIÕES (GEOJSON) ---------
      polygonsChanged: state.regionalPolygons,                // polígonos do state
      polygonChangeColors: state.regionColors,                        // cores por região
      allowMultiSelect: false,
      selectedRegionNames: state.selectedRegionNamesForMap,    // espelha seleção atual

      // Toque na região → atualiza o filtro no BLoC (toggle)
      onRegionTap: (region) {
        final bloc = context.read<ActiveOaesBloc>();
        final current = state.selectedRegionFilter?.toUpperCase();
        final tapped  = region?.toUpperCase();

        // se tocou na mesma, limpa; senão, aplica a nova
        final newValue = (current != null && tapped != null && current == tapped)
            ? null
            : region;

        bloc.add(ActiveOaesRegionFilterChanged(newValue));
      },
    );
  }
}
