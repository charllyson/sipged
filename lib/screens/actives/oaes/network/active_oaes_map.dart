import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/map/markers/animated_cluster_marker_widget.dart';
import 'package:siged/_widgets/map/map_interactive.dart';
import 'package:siged/_widgets/map/shimmer/map_loading_shimmer.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_state.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_bloc.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_event.dart';

import '../../../../_blocs/actives/oaes/active_oaes_data.dart';
import '../../../../_blocs/actives/oaes/active_oaes_style.dart';

class ActiveOaesMap extends StatelessWidget {
  const ActiveOaesMap({
    super.key,
    required this.state,
    this.onOpenDetails,
  });

  final ActiveOaesState state;

  /// callback para abrir o painel de detalhes na página pai
  final void Function(TaggedChangedMarker<ActiveOaesData> marker)? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == ActiveOaesLoadStatus.loading && !state.initialized) {
      return const MapLoadingShimmer();
    }

    final markers = state.filteredAll
        .map((o) => o.toTaggedMarker())
        .whereType<TaggedChangedMarker<ActiveOaesData>>()
        .toList(growable: false);

    return MapInteractivePage<ActiveOaesData>(
      taggedMarkers: markers,
      clusterWidgetBuilder: (markers, selected, onSelect) {
        return AnimatedClusterMarkerLayer<ActiveOaesData>(
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
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Text(
                order,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            );
          },
          titleBuilder: (data) => data.identificationName ?? 'Sem nome',
          subTitleBuilder: (data) => data.state ?? 'Não identificado',

          // >>> aqui só repassamos o clique "Ver detalhes" pra página pai
          onViewDetails: (ctx, marker) => onOpenDetails?.call(marker),
        );
      },

      regionalPolygons: state.regionalPolygons,
      regionColors: state.regionColors,
      allowMultiSelect: false,
      selectedRegionNames: state.selectedRegionNamesForMap,

      onRegionTap: (region) {
        final bloc = context.read<ActiveOaesBloc>();
        final current = state.selectedRegionFilter?.toUpperCase();
        final tapped  = region?.toUpperCase();
        final newValue = (current != null && tapped != null && current == tapped) ? null : region;
        bloc.add(ActiveOaesRegionFilterChanged(newValue));
      },
    );
  }
}
