import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';
import 'package:sipged/_widgets/geo/layer/layer_single_symbol_preview.dart';
import 'package:sipged/_widgets/geo/properties/menu/symbology/catalogs/marker_icons_catalog.dart';

class LayerSymbolStackPreview extends StatelessWidget {
  final GeoLayersData layer;
  final bool isSelected;
  final bool isActive;

  const LayerSymbolStackPreview({super.key,
    required this.layer,
    required this.isSelected,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final visibleSymbols = layer.effectiveSymbolLayers
        .where((e) => e.enabled)
        .toList(growable: false);

    if (visibleSymbols.isEmpty) {
      final iconColor =
      isSelected ? Colors.white : (isActive ? layer.displayColor : Colors.grey);

      return SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: Icon(
            IconsCatalog.iconFor(layer.displayIconKey),
            size: 18,
            color: iconColor,
          ),
        ),
      );
    }

    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...visibleSymbols.reversed.map(
                (symbol) => DrawerSingleSymbolPreview(
              symbol: symbol,
              isSelected: isSelected,
              isActive: isActive,
            ),
          ),
        ],
      ),
    );
  }
}