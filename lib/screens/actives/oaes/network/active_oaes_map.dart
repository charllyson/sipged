import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_widgets/map/clusters/cluster_animated_marker_widget.dart';
import 'package:siged/_widgets/map/map_interactive.dart';
import 'package:siged/_widgets/map/shimmer/map_loading_shimmer.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_state.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_bloc.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_event.dart';
import 'package:siged/_widgets/search/search_overlay.dart';
import 'package:siged/_widgets/search/search_widget.dart';
import 'package:siged/_widgets/suggestions/suggestion_models.dart';

import '../../../../_blocs/actives/oaes/active_oaes_data.dart';
import '../../../../_blocs/actives/oaes/active_oaes_style.dart';
import '../../../../_services/geocoding/geocoding_service.dart';

class ActiveOaesMap extends StatefulWidget {
  const ActiveOaesMap({
    super.key,
    required this.state,
    this.onOpenDetails,
  });

  final ActiveOaesState state;

  /// callback para abrir o painel de detalhes na página pai
  final void Function(TaggedChangedMarker<ActiveOaesData> marker)? onOpenDetails;

  @override
  State<ActiveOaesMap> createState() => _ActiveOaesMapState();
}

class _ActiveOaesMapState extends State<ActiveOaesMap> {


  @override
  Widget build(BuildContext context) {
    if (widget.state.loadStatus == ActiveOaesLoadStatus.loading && !widget.state.initialized) {
      return const MapLoadingShimmer();
    }

    final markers = widget.state.filteredAll
        .map((o) => o.toTaggedMarker())
        .whereType<TaggedChangedMarker<ActiveOaesData>>()
        .toList(growable: false);

    return MapInteractivePage<ActiveOaesData>(
      showSearch: true,
      searchTargetZoom: 16,
      showSearchMarker: true,
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
          onViewDetails: (ctx, marker) => widget.onOpenDetails?.call(marker),
        );
      },

      polygonsChanged: widget.state.regionalPolygons,
      polygonChangeColors: widget.state.regionColors,
      allowMultiSelect: false,
      selectedRegionNames: widget.state.selectedRegionNamesForMap,

      onRegionTap: (region) {
        final bloc = context.read<ActiveOaesBloc>();
        final current = widget.state.selectedRegionFilter?.toUpperCase();
        final tapped  = region?.toUpperCase();
        final newValue = (current != null && tapped != null && current == tapped) ? null : region;
        bloc.add(ActiveOaesRegionFilterChanged(newValue));
      },
    );
  }
}
