import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PinUserLocation extends StatelessWidget {
  const PinUserLocation({
    super.key,
    required this.userLocationVN,
    required this.pulseAnimation,
    this.color = Colors.blueAccent,
    this.markerSize = 64,
    this.pulseSize = 44,
    this.dotSize = 18,
  });

  final ValueListenable<LatLng?> userLocationVN;
  final Animation<double> pulseAnimation;

  final Color color;
  final double markerSize;
  final double pulseSize;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LatLng?>(
      valueListenable: userLocationVN,
      builder: (_, pos, _) {
        if (pos == null) return const SizedBox.shrink();

        return RepaintBoundary(
          child: MarkerLayer(
            markers: [
              Marker(
                point: pos,
                width: markerSize,
                height: markerSize,
                alignment: Alignment.center,
                child: IgnorePointer(
                  child: _PulseLocationDot(
                    animation: pulseAnimation,
                    color: color,
                    pulseSize: pulseSize,
                    dotSize: dotSize,
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

class _PulseLocationDot extends StatelessWidget {
  const _PulseLocationDot({
    required this.animation,
    required this.color,
    required this.pulseSize,
    required this.dotSize,
  });

  final Animation<double> animation;
  final Color color;
  final double pulseSize;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final scale = animation.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: pulseSize,
                height: pulseSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.16),
                  border: Border.all(
                    color: color.withValues(alpha: 0.38),
                    width: 1.4,
                  ),
                ),
              ),
            ),
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}