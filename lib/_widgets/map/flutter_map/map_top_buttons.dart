import 'package:flutter/material.dart';
import 'package:sipged/_widgets/buttons/circle_button_change.dart';

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
        CircleButtonChange(
          icon: Icons.pin_drop,
          tooltip: 'Minha localização',
          radius: 21,
          backgroundColor: Colors.black38,
          iconColor: Colors.white,
          onPressed: onMyLocationTap == null
              ? null
              : () async {
            await onMyLocationTap!.call();
          },
        ),
      );
    }

    if (showChangeMapType) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 8));

      children.add(
        CircleButtonChange(
          icon: Icons.map,
          tooltip: 'Mapa: $mapName',
          radius: 21,
          backgroundColor: Colors.black38,
          iconColor: Colors.white,
          onPressed: onMapSwitchTap,
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