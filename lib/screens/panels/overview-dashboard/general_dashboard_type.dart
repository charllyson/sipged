// lib/screens/panels/overview-dashboard/general_dashboard_type.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/panels/general_dashboard/general_dashboard_cubit.dart';
import 'package:siged/_blocs/panels/general_dashboard/general_dashboard_state.dart';

class GeneralDashboardTypeFiltered extends StatelessWidget {
  const GeneralDashboardTypeFiltered({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<GeneralDashboardCubit>();
    final GeneralDashboardState state = cubit.state;

    return Row(
      children: [
        const SizedBox(width: 20),
        const Text(
          'Filtrar por: ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          dropdownColor: Colors.white,
          isDense: true,
          underline: Container(),
          value: state.tipoDeValorSelecionado,
          items: const [
            'Somatório total',
            'Valor contratado',
            'Total em aditivos',
            'Total em apostilas',
          ].map(
                (tipo) {
              return DropdownMenuItem(
                value: tipo,
                child: Text(tipo),
              );
            },
          ).toList(),
          onChanged: (val) {
            cubit.onTipoDeValorSelecionado(val ?? 'Somatório total');
          },
        ),
      ],
    );
  }
}
