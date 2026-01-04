import 'package:equatable/equatable.dart';

import 'ana_pluviometric_series_data.dart';

enum AnaPluviometricSeriesStatus { initial, loading, success, failure }

class AnaPluviometricSeriesState extends Equatable {
  final AnaPluviometricSeriesStatus status;
  final String? error;
  final String codigoEstacao;
  final String stationName;
  final List<AnaPluviometricSeriesData> series;

  const AnaPluviometricSeriesState({
    this.status = AnaPluviometricSeriesStatus.initial,
    this.error,
    this.codigoEstacao = '',
    this.stationName = '',
    this.series = const [],
  });

  AnaPluviometricSeriesState copyWith({
    AnaPluviometricSeriesStatus? status,
    String? error,
    String? codigoEstacao,
    String? stationName,
    List<AnaPluviometricSeriesData>? series,
  }) {
    return AnaPluviometricSeriesState(
      status: status ?? this.status,
      error: error,
      codigoEstacao: codigoEstacao ?? this.codigoEstacao,
      stationName: stationName ?? this.stationName,
      series: series ?? this.series,
    );
  }

  @override
  List<Object?> get props =>
      [status, error, codigoEstacao, stationName, series];
}
