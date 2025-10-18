// lib/screens/sectors/actives/oaes/active_oaes_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/map/clusters/cluster_animated_marker_widget.dart';
import 'package:siged/_widgets/map/map_interactive.dart';
import 'package:siged/_widgets/map/shimmer/map_loading_shimmer.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';

// pin com bico/seleção
import 'package:siged/_widgets/map/pin/pin_changed.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_state.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_bloc.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_event.dart';

import '../../../../_blocs/actives/oaes/active_oaes_data.dart';
import '../../../../_blocs/actives/oaes/active_oaes_style.dart';

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
        final bool anySelected = selected != null;

        return ClusterAnimatedMarkerLayer<ActiveOaesData>(
          taggedMarkers: markers,
          selectedMarkerPosition: selected,
          onMarkerSelected: onSelect,
          inlineTooltip: true,
          inlineMaxWidth: 240,
          inlineClearance: -10,
          markerAlignment: Alignment.topCenter,
          // pin + lógica de seleção/destaque
          markerBuilder: (context, tagged, isSelected) {
            final nota  = tagged.data.score?.toDouble() ?? 0;
            final order = (tagged.data.order?.toString() ?? '').trim();

            final Color notaColor = OaesDataStyle.getColorByNota(nota);
            final Color pinColor = isSelected
                ? notaColor
                : (anySelected ? Colors.black26 : notaColor);

            return PinChanged(
              size: 50,
              label: order.isEmpty ? ' ' : order,
              color: pinColor,
              halo: isSelected,
              haloOpacity: 0.20,
              haloScale: 1.85,
              innerDot: true,
            );
          },

          titleBuilder: (data) => data.identificationName ?? 'Sem nome',
          subTitleBuilder: (data) => data.state ?? 'Não identificado',

          // abrir painel de detalhes na página pai
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
