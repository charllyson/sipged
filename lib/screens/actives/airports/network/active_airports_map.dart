// lib/screens/actives/oaes/network/pages/active_airports_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_widgets/map/clusters/cluster_animated_marker_widget.dart';

import 'package:siged/_widgets/map/map_interactive.dart';
import 'package:siged/_widgets/map/pin/pin_changed.dart';
import 'package:siged/_widgets/map/shimmer/map_loading_shimmer.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';

import 'package:siged/_blocs/actives/oaes/active_oaes_state.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_bloc.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_event.dart';

import '../../../../_blocs/actives/oaes/active_oaes_data.dart';
import '../../../../_blocs/actives/oaes/active_oaes_style.dart';

class ActiveAirportsMap extends StatefulWidget {
  const ActiveAirportsMap({
    super.key,
    required this.state,
    this.onOpenDetails,
  });

  final ActiveOaesState state;
  final void Function(TaggedChangedMarker<ActiveOaesData> marker)? onOpenDetails;

  @override
  State<ActiveAirportsMap> createState() => _ActiveAirportsMapState();
}

class _ActiveAirportsMapState extends State<ActiveAirportsMap> {
  @override
  Widget build(BuildContext context) {
    if (widget.state.loadStatus == ActiveOaesLoadStatus.loading && !widget.state.initialized) {
      return const MapLoadingShimmer();
    }

    // Marcadores já APLICANDO os filtros atuais (região/nota)
    final markers = widget.state.filteredAll
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
          markerAlignment: Alignment.topCenter,
          // ⬇️ usa o MESMO pin (PinChanged) e lógica de seleção (isSelected)
          markerBuilder: (context, tagged, isSelected) {
            final nota  = tagged.data.score?.toDouble() ?? 0;
            final order = (tagged.data.order?.toString() ?? '').trim();

            // cor de destaque quando selecionado; normal quando não
            final Color pinColor = isSelected
                ? Colors.amber.shade700
                : Colors.black87;

            // mantemos a cor pela NOTA na borda (como você fazia antes)
            final Color notaBorder = OaesDataStyle.getColorByNota(nota);

            // borda branca quando selecionado para dar contraste + halo
            final Color borderColor = isSelected
                ? Colors.white.withOpacity(0.95)
                : notaBorder;

            return PinChanged(
              size: 50,
              label: order.isEmpty ? ' ' : order,
              color: pinColor,
              borderColor: borderColor,
              halo: isSelected,
              haloOpacity: 0.20,
              haloScale: 1.85,
              innerDot: true,
              // você pode ajustar tipFactor/taper se quiser o bico mais longo/curto
            );
          },

          titleBuilder: (data) => data.identificationName ?? 'Sem nome',
          subTitleBuilder: (data) => data.state ?? 'Não identificado',

          // >>> aqui só repassamos o clique "Ver detalhes" pra página pai
          onViewDetails: (ctx, marker) => widget.onOpenDetails?.call(marker),
        );
      },

      // --------- REGIÕES (GEOJSON) ---------
      polygonsChanged: widget.state.regionalPolygons,                // polígonos do state
      polygonChangeColors: widget.state.regionColors,                        // cores por região
      allowMultiSelect: false,
      selectedRegionNames: widget.state.selectedRegionNamesForMap,    // espelha seleção atual

      // Toque na região → atualiza o filtro no BLoC (toggle)
      onRegionTap: (region) {
        final bloc = context.read<ActiveOaesBloc>();
        final current = widget.state.selectedRegionFilter?.toUpperCase();
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
