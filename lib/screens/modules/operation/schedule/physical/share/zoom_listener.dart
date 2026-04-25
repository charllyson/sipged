// lib/_services/files/geoJson/zoom_listener.dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Novo padrão: usando Cubit em vez de Bloc/Event
import 'package:sipged/_blocs/modules/operation/operation/road/schedule_road_cubit.dart';

class ZoomListener extends StatefulWidget {
  final MapController mapController;

  const ZoomListener({
    super.key,
    required this.mapController,
  });

  @override
  State<ZoomListener> createState() => _ZoomListenerState();
}

class _ZoomListenerState extends State<ZoomListener> {
  StreamSubscription? _sub;

  double _last = 12.0;
  static const double _minDelta = 0.25; // menos eventos (era 0.05)
  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);
  static const _minInterval = Duration(milliseconds: 120); // debounce

  void _maybeEmit(double z) {
    final now = DateTime.now();

    if ((z - _last).abs() >= _minDelta &&
        now.difference(_lastEmit) >= _minInterval) {
      _last = z;
      _lastEmit = now;

      if (!mounted) return;

      // 👉 Usa o método existente no Cubit
      context.read<ScheduleRoadCubit>().setMapZoom(z);
    }
  }

  @override
  void initState() {
    super.initState();

    // Emite o zoom inicial depois do primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final z = widget.mapController.camera.zoom;
      _last = z;
      _lastEmit = DateTime.now();

      if (!mounted) return;

      context.read<ScheduleRoadCubit>().setMapZoom(z);
    });

    // Fica ouvindo os eventos do mapa e dispara quando muda o zoom
    _sub = widget.mapController.mapEventStream.listen((_) {
      _maybeEmit(widget.mapController.camera.zoom);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
