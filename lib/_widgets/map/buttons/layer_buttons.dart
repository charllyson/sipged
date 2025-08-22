import 'package:flutter/material.dart';

class LayerButtons extends StatelessWidget {
  final VoidCallback onMyLocationTap;
  final VoidCallback onMapSwitchTap;
  final String mapaAtual;

  const LayerButtons({
    super.key,
    required this.onMyLocationTap,
    required this.onMapSwitchTap,
    required this.mapaAtual,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      right: 10,
      child: Column(
        children: [
          InkWell(
            onTap: onMyLocationTap,
            child: Tooltip(
              message: 'Minha localização',
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Icon(Icons.pin_drop, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onMapSwitchTap,
            child: Tooltip(
              message: 'Mapa: $mapaAtual',
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Icon(Icons.map, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
