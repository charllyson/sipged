// lib/_services/map/map_box/service/nominatim_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import 'nominatim_data.dart';
import 'nominatim_repository.dart';
import 'nominatim_state.dart';

class NominatimCubit extends Cubit<NominatimState> {
  NominatimCubit({
    required NominatimRepository repository,
  })  : _repository = repository,
        super(NominatimState.initial());

  final NominatimRepository _repository;

  Future<Placemark?> getPlaceMarkAdapted(LatLng coords) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final placemark = await _repository.getPlaceMarkAdapted(coords);

      emit(
        state.copyWith(
          isLoading: false,
          placemark: placemark,
          selectedCoordinates: coords,
        ),
      );

      return placemark;
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao buscar endereço: $e',
        ),
      );

      return null;
    }
  }

  Future<LatLng?> getCoordinates(String address) async {
    final text = address.trim();

    if (text.isEmpty) return null;

    emit(
      state.copyWith(
        isSearching: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final coords = await _repository.getCoordinates(text);

      emit(
        state.copyWith(
          isSearching: false,
          selectedCoordinates: coords,
          clearSelectedCoordinates: coords == null,
        ),
      );

      return coords;
    } catch (e) {
      emit(
        state.copyWith(
          isSearching: false,
          errorMessage: 'Erro ao buscar coordenadas: $e',
        ),
      );

      return null;
    }
  }

  Future<List<NominatimData>> search(
      String query, {
        int limit = 6,
      }) async {
    final text = query.trim();

    if (text.isEmpty) {
      emit(
        state.copyWith(
          suggestions: const <NominatimData>[],
          clearErrorMessage: true,
        ),
      );

      return const <NominatimData>[];
    }

    emit(
      state.copyWith(
        isSearching: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final suggestions = await _repository.search(
        text,
        limit: limit,
      );

      emit(
        state.copyWith(
          isSearching: false,
          suggestions: suggestions,
        ),
      );

      return suggestions;
    } catch (e) {
      emit(
        state.copyWith(
          isSearching: false,
          suggestions: const <NominatimData>[],
          errorMessage: 'Erro ao pesquisar endereço: $e',
        ),
      );

      return const <NominatimData>[];
    }
  }

  Future<LatLng?> getUserCurrentLocation() async {
    emit(
      state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final location = await _repository.getUserCurrentLocation();

      emit(
        state.copyWith(
          isLoading: false,
          currentLocation: location,
          selectedCoordinates: location,
          clearCurrentLocation: location == null,
          clearSelectedCoordinates: location == null,
        ),
      );

      return location;
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao obter localização atual: $e',
        ),
      );

      return null;
    }
  }

  Future<int> getBuildNumber() async {
    emit(
      state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final buildNumber = await _repository.getBuildNumber();

      emit(
        state.copyWith(
          isLoading: false,
          buildNumber: buildNumber,
        ),
      );

      return buildNumber;
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Erro ao buscar build number: $e',
        ),
      );

      return 0;
    }
  }

  void clearSuggestions() {
    emit(
      state.copyWith(
        suggestions: const <NominatimData>[],
      ),
    );
  }
}