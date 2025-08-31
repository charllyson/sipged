import 'package:flutter/material.dart';
import 'package:siged/_blocs/actives/railway/active_railway_data.dart';
import 'package:siged/_blocs/actives/railway/active_railways_rules.dart';

class ActiveRailwaysTooltipWidget {
  static OverlayEntry? _currentOverlay;

  static void show({
    required OverlayState overlayState,
    required Offset position,
    required ActiveRailwayData fer,
    bool showCloseButton = true,
    VoidCallback? onVerMais,
  }) {
    hide();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Size screenSize = overlayState.context.size ?? Size.zero;
      const double tooltipWidth = 320;
      const double tooltipEstimatedHeight = 168;

      final double top = _clamp(
        position.dy - tooltipEstimatedHeight - 10,
        16.0,
        screenSize.height - tooltipEstimatedHeight - 16.0,
      );

      final double left = _clamp(
        position.dx + 10,
        16.0,
        screenSize.width - tooltipWidth - 16.0,
      );

      final statusCode = ActiveRailwaysRules.statusCodeOf(fer.status);
      final statusLabel = ActiveRailwaysRules.labelForStatus(statusCode);

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
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showCloseButton)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Ferrovia: ${fer.nome ?? '--'}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 16),
                              onPressed: hide,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      _line('Código', fer.codigo),
                      _line('Município/UF', _fmtLoc(fer.municipio, fer.uf)),
                      _line('Bitola', fer.bitola),
                      _line('Status', statusLabel),
                      _line('Extensão', _fmtKm(fer.extensao)),
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



  static Widget _line(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$label: ${value ?? '--'}',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static String _fmtKm(double? v) =>
      v == null ? '--' : '${v.toStringAsFixed(2)} km';

  static String _fmtLoc(String? mun, String? uf) {
    final m = (mun ?? '').trim();
    final u = (uf ?? '').trim();
    if (m.isEmpty && u.isEmpty) return '--';
    if (m.isEmpty) return u;
    if (u.isEmpty) return m;
    return '$m/$u';
  }

  static double _clamp(double value, double min, double max) {
    if (min > max) return min;
    return value.clamp(min, max).toDouble();
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}
