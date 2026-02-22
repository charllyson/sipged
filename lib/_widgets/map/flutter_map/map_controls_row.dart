// lib/_widgets/map/flutter_map/widgets/map_controls_row.dart
import 'package:flutter/material.dart';
import 'package:sipged/_widgets/buttons/mini_circle_button.dart';

class MapControlsRow extends StatelessWidget {
  final bool showSearch;
  final bool showMyLocation;
  final bool showChangeMapType;

  final String mapName;

  final Future<void> Function()? onMyLocationTap;
  final VoidCallback? onMapSwitchTap;

  /// Já vem pronto (SearchAction ou builder do caller)
  final Widget searchAction;

  const MapControlsRow({
    super.key,
    required this.showSearch,
    required this.showMyLocation,
    required this.showChangeMapType,
    required this.mapName,
    required this.onMyLocationTap,
    required this.onMapSwitchTap,
    required this.searchAction,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (showSearch) {
      children.add(searchAction);
    }

    if (showMyLocation) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 8));
      children.add(
        InkWell(
          onTap: onMyLocationTap,
          child: const Tooltip(
            message: 'Minha localização',
            child: MiniCircleButton(icon: Icons.pin_drop),
          ),
        ),
      );
    }

    if (showChangeMapType) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 8));
      children.add(
        InkWell(
          onTap: onMapSwitchTap,
          child: Tooltip(
            message: 'Mapa: $mapName',
            child: const MiniCircleButton(icon: Icons.map),
          ),
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Row(children: children);
  }
}
