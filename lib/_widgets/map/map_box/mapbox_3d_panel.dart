// lib/_widgets/map/map_box/mapbox_3d_panel.dart
import 'package:flutter/material.dart';

import 'package:siged/_services/map/map_box/mapbox_data.dart';
import 'package:siged/_widgets/map/map_box/mapbox_cube_widget.dart';
import 'package:siged/_services/map/map_box/mapbox_3d.dart';

class Mapbox3DPanel extends StatefulWidget {
  final Mapbox3DController controller;
  final List<MapboxStyleOption> styles;
  final int initialStyleIndex;

  const Mapbox3DPanel({
    super.key,
    required this.controller,
    required this.styles,
    this.initialStyleIndex = 0,
  });

  @override
  State<Mapbox3DPanel> createState() => _Mapbox3DPanelState();
}

class _Mapbox3DPanelState extends State<Mapbox3DPanel> {
  late int _selectedStyleIndex;

  @override
  void initState() {
    super.initState();
    _selectedStyleIndex = widget.initialStyleIndex.clamp(
      0,
      widget.styles.isEmpty ? 0 : widget.styles.length - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: (isDark ? Colors.grey[900] : Colors.white)!.withOpacity(0.95),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Mapa 3D - SIGED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 90,
              child: Center(
                child: MapboxCubeWidget(
                  onRotate: (dBearing, dPitch) {
                    widget.controller.cameraDelta(
                      dBearing: dBearing,
                      dPitch: dPitch,
                      durationMs: 0,
                    );
                  },
                  onReset: () {
                    widget.controller.setCamera(
                      bearing: 0,
                      pitch: 0,
                      durationMs: 400,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Estilo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(widget.styles.length, (index) {
                final st = widget.styles[index];
                final bool active = _selectedStyleIndex == index;

                return GestureDetector(
                  onTap: () {
                    if (_selectedStyleIndex == index) return;
                    setState(() => _selectedStyleIndex = index);
                    widget.controller.setStyle(st.styleUrl);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: active
                          ? Colors.blue
                          : (isDark ? Colors.grey[800] : Colors.grey[200]),
                      border: Border.all(
                        color: active
                            ? Colors.blue.shade700
                            : Colors.grey.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      st.name,
                      style: TextStyle(
                        fontSize: 10,
                        color: active
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
