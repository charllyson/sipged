// lib/_services/ibge/ibge_localidade_state.dart
import 'package:equatable/equatable.dart';
import 'package:siged/_services/geography/ibge_location/ibge_localidade_data.dart';
import 'package:siged/_widgets/map/polygon/polygon_changed.dart';

class IBGELocationState extends Equatable {
  final bool isLoading;
  final String? errorMessage;

  final List<IBGELocationStateData> states;
  final IBGELocationStateData? selectedState;

  final List<PolygonChanged> cityPolygons;

  // 🔎 Detalhe de município selecionado
  final IBGELocationDetailData? selectedMunicipioDetail;
  final bool isLoadingMunicipioDetail;

  const IBGELocationState({
    required this.isLoading,
    required this.errorMessage,
    required this.states,
    required this.selectedState,
    required this.cityPolygons,
    required this.selectedMunicipioDetail,
    required this.isLoadingMunicipioDetail,
  });

  factory IBGELocationState.initial() {
    return const IBGELocationState(
      isLoading: false,
      errorMessage: null,
      states: [],
      selectedState: null,
      cityPolygons: [],
      selectedMunicipioDetail: null,
      isLoadingMunicipioDetail: false,
    );
  }

  IBGELocationState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<IBGELocationStateData>? states,
    IBGELocationStateData? selectedState,
    List<PolygonChanged>? cityPolygons,
    IBGELocationDetailData? selectedMunicipioDetail,
    bool clearMunicipioDetail = false,
    bool? isLoadingMunicipioDetail,
    bool clearError = false,
  }) {
    return IBGELocationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      states: states ?? this.states,
      selectedState: selectedState ?? this.selectedState,
      cityPolygons: cityPolygons ?? this.cityPolygons,
      selectedMunicipioDetail: clearMunicipioDetail
          ? null
          : (selectedMunicipioDetail ?? this.selectedMunicipioDetail),
      isLoadingMunicipioDetail:
      isLoadingMunicipioDetail ?? this.isLoadingMunicipioDetail,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    states,
    selectedState,
    cityPolygons,
    selectedMunicipioDetail,
    isLoadingMunicipioDetail,
  ];
}
