import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sipged/_widgets/map/pin/pin_changed.dart';

class PinSearch extends StatelessWidget {
  final ValueListenable<LatLng?> searchHitVN;

  const PinSearch({
    super.key,
    required this.searchHitVN,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LatLng?>(
      valueListenable: searchHitVN,
      builder: (_, pos, __) {
        if (pos == null) return const SizedBox.shrink();

        const double pinH = 56.0;
        const double pinW = 44.0;

        return MarkerLayer(
          markers: [
            Marker(
              point: pos,
              width: pinW,
              height: pinH,
              alignment: Alignment.topCenter,
              child: const PinChanged(
                size: pinH,
                color: Color(0xFFE53935),
                halo: true,
                haloOpacity: 0.18,
                haloScale: 1.8,
                anchor: PinAnchor.tip,
              ),
            ),
          ],
        );
      },
    );
  }
}