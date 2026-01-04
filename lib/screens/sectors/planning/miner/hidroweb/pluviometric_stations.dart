// lib/screens/sectors/planning/miner/hidroweb/pluviometric_stations.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_services/geography/ana_rain/ana_station_data.dart';
import 'package:siged/_services/geography/ana_rain/ana_stations_cubit.dart';
import 'package:siged/_services/geography/ana_rain/ana_stations_state.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';
import 'package:siged/_widgets/windows/show_window_dialog.dart';

// ⚠️ IMPORTANTE: este diálogo agora está usando SÉRIE TELEMÉTRICA
// (HidroinfoanaSerieTelemetricaAdotada) e não mais HIDROSerieChuva histórica.
import 'package:siged/screens/sectors/planning/miner/hidroweb/pluviometric_historic_dialog.dart';

// (O diálogo antigo de série histórica ou outra UI telemétrica
// ainda está aqui, se quiser separar depois.)
// ignore: unused_import
import 'package:siged/screens/sectors/planning/miner/hidroweb/pluviometric_series_dialog.dart';

import 'package:siged/_widgets/dates/selector/selectorDates.dart';

/// Página standalone – apenas ESTAÇÕES PLUVIOMÉTRICAS TELEMÉTRICAS.
class PluviometricPage extends StatelessWidget {
  const PluviometricPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
      AnaStationsCubit(stationType: 'PLUVIOMETRICA')..loadStations(),
      child: const Scaffold(
        body: PluviometricStationsPanel(),
      ),
    );
  }
}

/// Painel reutilizável que mostra a tabela de estações.
class PluviometricStationsPanel extends StatelessWidget {
  const PluviometricStationsPanel({super.key});

  /// Abre o diálogo com a SÉRIE TELEMÉTRICA ADOTADA da estação.
  void _openDialogs(
      BuildContext context,
      AnaStationsState state,
      AnaStationData station,
      ) {
    showWindowDialogMac(
      contentPadding: EdgeInsets.zero,
      context: context,
      title: 'Série telemétrica (últimos dias) - ${station.nome}',
      child: SizedBox(
        width: 1200,
        height: 600,
        child: PluviometricHistoricDialog(
          codigoEstacao: station.codigoEstacao,
          stationName: station.nome,
        ),
      ),
    );
  }

  /// Bolinha vermelha/verde com base no status de operação da estação.
  Widget _buildOperandoDot(AnaStationData s) {
    final label = s.operandoLabel.toLowerCase();
    final isOperating = label == 'sim' || label == 's';
    final color = isOperating ? Colors.green : Colors.red;

    return Center(
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Por enquanto, o SelectorDates aqui é apenas “cenário”;
    // o filtro real por data está dentro do diálogo de série telemétrica.
    final DateTime today = DateTime.now();

    return Stack(
      children: [
        BackgroundClean(),
        BlocBuilder<AnaStationsCubit, AnaStationsState>(
          builder: (context, state) {
            final cubit = context.read<AnaStationsCubit>();

            if (state.stations.isEmpty) {
              return Center(
                child: Text(
                  state.status == AnaStationsStatus.loading
                      ? 'Carregando estações...'
                      : 'Nenhuma estação carregada para a UF ${state.uf}.',
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: SelectorDates<DateTime>(
                          items: [today],
                          getDate: (d) => d,
                          initialYear: today.year,
                          initialMonth: today.month,
                          autoSelectInitial: true,
                          enableDaySelection: true,
                          sortByDate: true,
                          sortDescending: true,
                          onFilterChanged: (filtered) {
                            // Futuramente você pode vincular isso a alguma lógica
                            // de filtro de estações por data, se fizer sentido.
                          },
                          onSelectionChanged: ({
                            required List<DateTime> filteredItems,
                            int? selectedYear,
                            int? selectedMonth,
                            int? selectedDay,
                          }) {
                            // Mantido vazio por enquanto – o filtro de data
                            // para telemetria já está dentro do diálogo.
                          },
                        ),
                      ),
                      SimpleTableChanged<AnaStationData>(
                        listData: state.stations,
                        constraints: constraints,
                        columnTitles: const [
                          'Estação',
                          'Município',
                          'Medido (mm)',
                          'Latitude',
                          'Longitude',
                          'Cód. Estação',
                          'Cód. Bacia',
                        ],
                        columnGetters: [
                              (s) => s.nome,
                              (s) => s.municipio,
                          // Por enquanto fica vazio; depois podemos preencher com
                          // o último valor telemétrico de chuva da estação.
                              (s) => '',
                              (s) => s.latitude,
                              (s) => s.longitude,
                              (s) => s.codigoEstacao,
                              (s) => s.codigoBacia,
                        ],
                        groupBy: (s) => s.uf,
                        columnWidths: const [
                          100, // Operando
                          220, // Estação
                          180, // Município
                          170, // Medido (mm)
                          120, // Latitude
                          120, // Longitude
                          130, // Cód. Estação
                          110, // Cód. Bacia
                        ],
                        columnTextAligns: const [
                          TextAlign.left,   // Operando
                          TextAlign.left,   // Estação
                          TextAlign.left,   // Município
                          TextAlign.center, // Medido (mm)
                          TextAlign.center, // Latitude
                          TextAlign.center, // Longitude
                          TextAlign.center, // Cód. Estação
                          TextAlign.center, // Cód. Bacia
                        ],
                        leadingCell: _buildOperandoDot,
                        leadingCellTitle: 'Operando',
                        onTapItem: (item) {
                          cubit.selectStation(item);
                          _openDialogs(context, state, item);
                        },
                        onDelete: null,
                        colorHeadTable: const Color(0xFF091D68),
                        colorHeadTableText: Colors.white,
                        selectedItem: state.selectedStation,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
