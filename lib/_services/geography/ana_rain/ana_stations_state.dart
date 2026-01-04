import 'package:equatable/equatable.dart';

import 'ana_station_data.dart';

enum AnaStationsStatus { initial, loading, success, failure }

class AnaStationsState extends Equatable {
  final AnaStationsStatus status;
  final String? error;
  final String uf;
  final String stationType; // PLUVIOMETRICA ou FLUVIOMETRICA
  final List<AnaStationData> stations;
  final AnaStationData? selectedStation;

  const AnaStationsState({
    this.status = AnaStationsStatus.initial,
    this.error,
    this.uf = 'AL',
    this.stationType = 'PLUVIOMETRICA',
    this.stations = const [],
    this.selectedStation,
  });

  AnaStationsState copyWith({
    AnaStationsStatus? status,
    String? error,
    String? uf,
    String? stationType,
    List<AnaStationData>? stations,
    AnaStationData? selectedStation,
  }) {
    return AnaStationsState(
      status: status ?? this.status,
      error: error,
      uf: uf ?? this.uf,
      stationType: stationType ?? this.stationType,
      stations: stations ?? this.stations,
      selectedStation: selectedStation ?? this.selectedStation,
    );
  }

  @override
  List<Object?> get props => [
    status,
    error,
    uf,
    stationType,
    stations,
    selectedStation,
  ];
}
