import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/screens/modules/planning/geo/geo_network_controller.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_state.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/geo_layers_data.dart';

class GeoLayersCubit extends Cubit<GeoLayersState> {
  GeoLayersCubit({
    GeoLayersRepository? repository,
  })  : _repository = repository ?? GeoLayersRepository(),
        super(const GeoLayersState());

  final GeoLayersRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final tree = await _repository.loadTree();
      emit(state.copyWith(
        tree: tree,
        isLoading: false,
        loaded: true,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> saveTree(List<GeoLayersData> tree) async {
    emit(state.copyWith(
      tree: tree,
      isSaving: true,
      clearError: true,
    ));

    try {
      await _repository.saveTree(tree);
      emit(state.copyWith(
        tree: tree,
        isSaving: false,
        loaded: true,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        tree: tree,
        isSaving: false,
        error: e.toString(),
      ));
    }
  }

  Future<bool> hasDataForLayer(GeoLayersData layer) async {
    final path = (layer.effectiveCollectionPath ?? '').trim();
    if (path.isEmpty) return false;
    return _repository.hasData(collectionPath: path);
  }

  GeoNetworkController buildController() {
    return GeoNetworkController(initialTree: state.tree);
  }
}