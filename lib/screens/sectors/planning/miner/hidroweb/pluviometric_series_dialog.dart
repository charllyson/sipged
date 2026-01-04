import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_services/geography/ana_rain/ana_pluviometric_series_cubit.dart';
import 'package:siged/_services/geography/ana_rain/ana_pluviometric_series_state.dart';

/// Série histórica com RANGE CURTO (ex.: últimos dias)
class PluviometricSeriesDialog extends StatefulWidget {
  final Map<String, dynamic> station;

  const PluviometricSeriesDialog({
    super.key,
    required this.station,
  });

  @override
  State<PluviometricSeriesDialog> createState() =>
      _PluviometricSeriesDialogState();
}

class _PluviometricSeriesDialogState extends State<PluviometricSeriesDialog> {
  int _days = 30;

  String _get(String key) => widget.station[key]?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    final codigo = _get('codigoestacao');
    final nome = _get('Estacao_Nome');

    return BlocProvider(
      create: (_) => AnaPluviometricSeriesCubit(
        codigoEstacao: codigo,
        stationName: nome,
      )..loadAllHistoric(),
      child: BlocBuilder<AnaPluviometricSeriesCubit,
          AnaPluviometricSeriesState>(
        builder: (context, state) {
          if (state.status == AnaPluviometricSeriesStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = state.series.where((x) {
            if (x.date == null) return false;

            final diff =
            DateTime.now().difference(x.date!).inDays.abs();
            return diff <= _days;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$nome ($codigo)",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              // SELECTOR DE DIAS
              Row(
                children: [
                  const Text("Período: "),
                  DropdownButton<int>(
                    value: _days,
                    items: const [
                      DropdownMenuItem(value: 7, child: Text("7 dias")),
                      DropdownMenuItem(value: 15, child: Text("15 dias")),
                      DropdownMenuItem(value: 30, child: Text("30 dias")),
                      DropdownMenuItem(value: 60, child: Text("60 dias")),
                      DropdownMenuItem(value: 90, child: Text("90 dias")),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _days = v);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                "Registros: ${list.length}",
                style:
                const TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final i = list[index];

                    return ListTile(
                      dense: true,
                      title: Text(i.dataHoraLabel),
                      subtitle: Text("Total: ${i.raw["Total"] ?? "-"}"),
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
