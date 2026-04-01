import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class ToolboxState extends Equatable {
  final List<LatLng> points;
  final List<double> segmentDistancesMeters;
  final double totalDistanceMeters;
  final String totalDistanceLabel;
  final String lastSegmentLabel;

  const ToolboxState({
    this.points = const [],
    this.segmentDistancesMeters = const [],
    this.totalDistanceMeters = 0,
    this.totalDistanceLabel = '0 m',
    this.lastSegmentLabel = '0 m',
  });

  bool get isEmpty => points.isEmpty;
  bool get hasSegments => points.length >= 2;

  ToolboxState copyWith({
    List<LatLng>? points,
    List<double>? segmentDistancesMeters,
    double? totalDistanceMeters,
    String? totalDistanceLabel,
    String? lastSegmentLabel,
  }) {
    return ToolboxState(
      points: points ?? this.points,
      segmentDistancesMeters:
      segmentDistancesMeters ?? this.segmentDistancesMeters,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      totalDistanceLabel: totalDistanceLabel ?? this.totalDistanceLabel,
      lastSegmentLabel: lastSegmentLabel ?? this.lastSegmentLabel,
    );
  }

  @override
  List<Object?> get props => [
    points,
    segmentDistancesMeters,
    totalDistanceMeters,
    totalDistanceLabel,
    lastSegmentLabel,
  ];
}