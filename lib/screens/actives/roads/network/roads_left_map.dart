import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sisged/_blocs/actives/roads/active_road_bloc.dart';

import 'package:sisged/_widgets/map/map_interactive.dart';
import 'package:sisged/_widgets/map/shimmer/map_loading_shimmer.dart';

import 'package:sisged/_blocs/actives/roads/active_roads_state.dart';
import 'package:sisged/_blocs/actives/roads/active_roads_event.dart';

import 'package:sisged/screens/actives/roads/network/active_roads_details.dart';
import 'package:sisged/screens/actives/roads/network/active_roads_tooltip_widget.dart';

class RoadsLeftMap extends StatelessWidget {
  const RoadsLeftMap({super.key, required this.state});

  final ActiveRoadsState state;

  @override
  Widget build(BuildContext context) {
    final isInitialLoading =
        state.loadStatus == ActiveRoadsLoadStatus.loading && !state.initialized;

    if (isInitialLoading) {
      return const MapLoadingShimmer();
    }

    return MapInteractivePage(
      tappablePolylines: state.buildStyledPolylines(),

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
        final road = state.filteredAll.firstWhere(
              (r) => r.id == id,
          orElse: () => state.all.firstWhere(
                (r) => r.id == id,
            orElse: () => null as dynamic,
          ),
        );
        if (road == null) return;

        final overlay = Overlay.of(context);
        if (overlay == null) return;

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
