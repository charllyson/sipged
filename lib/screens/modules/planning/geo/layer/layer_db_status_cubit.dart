import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

class LayerDbStatusState {
  final Map<String, bool> hasDbByLayer;
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
    required Map<String, LayerHasDataFn> resolvers,
  })  : _resolvers = Map<String, LayerHasDataFn>.from(resolvers),
        super(const LayerDbStatusState());

  final Map<String, LayerHasDataFn> _resolvers;

  final Map<String, Map<String, bool>> _cacheByUf = {};
  final Map<String, Future<void>> _inFlightByUf = {};

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

    emit(state.copyWith(
      uf: ufNorm,
      isLoading: true,
      clearError: true,
    ));

    final future = _doRefreshAll(ufNorm).whenComplete(() {
      _inFlightByUf.remove(ufNorm);
    });

    _inFlightByUf[ufNorm] = future;
    await future;
  }

  Future<void> _doRefreshAll(String uf) async {
    try {
      final entries = _resolvers.entries.toList(growable: false);

      final values = await Future.wait<bool>(
        entries.map((e) => e.value(uf)),
      );

      final result = <String, bool>{};
      for (int i = 0; i < entries.length; i++) {
        result[entries[i].key] = values[i];
      }

      _cacheByUf[uf] = Map<String, bool>.from(result);

      emit(state.copyWith(
        uf: uf,
        hasDbByLayer: result,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        uf: uf,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> refreshLayer({
    required String uf,
    required String layerId,
  }) async {
    final ufNorm = uf.trim().toUpperCase();
    final resolver = _resolvers[layerId];
    if (resolver == null) return;

    try {
      final current = Map<String, bool>.from(
        _cacheByUf[ufNorm] ?? state.hasDbByLayer,
      );

      final value = await resolver(ufNorm);
      current[layerId] = value;

      _cacheByUf[ufNorm] = Map<String, bool>.from(current);

      emit(state.copyWith(
        uf: ufNorm,
        hasDbByLayer: current,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        uf: ufNorm,
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void setHasData(String layerId, bool value) {
    final next = Map<String, bool>.from(state.hasDbByLayer);
    next[layerId] = value;

    final ufNorm = state.uf?.trim().toUpperCase();
    if (ufNorm != null && ufNorm.isNotEmpty) {
      _cacheByUf[ufNorm] = Map<String, bool>.from(next);
    }

    emit(state.copyWith(
      hasDbByLayer: next,
      clearError: true,
    ));
  }
}