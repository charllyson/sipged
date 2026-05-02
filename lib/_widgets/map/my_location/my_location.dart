import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  Future<void> _handleTap(BuildContext context) async {
    final bloc = context.read<NominatimBloc>();
    final loc = await bloc.getUserCurrentLocation();

    if (!context.mounted) return;

    if (loc == null) return;

    const zoom = 16.0;

    userLocationVN.value = loc;
    searchHitVN.value = loc;

    mapController.move(loc, zoom);

    onMoved?.call(loc, zoom);
    onMapTap?.call(loc.latitude, loc.longitude);
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