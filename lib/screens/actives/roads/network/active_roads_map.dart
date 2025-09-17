import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/actives/roads/active_road_bloc.dart';
import 'package:siged/_services/geocoding/geocoding_service.dart';

import 'package:siged/_widgets/map/map_interactive.dart';
import 'package:siged/_widgets/map/shimmer/map_loading_shimmer.dart';

import 'package:siged/_blocs/actives/roads/active_roads_state.dart';
import 'package:siged/_blocs/actives/roads/active_roads_event.dart';
import 'package:siged/_widgets/search/search_overlay.dart';
import 'package:siged/_widgets/search/search_widget.dart';

import 'package:siged/screens/actives/roads/network/active_roads_details.dart';
import 'package:siged/screens/actives/roads/network/active_roads_tooltip_widget.dart';

class ActiveRoadsMap extends StatefulWidget {
  const ActiveRoadsMap({super.key, required this.state});

  final ActiveRoadsState state;

  @override
  State<ActiveRoadsMap> createState() => _ActiveRoadsMapState();
}

class _ActiveRoadsMapState extends State<ActiveRoadsMap> {

  @override
  Widget build(BuildContext context) {
    final isInitialLoading =
        widget.state.loadStatus == ActiveRoadsLoadStatus.loading && !widget.state.initialized;

    if (isInitialLoading) {
      return const MapLoadingShimmer();
    }

    return MapInteractivePage(
      showSearch: true,
      searchTargetZoom: 16,
      showSearchMarker: true,
      tappablePolylines: widget.state.buildStyledPolylines(),
      onClearPolylineSelection: () async {
        context.read<ActiveRoadsBloc>().add(const ActiveRoadsSelectPolyline(null));
      },

      onSelectPolyline: (polyline) async {
        context.read<ActiveRoadsBloc>().add(
          ActiveRoadsSelectPolyline(polyline.tag?.toString()),
        );
      },

      onShowPolylineTooltip: ({
        required BuildContext context,
        required Offset position,
        required Object? tag,
      }) async {
        final id = tag?.toString();
        if (id == null) return;

        // tenta achar primeiro nos filtrados (respeita filtros ativos)
        final road = widget.state.filteredAll.firstWhere(
              (r) => r.id == id,
          orElse: () => widget.state.all.firstWhere(
                (r) => r.id == id,
            orElse: () => null as dynamic,
          ),
        );

        final overlay = Overlay.of(context);

        ActiveRoadsTooltipWidget.show(
          overlayState: overlay,
          position: position,
          road: road,
          onVerMais: () async {
            ActiveRoadsTooltipWidget.hide();
            await showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => Dialog(
                backgroundColor: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: ActiveRoadsDetails(road: road),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
