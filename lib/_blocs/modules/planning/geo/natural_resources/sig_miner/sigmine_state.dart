import 'package:flutter/material.dart';

import 'sigmine_data.dart';

enum SigMineStatus {
  initial,
  loading,
  loaded,
  error,
}

class SigMineState {
  final SigMineStatus status;
  final bool showPanel;

  final List<SigMineData> features;
  final Set<String> mineriosAtivos; // chaves normalizadas
  final Map<String, Color> colorMap; // paleta por minério (normalizado)
  final Map<String, int> minerioCounts; // contagem global por minério

  final SigMineData? selectedFeature;

  final String selectedUF;
  final String? errorMessage;

  const SigMineState({
    required this.status,
    required this.showPanel,
    required this.features,
    required this.mineriosAtivos,
    required this.colorMap,
    required this.minerioCounts,
    required this.selectedFeature,
    required this.selectedUF,
    required this.errorMessage,
  });

  factory SigMineState.initial({String initialUF = 'AL'}) {
    return SigMineState(
      status: SigMineStatus.initial,
      showPanel: true,
      features: const [],
      mineriosAtivos: const {},
      colorMap: const {},
      minerioCounts: const {},
      selectedFeature: null,
      selectedUF: initialUF,
      errorMessage: null,
    );
  }

  bool get isLoading => status == SigMineStatus.loading;
  bool get hasData => features.isNotEmpty;
  bool get hasError =>
      errorMessage != null && errorMessage!.isNotEmpty;
  bool get isLoaded => status == SigMineStatus.loaded;

  SigMineState copyWith({
    SigMineStatus? status,
    bool? showPanel,
    List<SigMineData>? features,
    Set<String>? mineriosAtivos,
    Map<String, Color>? colorMap,
    Map<String, int>? minerioCounts,
    SigMineData? selectedFeature,
    bool clearSelectedFeature = false,
    String? selectedUF,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SigMineState(
      status: status ?? this.status,
      showPanel: showPanel ?? this.showPanel,
      features: features ?? this.features,
      mineriosAtivos: mineriosAtivos ?? this.mineriosAtivos,
      colorMap: colorMap ?? this.colorMap,
      minerioCounts: minerioCounts ?? this.minerioCounts,
      selectedFeature: clearSelectedFeature
          ? null
          : (selectedFeature ?? this.selectedFeature),
      selectedUF: selectedUF ?? this.selectedUF,
      errorMessage: clearError
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

/// ViewModel derivado para painel + mapa, calculado no Cubit.
///
/// A ideia é a tela não precisar fazer loops de filtragem/contagem.
class SigMineDerived {
  final List<SigMineData> visibleFeatures;
  final List<String> mineriosOrdenados; // chaves normalizadas
  final List<int> contagensVisiveis; // 1-1 com mineriosOrdenados
  final int? selectedMinerioIndex;

  const SigMineDerived({
    required this.visibleFeatures,
    required this.mineriosOrdenados,
    required this.contagensVisiveis,
    required this.selectedMinerioIndex,
  });

  bool get hasVisibleData => visibleFeatures.isNotEmpty;
}
