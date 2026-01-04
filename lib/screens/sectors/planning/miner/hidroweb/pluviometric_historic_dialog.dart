import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/dates/selector/selectorDates.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/table/simple/simple_table_changed.dart';

import 'package:siged/_services/geography/ana_rain/ana_pluviometric_series_cubit.dart';
import 'package:siged/_services/geography/ana_rain/ana_pluviometric_series_state.dart';
import 'package:siged/_services/geography/ana_rain/ana_pluviometric_series_data.dart';

class PluviometricHistoricDialog extends StatelessWidget {
  final String codigoEstacao;
  final String stationName;

  const PluviometricHistoricDialog({
    super.key,
    required this.codigoEstacao,
    required this.stationName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnaPluviometricSeriesCubit(
        codigoEstacao: codigoEstacao,
        stationName: stationName,
      )..loadAllHistoric(daysBack: 30), // ex.: últimos 30 dias
      child: _PluviometricHistoricBody(
        codigoEstacao: codigoEstacao,
        stationName: stationName,
      ),
    );
  }
}

class _PluviometricHistoricBody extends StatefulWidget {
  final String codigoEstacao;
  final String stationName;

  const _PluviometricHistoricBody({
    required this.codigoEstacao,
    required this.stationName,
  });

  @override
  State<_PluviometricHistoricBody> createState() =>
      _PluviometricHistoricBodyState();
}

class _PluviometricHistoricBodyState
    extends State<_PluviometricHistoricBody> {
  List<AnaPluviometricSeriesData>? _filtered;

  List<AnaPluviometricSeriesData> _effective(AnaPluviometricSeriesState s) {
    return _filtered ?? s.series;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundClean(),
        BlocBuilder<AnaPluviometricSeriesCubit, AnaPluviometricSeriesState>(
          builder: (context, state) {
            if (state.status == AnaPluviometricSeriesStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == AnaPluviometricSeriesStatus.failure) {
              return Center(
                child: Text(
                  state.error ?? "Erro desconhecido.",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final list = _effective(state);

            // ---------- Definição de colunas (TELEMETRIA ADOTADA) ----------
            final columnTitles = <String>[
              "Data_Hora_Medicao",
              "Chuva_Adotada (mm)",
              "Chuva_Status",
              "Cota_Adotada (cm)",
              "Cota_Status",
              "Vazao_Adotada (m³/s)",
              "Vazao_Status",
              "Data_Atualizacao",
              "codigoestacao",
            ];

            String _rawOrEmpty(AnaPluviometricSeriesData d, String key) {
              final v = d.raw[key];
              return v?.toString() ?? '';
            }

            final columnGetters =
            <String Function(AnaPluviometricSeriesData)>[
                  (d) => d.dataHoraLabel, // Data_Hora_Medicao
                  (d) => d.chuvaAdotada,
                  (d) => d.chuvaStatus,
                  (d) => d.cotaAdotada,
                  (d) => d.cotaStatus,
                  (d) => d.vazaoAdotada,
                  (d) => d.vazaoStatus,
                  (d) => _rawOrEmpty(d, "Data_Atualizacao"),
                  (d) => _rawOrEmpty(d, "codigoestacao"),
            ];

            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectorDates<AnaPluviometricSeriesData>(
                    items: state.series,
                    getDate: (i) => i.date,
                    getLabel: (i) => i.dataHoraLabel,
                    sortByDate: true,
                    sortDescending: true, // mais recente primeiro
                    enableDaySelection: true,
                    autoSelectInitial: false,
                    onFilterChanged: (filtered) {
                      setState(() {
                        _filtered = filtered;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: list.isEmpty
                        ? const Center(
                      child: Text(
                        "Nenhum dado encontrado para o filtro.",
                      ),
                    )
                        : LayoutBuilder(
                      builder: (context, constraints) {
                        return SimpleTableChanged<
                            AnaPluviometricSeriesData>(
                          listData: list,
                          constraints: constraints,
                          status:
                          'Série telemétrica adotada (HidroinfoanaSerieTelemetricaAdotada)',
                          columnTitles: columnTitles,
                          columnGetters: columnGetters,
                          colorHeadTable: const Color(0xFF091D68),
                          colorHeadTableText: Colors.white,
                          onTapItem: null,
                          onDelete: null,
                          leadingCell: null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
