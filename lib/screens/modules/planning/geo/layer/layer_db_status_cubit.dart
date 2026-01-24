// lib/screens/modules/planning/geo/layer/layer_db_status_cubit.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

class LayerDbStatusState {
  /// layerId -> hasData
  final Map<String, bool> hasDbByLayer;

  /// UF atual (opcional)
  final String? uf;

  final bool isLoading;
  final String? error;

  const LayerDbStatusState({
    this.hasDbByLayer = const {},
    this.uf,
    this.isLoading = false,
    this.error,
  });

  LayerDbStatusState copyWith({
    Map<String, bool>? hasDbByLayer,
    String? uf,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return LayerDbStatusState(
      hasDbByLayer: hasDbByLayer ?? this.hasDbByLayer,
      uf: uf ?? this.uf,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

typedef LayerHasDataFn = Future<bool> Function(String uf);

class LayerDbStatusCubit extends Cubit<LayerDbStatusState> {
  LayerDbStatusCubit({
    required this.roadsFederalHasData,
    required this.roadsStateHasData,
    required this.roadsMunicipalHasData,
    required this.railwaysHasData,
    required this.energyPlantsHasData, // ✅ NOVO
  }) : super(const LayerDbStatusState());

  final LayerHasDataFn roadsFederalHasData;
  final LayerHasDataFn roadsStateHasData;
  final LayerHasDataFn roadsMunicipalHasData;
  final LayerHasDataFn railwaysHasData;
  final LayerHasDataFn energyPlantsHasData;

  /// Cache: uf -> (layerId -> hasData)
  final Map<String, Map<String, bool>> _cacheByUf = {};

  /// Evita concorrência: uf -> Future em andamento
  final Map<String, Future<void>> _inFlightByUf = {};

  static const String kFederal = 'federal_road';
  static const String kState = 'state_road';
  static const String kMunicipal = 'municipal_road';
  static const String kRailways = 'railways';

  /// ✅ IMPORTANTE: o ID REAL do seu layer no Drawer/Controller é 'units_energy'
  static const String kEnergyPlants = 'units_energy';

  Future<void> refreshAll({
    required String uf,
    bool force = false,
  }) async {
    final ufNorm = uf.trim().toUpperCase();

    final cached = _cacheByUf[ufNorm];
    if (!force && cached != null && cached.isNotEmpty) {
      emit(state.copyWith(
        uf: ufNorm,
        hasDbByLayer: Map<String, bool>.from(cached),
        isLoading: false,
        clearError: true,
      ));
      return;
    }

    final inFlight = _inFlightByUf[ufNorm];
    if (inFlight != null) {
      await inFlight;
      return;
    }

    emit(state.copyWith(isLoading: true, uf: ufNorm, clearError: true));

    final f = _doRefreshAll(ufNorm).whenComplete(() {
      _inFlightByUf.remove(ufNorm);
    });

    _inFlightByUf[ufNorm] = f;
    await f;
  }

  Future<void> _doRefreshAll(String uf) async {
    try {
      final results = await Future.wait<bool>([
        roadsFederalHasData(uf),
        roadsStateHasData(uf),
        roadsMunicipalHasData(uf),
        railwaysHasData(uf),
        energyPlantsHasData(uf),
      ]);

      final map = <String, bool>{
        kFederal: results[0],
        kState: results[1],
        kMunicipal: results[2],
        kRailways: results[3],
        kEnergyPlants: results[4], // ✅ agora casa com o Drawer (units_energy)
      };

      _cacheByUf[uf] = Map<String, bool>.from(map);

      emit(state.copyWith(
        uf: uf,
        isLoading: false,
        hasDbByLayer: map,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> refreshLayer({
    required String uf,
    required String layerId,
    bool force = true,
  }) async {
    final ufNorm = uf.trim().toUpperCase();

    try {
      final current = Map<String, bool>.from(
        _cacheByUf[ufNorm] ?? state.hasDbByLayer,
      );

      bool value;
      switch (layerId) {
        case kFederal:
          value = await roadsFederalHasData(ufNorm);
          break;
        case kState:
          value = await roadsStateHasData(ufNorm);
          break;
        case kMunicipal:
          value = await roadsMunicipalHasData(ufNorm);
          break;
        case kRailways:
          value = await railwaysHasData(ufNorm);
          break;
        case kEnergyPlants:
          value = await energyPlantsHasData(ufNorm);
          break;
        default:
          return;
      }

      current[layerId] = value;
      _cacheByUf[ufNorm] = Map<String, bool>.from(current);

      emit(state.copyWith(
        uf: ufNorm,
        hasDbByLayer: current,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setHasData(String layerId, bool value) {
    final next = Map<String, bool>.from(state.hasDbByLayer);
    next[layerId] = value;
    emit(state.copyWith(hasDbByLayer: next));
  }
}
