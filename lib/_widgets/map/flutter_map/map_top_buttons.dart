import 'package:flutter/material.dart';
import 'package:sipged/_widgets/buttons/mini_circle_button.dart';

class MapTopButtons extends StatelessWidget {
  final bool showSearch;
  final bool showMyLocation;
  final bool showChangeMapType;

  final String mapName;

  final Future<void> Function()? onMyLocationTap;
  final VoidCallback? onMapSwitchTap;

  /// Já vem pronto: SearchAction ou builder externo.
  final Widget searchAction;

  const MapTopButtons({
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
        Tooltip(
          message: 'Minha localização',
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onMyLocationTap,
            child: const MiniCircleButton(icon: Icons.pin_drop),
          ),
        ),
      );
    }

    if (showChangeMapType) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 8));
      children.add(
        Tooltip(
          message: 'Mapa: $mapName',
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onMapSwitchTap,
            child: const MiniCircleButton(icon: Icons.map),
          ),
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}