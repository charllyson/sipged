import 'package:flutter/material.dart';
import 'package:siged/_blocs/modules/actives/roads/active_roads_data.dart';

class ActiveRoadsTooltipWidget {
  static OverlayEntry? _currentOverlay;

  static void show({
    required OverlayState overlayState,
    required Offset position,
    required ActiveRoadsData road,
    bool showCloseButton = true,
    VoidCallback? onVerMais,
  }) {
    hide();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Size screenSize = overlayState.context.size ?? Size.zero;
      const double tooltipWidth = 320;
      const double tooltipEstimatedHeight = 160;

      final double top = _clampDouble(
        position.dy - tooltipEstimatedHeight - 10,
        16.0,
        screenSize.height - tooltipEstimatedHeight - 16.0,
      );

      final double left = _clampDouble(
        position.dx + 10,
        16.0,
        screenSize.width - tooltipWidth - 16.0,
      );

      final pavLabel =
      ActiveRoadsData.getStatusSurface(road.stateSurface ?? '');

      _currentOverlay = OverlayEntry(
        builder: (context) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: hide,
              ),
            ),
            Positioned(
              top: top,
              left: left,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: tooltipWidth,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showCloseButton)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rodovia: AL-${road.acronym ?? '--'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                              onPressed: hide,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Código: ${road.roadCode}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Sub-trecho: ${road.initialSegment} / ${road.finalSegment}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Extensão: ${road.extension?.toStringAsFixed(2) ?? '--'} km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Pavimento: $pavLabel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (onVerMais != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              hide();
                              onVerMais();
                            },
                            child: const Text(
                              'Ver mais...',
                              style: TextStyle(
                                color: Colors.lightBlueAccent,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      overlayState.insert(_currentOverlay!);
    });
  }

  static double _clampDouble(double value, double min, double max) {
    if (min > max) return min;
    return value.clamp(min, max).toDouble();
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}
