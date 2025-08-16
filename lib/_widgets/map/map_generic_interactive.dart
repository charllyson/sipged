import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:sisged/_widgets/map/markers/tagged_marker.dart';
import 'package:sisged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:sisged/_widgets/map/polylines/tappable_changed_polyline_layer.dart';
import 'package:sisged/_datas/widgets/map_data.dart';
import '../../_blocs/system/system_bloc.dart';
import 'buttons/layer_buttons.dart';
import 'legend/map_legend_widget.dart';

class MapInteractivePage<T> extends StatefulWidget {
  final double? initialZoom;
  final double? maxZoom;
  final double? minZoom;
  final bool activeMap;
  final bool showLegend;

  /// Permite injetar uma base custom (ex.: tiles do Mapbox, WMS etc.)
  final Widget Function()? baseTileLayerBuilder;

  final List<TappableChangedPolyline>? tappablePolylines;
  final Future<void> Function()? onClearPolylineSelection;
  final Future<void> Function(TappableChangedPolyline)? onSelectPolyline;

  final void Function({
  required BuildContext context,
  required Offset position,
  required Object? tag,
  })? onShowPolylineTooltip;

  final List<TaggedChangedMarker<T>>? taggedMarkers;
  final Widget Function(
      List<TaggedChangedMarker<T>> taggedMarkers,
      LatLng? selectedMarkerPosition,
      ValueChanged<TaggedChangedMarker<T>> onMarkerSelected,
      )? clusterWidgetBuilder;

  final List<Polygon>? polygon;
  final Map<String, Color>? regionColors;

  const MapInteractivePage({
    super.key,
    this.initialZoom = 9.0,
    this.maxZoom = 18.0,
    this.minZoom = 5.0,
    this.activeMap = true,
    this.showLegend = true,
    this.baseTileLayerBuilder,
    this.tappablePolylines,
    this.onClearPolylineSelection,
    this.onSelectPolyline,
    this.polygon,
    this.taggedMarkers,
    this.regionColors,
    this.clusterWidgetBuilder,
    this.onShowPolylineTooltip,
  });

  @override
  State<MapInteractivePage<T>> createState() => _MapInteractivePageState<T>();
}

class _MapInteractivePageState<T> extends State<MapInteractivePage<T>>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  int _indexSelectedMap = 0;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  late final SystemBloc _systemBloc;

  LatLng? _selectedMarkerPosition;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _systemBloc = SystemBloc();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  Future<void> _handleMyLocationTap() async {
    final location = await _systemBloc.getUserCurrentLocation();
    if (!mounted) return;
    if (location != null) {
      setState(() => _userLocation = location);
      _mapController.move(location, 16);
    }
  }

  void _handleMapSwitchTap() {
    setState(() {
      _indexSelectedMap = (_indexSelectedMap + 1) % MapData.mapBase.length;
    });
  }

  Future<void> _handlePolylineTap(
      List<TappableChangedPolyline> tapped,
      TapUpDetails details,
      ) async {
    if (tapped.isEmpty) return;

    final tappedPolyline = tapped.first;
    // debug
    // print('🟢 Polyline tocada: ${tappedPolyline.tag}');

    // Notifica quem estiver ouvindo
    await widget.onSelectPolyline?.call(tappedPolyline);

    // Tooltip opcional
    final onShow = widget.onShowPolylineTooltip;
    if (onShow != null) {
      onShow(
        context: context,
        position: details.globalPosition,
        tag: tappedPolyline.tag,
      );
    }
  }

  List<Widget> _buildMapLayers() {
    final List<Widget> layers = [];

    // Base layer (custom builder tem prioridade)
    if (widget.activeMap) {
      if (widget.baseTileLayerBuilder != null) {
        layers.add(widget.baseTileLayerBuilder!());
      } else if (MapData.mapBase[_indexSelectedMap].url.isNotEmpty) {
        layers.add(
          TileLayer(
            key: ValueKey(_indexSelectedMap),
            tileProvider: CancellableNetworkTileProvider(),
            urlTemplate: MapData.mapBase[_indexSelectedMap].url,
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.sisgeo',
          ),
        );
      }
    }

    // Polylines clicáveis
    final lines = widget.tappablePolylines;
    if (lines != null && lines.isNotEmpty) {
      layers.add(
        MapTappablePolylineLayer(
          polylines: lines,
          onTap: _handlePolylineTap,
          polylineCulling: false,
        ),
      );
    }

    // Markers/Clusters (só renderiza se tiver builder)
    final markers = widget.taggedMarkers;
    if (markers != null &&
        markers.isNotEmpty &&
        widget.clusterWidgetBuilder != null) {
      layers.add(
        widget.clusterWidgetBuilder!(
          markers,
          _selectedMarkerPosition,
              (marker) => setState(() => _selectedMarkerPosition = marker.point),
        ),
      );
    }

    // Polígonos (ex.: municípios / regiões)
    final polys = widget.polygon;
    if (polys != null && polys.isNotEmpty) {
      layers.add(PolygonLayer(polygons: polys));
    }

    // Marcador pulsante da minha localização
    if (_userLocation != null) {
      layers.add(
        MarkerLayer(
          markers: [
            Marker(
              point: _userLocation!,
              width: 60,
              height: 60,
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.25),
                    border: Border.all(color: Colors.blueAccent, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Legenda por região (se houver cores)
    if (widget.showLegend && (widget.regionColors?.isNotEmpty ?? false)) {
      layers.add(
        Align(
          alignment: Alignment.bottomLeft,
          child: MapLegendLayer(regionColors: widget.regionColors!),
        ),
      );
    }

    return layers;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(-9.65, -36.7),
                  initialZoom: widget.initialZoom ?? 9,
                  maxZoom: widget.maxZoom ?? 18,
                  minZoom: widget.minZoom ?? 5,
                  // Toque no mapa limpa seleção de polylines e marker selecionado
                  onTap: (_, __) {
                    setState(() => _selectedMarkerPosition = null);
                    // Só chama se existir
                    widget.onClearPolylineSelection?.call();
                  },
                ),
                children: _buildMapLayers(),
              ),
            ),
          ],
        ),
        LayerButtons(
          onMyLocationTap: _handleMyLocationTap,
          onMapSwitchTap: _handleMapSwitchTap,
          mapaAtual: MapData.mapBase[_indexSelectedMap].nome,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
