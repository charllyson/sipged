import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/toolbox_state.dart';

class ToolboxCubit extends Cubit<ToolboxState> {
  ToolboxCubit() : super(const ToolboxState());

  static const Distance _distance = Distance();

  void addPoint(LatLng point) {
    final nextPoints = [...state.points, point];
    emit(_buildState(nextPoints));
  }

  void removeLastPoint() {
    if (state.points.isEmpty) return;
    final nextPoints = state.points.sublist(0, state.points.length - 1);
    emit(_buildState(nextPoints));
  }

  void clear() {
    emit(const ToolboxState());
  }

  void replacePoints(List<LatLng> points) {
    emit(_buildState(points));
  }

  ToolboxState _buildState(List<LatLng> points) {
    final segmentDistances = _calculateSegmentDistancesMeters(points);
    final totalDistance = segmentDistances.fold<double>(0, (a, b) => a + b);

    return ToolboxState(
      points: List.unmodifiable(points),
      segmentDistancesMeters: List.unmodifiable(segmentDistances),
      totalDistanceMeters: totalDistance,
      totalDistanceLabel: _formatDistance(totalDistance),
      lastSegmentLabel: segmentDistances.isEmpty
          ? '0 m'
          : _formatDistance(segmentDistances.last),
    );
  }

  List<double> _calculateSegmentDistancesMeters(List<LatLng> points) {
    if (points.length < 2) return const [];

    final segments = <double>[];
    for (int i = 0; i < points.length - 1; i++) {
      segments.add(
        _distance.as(
          LengthUnit.Meter,
          points[i],
          points[i + 1],
        ),
      );
    }
    return segments;
  }

  String _formatDistance(double meters) {
    if (meters <= 0) return '0 m';

    if (meters < 1000) {
      if (meters < 10) return '${meters.toStringAsFixed(2)} m';
      if (meters < 100) return '${meters.toStringAsFixed(1)} m';
      return '${meters.toStringAsFixed(0)} m';
    }

    final km = meters / 1000.0;
    if (km < 10) return '${km.toStringAsFixed(2)} km';
    if (km < 100) return '${km.toStringAsFixed(1)} km';
    return '${km.toStringAsFixed(0)} km';
  }
}