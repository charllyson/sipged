import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:siged/_blocs/actives/railway/active_railways_bloc.dart';
import 'package:siged/_blocs/actives/railway/active_railways_event.dart';
import 'package:siged/_blocs/actives/railway/active_railways_state.dart';

import 'package:siged/_widgets/map/map_interactive.dart';
import 'package:siged/_widgets/map/shimmer/map_loading_shimmer.dart';

import 'active_railways_details.dart';
import 'active_railways_tooltip_widget.dart';

class ActiveRailwaysMap extends StatelessWidget {
  const ActiveRailwaysMap({super.key, required this.state});
  final ActiveRailwaysState state;

  @override
  Widget build(BuildContext context) {
    final isInitialLoading =
        state.loadStatus == ActiveRailwaysLoadStatus.loading && !state.initialized;

    if (isInitialLoading) {
      return const MapLoadingShimmer();
    }

    return MapInteractivePage(
      // usa o zoom do estado para gerar as polylines responsivas
      tappablePolylines: state.buildStyledPolylines(zoom: state.mapZoom),

      // overlay invisível para ouvir zoom sem tocar no MapInteractivePage
      overlayBuilder: (MapController mc, GlobalKey _) =>
          _ZoomListenerOverlay(mapController: mc),

      onClearPolylineSelection: () async {
        context.read<ActiveRailwaysBloc>().add(const ActiveRailwaysSelectPolyline(null));
      },

      onSelectPolyline: (polyline) async {
        context.read<ActiveRailwaysBloc>().add(
          ActiveRailwaysSelectPolyline(polyline.tag?.toString()),
        );
      },

      onShowPolylineTooltip: ({
        required BuildContext context,
        required Offset position,
        required Object? tag,
      }) async {
        final id = tag?.toString();
        if (id == null) return;

        final fer = state.filteredAll.firstWhere(
              (f) => f.id == id,
          orElse: () => state.all.firstWhere(
                (f) => f.id == id,
            orElse: () => null as dynamic,
          ),
        );
        if (fer == null) return;

        final overlay = Overlay.of(context);
        if (overlay == null) return;

        ActiveRailwaysTooltipWidget.show(
          overlayState: overlay,
          position: position,
          fer: fer,
          onVerMais: () async {
            ActiveRailwaysTooltipWidget.hide();
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
                  child: ActiveRailwaysDetails(fer: fer),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Widget invisível que assina o mapEventStream e envia o zoom ao BLoC.
class _ZoomListenerOverlay extends StatefulWidget {
  const _ZoomListenerOverlay({required this.mapController});
  final MapController mapController;

  @override
  State<_ZoomListenerOverlay> createState() => _ZoomListenerOverlayState();
}

class _ZoomListenerOverlayState extends State<_ZoomListenerOverlay> {
  StreamSubscription? _sub;
  double _last = 12.0;

  @override
  void initState() {
    super.initState();
    // envia zoom inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final z = widget.mapController.camera.zoom;
      _last = z;
      context.read<ActiveRailwaysBloc>().add(ActiveRailwaysMapZoomChanged(z));
    });

    _sub = widget.mapController.mapEventStream.listen((_) {
      final z = widget.mapController.camera.zoom;
      if ((z - _last).abs() >= 0.05) {
        _last = z;
        context.read<ActiveRailwaysBloc>().add(ActiveRailwaysMapZoomChanged(z));
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
