/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:sisged/_datas/oaes/oaesData.dart';
import '../../../../_class/map/tagged_marker.dart';
import 'package:flutter_map/flutter_map.dart' show AnchorAlign, AnchorPos;


class AnimatedOAEsClusterWidget extends StatelessWidget {
  final List<TaggedMarker> taggedMarkers;
  final LatLng? selectedMarkerPosition;
  final ValueChanged<TaggedMarker> onMarkerSelected;

  /// Callback de tooltip flutuante tradicional
  final void Function(LatLng, String)? onTooltipRequested;

  /// Callback para exibir tooltip fixo acima do marcador
  final void Function({
  required BuildContext context,
  required LatLng position,
  required List<MapEntry<String, String>> entries,
  })? onShowTooltipAcima;

  const AnimatedOAEsClusterWidget({
    Key? key,
    required this.taggedMarkers,
    required this.selectedMarkerPosition,
    required this.onMarkerSelected,
    this.onTooltipRequested,
    this.onShowTooltipAcima,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final markers = taggedMarkers.map((tagged) => _buildMarker(context, tagged)).toList();

    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        markers: markers,
        maxClusterRadius: 45,
        size: const Size(40, 40),
        zoomToBoundsOnClick: true,
        forceIntegerZoomLevel: true,
        padding: EdgeInsets.all(100),
        animationsOptions:AnimationsOptions(
          centerMarker: Duration(
              milliseconds: 200
          ),
        ),
        builder: (context, cluster) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black54,
          ),
          child: Center(
            child: Text(
              '${cluster.length}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );

  }

  Marker _buildMarker(BuildContext context, TaggedMarker tagged) {
    final point = tagged.point;
    final oaEsData = OAEsData.fromMap(tagged.properties);
    final isSelected = selectedMarkerPosition == point;

    return Marker(
      width: 50,
      height: 50,
      point: point,
      child: GestureDetector(
        onTapDown: (_) {
          onTooltipRequested?.call(tagged.point, oaEsData.identificationName ?? 'Sem nome');
          onMarkerSelected(tagged);

          final entries = tagged.properties.entries
              .where((e) => e.value != null && e.value.toString().isNotEmpty)
              .map((e) => MapEntry(e.key, e.value.toString()))
              .toList();

          onShowTooltipAcima?.call(
            context: context,
            position: tagged.point,
            entries: entries,
          );
        },
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1.0, end: isSelected ? 1.6 : 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.85,
                duration: const Duration(milliseconds: 200),
                child: child,
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (isSelected)
                Positioned(
                  top: -36,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      oaEsData.identificationName ?? 'Sem nome',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      softWrap: true,
                    ),
                  ),
                ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: OAEsData.getColorByNota(oaEsData.score?.toDouble() ?? 0),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    oaEsData.order?.toString() ?? '',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
