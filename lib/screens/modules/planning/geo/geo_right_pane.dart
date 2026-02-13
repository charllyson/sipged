// lib/screens/modules/planning/geo/geo_right_pane.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/planning/geo/sig_miner/sigmine_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/sig_miner/sigmine_state.dart';

// IBGE – Localidades
import 'package:sipged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_state.dart';
import 'package:sipged/_widgets/background/background_cleaner.dart';

// Detalhes e painel
import 'package:sipged/screens/modules/planning/geo/ibge_localidade/municipio_details.dart';
import 'package:sipged/screens/modules/planning/geo/ores_sigmine/ores_details.dart';
import 'package:sipged/screens/modules/planning/geo/ores_sigmine/ores_panel.dart';

class GeoRightPane extends StatelessWidget {
  const GeoRightPane({
    super.key,
    required this.sigmineState,
    required this.ibgeState,
    required this.derived,
    required this.showSigmine,
    required this.showIbge,
    required this.showWeather,
    required this.getColorForMinerio,
  });

  final SigMineState sigmineState;
  final IBGELocationState ibgeState;

  /// Objeto derivado de [SigMineCubit.buildDerived].
  final dynamic derived;

  final bool showSigmine;
  final bool showIbge;
  final bool showWeather;

  final Color Function(String nome) getColorForMinerio;

  @override
  Widget build(BuildContext context) {
    final selectedFeature = sigmineState.selectedFeature;
    final selectedMunicipio = ibgeState.selectedMunicipioDetail;

    // 1) Detalhes da jazida selecionada (SIGMINE)
    if (selectedFeature != null && showSigmine) {
      return OresDetails(
        feature: selectedFeature,
        onClose: context.read<SigMineCubit>().closeDetails,
      );
    }

    // 2) Detalhes do município selecionado (IBGE)
    if (selectedMunicipio != null && showIbge) {
      return MunicipioDetails(
        detail: selectedMunicipio,
        onClose: () =>
            context.read<IBGELocationCubit>().closeMunicipioDetails(),
      );
    }

    // 3) Painel de jazidas (gauge + pizza + lista)
    if (showSigmine) {
      return OresPanel(
        minerios: derived.mineriosOrdenados,
        contagens: derived.contagensVisiveis,
        selectedIndex: derived.selectedMinerioIndex ?? -1,
        getColorForMinerio: getColorForMinerio,
        onSelectMinerio: (m) =>
            context.read<SigMineCubit>().selectSingleMinerio(m),
        hasData: derived.visibleFeatures.isNotEmpty,
      );
    }
    // 5) Mensagem quando IBGE está ativo, mas sem seleção
    if (showIbge) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Clique em um município para ver os detalhes.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 6) Nenhuma camada relevante ativa
    return Stack(
      children: [
        BackgroundClean(),
        const Center(
          child: Text("Ative uma camada para iniciar a análise."),
        ),
      ],
    );
  }
}
