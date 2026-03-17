import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapUserLocation extends StatelessWidget {
  final ValueListenable<LatLng?> userLocationVN;
  final Animation<double> pulseAnimation;

  const MapUserLocation({
    super.key,
    required this.userLocationVN,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LatLng?>(
      valueListenable: userLocationVN,
      builder: (_, pos, __) {
        if (pos == null) return const SizedBox.shrink();

        return RepaintBoundary(
          child: MarkerLayer(
            markers: [
              Marker(
                point: pos,
                width: 58,
                height: 58,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: ScaleTransition(
                    scale: pulseAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withValues(alpha: 0.25),
                        border: Border.all(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}