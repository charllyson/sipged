import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:sipged/_blocs/system/notification/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/map/base/map_types.dart';

class MapType extends StatelessWidget {
  const MapType({
    super.key,
    required this.mapController,
    required this.selectedMapIndex,
    required this.onChanged,
  });

  final MapController mapController;
  final int selectedMapIndex;
  final ValueChanged<int> onChanged;

  void _notify(
      BuildContext context,
      String title, {
        NotificationType type = NotificationType.info,
        String? subtitle,
        Duration duration = const Duration(seconds: 4),
      }) {
    context.read<NotificationCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'Mapa',
        type: type,
        duration: duration,
        extra: const <String, dynamic>{
          'module': 'map_interactive',
        },
      ),
      saveInFirebase: false,
    );
  }

  void _handleTap(BuildContext context) {
    if (MapTypes.mapBase.isEmpty) return;

    final nextIndex = (selectedMapIndex + 1) % MapTypes.mapBase.length;

    onChanged(nextIndex);

    Future.microtask(() {
      try {
        final camera = mapController.camera;
        mapController.move(camera.center, camera.zoom);
      } catch (_) {}
    });

    _notify(
      context,
      'Mapa: ${MapTypes.mapBase[nextIndex].nome}',
      type: NotificationType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex =
    selectedMapIndex >= 0 && selectedMapIndex < MapTypes.mapBase.length
        ? selectedMapIndex
        : 0;

    final mapName = MapTypes.mapBase.isNotEmpty
        ? MapTypes.mapBase[safeIndex].nome
        : 'Mapa';

    return CircleButtonChange(
      icon: Icons.map,
      tooltip: 'Mapa: $mapName',
      radius: 21,
      backgroundColor: Colors.black38,
      iconColor: Colors.white,
      onPressed: () => _handleTap(context),
    );
  }
}