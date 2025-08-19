/*
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sisged/_datas/oaes/active_oaes_data.dart';
import '../../../../_class/map/tagged_marker.dart';

class AnimatedOAEsWidget extends StatelessWidget {
  final List<TaggedMarker> taggedMarkers;
  final LatLng? selectedMarkerPosition;
  final ValueChanged<TaggedMarker> onMarkerSelected;
  final void Function(LatLng, String)? onTooltipRequested;

  /// Callback com contexto para tooltip fixo
  final void Function({
  required BuildContext context,
  required LatLng position,
  required List<MapEntry<String, String>> entries,
  })? onShowTooltipAcima;

  const AnimatedOAEsWidget({
    Key? key,
    required this.taggedMarkers,
    required this.selectedMarkerPosition,
    required this.onMarkerSelected,
    this.onShowTooltipAcima,
    this.onTooltipRequested,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: taggedMarkers.map((tagged) => _buildMarker(context, tagged)).toList(),
    );
  }

  Marker _buildMarker(BuildContext context, TaggedMarker tagged) {
    final point = tagged.point;
    final oaEsData = OAEsData.fromMap(tagged.properties);
    final isSelected = selectedMarkerPosition == point;

    return Marker(
      point: point,
      child: GestureDetector(
        onTapDown: (details) {
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
          tween: Tween<double>(
            begin: 1.0,
            end: isSelected ? 1.6 : 1.0,
          ),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            child: AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.85,
              duration: const Duration(milliseconds: 1),
              child: child,
            ),
          ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),

              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: OAEsData.getColorByNota(oaEsData.score?.toDouble() ?? 0),
                    width: 2,
                  ),
                ),
                width: 24,
                height: 24,
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
