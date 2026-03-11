import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/db/layer_db_status_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';

class LayerDbStatusCubit extends Cubit<LayerDbStatusState> {
  LayerDbStatusCubit({
    GeoLayersRepository? repository,
  })  : _repository = repository ?? GeoLayersRepository(),
        super(const LayerDbStatusState());

  final GeoLayersRepository _repository;

  final Map<String, bool> _cache = {};
  final Map<String, Future<bool>> _inFlightByPath = {};

  Future<void> refreshAll(List<GeoLayersData> tree, {bool force = false}) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final flattened = _flattenLeaves(tree);
      final next = <String, bool>{};

      final uniquePaths = <String>{};
      for (final layer in flattened) {
        final path = (layer.effectiveCollectionPath ?? '').trim();
        if (path.isNotEmpty) uniquePaths.add(path);
      }

      final resolvedByPath = <String, bool>{};
      await Future.wait(
        uniquePaths.map((path) async {
          resolvedByPath[path] = await _resolvePath(path, force: force);
        }),
      );

      for (final layer in flattened) {
        final path = (layer.effectiveCollectionPath ?? '').trim();
        next[layer.id] = path.isEmpty ? false : (resolvedByPath[path] ?? false);
      }

      emit(
        state.copyWith(
          hasDbByLayer: next,
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> refreshLayer(GeoLayersData layer, {bool force = false}) async {
    final path = (layer.effectiveCollectionPath ?? '').trim();

    if (path.isEmpty) {
      final current = Map<String, bool>.from(state.hasDbByLayer);
      current[layer.id] = false;
      emit(state.copyWith(hasDbByLayer: current, clearError: true));
      return;
    }

    try {
      final current = Map<String, bool>.from(state.hasDbByLayer);
      current[layer.id] = await _resolvePath(path, force: force);
      emit(state.copyWith(hasDbByLayer: current, clearError: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<bool> _resolvePath(String path, {bool force = false}) async {
    if (force) {
      _cache.remove(path);
      _inFlightByPath.remove(path);
    }

    if (_cache.containsKey(path)) return _cache[path]!;

    final inFlight = _inFlightByPath[path];
    if (inFlight != null) return inFlight;

    final future = _repository.hasData(collectionPath: path).whenComplete(() {
      _inFlightByPath.remove(path);
    });

    _inFlightByPath[path] = future;

    final value = await future;
    _cache[path] = value;
    return value;
  }

  List<GeoLayersData> _flattenLeaves(List<GeoLayersData> nodes) {
    final out = <GeoLayersData>[];

    void walk(List<GeoLayersData> list) {
      for (final item in list) {
        if (item.isGroup) {
          walk(item.children);
        } else {
          out.add(item);
        }
      }
    }

    walk(nodes);
    return out;
  }
}