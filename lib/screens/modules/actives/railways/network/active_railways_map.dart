import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/actives/railway/active_railway_data.dart';
import 'package:sipged/_blocs/modules/actives/railway/active_railways_cubit.dart';
import 'package:sipged/_blocs/modules/actives/railway/active_railways_state.dart';

import 'package:sipged/_widgets/map/flutter_map/map_interactive.dart';
import 'package:sipged/_widgets/map/shimmer/map_shimmer.dart';

// NOVO helper de overlay ancorado
import 'package:sipged/_widgets/map/tooltip/tooltip_overlay.dart';

import 'active_railways_details.dart';

class ActiveRailwaysMap extends StatefulWidget {
  const ActiveRailwaysMap({super.key, required this.state});
  final ActiveRailwaysState state;

  @override
  State<ActiveRailwaysMap> createState() => _ActiveRailwaysMapState();
}

class _ActiveRailwaysMapState extends State<ActiveRailwaysMap> {
  // âncora do tooltip (LatLng na ferrovia)
  LatLng? _anchorLatLng;
  // para reprojetar em pan/zoom
  MapController? _lastMapController;
  Offset Function(Offset local)? _toGlobal;

  @override
  Widget build(BuildContext context) {
    final isInitialLoading =
        widget.state.loadStatus == ActiveRailwaysLoadStatus.loading &&
            !widget.state.initialized;

    if (isInitialLoading) {
      return const MapShimmer();
    }

    return MapInteractivePage(
      // polylines responsivas
      tappablePolylines:
      widget.state.buildStyledPolylines(zoom: widget.state.mapZoom),

      // overlay invisível que já alimenta o zoom pro Cubit
      overlayBuilder: (MapController mc, GlobalKey _) =>
          _ZoomListenerOverlay(mapController: mc),

      // 👉 atualiza o tooltip ancorado conforme pan/zoom
      onCameraChanged: (double _, LatLng _) {
        if (_anchorLatLng != null &&
            _lastMapController != null &&
            _toGlobal != null) {
          final local = _lastMapController!.camera.latLngToScreenOffset(
            _anchorLatLng!,
          );
          final global = _toGlobal!(local);
          TooltipOverlay.updatePosition(global);
        }
      },

      onClearPolylineSelection: () async {
        context.read<ActiveRailwaysCubit>().selectPolyline(null);
        _anchorLatLng = null;
        _lastMapController = null;
        _toGlobal = null;
        TooltipOverlay.hide();
      },

      onSelectPolyline: (polyline) async {
        context
            .read<ActiveRailwaysCubit>()
            .selectPolyline(polyline.tag?.toString());
      },

      onShowPolylineTooltip: ({
        required BuildContext context,
        required Offset position,
        required Object? tag,
        required MapController mapController,
        LatLng? tapLatLng,
        Offset Function(Offset p)? toGlobal,
      }) async {
        final id = tag?.toString();
        if (id == null) return;

        final st = widget.state;

        ActiveRailwayData? fer = st.filteredAll
            .where((f) => f.id == id)
            .cast<ActiveRailwayData?>()
            .firstWhere(
              (f) => f != null,
          orElse: () => null,
        );

        fer ??= st.all
            .where((f) => f.id == id)
            .cast<ActiveRailwayData?>()
            .firstWhere(
              (f) => f != null,
          orElse: () => null,
        );

        if (fer == null) return;

        // âncora ideal: projeção do toque na linha; fallback: centro/início/fim
        _anchorLatLng = fer.anchorForTap(tapLatLng);
        if (_anchorLatLng == null) return;

        // guarda pra reprojetar durante pan/zoom
        _lastMapController = mapController;
        _toGlobal = toGlobal;

        final overlay = Overlay.of(context);

        final title = _title(fer);
        final subtitle = _subtitle(fer);

        TooltipOverlay.show(
          overlayState: overlay,
          position: position,
          title: title,
          subtitle: subtitle.isEmpty ? null : subtitle,
          maxWidth: 320,
          forceDownArrow: true, // seta sempre para baixo (aponta para a via)
          onDetails: () async {
            TooltipOverlay.hide();
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
                  child: ActiveRailwaysDetails(
                    fer: fer!,
                    enabled: false,
                  ),
                ),
              ),
            );
          },
          onClose: () {
            _anchorLatLng = null;
            _lastMapController = null;
            _toGlobal = null;
          },
        );
      },
    );
  }

  String _title(ActiveRailwayData fer) {
    final nome = (fer.nome ?? '').trim();
    if (nome.isNotEmpty) return nome;
    final cod = (fer.codigo ?? '').trim();
    if (cod.isNotEmpty) return 'Ferrovia $cod';
    return fer.id ?? 'Ferrovia';
  }

  String _subtitle(ActiveRailwayData fer) {
    final s = <String>[];
    if ((fer.uf ?? '').trim().isNotEmpty) s.add('UF: ${fer.uf}');
    if ((fer.status ?? '').trim().isNotEmpty) s.add('Status: ${fer.status}');
    if ((fer.bitola ?? '').trim().isNotEmpty) s.add('Bitola: ${fer.bitola}');
    if ((fer.municipio ?? '').trim().isNotEmpty) s.add(fer.municipio!);
    return s.join(' • ');
  }
}

/// Widget invisível que assina o mapEventStream e envia o zoom ao Cubit.
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
      context.read<ActiveRailwaysCubit>().setMapZoom(z);
    });

    _sub = widget.mapController.mapEventStream.listen((_) {
      final z = widget.mapController.camera.zoom;
      if ((z - _last).abs() >= 0.05) {
        _last = z;
        context.read<ActiveRailwaysCubit>().setMapZoom(z);
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
