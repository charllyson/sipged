import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/system/notification/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_services/map/map_box/service/nominatim_bloc.dart';
import 'package:sipged/_widgets/buttons/circle_button_change.dart';

class MyLocation extends StatelessWidget {
  const MyLocation({
    super.key,
    required this.mapController,
    required this.userLocationVN,
    required this.searchHitVN,
    this.onMapTap,
    this.onMoved,
  });

  final MapController mapController;
  final ValueNotifier<LatLng?> userLocationVN;
  final ValueNotifier<LatLng?> searchHitVN;

  final void Function(double lat, double lon)? onMapTap;
  final void Function(LatLng center, double zoom)? onMoved;

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

  Future<void> _handleTap(BuildContext context) async {
    final bloc = context.read<NominatimBloc>();
    final loc = await bloc.getUserCurrentLocation();

    if (!context.mounted) return;

    if (loc != null) {
      const zoom = 16.0;

      userLocationVN.value = loc;

      mapController.move(loc, zoom);

      onMoved?.call(loc, zoom);
      onMapTap?.call(loc.latitude, loc.longitude);

      _notify(
        context,
        'Minha localização centralizada',
        type: NotificationType.success,
      );

      return;
    }

    _notify(
      context,
      'Não foi possível obter sua localização',
      type: NotificationType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CircleButtonChange(
      icon: Icons.pin_drop,
      tooltip: 'Minha localização',
      radius: 21,
      backgroundColor: Colors.black38,
      iconColor: Colors.white,
      onPressed: () async {
        await _handleTap(context);
      },
    );
  }
}